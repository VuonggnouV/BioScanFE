import 'package:bioscan/models/user_feedback_stats.dart';
import 'package:bioscan/models/user_scan_stats.dart';
import 'package:bioscan/screens/manager/history_screen.dart';
import 'package:bioscan/services/manager_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:bioscan/theme/colors.dart' as app_colors;
import 'package:intl/intl.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app_colors.background,
      appBar: AppBar(
        title: const Text('Quản lí Người dùng', style: TextStyle(color: app_colors.textLight)),
        backgroundColor: app_colors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: app_colors.textLight),
        bottom: TabBar(
          controller: _tabController,
          labelColor: app_colors.textLight,
          unselectedLabelColor: app_colors.placeholder,
          indicatorColor: app_colors.textLight,
          tabs: const [
            Tab(icon: Icon(Icons.show_chart), text: 'Hoạt động'),
            Tab(icon: Icon(Icons.reviews_outlined), text: 'Đánh giá'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AdminActivityView(),
          AdminFeedbackAnalysisView(),
        ],
      ),
    );
  }
}

// --- VIEW HOẠT ĐỘNG CỦA ADMIN ---
class AdminActivityView extends StatefulWidget {
  const AdminActivityView({super.key});
  @override
  State<AdminActivityView> createState() => _AdminActivityViewState();
}

class _AdminActivityViewState extends State<AdminActivityView> {
  final ManagerService _managerService = ManagerService();
  List<UserScanStats> _allStats = [];
  List<UserScanStats> _filteredStats = [];
  Map<DateTime, int> _frequency = {};
  bool _isLoading = true;
  int _sortColumnIndex = 0;
  bool _isAscending = true;
  String? _roleFilter;
  int _selectedDateChip = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() { _isLoading = true; });

    DateTime? startDate;
    DateTime? endDate;

    if (_selectedDateChip == 1) {
      startDate = DateTime.now().subtract(const Duration(days: 29));
    } else if (_selectedDateChip == 2) {
      final range = await showDateRangePicker(
        context: context,
        initialDateRange: DateTimeRange(start: DateTime.now().subtract(const Duration(days: 6)), end: DateTime.now()),
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (range != null) {
        startDate = range.start;
        endDate = range.end;
      } else {
        if (mounted) setState(() { _isLoading = false; });
        return;
      }
    }
    
    final statsData = await _managerService.getActivityStats();
    final frequencyData = await _managerService.getDailyScanFrequency(
      roleFilter: _roleFilter,
      startDate: startDate,
      endDate: endDate
    );
    
    if (mounted) {
      setState(() {
        _allStats = statsData;
        _frequency = frequencyData;
        _applyFilter();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (_roleFilter == null) {
      _filteredStats = List.from(_allStats);
    } else {
      _filteredStats = _allStats.where((s) => s.role == _roleFilter).toList();
    }
    _onSort(_sortColumnIndex, _isAscending);
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
      if (columnIndex == 0) _filteredStats.sort((a, b) => a.username.compareTo(b.username));
      else if (columnIndex == 1) _filteredStats.sort((a, b) => a.role.compareTo(b.role));
      else if (columnIndex == 2) _filteredStats.sort((a, b) => (a.teacherCode ?? '').compareTo(b.teacherCode ?? ''));
      else if (columnIndex == 3) _filteredStats.sort((a, b) => a.totalScans.compareTo(b.totalScans));
      if (!ascending) _filteredStats = _filteredStats.reversed.toList();
    });
  }

  String _formatRole(String role) {
    if (role == 'manager') return 'Giáo viên';
    if (role == 'user') return 'Học sinh';
    if (role == 'pending_teacher') return 'Chờ duyệt';
    return role;
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Các nút lọc luôn hiển thị
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SegmentedButton<String?>(
            style: SegmentedButton.styleFrom(
              backgroundColor: app_colors.primaryButton,
              foregroundColor: app_colors.textLight,
              selectedForegroundColor: app_colors.textDark,
              selectedBackgroundColor: app_colors.textLight,
            ),
            segments: const [
              ButtonSegment(value: null, label: Text('Tất cả'), icon: Icon(Icons.all_inclusive)),
              ButtonSegment(value: 'manager', label: Text('Giáo viên'), icon: Icon(Icons.school)),
              ButtonSegment(value: 'user', label: Text('Học sinh'), icon: Icon(Icons.person)),
            ],
            selected: {_roleFilter},
            onSelectionChanged: (newSelection) {
              setState(() {
                _roleFilter = newSelection.first;
              });
              _loadData(); // Tải lại dữ liệu với bộ lọc mới
            },
          ),
        ),
        // Vùng nội dung có thể làm mới
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: app_colors.textLight))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(0),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tần suất quét', style: TextStyle(color: app_colors.textLight, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8.0,
                              children: [
                                ChoiceChip(label: const Text('7 ngày qua'), selected: _selectedDateChip == 0, onSelected: (val) { if(val) setState(() { _selectedDateChip = 0; _loadData(); }); }),
                                ChoiceChip(label: const Text('30 ngày qua'), selected: _selectedDateChip == 1, onSelected: (val) { if(val) setState(() { _selectedDateChip = 1; _loadData(); }); }),
                                ChoiceChip(label: const Text('Tùy chọn...'), selected: _selectedDateChip == 2, onSelected: (val) { if(val) setState(() { _selectedDateChip = 2; _loadData(); }); }),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 150,
                              child: _frequency.values.any((v) => v > 0)
                                ? BarChartWidget(frequency: _frequency)
                                : const Center(child: Text("Không có dữ liệu quét trong bộ lọc này.", style: TextStyle(color: app_colors.placeholder))),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: app_colors.placeholder, height: 1),
                      _filteredStats.isEmpty
                        ? const Center(child: Padding(padding: EdgeInsets.all(30.0), child: Text('Không có dữ liệu người dùng.', style: TextStyle(color: app_colors.textLight))))
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              sortColumnIndex: _sortColumnIndex,
                              sortAscending: _isAscending,
                              columns: [
                                DataColumn(label: const Text('Người dùng', style: TextStyle(color: app_colors.textLight, fontWeight: FontWeight.bold)), onSort: _onSort),
                                DataColumn(label: const Text('Vai trò', style: TextStyle(color: app_colors.textLight, fontWeight: FontWeight.bold)), onSort: _onSort),
                                DataColumn(label: const Text('Mã GV', style: TextStyle(color: app_colors.textLight, fontWeight: FontWeight.bold)), onSort: _onSort),
                                DataColumn(label: const Text('Tổng quét', style: TextStyle(color: app_colors.textLight, fontWeight: FontWeight.bold)), numeric: true, onSort: _onSort),
                              ],
                              rows: _filteredStats.map((stat) => DataRow(
                                cells: [
                                  DataCell(Text(stat.username, style: const TextStyle(color: app_colors.textLight))),
                                  DataCell(Text(_formatRole(stat.role), style: const TextStyle(color: app_colors.textLight))),
                                  DataCell(Text(stat.teacherCode ?? '-', style: const TextStyle(color: app_colors.placeholder))),
                                  DataCell(Text(stat.totalScans.toString(), style: const TextStyle(color: app_colors.textLight))),
                                ]
                              )).toList(),
                            ),
                          ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

