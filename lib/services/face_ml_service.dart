// lib/services/face_ml_service.dart

import 'dart:typed_data';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:upastithi_pramaan/core/constants/app_constants.dart';
import 'package:upastithi_pramaan/core/utils/app_logger.dart';

class FaceMLService {
  Interpreter? _interpreter;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  // ── Model lifecycle ────────────────────────────────────────────────────────

  Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(
        AppConstants.tfliteModelPath,
        options: options,
      );
      _isLoaded = true;
      AppLogger.i('FaceMLService: model loaded');
    } catch (e) {
      AppLogger.e('FaceMLService: failed to load model', e);
      rethrow;
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }

  // ── Inference ──────────────────────────────────────────────────────────────

  /// Returns a normalised 128-d embedding, or null on failure.
  Future<List<double>?> getEmbedding(CameraImage image, Face face) async {
    if (!_isLoaded || _interpreter == null) return null;
    try {
      final input = _preprocessFaceSync(image, face);
      if (input == null) {
        AppLogger.e('FaceMLService: preprocessing returned null');
        return null;
      }

      // Shape: [1, 128]
      final output = [List.filled(AppConstants.faceEmbeddingSize, 0.0)];
      _interpreter!.run(input, output);

      final embedding = List<double>.from(output[0]);
      return _l2Normalize(embedding);
    } catch (e) {
      AppLogger.e('FaceMLService: inference error: $e');
      return null;
    }
  }

  // ── Preprocessing ──────────────────────────────────────────────────────────

  /// Crops face bbox from YUV420 Y-plane, resizes to 112×112,
  /// returns [1, 112, 112, 3] float32 tensor normalised to [-1, 1].
  List<List<List<List<double>>>>? _preprocessFaceSync(CameraImage image, Face face) {
    try {
      final bbox = face.boundingBox;
      final imgWidth = image.width;
      final imgHeight = image.height;

      final yPlane = image.planes[0];
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];

      final left = bbox.left.clamp(0, imgWidth - 1).toInt();
      final top = bbox.top.clamp(0, imgHeight - 1).toInt();
      final right = bbox.right.clamp(0, imgWidth - 1).toInt();
      final bottom = bbox.bottom.clamp(0, imgHeight - 1).toInt();

      final faceW = (right - left).clamp(1, imgWidth);
      final faceH = (bottom - top).clamp(1, imgHeight);
      const targetSize = 112;

      final tensor = List.generate(
        targetSize,
        (row) => List.generate(
          targetSize,
          (col) {
            final srcX = (left + (col / targetSize * faceW))
                .clamp(0, imgWidth - 1).toInt();
            final srcY = (top + (row / targetSize * faceH))
                .clamp(0, imgHeight - 1).toInt();

            final yVal = yPlane.bytes[srcY * yPlane.bytesPerRow + srcX].toDouble();

            // UV is half resolution
            final uvX = (srcX ~/ 2).clamp(0, imgWidth ~/ 2 - 1);
            final uvY = (srcY ~/ 2).clamp(0, imgHeight ~/ 2 - 1);
            final uVal = uPlane.bytes[uvY * uPlane.bytesPerRow + uvX * uPlane.bytesPerPixel!].toDouble();
            final vVal = vPlane.bytes[uvY * vPlane.bytesPerRow + uvX * vPlane.bytesPerPixel!].toDouble();

            // YUV → RGB
            final r = (yVal + 1.402 * (vVal - 128)).clamp(0, 255);
            final g = (yVal - 0.344136 * (uVal - 128) - 0.714136 * (vVal - 128)).clamp(0, 255);
            final b = (yVal + 1.772 * (uVal - 128)).clamp(0, 255);

            // Normalize to [-1, 1] as MobileFaceNet expects
            return [
              (r - 127.5) / 127.5,
              (g - 127.5) / 127.5,
              (b - 127.5) / 127.5,
            ];
          },
        ),
      );
      return [tensor];
    } catch (e) {
      AppLogger.e('FaceMLService: preprocessing error: $e');
      return null;
    }
  }

  // ── Enrollment ─────────────────────────────────────────────────────────────

  /// Averages a list of embeddings into one representative embedding.
  List<double> averageEmbeddings(List<List<double>> embeddings) {
    assert(embeddings.isNotEmpty);
    final size = embeddings.first.length;
    final avg = List.filled(size, 0.0);
    for (final e in embeddings) {
      for (int i = 0; i < size; i++) {
        avg[i] += e[i];
      }
    }
    for (int i = 0; i < size; i++) {
      avg[i] /= embeddings.length;
    }
    return _l2Normalize(avg);
  }

  /// Serialises embedding to bytes (128 × float32 = 512 bytes).
  static Uint8List embeddingToBytes(List<double> embedding) {
    final bd = ByteData(embedding.length * 4);
    for (int i = 0; i < embedding.length; i++) {
      bd.setFloat32(i * 4, embedding[i], Endian.little);
    }
    return bd.buffer.asUint8List();
  }

  /// Deserialises bytes back to embedding.
  static List<double> embeddingFromBytes(Uint8List bytes) {
    final bd = bytes.buffer.asByteData();
    final size = bytes.length ~/ 4;
    return List.generate(size, (i) => bd.getFloat32(i * 4, Endian.little));
  }

  // ── Matching ───────────────────────────────────────────────────────────────

  static bool isMatch(List<double> a, List<double> b) {
    return euclideanDistance(a, b) < AppConstants.faceMatchThreshold;
  }

  static double euclideanDistance(List<double> a, List<double> b) {
    double sum = 0;
    for (int i = 0; i < a.length; i++) {
      final diff = a[i] - b[i];
      sum += diff * diff;
    }
    return math.sqrt(sum);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  List<double> _l2Normalize(List<double> v) {
    double norm = 0;
    for (final x in v) {
      norm += x * x;
    }
    norm = math.sqrt(norm);
    if (norm == 0) return v;
    return v.map((x) => x / norm).toList();
  }
}

// ── Riverpod provider ──────────────────────────────────────────────────────

final faceMLServiceProvider = Provider<FaceMLService>((ref) {
  final service = FaceMLService();
  ref.onDispose(service.dispose);
  return service;
});