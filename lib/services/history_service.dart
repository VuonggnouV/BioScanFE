import 'dart:io';
import 'package:bioscan/models/history_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Hàm helper để lấy collection tương ứng (user hoặc guest)
  CollectionReference _getHistoryCollection({required String userId, required bool isGuest}) {
    final parentCollection = isGuest ? 'archived_guests' : 'users';
    return _firestore.collection(parentCollection).doc(userId).collection('scanHistory');
  }

  /// Lấy tất cả các thư mục lịch sử của một người dùng từ Firestore.
  Future<List<HistoryFolder>> getHistoryFolders({required String userId, required bool isGuest}) async {
    try {
      final querySnapshot = await _getHistoryCollection(userId: userId, isGuest: isGuest)
          .orderBy('date', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Gán ID của document vào data
        return HistoryFolder.fromJson(data);
      }).toList();

    } catch (e) {
      print("Lỗi khi lấy lịch sử từ Firestore: $e");
      return [];
    }
  }

  /// Xóa các mục lịch sử được chỉ định và giảm `scanCount` của người dùng.
  Future<void> deleteHistoryEntries({
    required String userId, 
    required List<String> ids,
    required bool isGuest,
  }) async {
    if (ids.isEmpty) return;
    
    final historyCollection = _getHistoryCollection(userId: userId, isGuest: isGuest);
    final batch = _firestore.batch();

    for (final id in ids) {
      // Xóa các file vật lý (ảnh và file txt) nếu có
      try {
        final docSnapshot = await historyCollection.doc(id).get();
        if (docSnapshot.exists) {
          final folder = HistoryFolder.fromJson(docSnapshot.data() as Map<String, dynamic>);
          
          final infoFile = File(folder.infoFileUri);
          if (await infoFile.exists()) await infoFile.delete();

          for (var imagePath in folder.imagePaths) {
            final imgFile = File(imagePath);
            if (await imgFile.exists()) await imgFile.delete();
          }

          // Xóa ảnh local nếu có trường localImagePath
          if (folder.localImagePath != null) {
            final localFile = File(folder.localImagePath!);
            if (await localFile.exists()) await localFile.delete();
          }
        }
      } catch (e) {
        print("Lỗi khi xóa file vật lý cho $id: $e");
      }
      
      // Thêm hành động xóa document vào batch
      batch.delete(historyCollection.doc(id));
    }
    
    // Thực hiện tất cả các hành động xóa trong batch
    await batch.commit();

    // Giảm bộ đếm số lần quét (chỉ cho người dùng đã đăng ký)
    if (!isGuest && ids.isNotEmpty) {
      final userDocRef = _firestore.collection('users').doc(userId);
      await userDocRef.update({'scanCount': FieldValue.increment(-ids.length)});
    }
  }

  /// Tạo bản ghi tạm thời trước khi gửi ảnh lên backend.
  Future<DocumentReference> createPlaceholderHistoryEntry({
    required String userId,
    required String imagePath, // Đường dẫn file ảnh local
    required bool isGuest,
  }) async {
    final now = DateTime.now();
    
    final placeholderData = {
      'name': 'Ngày ${DateFormat('dd/MM/yy - HH:mm:ss').format(now)}',
      'date': Timestamp.fromDate(now),
      'imagePaths': [], // Backend sẽ cập nhật sau
      'localImagePath': imagePath, // ✅ Lưu local image path riêng
      'infoFileUri': '',
      'feedbackStatus': 0,
      'processingStatus': 'processing',
      'role': isGuest ? 'guest' : 'user',
    };

    final docRef = await _getHistoryCollection(userId: userId, isGuest: isGuest).add(placeholderData);

    if (!isGuest) {
      final userDocRef = _firestore.collection('users').doc(userId);
      await userDocRef.update({'scanCount': FieldValue.increment(1)});
    }
    
    return docRef;
  }

  /// Cập nhật trạng thái feedback cho một mục lịch sử.
  Future<void> updateFeedbackStatus({
    required String userId,
    required String folderId,
    required int status,
    required bool isGuest,
  }) async {
    await _getHistoryCollection(userId: userId, isGuest: isGuest).doc(folderId).update({
      'feedbackStatus': status,
    });
  }
}
