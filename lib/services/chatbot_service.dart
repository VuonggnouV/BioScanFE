// lib/services/chatbot_service.dart
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatbotService {
  static const String _apiKey = 'AIzaSyCL6wS6bEJ0QE2wMppPcTTSUr48GK56Pd0';

  final GenerativeModel _model;
  
  ChatbotService()
      : _model = GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: _apiKey,
          systemInstruction: Content.text(
            'Bạn là một trợ lý AI chuyên về sinh học. '
            'LUÔN LUÔN trả lời bằng tiếng Việt. '
            'Từ chối trả lời các câu hỏi không liên quan đến sinh học, sinh vật, thực vật, hoặc các chủ đề khoa học tự nhiên liên quan.'
          ),
        );
  
  Future<String> getGeneralResponse({
    required String userQuery,
    required List<Content> chatHistory,
  }) async {
    try {
      final chat = _model.startChat(history: chatHistory);
      
      var response = await chat.sendMessage(Content.text(userQuery));
      return response.text ?? "Tôi không thể xử lý yêu cầu này.";

    } catch (e) {
      print("Lỗi khi gọi Gemini API: $e");
      return "Đã xảy ra lỗi, vui lòng thử lại.";
    }
  }
}
