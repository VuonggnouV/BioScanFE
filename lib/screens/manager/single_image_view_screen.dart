import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bioscan/models/history_model.dart';

class SingleImageViewScreen extends StatelessWidget {
  final HistoryFolder item;

  const SingleImageViewScreen({Key? key, required this.item}) : super(key: key);

  Widget _buildImageWidget() {
    final localPath = item.localImagePath;
    final hasLocal = localPath != null && File(localPath).existsSync();

    if (hasLocal) {
      return Image.file(
        File(localPath!),
        fit: BoxFit.contain, // Đảm bảo ảnh không tràn ra ngoài
      );
    }

    if (item.imagePaths.isNotEmpty) {
      final url = item.imagePaths.first;
      return Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Text("Không tải được ảnh từ server"));
        },
      );
    }

    return const Center(child: Text("Không có ảnh để hiển thị"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Xem ảnh'),
        backgroundColor: Colors.black,
        elevation: 0,
        foregroundColor: Colors.white, // nút quay lại và tiêu đề rõ ràng
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 1,
            maxScale: 5,
            child: _buildImageWidget(),
          ),
        ),
      ),
    );
  }
}
