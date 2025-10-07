import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../config/flutter_backend_config.dart';

Future<Map<String, dynamic>> predictAnimal({
  required String userId,
  required String role,
  required File imageFile,
  required String scanId, 

}) async {
  final request = http.MultipartRequest(
    "POST",
    Uri.parse("${BackendConfig.baseUrl}/predict"),
  );
  request.fields['user_id'] = userId;
  request.fields['role'] = role;
  request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
  request.fields['scan_id'] = scanId; 


  final response = await request.send();
  final resBody = await http.Response.fromStream(response);
  return jsonDecode(resBody.body);
}
