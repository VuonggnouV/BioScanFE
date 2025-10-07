import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bioscan/models/user_scan_stats.dart';
import 'package:bioscan/models/user_feedback_stats.dart';

class ManagerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<UserScanStats>> getActivityStats({String? teacherId, String? roleFilter}) async {
    final List<UserScanStats> stats = [];
    final teacherSnapshot = await _firestore.collection('users').where('role', isEqualTo: 'manager').get();
    final teacherCodeMap = {for (var doc in teacherSnapshot.docs) doc.id: doc.data()['teacherCode'] as String?};

    Query query = _firestore.collection('users');
    if (teacherId != null) {
      query = query.where('teacherId', isEqualTo: teacherId);
    } else if (roleFilter != null) {
      query = query.where('role', isEqualTo: roleFilter);
    }
    
    try {
      final usersSnapshot = await query.get();
      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final userId = userDoc.id;
        final historyCollection = _firestore.collection('users').doc(userId).collection('scanHistory');
        
        
        final totalScans = userData['scanCount'] ?? 0; // Đọc trực tiếp từ trường scanCount
        
        DateTime? lastScanDate;
        if (totalScans > 0) {
          final lastScanDoc = await historyCollection.orderBy('date', descending: true).limit(1).get();
          if (lastScanDoc.docs.isNotEmpty) {
            final dateData = lastScanDoc.docs.first.data()['date'];
            if (dateData is Timestamp) lastScanDate = dateData.toDate();
            else if (dateData is String) lastScanDate = DateTime.parse(dateData);
          }
        }
        
        String? code;
        if (userData['role'] == 'manager') {
          code = userData['teacherCode'];
        } else if (userData['role'] == 'user' && userData['teacherId'] != null) {
          code = teacherCodeMap[userData['teacherId']];
        }

        stats.add(UserScanStats(
          uid: userId,
          username: userData['username'] ?? 'N/A',
          email: userData['email'] ?? 'N/A',
          createdAt: (userData['createdAt'] as Timestamp).toDate(),
          totalScans: totalScans,
          lastScanDate: lastScanDate,
          role: userData['role'] ?? 'user',
          teacherCode: code,
        ));
      }
    } catch (e) {
      print("Lỗi khi lấy thống kê hoạt động: $e");
    }
    return stats;
  }



  // Lấy dữ liệu đánh giá, có thể lọc theo teacherId hoặc roleFilter
  Future<List<UserFeedbackStats>> getFeedbackStats({String? teacherId, String? roleFilter}) async {
    final List<UserFeedbackStats> stats = [];
    
    Query query = _firestore.collection('users');
    if (teacherId != null) {
      query = query.where('teacherId', isEqualTo: teacherId);
    } else if (roleFilter != null) {
      query = query.where('role', isEqualTo: roleFilter);
    }
    
    try {
      final usersSnapshot = await query.get();

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final userId = userDoc.id;
        final historySnapshot = await _firestore.collection('users').doc(userId).collection('scanHistory').get();
        
        int likes = 0, dislikes = 0, notRated = 0;
        for (final scanDoc in historySnapshot.docs) {
          final status = scanDoc.data()['feedbackStatus'] ?? 0;
          if (status == 1) likes++;
          else if (status == 2) dislikes++;
          else notRated++;
        }
        
        // --- THAY ĐỔI DUY NHẤT Ở ĐÂY ---
        // Lấy tổng số quét từ trường scanCount thay vì đếm lại
        final totalScans = userData['scanCount'] ?? 0;
        // --- KẾT THÚC ---
        
        final likeRate = (totalScans == 0) ? 0.0 : (likes / totalScans);
        
        stats.add(UserFeedbackStats(
          uid: userId,
          username: userData['username'] ?? 'N/A',
          totalScans: totalScans,
          likes: likes,
          dislikes: dislikes,
          notRated: notRated,
          likeRate: likeRate,
          role: userData['role'] ?? 'user',
        ));
      }
    } catch(e) {
      print("Lỗi khi lấy thống kê đánh giá: $e");
    }

    return stats;
  }

  // Lấy tần suất quét, có thể lọc theo teacherId
  Future<Map<DateTime, int>> getDailyScanFrequency({
      String? teacherId,
      String? roleFilter, // Tham số này sẽ không được sử dụng trong logic mới nhưng giữ lại để cấu trúc hàm nhất quán
      DateTime? startDate,
      DateTime? endDate,
    }) async {
      Map<DateTime, int> frequencyMap = {};
      final now = DateTime.now();

      final end = endDate ?? now;
      final start = startDate ?? now.subtract(const Duration(days: 6));

      for (int i = 0; i <= end.difference(start).inDays; i++) {
        final day = DateTime(start.year, start.month, start.day + i);
        frequencyMap[day] = 0;
      }

      // Hàm xử lý một bản ghi quét
      void processScan(QueryDocumentSnapshot<Map<String, dynamic>> scan) {
          final dateData = scan.data()['date'];
          DateTime scanDate;
          if (dateData is Timestamp) scanDate = dateData.toDate();
          else if (dateData is String) scanDate = DateTime.parse(dateData);
          else return;
          
          final dayOnly = DateTime(scanDate.year, scanDate.month, scanDate.day);
          if (frequencyMap.containsKey(dayOnly)) {
            frequencyMap[dayOnly] = frequencyMap[dayOnly]! + 1;
          }
      }

      // --- LOGIC TỐI ƯU ---
      // Nếu là giáo viên, chỉ lấy của học sinh của họ (logic cũ, vẫn hiệu quả cho quy mô nhỏ)
      if (teacherId != null) {
        final studentSnapshot = await _firestore.collection('users').where('teacherId', isEqualTo: teacherId).get();
        if (studentSnapshot.docs.isEmpty) return frequencyMap;

        for (final studentDoc in studentSnapshot.docs) {
          final studentScans = await _firestore
              .collection('users')
              .doc(studentDoc.id)
              .collection('scanHistory')
              .where('date', isGreaterThanOrEqualTo: start)
              .where('date', isLessThanOrEqualTo: end.add(const Duration(days: 1)))
              .get();
          
          studentScans.docs.forEach(processScan);
        }
      } else {
        // Nếu là Admin, dùng một câu lệnh duy nhất để lấy toàn bộ lịch sử quét
        final scansSnapshot = await _firestore
            .collectionGroup('scanHistory')
            .where('date', isGreaterThanOrEqualTo: start)
            .where('date', isLessThanOrEqualTo: end.add(const Duration(days: 1)))
            .get();

        scansSnapshot.docs.forEach(processScan);
      }
      // --- KẾT THÚC ---
      
      return frequencyMap;
    }
}
