import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/flutter_backend_config.dart';
import '../models/scan_history_item.dart';

Future<List<ScanHistoryItem>> fetchHistory(String uid, String role) async {
  final response = await http.get(
    Uri.parse("${BackendConfig.baseUrl}/history/$uid?role=$role"),
  );
  final List data = jsonDecode(response.body);
  return data.map((item) => ScanHistoryItem.fromJson(item)).toList();
}
