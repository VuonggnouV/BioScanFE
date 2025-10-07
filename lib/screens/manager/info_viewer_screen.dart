import 'dart:convert';
import 'package:bioscan/models/history_model.dart';
import 'package:bioscan/services/history_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bioscan/theme/colors.dart' as app_colors;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:bioscan/config/flutter_backend_config.dart';

class InfoViewerScreen extends StatefulWidget {
  final String userId;
  final HistoryFolder folder;
  final bool isOwnerView;
  final bool isGuest;

  const InfoViewerScreen({
    super.key,
    required this.userId,
    required this.folder,
    required this.isOwnerView,
    required this.isGuest,
  });

  @override
  State<InfoViewerScreen> createState() => _InfoViewerScreenState();
}

class _InfoViewerScreenState extends State<InfoViewerScreen> {
  final HistoryService _historyService = HistoryService();
  late int _feedbackStatus;

  @override
  void initState() {
    super.initState();
    _feedbackStatus = widget.folder.feedbackStatus;
  }

  /// Tải nội dung file mô tả từ backend.
  Future<String> _readContent(String infoFileUri) async {
    try {
      final fileName = p.basename(infoFileUri);
      final url = Uri.parse('${BackendConfig.baseUrl}/outputs/$fileName');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return utf8.decode(response.bodyBytes);
      } else {
        return "Lỗi: Không thể tải nội dung (Mã lỗi: ${response.statusCode})";
      }
    } catch (e) {
      return "Lỗi kết nối. Không thể đọc được nội dung file.";
    }
  }

  /// Xử lý khi người dùng nhấn nút feedback.
  void _handleFeedbackTap(int newStatus) {
    setState(() {
      _feedbackStatus = _feedbackStatus == newStatus ? 0 : newStatus;
    });
    _historyService.updateFeedbackStatus(
      userId: widget.userId,
      folderId: widget.folder.id,
      status: _feedbackStatus,
      isGuest: widget.isGuest,
    );
  }

  @override
  Widget build(BuildContext context) {
    final parentCollection = widget.isGuest ? 'archived_guests' : 'users';
    final docStream = FirebaseFirestore.instance
        .collection(parentCollection)
        .doc(widget.userId)
        .collection('scanHistory')
        .doc(widget.folder.id)
        .snapshots();

    return Scaffold(
      backgroundColor: app_colors.formBackground,
      appBar: AppBar(
        title: Text(widget.folder.name, style: const TextStyle(color: app_colors.textDark)),
        backgroundColor: app_colors.formBackground,
        iconTheme: const IconThemeData(color: app_colors.textDark),
        elevation: 1,
      ),
      bottomNavigationBar: widget.isOwnerView ? _buildFeedbackSection() : null,
      body: StreamBuilder<DocumentSnapshot>(
        stream: docStream,
        builder: (context, snapshot) {
          // Trường hợp đang chờ dữ liệu từ stream
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Trường hợp có lỗi hoặc không có dữ liệu
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Không tìm thấy dữ liệu hoặc có lỗi xảy ra."));
          }

          // Parse dữ liệu mới nhất từ stream
          final data = snapshot.data!.data() as Map<String, dynamic>;
          data['id'] = snapshot.data!.id;
          final currentFolder = HistoryFolder.fromJson(data);

          // Nếu đang xử lý, hiển thị màn hình loading
          if (currentFolder.processingStatus == 'processing') {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Đang xử lý kết quả...", style: TextStyle(fontSize: 16)),
                  Text("Vui lòng chờ trong giây lát.", style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          }
          
          // Nếu xử lý thất bại
          if (currentFolder.processingStatus == 'failed') {
             return const Center(child: Text("Xử lý thất bại. Vui lòng thử lại.", style: TextStyle(fontSize: 16, color: Colors.red)));
          }

          // Nếu đã xử lý xong, hiển thị kết quả
          return FutureBuilder<String>(
            future: _readContent(currentFolder.infoFileUri),
            builder: (context, contentSnapshot) {
              if (contentSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (contentSnapshot.hasError || !contentSnapshot.hasData) {
                return Center(child: Text(contentSnapshot.data ?? "Lỗi tải nội dung."));
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                  contentSnapshot.data!,
                  style: const TextStyle(fontSize: 16, color: app_colors.textDark, height: 1.5),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Widget hiển thị thanh feedback
  Widget _buildFeedbackSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: app_colors.inputBackground,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 0, blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(child: Text('Bạn thấy kết quả này có hữu ích không?', style: TextStyle(fontSize: 15, color: app_colors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 16),
            Row(children: [
              InkWell(
                onTap: () => _handleFeedbackTap(1),
                borderRadius: BorderRadius.circular(20),
                child: Padding(padding: const EdgeInsets.all(8.0), child: Icon(_feedbackStatus == 1 ? Icons.thumb_up : Icons.thumb_up_outlined, color: _feedbackStatus == 1 ? Colors.green : app_colors.placeholder, size: 26)),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _handleFeedbackTap(2),
                borderRadius: BorderRadius.circular(20),
                child: Padding(padding: const EdgeInsets.all(8.0), child: Icon(_feedbackStatus == 2 ? Icons.thumb_down : Icons.thumb_down_outlined, color: _feedbackStatus == 2 ? Colors.red : app_colors.placeholder, size: 26)),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}