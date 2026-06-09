// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  static const String appName = 'Upastithi Pramaan';
  static const String appVersion = '1.0.0';

  // Session code
  static const int sessionCodeLength = 6;
  static const int sessionCodeRefreshMinSeconds = 40;
  static const int sessionCodeRefreshMaxSeconds = 50;

  // Face recognition
  static const String tfliteModelPath = 'assets/models/mobilefacenet.tflite';
  static const int faceEmbeddingSize = 128;
  static const int faceEnrollmentCaptures = 5;
  static const double faceMatchThreshold = 0.45;

  // BLE RSSI
  static const int rssiThreshold = -65;
  static const int rssiWindowSize = 7;

  // Sync
  static const Duration syncRetryInterval = Duration(minutes: 5);

  // Routes
  static const String routeLogin = '/login';
  static const String routeTeacherDashboard = '/teacher';
  static const String routeStudentDashboard = '/student';
  static const String routeRegister = '/register';

  // Admin routes
  static const String routeAdminDashboard = '/admin';
  static const String routeAdminAddFaculty = '/admin/add-faculty';
  static const String routeAdminSubjects = '/admin/subjects';
  static const String routeAdminStudents = '/admin/students';
  static const String routeAdminFaculty = '/admin/faculty';
}