// lib/screens/admin/pending_teachers_screen.dart
import 'package:bioscan/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bioscan/theme/colors.dart' as app_colors;

class PendingTeachersScreen extends StatefulWidget {
  const PendingTeachersScreen({super.key});

  @override
  State<PendingTeachersScreen> createState() => _PendingTeachersScreenState();
}

class _PendingTeachersScreenState extends State<PendingTeachersScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app_colors.background,
      appBar: AppBar(
        title: const Text('Giáo viên chờ duyệt', style: TextStyle(color: app_colors.textLight)),
        backgroundColor: app_colors.background,
        iconTheme: const IconThemeData(color: app_colors.textLight),
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _authService.getPendingTeachers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có yêu cầu nào.', style: TextStyle(color: app_colors.textLight)));
          }

          final pendingUsers = snapshot.data!;
          return ListView.builder(
            itemCount: pendingUsers.length,
            itemBuilder: (context, index) {
              final user = pendingUsers[index];
              final userData = user.data() as Map<String, dynamic>;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(userData['username']),
                  subtitle: Text("${userData['email']}\n${userData['phone'] ?? 'Chưa có SĐT'}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () async {
                          await _authService.approveTeacher(user.id);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã duyệt thành công.'), backgroundColor: Colors.green));
                          setState(() {}); // Tải lại danh sách
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () async {
                           await _authService.rejectTeacher(user.id);
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã từ chối.'), backgroundColor: Colors.red));
                           setState(() {}); // Tải lại danh sách
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}