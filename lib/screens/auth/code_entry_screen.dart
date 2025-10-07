import 'package:bioscan/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bioscan/theme/colors.dart' as app_colors;

class CodeEntryScreen extends StatefulWidget {
  final VoidCallback onCodeVerified;
  const CodeEntryScreen({super.key, required this.onCodeVerified});

  @override
  State<CodeEntryScreen> createState() => _CodeEntryScreenState();
}

class _CodeEntryScreenState extends State<CodeEntryScreen> {
  final _codeController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorText;
  bool _wasRejected = false;

  @override
  void initState() {
    super.initState();
    _checkIfRejected();
  }

  Future<void> _checkIfRejected() async {
    final user = _authService.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted && doc.exists) {
        setState(() {
          _wasRejected = doc.data()?['wasRejected'] ?? false;
        });
      }
    }
  }

  void _submitCode() async {
    if (_codeController.text.isEmpty) return;
    setState(() { _isLoading = true; _errorText = null; });
    
    final result = await _authService.linkStudentToTeacher(_codeController.text.trim());

    if (result == "success") {
      widget.onCodeVerified();
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorText = result;
        });
      }
    }
  }

  void _handleReapply() async {
    setState(() => _isLoading = true);
    await _authService.reapplyAsTeacher();
    widget.onCodeVerified(); // Refresh lại AuthGate để nó nhận diện vai trò mới
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app_colors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.school_outlined, size: 80, color: app_colors.textLight),
              const SizedBox(height: 20),
              const Text('Yêu cầu liên kết', style: TextStyle(color: app_colors.textLight, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text(
                'Bạn cần nhập mã do giáo viên cung cấp để có thể sử dụng các tính năng của ứng dụng.',
                style: TextStyle(color: app_colors.placeholder, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: app_colors.textDark, letterSpacing: 3),
                decoration: InputDecoration(
                  hintText: 'MÃ GIÁO VIÊN',
                  filled: true,
                  fillColor: app_colors.formBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  errorText: _errorText,
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _submitCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: app_colors.primaryButton,
                    foregroundColor: app_colors.textLight,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('XÁC NHẬN'),
                ),
              
              // --- NÚT ĐĂNG KÝ LẠI CHO GIÁO VIÊN BỊ TỪ CHỐI ---
              if (_wasRejected) ...[
                const SizedBox(height: 20),
                const Text('Hoặc', style: TextStyle(color: app_colors.placeholder)),
                TextButton(
                  onPressed: _isLoading ? null : _handleReapply,
                  child: const Text(
                    'Đăng ký lại làm Giáo viên',
                    style: TextStyle(color: Colors.yellow, decoration: TextDecoration.underline, decorationColor: Colors.yellow),
                  ),
                ),
              ],

              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => _authService.signOut(),
                icon: const Icon(Icons.logout, size: 18, color: app_colors.placeholder),
                label: const Text('Đăng xuất', style: TextStyle(color: app_colors.placeholder)),
              )
            ],
          ),
        ),
      ),
    );
  }
}