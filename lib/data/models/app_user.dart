// lib/data/models/app_user.dart

enum UserRole { student, faculty, admin }

class AppUser {
  const AppUser({
    required this.id,
    required this.role,
    required this.name,
    this.rollNumber,
    this.empId,
    this.email,
    this.division,
    this.semester,
    this.department,
    this.studentId,
  });

  final String id;
  final UserRole role;
  final String name;
  final String? rollNumber;
  final String? empId;
  final String? email;
  final String? division;
  final int? semester;
  final String? department;
  final String? studentId;

  bool get isStudent => role == UserRole.student;
  bool get isFaculty => role == UserRole.faculty;
  bool get isAdmin => role == UserRole.admin;

  factory AppUser.fromStudentMap(
      Map<String, dynamic> user, Map<String, dynamic> student) {
    return AppUser(
      id: user['id'] as String,
      role: UserRole.student,
      name: student['name'] as String,
      rollNumber: student['roll'] as String?,
      email: student['email'] as String?,
      division: student['division'] as String?,
      semester: student['semester'] as int?,
      department: student['department'] as String?,
      studentId: student['id'] as String?,
    );
  }

  factory AppUser.fromFacultyMap(
      Map<String, dynamic> user, Map<String, dynamic> faculty) {
    return AppUser(
      id: user['id'] as String,
      role: UserRole.faculty,
      name: faculty['name'] as String,
      empId: faculty['emp_id'] as String?,
      email: faculty['email'] as String?,
      department: faculty['department'] as String?,
    );
  }
}