// --- VIEW ĐÁNH GIÁ CỦA ADMIN ---
class AdminFeedbackAnalysisView extends StatefulWidget {
  const AdminFeedbackAnalysisView({super.key});
  @override
  State<AdminFeedbackAnalysisView> createState() => _AdminFeedbackAnalysisViewState();
}
class _AdminFeedbackAnalysisViewState extends State<AdminFeedbackAnalysisView> {
  final ManagerService _managerService = ManagerService();
  List<UserFeedbackStats> _allStats = [];
  List<UserFeedbackStats> _filteredStats = [];
  bool _isLoading = true;
  int _sortColumnIndex = 1;
  bool _isAscending = false;
  String? _roleFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() { _isLoading = true; });
    final data = await _managerService.getFeedbackStats();
    if (mounted) {
      setState(() {
        _allStats = data;
        _applyFilter();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    setState(() {
      if (_roleFilter == null) {
        _filteredStats = List.from(_allStats);
      } else {
        _filteredStats = _allStats.where((s) => s.role == _roleFilter).toList();
      }
      _onSort(_sortColumnIndex, _isAscending);
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
      if (columnIndex == 0) _filteredStats.sort((a, b) => a.username.compareTo(b.username));
      else if (columnIndex == 1) _filteredStats.sort((a, b) => a.role.compareTo(b.role));
      else if (columnIndex == 2) _filteredStats.sort((a, b) => a.totalScans.compareTo(b.totalScans));
      else if (columnIndex == 3) _filteredStats.sort((a, b) => a.likes.compareTo(b.likes));
      else if (columnIndex == 4) _filteredStats.sort((a, b) => a.dislikes.compareTo(b.dislikes));
      else if (columnIndex == 5) _filteredStats.sort((a, b) => a.likeRate.compareTo(b.likeRate));
      if (!ascending) _filteredStats = _filteredStats.reversed.toList();
    });
  }

  String _formatRole(String role) {
    if (role == 'manager') return 'Giáo viên';
    if (role == 'user') return 'Học sinh';
    if (role == 'pending_teacher') return 'Chờ duyệt';
    return role;
  }
  
  void _showHistoryDetails(BuildContext context, UserFeedbackStats stat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: app_colors.formBackground,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Xem chi tiết cho ${stat.username}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: app_colors.textDark)),
          ),
          ListTile(leading: const Icon(Icons.history, color: app_colors.textDark), title: const Text('Tất cả lịch sử', style: TextStyle(color: app_colors.textDark)), onTap: () => _navigateToFilteredHistory(context, stat.uid, stat.username, null)),
          ListTile(leading: const Icon(Icons.thumb_up_outlined, color: Colors.green), title: const Text('Chỉ xem các lượt thích', style: TextStyle(color: app_colors.textDark)), onTap: () => _navigateToFilteredHistory(context, stat.uid, stat.username, 'liked')),
          ListTile(leading: const Icon(Icons.thumb_down_outlined, color: Colors.red), title: const Text('Chỉ xem các lượt không thích', style: TextStyle(color: app_colors.textDark)), onTap: () => _navigateToFilteredHistory(context, stat.uid, stat.username, 'disliked')),
        ]),
      ),
    );
  }

  void _navigateToFilteredHistory(BuildContext context, String userId, String username, String? filter) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryScreen(
      userId: userId,
      onScanNow: () {},
      feedbackFilter: filter,
      viewingUsername: username,
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SegmentedButton<String?>(
            style: SegmentedButton.styleFrom(
              backgroundColor: app_colors.primaryButton,
              foregroundColor: app_colors.textLight,
              selectedForegroundColor: app_colors.textDark,
              selectedBackgroundColor: app_colors.textLight,
            ),
            segments: const [
              ButtonSegment(value: null, label: Text('Tất cả')),
              ButtonSegment(value: 'manager', label: Text('Giáo viên')),
              ButtonSegment(value: 'user', label: Text('Học sinh')),
            ],
            selected: {_roleFilter},
            onSelectionChanged: (newSelection) {
              setState(() {
                _roleFilter = newSelection.first;
                _applyFilter();
              });
            },
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: app_colors.textLight))
              : _filteredStats.isEmpty
                  ? const Center(child: Text('Không có dữ liệu phù hợp.', style: TextStyle(color: app_colors.textLight)))
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            sortColumnIndex: _sortColumnIndex,
                            sortAscending: _isAscending,
                            showCheckboxColumn: false,
                            columns: [
                              DataColumn(label: const Text('Người dùng', style: TextStyle(color: app_colors.textLight, fontWeight: FontWeight.bold)), onSort: _onSort),
                              DataColumn(label: const Text('Vai trò', style: TextStyle(color: app_colors.textLight, fontWeight: FontWeight.bold)), onSort: _onSort),
                              DataColumn(label: const Text('Tổng', style: TextStyle(color: app_colors.textLight, fontWeight: FontWeight.bold)), numeric: true, onSort: _onSort),
                              DataColumn(label: const Text('👍', style: TextStyle(fontSize: 18)), numeric: true, onSort: _onSort),
                              DataColumn(label: const Text('👎', style: TextStyle(fontSize: 18)), numeric: true, onSort: _onSort),
                              DataColumn(label: const Text('Tỷ lệ 👍', style: TextStyle(color: app_colors.textLight, fontWeight: FontWeight.bold)), numeric: true, onSort: _onSort),
                            ],
                            rows: _filteredStats.map((stat) => DataRow(
                              onSelectChanged: (_) => _showHistoryDetails(context, stat),
                              cells: [
                                DataCell(Text(stat.username, style: const TextStyle(color: app_colors.textLight))),
                                DataCell(Text(_formatRole(stat.role), style: const TextStyle(color: app_colors.textLight))),
                                DataCell(Text(stat.totalScans.toString(), style: const TextStyle(color: app_colors.textLight))),
                                DataCell(Text(stat.likes.toString(), style: const TextStyle(color: app_colors.textLight))),
                                DataCell(Text(stat.dislikes.toString(), style: const TextStyle(color: app_colors.textLight))),
                                DataCell(Text('${(stat.likeRate * 100).toStringAsFixed(0)}%', style: const TextStyle(color: app_colors.textLight))),
                              ]
                            )).toList(),
                          ),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}

class BarChartWidget extends StatelessWidget {
  final Map<DateTime, int> frequency;
  const BarChartWidget({super.key, required this.frequency});

  @override
  Widget build(BuildContext context) {
    final sortedEntries = frequency.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final maxY = (frequency.values.isEmpty || frequency.values.every((v) => v == 0)
            ? 10.0
            : frequency.values.reduce((a, b) => a > b ? a : b))
        .toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blueGrey.withOpacity(0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final day = sortedEntries[group.x.toInt()].key;
              final count = rod.toY.toInt();
              return BarTooltipItem(
                '${DateFormat('dd/MM').format(day)}\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                children: <TextSpan>[
                  TextSpan(
                    text: '$count lượt quét',
                    style: const TextStyle(color: Colors.yellow, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final day = sortedEntries[value.toInt()].key;
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 4,
                  child: Text(DateFormat('dd/MM').format(day), style: const TextStyle(color: app_colors.placeholder, fontSize: 12)),
                );
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: sortedEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data.value.toDouble(),
                color: app_colors.textLight.withOpacity(0.8),
                width: 18,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}