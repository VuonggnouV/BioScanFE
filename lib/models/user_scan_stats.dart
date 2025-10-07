// lib/models/user_scan_stats.dart
class UserScanStats {
  final String uid;
  final String username;
  final String email;
  final DateTime createdAt;
  final int totalScans;
  final DateTime? lastScanDate;
  final String role;
  final String? teacherCode; // <-- Thêm dòng này

  UserScanStats({
    required this.uid,
    required this.username,
    required this.email,
    required this.createdAt,
    required this.totalScans,
    this.lastScanDate,
    required this.role,
    this.teacherCode, // <-- Thêm vào constructor
  });
}