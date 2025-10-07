import 'package:bioscan/models/history_model.dart';
import 'package:bioscan/screens/manager/info_viewer_screen.dart';
import 'package:bioscan/screens/manager/single_image_view_screen.dart';
import 'package:bioscan/services/auth_service.dart';
import 'package:bioscan/services/history_service.dart';
import 'package:bioscan/theme/colors.dart' as app_colors;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bioscan/config/flutter_backend_config.dart';
import 'package:path/path.dart' as p;

class HistoryScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onScanNow;
  final String? feedbackFilter;
  final String? viewingUsername;
  final bool isGuest;

  const HistoryScreen({
    super.key,
    required this.userId,
    required this.onScanNow,
    this.feedbackFilter,
    this.viewingUsername,
    this.isGuest = false,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  final AuthService _authService = AuthService();

  List<HistoryFolder> _historyFolders = [];
  bool _isLoading = true;
  bool _selectionMode = false;
  List<String> _selectedFolderIds = [];
  bool _isViewingOwnHistory = false;
  String _viewingUsername = '...';

  @override
  void initState() {
    super.initState();
    _setupScreen();
  }

  Future<void> _setupScreen() async {
    final isOwn = widget.userId == _authService.currentUser?.uid;
    setState(() { _isViewingOwnHistory = isOwn; });

    if (widget.viewingUsername != null) {
      setState(() { _viewingUsername = widget.viewingUsername!; });
    } else if (!isOwn) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (mounted && userDoc.exists) {
        setState(() { _viewingUsername = userDoc.data()?['username'] ?? 'Người dùng'; });
      }
    }
    
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });

    var folders = await _historyService.getHistoryFolders(userId: widget.userId, isGuest: widget.isGuest);

    if (widget.feedbackFilter != null) {
      if (widget.feedbackFilter == 'liked') {
        folders.removeWhere((f) => f.feedbackStatus != 1);
      } else if (widget.feedbackFilter == 'disliked') {
        folders.removeWhere((f) => f.feedbackStatus != 2);
      }
    }

    if (mounted) {
      setState(() {
        _historyFolders = folders;
        _isLoading = false;
        _selectionMode = false;
        _selectedFolderIds = [];
      });
    }
  }

  void _handleItemTap(HistoryFolder folder) {
    if (_selectionMode) {
      _toggleSelection(folder.id);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'SingleImageViewScreen'),
        builder: (context) => SingleImageViewScreen(item: folder),
      ),
    );
  }

  void _navigateToInfo(HistoryFolder folder) async {
    final isOwner = _authService.currentUser?.uid == widget.userId;
    await Navigator.push(context, MaterialPageRoute(
      settings: const RouteSettings(name: 'InfoViewerScreen'),
      builder: (context) => InfoViewerScreen(
        userId: widget.userId,
        folder: folder,
        isOwnerView: isOwner,
        isGuest: widget.isGuest,
      ),
    ));
    if (mounted) {
      _loadHistory();
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedFolderIds.contains(id)) {
        _selectedFolderIds.remove(id);
      } else {
        _selectedFolderIds.add(id);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedFolderIds.length == _historyFolders.length) {
        _selectedFolderIds.clear();
      } else {
        _selectedFolderIds = _historyFolders.map((f) => f.id).toList();
      }
    });
  }

  void _deleteSelected() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc muốn xóa ${_selectedFolderIds.length} mục đã chọn?"),
        actions: [
          TextButton(child: const Text("Hủy"), onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _historyService.deleteHistoryEntries(userId: widget.userId, ids: _selectedFolderIds, isGuest: widget.isGuest);
              _loadHistory();
            },
          ),
        ],
      ),
    );
  }

  void _enterSelectionMode(String id) {
    if (!_isViewingOwnHistory) return;
    if (!_selectionMode) {
      setState(() {
        _selectionMode = true;
        _selectedFolderIds.add(id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app_colors.background,
      appBar: AppBar(
        backgroundColor: app_colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(_selectionMode ? Icons.close : Icons.arrow_back, color: app_colors.textLight),
          onPressed: () {
            if (_selectionMode) {
              setState(() {
                _selectionMode = false;
                _selectedFolderIds.clear();
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          _selectionMode ? (_selectedFolderIds.isNotEmpty ? '${_selectedFolderIds.length} đã chọn' : 'Chọn mục') : _getTitle(),
          style: const TextStyle(color: app_colors.textLight, fontWeight: FontWeight.bold),
        ),
        actions: _buildAppBarActions(),
      ),
      body: _buildBody(),
    );
  }

  String _getTitle() {
    if (widget.feedbackFilter != null) {
      final username = _viewingUsername;
      if (widget.feedbackFilter == 'liked') {
        return 'Các mục thích của $username';
      } else if (widget.feedbackFilter == 'disliked') {
        return 'Các mục không thích của $username';
      }
    }
    if (_isViewingOwnHistory) {
      return 'Lịch sử quét của tôi';
    }
    return 'Lịch sử của $_viewingUsername';
  }

  List<Widget> _buildAppBarActions() {
    if (!_isViewingOwnHistory) return [];

    if (_selectionMode) {
      return [
        IconButton(
          icon: Icon(
            _selectedFolderIds.length == _historyFolders.length && _historyFolders.isNotEmpty ? Icons.check_box : Icons.check_box_outline_blank,
            color: app_colors.textLight,
          ),
          onPressed: _toggleSelectAll,
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, color: _selectedFolderIds.isNotEmpty ? Colors.redAccent : app_colors.placeholder),
          onPressed: _selectedFolderIds.isNotEmpty ? _deleteSelected : null,
        ),
      ];
    } else {
      return [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: TextButton(
            onPressed: _historyFolders.isNotEmpty ? () => setState(() => _selectionMode = true) : null,
            child: Text('Chọn', style: TextStyle(color: _historyFolders.isNotEmpty ? app_colors.textLight : app_colors.placeholder, fontSize: 17, fontWeight: FontWeight.w600)),
          ),
        ),
      ];
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: app_colors.textLight));
    }
    if (_historyFolders.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        itemCount: _historyFolders.length,
        itemBuilder: (context, index) {
          final folder = _historyFolders[index];
          final isSelected = _selectedFolderIds.contains(folder.id);
          return _buildHistoryItem(folder, isSelected);
        },
      ),
    );
  }

  Widget _buildHistoryItem(HistoryFolder folder, bool isSelected) {
    return Card(
      color: app_colors.formBackground,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected ? const BorderSide(color: app_colors.primaryButton, width: 2.5) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleItemTap(folder),
        onLongPress: () => _enterSelectionMode(folder.id),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              if (_selectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: app_colors.primaryButton),
                ),
              Icon(
                 folder.processingStatus == 'processing' ? Icons.hourglass_top_rounded : Icons.folder_outlined,
                 color: app_colors.primaryButton, size: 40
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(folder.name, style: const TextStyle(fontWeight: FontWeight.bold, color: app_colors.textDark, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (!_selectionMode)
                IconButton(
                  icon: const Icon(Icons.article_outlined, color: app_colors.primaryButton, size: 26),
                  onPressed: () => _navigateToInfo(folder),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_edu_outlined, size: 80, color: app_colors.placeholder),
          const SizedBox(height: 15),
          Text(
            _isViewingOwnHistory ? 'Lịch sử quét của bạn trống.' : 'Người dùng này không có lịch sử.',
            style: const TextStyle(color: app_colors.textLight, fontSize: 18)
          ),
          const SizedBox(height: 25),
          if (_isViewingOwnHistory)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onScanNow();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: app_colors.formBackground,
                foregroundColor: app_colors.textDark,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Quét mẫu vật ngay', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          else
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: app_colors.formBackground,
                foregroundColor: app_colors.textDark,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Quay lại', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}
