// lib/features/auth/register_screen.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:upastithi_pramaan/core/constants/app_constants.dart';
import 'package:upastithi_pramaan/core/theme/app_theme.dart';
import 'package:upastithi_pramaan/core/utils/app_logger.dart';
import 'package:upastithi_pramaan/data/models/app_user.dart';
import 'package:upastithi_pramaan/services/auth_service.dart';
import 'package:upastithi_pramaan/services/face_ml_service.dart';
import 'package:uuid/uuid.dart';

// ── Steps ─────────────────────────────────────────────────────────────────

enum _RegisterStep { details, face, done }

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  _RegisterStep _step = _RegisterStep.details;

  // ── Step 1 controllers ────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _divisionCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _institutionCtrl = TextEditingController();
  int _semester = 1;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  String? _errorMessage;
  bool _isLoading = false;

  // ── Step 2 face enrollment state ──────────────────────────────────────
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _cameraReady = false;
  bool _isProcessing = false;
  Face? _detectedFace;
  final List<List<double>> _enrollCaptures = [];
  static const int _enrollTarget = AppConstants.faceEnrollmentCaptures;
  String _faceStatus = 'Initialising camera…';
  bool _faceEnrolled = false;
  List<double>? _avgEmbedding;

  // ── Registered user (set after DB insert) ─────────────────────────────
  String? _newUserId;
  String? _newStudentId;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rollCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _divisionCtrl.dispose();
    _departmentCtrl.dispose();
    _institutionCtrl.dispose();
    _stopCamera();
    _faceDetector?.close();
    super.dispose();
  }

  // ── Step 1: Validate & insert user/student rows ───────────────────────

  Future<void> _submitDetails() async {
    final name = _nameCtrl.text.trim();
    final roll = _rollCtrl.text.trim().toUpperCase();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;
    final division = _divisionCtrl.text.trim().toUpperCase();
    final department = _departmentCtrl.text.trim();
    final institution = _institutionCtrl.text.trim();

    if (name.isEmpty || roll.isEmpty || password.isEmpty ||
        division.isEmpty || department.isEmpty) {
      setState(() => _errorMessage = 'Please fill all required fields');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = ref.read(supabaseClientProvider);
      final passwordHash = sha256.convert(utf8.encode(password)).toString();
      final userId = const Uuid().v4();
      final studentId = userId; // students.id = users.id per FK

      // 1. Insert into users
      await supabase.from('users').insert({
        'id': userId,
        'role': 'student',
        'password_hash': passwordHash,
        'name': name,
      });

      // 2. Insert into students
      await supabase.from('students').insert({
        'id': studentId,
        'roll': roll,
        'name': name,
        'email': email.isEmpty ? null : email,
        'division': division,
        'semester': _semester,
        'department': department,
        'institution': institution.isEmpty ? null : institution,
      });

      _newUserId = userId;
      _newStudentId = studentId;

      AppLogger.i('Registered user/student: $roll');

      // Move to face enrollment step
      setState(() => _step = _RegisterStep.face);
      await _initCamera();
    } catch (e) {
      AppLogger.e('Registration details error', e);
      setState(() => _errorMessage = 'Registration failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Step 2: Camera + face enrollment ─────────────────────────────────

  Future<void> _initCamera() async {
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
      await _cameraController!.startImageStream(_onCameraFrame);

      if (mounted) {
        setState(() {
          _cameraReady = true;
          _faceStatus = 'Look straight at the camera';
        });
      }
    } catch (e) {
      AppLogger.e('RegisterScreen camera init error', e);
      if (mounted) setState(() => _faceStatus = 'Camera init failed: $e');
    }
  }

  Future<void> _stopCamera() async {
    if (_cameraController?.value.isStreamingImages == true) {
      await _cameraController?.stopImageStream();
    }
    await _cameraController?.dispose();
    _cameraController = null;
  }

  Future<void> _onCameraFrame(CameraImage image) async {
    if (_isProcessing || _faceEnrolled) return;
    _isProcessing = true;
    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector!.processImage(inputImage);
      if (faces.isEmpty) {
        if (mounted) {
          setState(() {
            _detectedFace = null;
            _faceStatus = 'No face detected — look at camera';
          });
        }
        return;
      }

      final face = faces.first;
      if (mounted) setState(() => _detectedFace = face);

      // Auto-capture
      final mlService = ref.read(faceMLServiceProvider);
      final embedding = await mlService.getEmbedding(image, face);
      if (embedding == null) return;

      _enrollCaptures.add(embedding);
      final count = _enrollCaptures.length;
      if (mounted) {
        setState(() =>
            _faceStatus = 'Capturing ($count/$_enrollTarget) — hold still…');
      }

      if (count >= _enrollTarget) {
        await _stopCamera();
        await _saveEnrollment(mlService);
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
    final width = image.width;
    final height = image.height;

    final nv21 = Uint8List(width * height + (width * height ~/ 2));
    for (int i = 0; i < height; i++) {
      nv21.setRange(
          i * width, i * width + width, yPlane.bytes, i * yPlane.bytesPerRow);
    }
    int uvIndex = width * height;
    final uvHeight = height ~/ 2;
    final uvWidth = width ~/ 2;
    for (int i = 0; i < uvHeight; i++) {
      for (int j = 0; j < uvWidth; j++) {
        final vIdx = i * vPlane.bytesPerRow + j * vPlane.bytesPerPixel!;
        final uIdx = i * uPlane.bytesPerRow + j * uPlane.bytesPerPixel!;
        nv21[uvIndex++] = vPlane.bytes[vIdx];
        nv21[uvIndex++] = uPlane.bytes[uIdx];
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

  Future<void> _saveEnrollment(FaceMLService mlService) async {
    if (mounted) setState(() => _faceStatus = 'Saving face enrollment…');
    try {
      final avgEmbedding = mlService.averageEmbeddings(_enrollCaptures);
      _avgEmbedding = avgEmbedding;

      final supabase = ref.read(supabaseClientProvider);
      await supabase.from('face_embeddings').upsert({
        'student_id': _newStudentId,
        'embedding': avgEmbedding,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'student_id');

      AppLogger.i('Face enrolled for student: $_newStudentId');

      if (mounted) {
        setState(() {
          _faceEnrolled = true;
          _faceStatus = 'Face enrolled successfully!';
          _step = _RegisterStep.done;
        });
      }
    } catch (e) {
      AppLogger.e('Face enrollment save error', e);
      if (mounted) {
        setState(() => _faceStatus = 'Face save failed: $e — tap retry');
      }
    }
  }

  Future<void> _retryFaceEnrollment() async {
    _enrollCaptures.clear();
    setState(() {
      _faceEnrolled = false;
      _faceStatus = 'Look straight at the camera';
    });
    await _initCamera();
  }

  // ── Step 3: Login as newly registered student ─────────────────────────

  void _goToLogin() {
    // Set current user and go to student dashboard
    final user = AppUser(
      id: _newUserId!,
      studentId: _newStudentId,
      role: UserRole.student,
      name: _nameCtrl.text.trim(),
      rollNumber: _rollCtrl.text.trim().toUpperCase(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      division: _divisionCtrl.text.trim().toUpperCase(),
      semester: _semester,
      department: _departmentCtrl.text.trim(),
    );
    ref.read(currentUserProvider.notifier).state = user;
    context.go(AppConstants.routeStudentDashboard);
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Registration'),
        leading: _step == _RegisterStep.details
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go(AppConstants.routeLogin),
              )
            : const SizedBox.shrink(),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: switch (_step) {
                _RegisterStep.details => _buildDetailsStep(),
                _RegisterStep.face => _buildFaceStep(),
                _RegisterStep.done => _buildDoneStep(),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _StepDot(
              number: 1,
              label: 'Details',
              active: _step == _RegisterStep.details,
              done: _step != _RegisterStep.details),
          Expanded(
            child: Container(
              height: 2,
              color: _step != _RegisterStep.details
                  ? AppTheme.primary
                  : AppTheme.border,
            ),
          ),
          _StepDot(
              number: 2,
              label: 'Face',
              active: _step == _RegisterStep.face,
              done: _step == _RegisterStep.done),
          Expanded(
            child: Container(
              height: 2,
              color:
                  _step == _RegisterStep.done ? AppTheme.primary : AppTheme.border,
            ),
          ),
          _StepDot(
              number: 3,
              label: 'Done',
              active: _step == _RegisterStep.done,
              done: false),
        ],
      ),
    );
  }

  // ── Step 1: Details form ──────────────────────────────────────────────

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Personal Details',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          const Text('Fill in your information to create an account',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 24),

          _FieldLabel('Full Name *'),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'e.g. Aryan Sharma',
              prefixIcon:
                  Icon(Icons.person_outline, color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 16),

          _FieldLabel('Roll Number *'),
          TextField(
            controller: _rollCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'e.g. CE002',
              prefixIcon:
                  Icon(Icons.badge_outlined, color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 16),

          _FieldLabel('Email'),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'e.g. aryan@college.edu',
              prefixIcon:
                  Icon(Icons.email_outlined, color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Division *'),
                    TextField(
                      controller: _divisionCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(hintText: 'e.g. A'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Semester *'),
                    _SemesterDropdown(
                      value: _semester,
                      onChanged: (v) => setState(() => _semester = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _FieldLabel('Department *'),
          TextField(
            controller: _departmentCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'e.g. Computer Engineering',
              prefixIcon:
                  Icon(Icons.school_outlined, color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 16),

          _FieldLabel('Institution'),
          TextField(
            controller: _institutionCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'e.g. XYZ College of Engineering',
              prefixIcon: Icon(Icons.business_outlined,
                  color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 16),

          _FieldLabel('Password *'),
          TextField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Min 6 characters',
              prefixIcon: const Icon(Icons.lock_outline,
                  color: AppTheme.textSecondary),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _FieldLabel('Confirm Password *'),
          TextField(
            controller: _confirmPasswordCtrl,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline,
                  color: AppTheme.textSecondary),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
              ),
              child: Text(_errorMessage!,
                  style:
                      const TextStyle(color: AppTheme.error, fontSize: 13)),
            ),
          ],

          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isLoading ? null : _submitDetails,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Continue to Face Enrollment'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Step 2: Face enrollment ───────────────────────────────────────────

  Widget _buildFaceStep() {
    final progress = (_enrollCaptures.length / _enrollTarget).clamp(0.0, 1.0);
    final failed = _faceStatus.contains('failed') || _faceStatus.contains('error');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Face Enrollment',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          const Text(
              'Keep your face centred and still. Captures automatically.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),

          // Camera preview
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Camera
                  if (_cameraReady && _cameraController != null &&
                      _cameraController!.value.isInitialized)
                    AspectRatio(
                      aspectRatio: _cameraController!.value.aspectRatio,
                      child: CameraPreview(_cameraController!),
                    )
                  else
                    const Center(child: CircularProgressIndicator()),

                  // Bounding box
                  if (_detectedFace != null &&
                      _cameraController != null &&
                      _cameraController!.value.isInitialized)
                    CustomPaint(
                      painter: _FaceBoxPainter(
                        face: _detectedFace!,
                        imageSize: Size(
                          _cameraController!.value.previewSize!.height,
                          _cameraController!.value.previewSize!.width,
                        ),
                      ),
                    ),

                  // Status overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      color: Colors.black54,
                      child: Text(
                        _faceStatus,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_enrollCaptures.length}/$_enrollTarget captures',
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
          ),

          if (failed) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _retryFaceEnrollment,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry Enrollment'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Step 3: Done ──────────────────────────────────────────────────────

  Widget _buildDoneStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user,
                  color: AppTheme.accent, size: 40),
            ),
            const SizedBox(height: 24),
            const Text('Registration Complete!',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Welcome, ${_nameCtrl.text.trim()}.\nYour face has been enrolled.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _goToLogin,
              icon: const Icon(Icons.dashboard_outlined, size: 18),
              label: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary)),
    );
  }
}

class _SemesterDropdown extends StatelessWidget {
  const _SemesterDropdown({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
      items: List.generate(
        8,
        (i) => DropdownMenuItem(value: i + 1, child: Text('Sem ${i + 1}')),
      ),
      onChanged: (v) => onChanged(v ?? 1),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.number,
    required this.label,
    required this.active,
    required this.done,
  });
  final int number;
  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final color = active || done ? AppTheme.primary : AppTheme.border;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : Text('$number',
                    style: TextStyle(
                        color: active || done
                            ? Colors.white
                            : AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: active ? AppTheme.primary : AppTheme.textSecondary,
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.w400)),
      ],
    );
  }
}

// ── Face bounding box painter ─────────────────────────────────────────────

class _FaceBoxPainter extends CustomPainter {
  const _FaceBoxPainter({required this.face, required this.imageSize});
  final Face face;
  final Size imageSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = AppTheme.primary;

    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    final rect = Rect.fromLTRB(
      size.width - face.boundingBox.right * scaleX,
      face.boundingBox.top * scaleY,
      size.width - face.boundingBox.left * scaleX,
      face.boundingBox.bottom * scaleY,
    );

    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);
  }

  @override
  bool shouldRepaint(_FaceBoxPainter old) => old.face != face;
}