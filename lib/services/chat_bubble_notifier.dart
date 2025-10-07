// lib/services/chat_bubble_notifier.dart
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:bioscan/services/chatbot_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatBubbleNotifier extends ChangeNotifier {
  final ChatbotService _chatbotService = ChatbotService();

  bool _isChatEnabled = false;
  bool _isChatOpen = false;
  Offset _position = const Offset(10, 100);
  String _currentRouteName = '/';

  List<ChatMessage> _messages = [
    ChatMessage(text: 'Xin chào! Tôi là trợ lý AI, tôi có thể giúp gì cho bạn?', isUser: false)
  ];
  List<Content> _chatHistory = [];
  bool _isLoading = false;

  bool get isBubbleVisible => _isChatEnabled && _currentRouteName != 'CameraScreen';
  bool get isChatEnabled => _isChatEnabled;
  bool get isChatOpen => _isChatOpen;
  Offset get position => _position;
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  
  void updateCurrentRoute(String routeName) {
    if (_currentRouteName != routeName) {
      _currentRouteName = routeName;
      notifyListeners();
    }
  }

  void enableChat() {
    if (!_isChatEnabled) {
      _isChatEnabled = true;
      notifyListeners();
    }
  }

  void disableChat() {
    if (_isChatEnabled) {
      _isChatEnabled = false;
      notifyListeners();
    }
  }

  void toggleChat() {
    _isChatOpen = !_isChatOpen;
    notifyListeners();
  }
  
  void updatePosition(Offset newPosition) {
    _position = newPosition;
    notifyListeners();
  }

  // HÀM MỚI: Reset lại toàn bộ trạng thái của cuộc trò chuyện
  void resetChat() {
    _messages = [
      ChatMessage(text: 'Xin chào! Tôi là trợ lý AI, tôi có thể giúp gì cho bạn?', isUser: false)
    ];
    _chatHistory.clear();
    _isChatOpen = false; // Đảm bảo cửa sổ chat đóng lại khi reset
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(ChatMessage(text: text, isUser: true));
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _chatbotService.getGeneralResponse(
        userQuery: text,
        chatHistory: _chatHistory,
      );
      _messages.add(ChatMessage(text: response, isUser: false));
      _chatHistory.add(Content.text(text));
      _chatHistory.add(Content.model([TextPart(response)]));
    } catch (e) {
      _messages.add(ChatMessage(text: 'Đã có lỗi xảy ra.', isUser: false));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}