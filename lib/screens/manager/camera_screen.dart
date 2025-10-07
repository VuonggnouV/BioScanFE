import 'dart:io';
import 'package:bioscan/api/predict_api.dart';
import 'package:bioscan/services/history_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:bioscan/theme/colors.dart' as app_colors;
import 'package:bioscan/widgets/animated_border_painter.dart';
import 'package:image_picker/image_picker.dart'; // Import package mới

class CameraScreen extends StatefulWidget {
  final String userId;
  final bool isScanDisabled;
  final bool isGuest;

  const CameraScreen({
    super.key,
    required this.userId,
    this.isScanDisabled = false,
    this.isGuest = false,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final HistoryService _historyService = HistoryService();
  final ImagePicker _picker = ImagePicker(); // Khởi tạo ImagePicker
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String? _userRole;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    availableCameras().then((availableCameras) {
      if (!mounted) return;
      if (availableCameras.isNotEmpty) {
        _cameras = availableCameras;
        _initializeCamera(_cameras![_selectedCameraIndex]);
      }
    }).catchError((err) {
      print('Lỗi khi lấy danh sách camera: $err');
    });

    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    if (widget.isGuest) {
      if (mounted) setState(() => _userRole = 'guest');
      return;
    }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (mounted) {
        final data = userDoc.data() as Map<String, dynamic>?;
        setState(() {
          _userRole = (userDoc.exists && data != null) ? data['role'] : 'user';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _userRole = 'user');
    }
  }

  // --- HÀM MỚI: Xử lý khi nhấn nút Tải ảnh lên ---
  Future<void> _onUploadPressed() async {
    if (_isProcessing || _userRole == null) return;

    try {
      final XFile? imageXFile = await _picker.pickImage(source: ImageSource.gallery);

      if (imageXFile != null) {
        // Nếu người dùng đã chọn ảnh, bắt đầu xử lý
        await _processImage(imageXFile);
      }
    } catch (e) {
      print("Lỗi khi chọn ảnh từ thư viện: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải ảnh lên. Vui lòng thử lại.')),
        );
      }
    }
  }

  Future<void> _onScanPressed() async {
    if (!_isCameraInitialized ||
        _controller == null ||
        _isProcessing ||
        _userRole == null) return;

    setState(() {
      _isProcessing = true;
      _animationController.repeat();
    });

    try {
      final imageXFile = await _controller!.takePicture();
      await _processImage(imageXFile);
    } catch (e) {
      print("Lỗi trong quá trình quét: $e");
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _animationController.stop();
        });
      }
    }
  }

  // --- HÀM MỚI: Tách logic xử lý ảnh ra để tái sử dụng ---
  Future<void> _processImage(XFile imageXFile) async {
    try {
      final docRef = await _historyService.createPlaceholderHistoryEntry(
        userId: widget.userId,
        imagePath: imageXFile.path,
        isGuest: widget.isGuest,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text('Thành công',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text(
              'Đã gửi ảnh thành công. Kết quả sẽ được xử lý trong nền.',
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: <Widget>[
              TextButton(
                child: const Text('OK',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }

      predictAnimal(
        userId: widget.userId,
        role: _userRole!,
        imageFile: File(imageXFile.path),
        scanId: docRef.id,
      ).then((_) {
        print('Backend đã xử lý xong cho scanId: ${docRef.id}');
      }).catchError((err) {
        print('Lỗi khi gọi API xử lý nền: $err');
        docRef.update({'processingStatus': 'failed'});
      });

    } catch (e) {
      print("Lỗi trong quá trình xử lý ảnh: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _animationController.stop();
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) _controller!.dispose();
    else if (state == AppLifecycleState.resumed) {
      if (_cameras != null && _cameras!.isNotEmpty) {
        _initializeCamera(_cameras![_selectedCameraIndex]);
      }
    }
  }

  Future<void> _initializeCamera(CameraDescription cameraDescription) async {
    if (_controller != null) await _controller!.dispose();
    final newController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller = newController;
    try {
      await newController.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      print("Lỗi khởi tạo camera: $e");
    }
  }

  void _onSwitchCamera() {
    if (_cameras == null || _cameras!.length <= 1) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    _initializeCamera(_cameras![_selectedCameraIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Text(
              'PLANT AND BIOLOGY\nSAMPLE RECOGNITION',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: app_colors.textLight,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Center(
                  child: (_isCameraInitialized &&
                          _controller != null &&
                          _controller!.value.isInitialized)
                      ? SizedBox(
                          width: MediaQuery.of(context).size.width * 0.85,
                          height: MediaQuery.of(context).size.width * 0.85,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (_isProcessing)
                                CustomPaint(
                                  painter: AnimatedBorderPainter(
                                    animation: _animationController,
                                    color: app_colors.textLight,
                                    strokeWidth: 4.0,
                                    borderRadius: 20.0,
                                  ),
                                ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20.0),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: _controller!
                                          .value.previewSize!.height,
                                      height: _controller!
                                          .value.previewSize!.width,
                                      child: CameraPreview(_controller!),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const CircularProgressIndicator(
                          color: app_colors.textLight),
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (!_isProcessing)
              Column( // Bọc các nút trong một Column
                children: [
                  ElevatedButton(
                    onPressed:
                        widget.isScanDisabled ? null : _onScanPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: app_colors.inputBackground,
                      foregroundColor: app_colors.textDark,
                      minimumSize: const Size(250, 55),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      elevation: 5,
                    ),
                    child: const Text('SCAN',
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 15),
                  // --- NÚT TẢI ẢNH LÊN MỚI ---
                  TextButton.icon(
                    onPressed: widget.isScanDisabled ? null : _onUploadPressed,
                    icon: const Icon(Icons.photo_library_outlined, color: app_colors.textLight),
                    label: const Text('Tải ảnh lên', style: TextStyle(color: app_colors.textLight, fontSize: 16)),
                  ),
                ],
              )
            else
              const SizedBox(height: 115), // Tăng chiều cao để giữ layout
            
            const SizedBox(height: 15),
            TextButton.icon(
              onPressed: _isProcessing ? null : _onSwitchCamera,
              icon: const Icon(Icons.flip_camera_ios_outlined,
                  color: app_colors.textLight),
              label: const Text('Đổi Camera',
                  style: TextStyle(
                      color: app_colors.textLight, fontSize: 16)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
