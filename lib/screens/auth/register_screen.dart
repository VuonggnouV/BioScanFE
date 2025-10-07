import 'package:bioscan/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:bioscan/theme/colors.dart' as app_colors;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers for the Teacher form
  final _teacherUsernameController = TextEditingController();
  final _teacherEmailController = TextEditingController();
  final _teacherPhoneController = TextEditingController();
  final _teacherPasswordController = TextEditingController();
  final _teacherConfirmPasswordController = TextEditingController();

  // Controllers for the Student form
  final _studentUsernameController = TextEditingController();
  final _studentEmailController = TextEditingController();
  final _studentPasswordController = TextEditingController();
  final _studentConfirmPasswordController = TextEditingController();
  final _teacherCodeController = TextEditingController();

  final _authService = AuthService();
  bool _isLoading = false;

  // State variables for password visibility
  bool _isTeacherPasswordVisible = false;
  bool _isTeacherConfirmPasswordVisible = false;
  bool _isStudentPasswordVisible = false;
  bool _isStudentConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _teacherUsernameController.dispose();
    _teacherEmailController.dispose();
    _teacherPhoneController.dispose();
    _teacherPasswordController.dispose();
    _teacherConfirmPasswordController.dispose();
    _studentUsernameController.dispose();
    _studentEmailController.dispose();
    _studentPasswordController.dispose();
    _studentConfirmPasswordController.dispose();
    _teacherCodeController.dispose();
    super.dispose();
  }

  void _showFeedback(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  void _handleRegister() {
    if (_tabController.index == 0) {
      _registerTeacher();
    } else {
      _registerStudent();
    }
  }

  Future<void> _registerTeacher() async {
    if (_teacherPasswordController.text != _teacherConfirmPasswordController.text) {
      _showFeedback('Mật khẩu nhập lại không khớp.');
      return;
    }
    if (_teacherUsernameController.text.isEmpty ||
        _teacherEmailController.text.isEmpty ||
        _teacherPhoneController.text.isEmpty ||
        _teacherPasswordController.text.isEmpty) {
      _showFeedback('Vui lòng nhập đầy đủ thông tin.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _authService.registerAsTeacher(
        username: _teacherUsernameController.text.trim(),
        email: _teacherEmailController.text.trim(),
        phone: _teacherPhoneController.text.trim(),
        password: _teacherPasswordController.text.trim(),
      );
      if (result == "success") {
        _showFeedback('Đăng ký thành công! Vui lòng chờ Admin duyệt.', isError: false);
        if(mounted) Navigator.of(context).pop();
      } else {
        _showFeedback(result);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _registerStudent() async {
    if (_studentPasswordController.text != _studentConfirmPasswordController.text) {
      _showFeedback('Mật khẩu nhập lại không khớp.');
      return;
    }
    if (_studentUsernameController.text.isEmpty ||
        _studentEmailController.text.isEmpty ||
        _studentPasswordController.text.isEmpty) {
      _showFeedback('Vui lòng nhập đầy đủ thông tin.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _authService.registerAsStudent(
        username: _studentUsernameController.text.trim(),
        email: _studentEmailController.text.trim(),
        password: _studentPasswordController.text.trim(),
      );
      if (result == "success") {
        _showFeedback('Đăng ký thành công! Vui lòng đăng nhập.', isError: false);
        if(mounted) Navigator.of(context).pop();
      } else {
        _showFeedback(result);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                Image.asset('assets/images/logo.png', width: 120, height: 120),
                const SizedBox(height: 15),
                const Text('PLANT AND BIOLOGY', style: TextStyle(color: app_colors.textLight, fontSize: 26, fontWeight: FontWeight.bold)),
                const Text('SAMPLE RECOGNITION', style: TextStyle(color: app_colors.textLight, fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: app_colors.formBackground,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "ĐĂNG KÝ",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: app_colors.textDark,
                        ),
                      ),
                      const SizedBox(height: 30),
                      TabBar(
                        controller: _tabController,
                        labelColor: app_colors.textDark,
                        unselectedLabelColor: app_colors.placeholder,
                        indicatorColor: app_colors.primaryButton,
                        tabs: const [
                          Tab(child: Text('GIÁO VIÊN', style: TextStyle(fontWeight: FontWeight.bold))),
                          Tab(child: Text('HỌC SINH', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, child) {
                          return _tabController.index == 0
                              ? _buildTeacherForm()
                              : _buildStudentForm();
                        },
                      ),
                      const SizedBox(height: 30),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: app_colors.primaryButton,
                                foregroundColor: app_colors.textLight,
                                minimumSize: const Size(double.infinity, 55),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              child: const Text('ĐĂNG KÝ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Đã có tài khoản? ', style: TextStyle(color: app_colors.textDark)),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Đăng nhập',
                              style: TextStyle(color: app_colors.primaryButton, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(controller: _teacherUsernameController, decoration: InputDecoration(hintText: 'Tên người dùng', prefixIcon: const Icon(Icons.person_outline), filled: true, fillColor: app_colors.inputBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
        const SizedBox(height: 20),
        TextField(controller: _teacherEmailController, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(hintText: 'Email', prefixIcon: const Icon(Icons.email_outlined), filled: true, fillColor: app_colors.inputBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
        const SizedBox(height: 20),
        TextField(controller: _teacherPhoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(hintText: 'Số điện thoại', prefixIcon: const Icon(Icons.phone_outlined), filled: true, fillColor: app_colors.inputBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
        const SizedBox(height: 20),
        TextField(
          controller: _teacherPasswordController,
          obscureText: !_isTeacherPasswordVisible,
          decoration: InputDecoration(
            hintText: 'Mật khẩu',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_isTeacherPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => setState(() => _isTeacherPasswordVisible = !_isTeacherPasswordVisible),
            ),
            filled: true,
            fillColor: app_colors.inputBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _teacherConfirmPasswordController,
          obscureText: !_isTeacherConfirmPasswordVisible,
          decoration: InputDecoration(
            hintText: 'Nhập lại mật khẩu',
            prefixIcon: const Icon(Icons.lock_reset_outlined),
            suffixIcon: IconButton(
              icon: Icon(_isTeacherConfirmPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => setState(() => _isTeacherConfirmPasswordVisible = !_isTeacherConfirmPasswordVisible),
            ),
            filled: true,
            fillColor: app_colors.inputBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStudentForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(controller: _studentUsernameController, decoration: InputDecoration(hintText: 'Tên người dùng', prefixIcon: const Icon(Icons.person_outline), filled: true, fillColor: app_colors.inputBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
        const SizedBox(height: 20),
        TextField(controller: _studentEmailController, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(hintText: 'Email', prefixIcon: const Icon(Icons.email_outlined), filled: true, fillColor: app_colors.inputBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
        const SizedBox(height: 20),
        TextField(
          controller: _studentPasswordController,
          obscureText: !_isStudentPasswordVisible,
          decoration: InputDecoration(
            hintText: 'Mật khẩu',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_isStudentPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => setState(() => _isStudentPasswordVisible = !_isStudentPasswordVisible),
            ),
            filled: true,
            fillColor: app_colors.inputBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _studentConfirmPasswordController,
          obscureText: !_isStudentConfirmPasswordVisible,
          decoration: InputDecoration(
            hintText: 'Nhập lại mật khẩu',
            prefixIcon: const Icon(Icons.lock_reset_outlined),
            suffixIcon: IconButton(
              icon: Icon(_isStudentConfirmPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => setState(() => _isStudentConfirmPasswordVisible = !_isStudentConfirmPasswordVisible),
            ),
            filled: true,
            fillColor: app_colors.inputBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}