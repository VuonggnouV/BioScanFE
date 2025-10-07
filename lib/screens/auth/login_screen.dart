import 'package:bioscan/screens/auth/register_screen.dart';
import 'package:bioscan/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bioscan/theme/colors.dart' as app_colors;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _login() async {
    if (_identifierController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userCredential = await _authService.signIn(
        _identifierController.text.trim(), 
        _passwordController.text.trim()
      );

      if (userCredential?.user != null && mounted) {
        // Sau khi đăng nhập thành công, gọi hàm kiểm tra thông báo
        await _authService.checkAndShowApprovalMessage(context, userCredential!.user!.uid);
      }
      // AuthGate sẽ tự động điều hướng người dùng sau đó
    } on FirebaseAuthException catch (e) {
      String message = 'Email/Tên người dùng hoặc mật khẩu không chính xác.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Email/Tên người dùng hoặc mật khẩu không chính xác.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _signInAsGuest() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInAsGuest();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng nhập khách thất bại.')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app_colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png', width: 150, height: 150),
                const SizedBox(height: 20),
                const Text('PLANT AND BIOLOGY', style: TextStyle(color: app_colors.textLight, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const Text('SAMPLE RECOGNITION', style: TextStyle(color: app_colors.textLight, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 40),

                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(color: app_colors.formBackground, borderRadius: BorderRadius.circular(25)),
                  child: Column(
                    children: [
                      const Text("ĐĂNG NHẬP", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: app_colors.textDark)),
                      const SizedBox(height: 30),
                      TextField(
                        controller: _identifierController,
                        enabled: !_isLoading,
                        decoration: InputDecoration(hintText: 'Email hoặc Tên người dùng', prefixIcon: const Icon(Icons.person_outline, color: app_colors.placeholder), filled: true, fillColor: app_colors.inputBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          hintText: 'Mật khẩu',
                          prefixIcon: const Icon(Icons.lock_outline, color: app_colors.placeholder),
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: app_colors.placeholder),
                            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible)
                          ),
                          filled: true,
                          fillColor: app_colors.inputBackground,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
                        ),
                      ),
                      const SizedBox(height: 30),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(backgroundColor: app_colors.primaryButton, foregroundColor: app_colors.textLight, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                              child: const Text('ĐĂNG NHẬP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Chưa có tài khoản? ', style: TextStyle(color: app_colors.textDark)),
                          GestureDetector(
                            onTap: _isLoading ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                            child: const Text('Đăng ký ngay', style: TextStyle(color: app_colors.primaryButton, fontWeight: FontWeight.bold)),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                TextButton(
                  onPressed: _isLoading ? null : _signInAsGuest,
                  child: const Text('Tiếp tục với tư cách khách', style: TextStyle(color: app_colors.textLight)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}