import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- GETTER VÀ STREAM ---
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // --- KIỂM TRA VAI TRÒ ---
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.exists && doc.data()?['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  Future<bool> isManager() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.exists && doc.data()?['role'] == 'manager';
    } catch (e) {
      return false;
    }
  }

  // --- HÀNH ĐỘNG ĐĂNG NHẬP / ĐĂNG XUẤT ---
  Future<UserCredential?> signIn(String identifier, String password) async {
    try {
      String email = identifier.trim();
      if (!email.contains('@')) {
        final querySnapshot = await _firestore
            .collection('users')
            .where('username_lowercase', isEqualTo: email.toLowerCase())
            .limit(1)
            .get();
        if (querySnapshot.docs.isNotEmpty) {
          email = querySnapshot.docs.first.data()['email'];
        } else {
          throw FirebaseAuthException(code: 'user-not-found');
        }
      }
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signInAsGuest() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      print("Lỗi đăng nhập khách: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    final user = _auth.currentUser;
    if (user != null && user.isAnonymous) {
      try {
        await _firestore.collection('archived_guests').doc(user.uid).set(
          {
            'uid': user.uid,
            'signedOutAt': Timestamp.now(),
          },
          SetOptions(merge: true), 
        );  
        await user.delete();
      } catch (e) {
        print("Lỗi khi xử lý đăng xuất khách: $e");
        await _auth.signOut();
      }
    } else {
      await _auth.signOut();
    }
  }

  // --- HÀNH ĐỘNG ĐĂNG KÝ ---
  Future<String> registerAsTeacher({
    required String username,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final phoneQuery = await _firestore
        .collection('users')
        .where('phone', isEqualTo: phone.trim())
        .get();
      if (phoneQuery.docs.isNotEmpty) {
        return "Số điện thoại này đã được đăng ký.";
      }

      final usernameQuery = await _firestore.collection('users').where('username_lowercase', isEqualTo: username.trim().toLowerCase()).get();
      if (usernameQuery.docs.isNotEmpty) {
        return "Tên người dùng này đã tồn tại.";
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      User? user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(username.trim());
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'username': username.trim(),
          'username_lowercase': username.trim().toLowerCase(),
          'email': email.trim(),
          'phone': phone.trim(),
          'createdAt': Timestamp.now(),
          'role': 'pending_teacher',
          'scanCount': 0, // <-- THÊM DÒNG NÀY

        });
      }
      return "success";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'Địa chỉ email này đã được sử dụng.';
      }
      return "Đã xảy ra lỗi khi đăng ký, vui lòng thử lại."; 
    } catch (e) {
      return "Đã xảy ra lỗi không xác định, vui lòng thử lại.";
    }
  }

  Future<String> registerAsStudent({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final usernameQuery = await _firestore.collection('users').where('username_lowercase', isEqualTo: username.trim().toLowerCase()).get();
      if (usernameQuery.docs.isNotEmpty) {
        return "Tên người dùng này đã tồn tại.";
      }
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      User? user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(username.trim());
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'username': username.trim(),
          'username_lowercase': username.trim().toLowerCase(),
          'email': email.trim(),
          'createdAt': Timestamp.now(),
          'role': 'user',
          'teacherId': null,
          'scanCount': 0, 

        });
      }
      return "success";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'Địa chỉ email này đã được sử dụng.';
      }
      // THAY ĐỔI: Luôn trả về thông báo tiếng Việt thân thiện
      return "Đã xảy ra lỗi khi đăng ký, vui lòng thử lại.";
    } catch (e) {
      // Bắt cả các lỗi không phải của Firebase
      return "Đã xảy ra lỗi không xác định, vui lòng thử lại.";
    }
  }

  // --- HÀNH ĐỘNG CỦA ADMIN VÀ GIÁO VIÊN ---
  String _generateTeacherCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Future<void> approveTeacher(String userId) async {
    String newCode;
    QuerySnapshot existingCode;
    do {
      newCode = _generateTeacherCode(6);
      existingCode = await _firestore.collection('users').where('teacherCode', isEqualTo: newCode).get();
    } while (existingCode.docs.isNotEmpty);

    await _firestore.collection('users').doc(userId).update({
      'role': 'manager',
      'teacherCode': newCode,
      'showApprovalMessage': true,
    });
  }

  Future<void> rejectTeacher(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'role': 'user',
      'wasRejected': true,
      'teacherId': null,
    });
  }

  Future<List<DocumentSnapshot>> getPendingTeachers() async {
    final snapshot = await _firestore.collection('users').where('role', isEqualTo: 'pending_teacher').get();
    return snapshot.docs;
  }
  
  Future<void> checkAndShowApprovalMessage(BuildContext context, String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && (userDoc.data()?['showApprovalMessage'] == true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tài khoản giáo viên của bạn đã được duyệt!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
        await _firestore.collection('users').doc(userId).update({'showApprovalMessage': false});
      }
    } catch (e) {
      print("Lỗi khi kiểm tra thông báo duyệt: $e");
    }
  }

  Future<void> reapplyAsTeacher() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).update({
      'role': 'pending_teacher',
      'wasRejected': false,
    });
  }

  Future<String> linkStudentToTeacher(String teacherCode) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return "Bạn cần đăng nhập để thực hiện việc này.";

    final teacherQuery = await _firestore.collection('users')
        .where('teacherCode', isEqualTo: teacherCode.trim().toUpperCase()) 
        .where('role', isEqualTo: 'manager')
        .limit(1)
        .get();

    if (teacherQuery.docs.isEmpty) {
      return "Mã giáo viên không hợp lệ hoặc không tồn tại.";
    }
    final teacherId = teacherQuery.docs.first.id;

    await _firestore.collection('users').doc(currentUser.uid).update({
      'teacherId': teacherId,
      'wasRejected': false,
    });
    return "success";
  }
}