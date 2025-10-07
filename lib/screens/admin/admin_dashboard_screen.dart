import 'package:bioscan/screens/admin/admin_management_screen.dart';
import 'package:bioscan/screens/admin/archived_guests_screen.dart';
import 'package:bioscan/screens/admin/pending_teachers_screen.dart';
import 'package:bioscan/services/auth_service.dart'; // Import AuthService
import 'package:flutter/material.dart';
import 'package:bioscan/theme/colors.dart' as app_colors;

class AdminDashboardScreen extends StatefulWidget { 
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AuthService _authService = AuthService();
  bool _hasPendingRequests = false; // State để lưu trạng thái có yêu cầu chờ duyệt hay không

  @override
  void initState() {
    super.initState();
    _checkPendingRequests();
  }

  // Hàm kiểm tra các yêu cầu đang chờ
  Future<void> _checkPendingRequests() async {
    final pendingTeachers = await _authService.getPendingTeachers();
    if (mounted) { // Kiểm tra để đảm bảo widget vẫn còn tồn tại
      setState(() {
        _hasPendingRequests = pendingTeachers.isNotEmpty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app_colors.background,
      appBar: AppBar(
        title: const Text('Admin Panel', style: TextStyle(color: app_colors.textLight)),
        backgroundColor: app_colors.background,
        iconTheme: const IconThemeData(color: app_colors.textLight),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.people, color: app_colors.textLight),
            title: const Text('Quản lý người dùng', style: TextStyle(color: app_colors.textLight)),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminManagementScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.no_accounts, color: app_colors.textLight),
            title: const Text('Xem lượt truy cập của khách', style: TextStyle(color: app_colors.textLight)),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ArchivedGuestsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.how_to_reg, color: app_colors.textLight),
            // --- PHẦN TITLE ĐÃ SỬA ---
            title: Row(
              children: [
                const Text('Duyệt tài khoản Giáo viên', style: TextStyle(color: app_colors.textLight)),
                const SizedBox(width: 8),
                // Nếu có yêu cầu, hiển thị dấu chấm đỏ
                if (_hasPendingRequests)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            onTap: () async {
              // Sau khi nhấn vào, điều hướng và có thể refresh lại trạng thái khi quay về
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingTeachersScreen()));
              _checkPendingRequests(); // Kiểm tra lại sau khi màn hình duyệt được đóng
            },
          ),
        ],
      ),
    );
  }
}