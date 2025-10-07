import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bioscan/services/auth_service.dart';
import 'package:bioscan/screens/admin/admin_dashboard_screen.dart';
import 'package:bioscan/screens/manager/manager_dashboard_screen.dart';
import 'package:bioscan/theme/colors.dart' as app_colors;

class UserScreen extends StatefulWidget {
  final User user;
  final VoidCallback onNavigateToHistory;

  const UserScreen({super.key, required this.user, required this.onNavigateToHistory});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final AuthService _authService = AuthService();
  DocumentSnapshot? _userDoc; // Lưu trữ thông tin từ Firestore
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (widget.user.isAnonymous) {
      setState(() => _isLoading = false);
      return;
    }
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).get();
    if (mounted) {
      setState(() {
        _userDoc = doc;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final role = _userDoc?.exists == true ? (_userDoc!.data() as Map<String, dynamic>)['role'] : null;
    final teacherCode = _userDoc?.exists == true ? (_userDoc!.data() as Map<String, dynamic>)['teacherCode'] : null;
    final isPending = role == 'pending_teacher';
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 50),
              const CircleAvatar(radius: 50, backgroundColor: app_colors.formBackground, child: Icon(Icons.person, size: 60, color: app_colors.placeholder)),
              const SizedBox(height: 15),
              Text(
                widget.user.isAnonymous ? 'GUEST' : (widget.user.displayName ?? 'No Name'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: app_colors.textLight, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              if (!widget.user.isAnonymous)
                Text(
                  widget.user.email ?? 'No Email',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: app_colors.textLight, fontSize: 16),
                ),
              // --- HIỂN THỊ MÃ GIÁO VIÊN ---
              if (role == 'manager' && teacherCode != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Mã giáo viên của bạn: $teacherCode',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.yellow, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 40),
              // --- THÔNG BÁO CHỜ DUYỆT ---
              if (isPending)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Tài khoản của bạn đang chờ quản trị viên duyệt. Vui lòng đăng nhập lại sau.', textAlign: TextAlign.center, style: TextStyle(color: Colors.orangeAccent)),
                ),
              if (!isPending) ...[
                Card(
                  color: app_colors.formBackground,
                  child: ListTile(
                    leading: const Icon(Icons.history, color: app_colors.textDark),
                    title: const Text('Lịch sử quét của tôi', style: TextStyle(color: app_colors.textDark)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: app_colors.placeholder),
                    onTap: widget.onNavigateToHistory,
                  ),
                ),
                const SizedBox(height: 10),
                if (role == 'manager')
                  Card(
                    color: app_colors.primaryButton,
                    child: ListTile(
                      leading: const Icon(Icons.analytics, color: app_colors.textLight),
                      title: const Text('Bảng điều khiển', style: TextStyle(color: app_colors.textLight, fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: app_colors.textLight),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerDashboardScreen())),
                    ),
                  ),
                if (role == 'admin')
                  Card(
                    color: app_colors.primaryButton,
                    child: ListTile(
                      leading: const Icon(Icons.admin_panel_settings, color: app_colors.textLight),
                      title: const Text('Admin Panel', style: TextStyle(color: app_colors.textLight, fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: app_colors.textLight),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
                    ),
                  ),
              ],
              const Spacer(),
              TextButton.icon(
                onPressed: () async => await _authService.signOut(),
                icon: const Icon(Icons.logout, color: app_colors.textLight),
                label: const Text('ĐĂNG XUẤT', style: TextStyle(color: app_colors.textLight, fontSize: 16, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(backgroundColor: app_colors.primaryButton, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}