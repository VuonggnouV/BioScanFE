// lib/main.dart
import 'package:bioscan/auth_gate.dart';
import 'package:bioscan/screens/manager/camera_screen.dart';
import 'package:bioscan/screens/manager/history_screen.dart';
import 'package:bioscan/screens/manager/user_screen.dart';
import 'package:bioscan/screens/auth/code_entry_screen.dart';
import 'package:bioscan/services/auth_service.dart';
import 'package:bioscan/services/chat_bubble_notifier.dart';
import 'package:bioscan/widgets/floating_chat_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:bioscan/theme/colors.dart' as app_colors;
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => ChatBubbleNotifier(),
      child: const MyApp(),
    ),
  );
}

// LỚP MỚI: Để theo dõi route và cập nhật notifier một cách tự động
class ChatRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  final ChatBubbleNotifier notifier;

  ChatRouteObserver(this.notifier);

  // Lấy tên màn hình từ `route.settings.name`
  String _getRouteName(Route<dynamic> route) {
    return route.settings.name ?? 'Unknown';
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    notifier.updateCurrentRoute(_getRouteName(route));
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
        notifier.updateCurrentRoute(_getRouteName(previousRoute));
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    // Lấy notifier để truyền vào ChatRouteObserver
    final chatNotifier = Provider.of<ChatBubbleNotifier>(context, listen: false);

    return MaterialApp(
      title: 'BioScan',
      theme: ThemeData(
        scaffoldBackgroundColor: app_colors.background,
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
      navigatorObservers: [ChatRouteObserver(chatNotifier)],
      home: const AppWrapper(),
    );
  }
}

class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        children: [
          AuthGate(),
          FloatingChatBubble(),
        ],
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final User user;
  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late PageController _pageController;
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _userRole;
  bool _isStudentLinked = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadUserDataAndDetermineRoute();

    // Cập nhật tên route ban đầu khi MainScreen được tạo
    // Vì PageView bắt đầu ở index 0 (Camera), ta đặt tên route là 'CameraScreen'
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatBubbleNotifier>(context, listen: false).updateCurrentRoute('CameraScreen');
    });
  }

  Future<void> _loadUserDataAndDetermineRoute() async {
    if (widget.user.isAnonymous) {
      setState(() {
        _isLoading = false;
        _userRole = 'guest';
      });
      return;
    }
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).get();
      if (mounted) {
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _userRole = userData['role'];
            if (_userRole == 'user') {
              _isStudentLinked = userData['teacherId'] != null;
            }
            _isLoading = false;
          });
        } else {
           if (mounted) AuthService().signOut();
        }
      }
    } catch (e) {
      if (mounted) AuthService().signOut();
    }
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_userRole == 'user' && !_isStudentLinked) {
      return CodeEntryScreen(onCodeVerified: _loadUserDataAndDetermineRoute);
    }
    
    final bool isScanDisabled = (_userRole == 'pending_teacher');
    
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          // Khi vuốt trang, cập nhật tên màn hình tương ứng
          final newRouteName = index == 0 ? 'CameraScreen' : 'UserScreen';
          Provider.of<ChatBubbleNotifier>(context, listen: false).updateCurrentRoute(newRouteName);
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          // Gán key để RouteObserver có thể lấy đúng tên khi điều hướng bên trong
          Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute(
              settings: const RouteSettings(name: 'CameraScreen'), // Đặt tên cố định cho tab này
              builder: (context) => CameraScreen(userId: widget.user.uid, isScanDisabled: isScanDisabled, isGuest: widget.user.isAnonymous),
            ),
          ),
          Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute(
              settings: const RouteSettings(name: 'UserScreen'), // Đặt tên cố định cho tab này
              builder: (context) => UserScreen(
                user: widget.user,
                onNavigateToHistory: () {
                  // Khi mở màn hình mới, đặt tên cho nó để Observer nhận biết
                  Navigator.push(context, MaterialPageRoute(
                    settings: const RouteSettings(name: 'HistoryScreen'),
                    builder: (context) => HistoryScreen(
                      userId: widget.user.uid,
                      onScanNow: () => _pageController.jumpToPage(0),
                      isGuest: widget.user.isAnonymous,
                    ),
                  ));
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({super.key, required this.selectedIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: app_colors.primaryButton,
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.camera_alt_outlined, 'Camera', 0),
          _buildNavItem(Icons.person_outline, 'useraccount', 1),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onItemTapped(index),
      behavior: HitTestBehavior.translucent,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? app_colors.textLight : app_colors.placeholder, size: 28),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isSelected ? app_colors.textLight : app_colors.placeholder, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}