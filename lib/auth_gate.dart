// lib/auth_gate.dart
import 'package:bioscan/screens/auth/login_screen.dart';
import 'package:bioscan/services/auth_service.dart';
import 'package:bioscan/services/chat_bubble_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bioscan/main.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final chatNotifier = Provider.of<ChatBubbleNotifier>(context, listen: false);

    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (snapshot.hasData) {
            // Đã đăng nhập -> Bật hệ thống chat
            if (!chatNotifier.isChatEnabled) chatNotifier.enableChat();
          } else {
            // Chưa đăng nhập -> Tắt hệ thống chat VÀ RESET LẠI NÓ
            if (chatNotifier.isChatEnabled) {
              chatNotifier.resetChat(); // Xóa lịch sử chat cũ
              chatNotifier.disableChat(); // Tắt bubble
            }
          }
        });

        if (snapshot.hasData) {
          return MainScreen(user: snapshot.data!);
        }
        
        return const LoginScreen();
      },
    );
  }
}