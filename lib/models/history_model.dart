// lib/models/history_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryFolder {
  final String id;
  final String name;
  final DateTime date;
  final List<String> imagePaths;
  final String? localImagePath; // ✅ Thêm trường
  final String infoFileUri;
  int feedbackStatus;
  final String processingStatus;

  HistoryFolder({
    required this.id,
    required this.name,
    required this.date,
    required this.imagePaths,
    required this.infoFileUri,
    this.localImagePath,
    this.feedbackStatus = 0,
    required this.processingStatus,
  });

  factory HistoryFolder.fromJson(Map<String, dynamic> json) {
    // --- Sửa lỗi kiểu ngày ---
    DateTime parsedDate;
    if (json['date'] is Timestamp) {
      parsedDate = (json['date'] as Timestamp).toDate();
    } else if (json['date'] is String) {
      parsedDate = DateTime.tryParse(json['date']) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return HistoryFolder(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      date: parsedDate,
      imagePaths: json['imagePaths'] is List
          ? List<String>.from(json['imagePaths'])
          : [],
      localImagePath: json['localImagePath']?.toString(), // ✅ Parse
      infoFileUri: json['infoFileUri'] ?? '',
      feedbackStatus: json['feedbackStatus'] ?? 0,
      processingStatus: json['processingStatus'] ?? 'completed',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date,
      'imagePaths': imagePaths,
      'localImagePath': localImagePath, // ✅ Serialize
      'infoFileUri': infoFileUri,
      'feedbackStatus': feedbackStatus,
      'processingStatus': processingStatus,
    };
  }
}
