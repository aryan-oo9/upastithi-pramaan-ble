// lib/features/student/face_verification_widget.dart

import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:upastithi_pramaan/core/constants/app_constants.dart';
import 'package:upastithi_pramaan/core/theme/app_theme.dart';
import 'package:upastithi_pramaan/core/utils/app_logger.dart';
import 'package:upastithi_pramaan/data/local/app_database.dart';
import 'package:upastithi_pramaan/data/local/models/student_embedding.dart';
import 'package:upastithi_pramaan/services/auth_service.dart';
import 'package:upastithi_pramaan/services/face_ml_service.dart';
import 'package:uuid/uuid.dart';

enum _FaceWidgetMode { verifying, enrolling }

enum FaceVerifyStatus {
  initialising,
  noEnrollment,
  scanning,
  processing,
  matched,
  noMatch,
  enrollCapturing,
  enrollDone,
  error,
}

class FaceVerificationWidget extends ConsumerStatefulWidget {
  const FaceVerificationWidget({
    super.key,
    required this.onVerified,
  });

  final VoidCallback onVerified;

  @override
  ConsumerState<FaceVerificationWidget> createState() =>
      _FaceVerificationWidgetState();
}

class _FaceVerificationWidgetState
    extends ConsumerState<FaceVerificationWidget> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;

  FaceVerifyStatus _status = FaceVerifyStatus.initialising;
  _FaceWidgetMode _mode = _FaceWidgetMode.verifying;
  String _statusMessage = 'Initialising camera…';

  Face? _detectedFace;
  bool _isProcessing = false;

  final List<List<double>> _enrollCaptures = [];
  static const int _enrollTarget = AppConstants.faceEnrollmentCaptures;

  Uint8List? _storedEmbeddingBytes;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    if (_cameraController?.value.isStreamingImages == true) {
      _cameraController?.stopImageStream();
    }
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    try {
      await ref.read(faceMLServiceProvider).loadModel();

      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableLandmarks: false,
          enableClassification: false,
        ),
      );

      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _cameraController!.initialize();

      final user = ref.read(currentUserProvider);
      if (user != null && user.studentId != null) {
        // 1. Try Drift cache first
        final db = ref.read(appDatabaseProvider);
        final rows = await db.getAllEmbeddings();
        final localRow = rows
            .where((r) => r.studentRollNumber == user.rollNumber)
            .firstOrNull;

        if (localRow != null) {
          _storedEmbeddingBytes = localRow.embedding;
          _setStatus(FaceVerifyStatus.scanning, 'Position your face in the frame');
        } else {
          // 2. Fall back to Supabase
          await _fetchEmbeddingFromSupabase(user.studentId!);
        }
      } else {
        _setStatus(FaceVerifyStatus.noEnrollment, 'No face enrolled — enroll first');
      }

      await _cameraController!.startImageStream(_onCameraFrame);
      if (mounted) setState(() {});
    } catch (e) {
      AppLogger.e('FaceVerificationWidget: init error', e);
      _setStatus(FaceVerifyStatus.error, 'Camera init failed: $e');
    }
  }

  Future<void> _fetchEmbeddingFromSupabase(String studentId) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      final res = await supabase
          .from('face_embeddings')
          .select('embedding')
          .eq('student_id', studentId)
          .maybeSingle();

      if (res == null || res['embedding'] == null) {
        _setStatus(FaceVerifyStatus.noEnrollment, 'No face enrolled — enroll first');
        return;
      }

      final jsonList = res['embedding'] as List<dynamic>;
      final embedding = jsonList.map((e) => (e as num).toDouble()).toList();
      final bytes = FaceMLService.embeddingToBytes(embedding);

      // Cache to Drift
      final user = ref.read(currentUserProvider)!;
      final db = ref.read(appDatabaseProvider);
      await db.upsertEmbedding(StudentEmbeddingsCompanion(
        id: Value(const Uuid().v4()),
        studentName: Value(user.name),
        studentRollNumber: Value(user.rollNumber),
        embedding: Value(bytes),
        enrolledAt: Value(DateTime.now().millisecondsSinceEpoch),
        synced: const Value(true),
      ));

      _storedEmbeddingBytes = bytes;
      _setStatus(FaceVerifyStatus.scanning, 'Position your face in the frame');
      AppLogger.i('Embedding fetched from Supabase for $studentId');
    } catch (e) {
      AppLogger.e('_fetchEmbeddingFromSupabase error', e);
      _setStatus(FaceVerifyStatus.noEnrollment, 'No face enrolled — enroll first');
    }
  }

  void _setStatus(FaceVerifyStatus status, String message) {
    if (!mounted) return;
    setState(() {
      _status = status;
      _statusMessage = message;
    });
  }

  // ── Camera frame processing ───────────────────────────────────────────────

  Future<void> _onCameraFrame(CameraImage image) async {
    if (_isProcessing) return;
    if (_status == FaceVerifyStatus.matched ||
        _status == FaceVerifyStatus.enrollDone ||
        _status == FaceVerifyStatus.error ||
        _status == FaceVerifyStatus.initialising ||
        _status == FaceVerifyStatus.noEnrollment ||
        _status == FaceVerifyStatus.processing) {
      return;
    }

    _isProcessing = true;
    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector!.processImage(inputImage);
      if (faces.isEmpty) {
        if (_status == FaceVerifyStatus.scanning) {
          _setStatus(FaceVerifyStatus.scanning, 'No face detected — look at camera');
        }
        if (mounted) setState(() => _detectedFace = null);
        return;
      }

      final face = faces.first;
      if (mounted) setState(() => _detectedFace = face);

      if (_mode == _FaceWidgetMode.verifying && _storedEmbeddingBytes != null) {
        await _runVerification(image, face);
      } else if (_mode == _FaceWidgetMode.enrolling &&
          _status == FaceVerifyStatus.enrollCapturing) {
        await _runEnrollCapture(image, face);
      }
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _buildInputImage(CameraImage image) {
    final controller = _cameraController;
    if (controller == null) return null;

    final sensorOrientation = controller.description.sensorOrientation;
    final rotation = switch (sensorOrientation) {
      90 => InputImageRotation.rotation90deg,
      180 => InputImageRotation.rotation180deg,
      270 => InputImageRotation.rotation270deg,
      _ => InputImageRotation.rotation0deg,
    };

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;

    final width = image.width;
    final height = image.height;

    final nv21 = Uint8List(width * height + (width * height ~/ 2));

    for (int i = 0; i < height; i++) {
      nv21.setRange(i * width, i * width + width, yBytes, i * yPlane.bytesPerRow);
    }

    int uvIndex = width * height;
    final uvHeight = height ~/ 2;
    final uvWidth = width ~/ 2;
    for (int i = 0; i < uvHeight; i++) {
      for (int j = 0; j < uvWidth; j++) {
        final vIdx = i * vPlane.bytesPerRow + j * vPlane.bytesPerPixel!;
        final uIdx = i * uPlane.bytesPerRow + j * uPlane.bytesPerPixel!;
        nv21[uvIndex++] = vBytes[vIdx];
        nv21[uvIndex++] = uBytes[uIdx];
      }
    }

    return InputImage.fromBytes(
      bytes: nv21,
      metadata: InputImageMetadata(
        size: Size(width.toDouble(), height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: width,
      ),
    );
  }

  // ── Verification ──────────────────────────────────────────────────────────

  Future<void> _runVerification(CameraImage image, Face face) async {
    _setStatus(FaceVerifyStatus.processing, 'Verifying…');
    final mlService = ref.read(faceMLServiceProvider);
    final liveEmbedding = await mlService.getEmbedding(image, face);
    if (liveEmbedding == null) {
      _setStatus(FaceVerifyStatus.scanning, 'Could not read face — try again');
      return;
    }

    final stored = FaceMLService.embeddingFromBytes(_storedEmbeddingBytes!);
    final dist = FaceMLService.euclideanDistance(liveEmbedding, stored);
    AppLogger.d('Face distance: $dist');

    if (FaceMLService.isMatch(liveEmbedding, stored)) {
      _setStatus(FaceVerifyStatus.matched, 'Face matched ✓');
      await _cameraController?.stopImageStream();
      widget.onVerified();
    } else {
      _setStatus(FaceVerifyStatus.noMatch,
          'Face not matched (dist: ${dist.toStringAsFixed(2)}) — try again');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted && _status != FaceVerifyStatus.matched) {
        _setStatus(FaceVerifyStatus.scanning, 'Position your face in the frame');
      }
    }
  }

  // ── Enrollment ────────────────────────────────────────────────────────────

  void _startEnrollment() {
    _enrollCaptures.clear();
    setState(() => _mode = _FaceWidgetMode.enrolling);
    _setStatus(FaceVerifyStatus.enrollCapturing,
        'Capturing (0/$_enrollTarget) — look straight at camera');
  }

  Future<void> _runEnrollCapture(CameraImage image, Face face) async {
    final mlService = ref.read(faceMLServiceProvider);
    final embedding = await mlService.getEmbedding(image, face);
    if (embedding == null) return;
    if (!mounted) return;

    _enrollCaptures.add(embedding);
    final count = _enrollCaptures.length;
    _setStatus(FaceVerifyStatus.enrollCapturing, 'Capturing ($count/$_enrollTarget)…');

    if (count >= _enrollTarget) {
      await _saveEnrollment(mlService);
    }
  }

  Future<void> _saveEnrollment(FaceMLService mlService) async {
    await _cameraController?.stopImageStream();
    _setStatus(FaceVerifyStatus.processing, 'Saving enrollment…');

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not found');
      if (user.studentId == null) throw Exception('Student ID not found');

      final avgEmbedding = mlService.averageEmbeddings(_enrollCaptures);
      final bytes = FaceMLService.embeddingToBytes(avgEmbedding);

      // 1. Save to Drift
      final db = ref.read(appDatabaseProvider);
      await db.upsertEmbedding(StudentEmbeddingsCompanion(
        id: Value(const Uuid().v4()),
        studentName: Value(user.name),
        studentRollNumber: Value(user.rollNumber),
        embedding: Value(bytes),
        enrolledAt: Value(DateTime.now().millisecondsSinceEpoch),
        synced: const Value(false),
      ));

      // 2. Sync to Supabase keyed by students.id
      final supabase = ref.read(supabaseClientProvider);
      await supabase.from('face_embeddings').upsert({
        'student_id': user.studentId,
        'embedding': avgEmbedding,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'student_id');

      // 3. Mark Drift row as synced
      final rows = await db.getAllEmbeddings();
      final row = rows
          .where((r) => r.studentRollNumber == user.rollNumber)
          .firstOrNull;
      if (row != null) {
        await db.upsertEmbedding(StudentEmbeddingsCompanion(
          id: Value(row.id),
          studentName: Value(row.studentName),
          studentRollNumber: Value(row.studentRollNumber),
          embedding: Value(row.embedding),
          enrolledAt: Value(row.enrolledAt),
          synced: const Value(true),
        ));
      }

      _storedEmbeddingBytes = bytes;
      _mode = _FaceWidgetMode.verifying;
      _setStatus(FaceVerifyStatus.enrollDone, 'Enrollment complete! Tap to verify');
      AppLogger.i('Face enrolled and synced for ${user.studentId}');
    } catch (e) {
      AppLogger.e('Enrollment save failed', e);
      _setStatus(FaceVerifyStatus.error, 'Enrollment failed: $e');
    }
  }

  Future<void> _restartStream() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    _enrollCaptures.clear();
    _mode = _FaceWidgetMode.verifying;
    await _cameraController!.startImageStream(_onCameraFrame);
    _setStatus(FaceVerifyStatus.scanning, 'Position your face in the frame');
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildCameraPreview(),
                _buildFaceOverlay(),
                _buildStatusOverlay(),
              ],
            ),
          ),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final ctrl = _cameraController;
    if (ctrl == null || !ctrl.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return CameraPreview(ctrl);
  }

  Widget _buildFaceOverlay() {
    if (_detectedFace == null || _cameraController == null) {
      return const SizedBox.shrink();
    }
    return CustomPaint(
      painter: _FaceBoundingBoxPainter(
        face: _detectedFace!,
        imageSize: Size(
          _cameraController!.value.previewSize!.height,
          _cameraController!.value.previewSize!.width,
        ),
        isMatched: _status == FaceVerifyStatus.matched,
        isNoMatch: _status == FaceVerifyStatus.noMatch,
      ),
    );
  }

  Widget _buildStatusOverlay() {
    Color bgColor = Colors.black54;
    if (_status == FaceVerifyStatus.matched) {
      bgColor = AppTheme.accent.withValues(alpha: 0.8);
    }
    if (_status == FaceVerifyStatus.noMatch) {
      bgColor = AppTheme.error.withValues(alpha: 0.7);
    }
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        color: bgColor,
        child: Text(
          _statusMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          if (_status == FaceVerifyStatus.noEnrollment)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startEnrollment,
                icon: const Icon(Icons.face_retouching_natural, size: 18),
                label: const Text('Enroll My Face'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          if (_status == FaceVerifyStatus.enrollDone) ...[
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: AppTheme.accent, size: 16),
                SizedBox(width: 6),
                Text('Enrolled!',
                    style: TextStyle(
                        color: AppTheme.accent, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _restartStream,
                child: const Text('Start Verification'),
              ),
            ),
          ],
          if (_status == FaceVerifyStatus.matched)
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user, color: AppTheme.accent, size: 16),
                SizedBox(width: 6),
                Text('Identity Verified',
                    style: TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ],
            ),
          if (_status == FaceVerifyStatus.error)
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _status = FaceVerifyStatus.initialising);
                _init();
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error),
            ),
          if (_status != FaceVerifyStatus.enrollCapturing &&
              _status != FaceVerifyStatus.processing &&
              _status != FaceVerifyStatus.initialising &&
              _status != FaceVerifyStatus.noEnrollment)
            TextButton(
              onPressed: _startEnrollment,
              child: const Text('Re-enroll face',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
            ),
        ],
      ),
    );
  }
}

// ── Bounding box painter ──────────────────────────────────────────────────

class _FaceBoundingBoxPainter extends CustomPainter {
  const _FaceBoundingBoxPainter({
    required this.face,
    required this.imageSize,
    required this.isMatched,
    required this.isNoMatch,
  });

  final Face face;
  final Size imageSize;
  final bool isMatched;
  final bool isNoMatch;

  @override
  void paint(Canvas canvas, Size size) {
    final Color color = isMatched
        ? AppTheme.accent
        : isNoMatch
            ? AppTheme.error
            : AppTheme.primary;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = color;

    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    final rect = Rect.fromLTRB(
      size.width - face.boundingBox.right * scaleX,
      face.boundingBox.top * scaleY,
      size.width - face.boundingBox.left * scaleX,
      face.boundingBox.bottom * scaleY,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_FaceBoundingBoxPainter old) =>
      old.face != face ||
      old.isMatched != isMatched ||
      old.isNoMatch != isNoMatch;
}