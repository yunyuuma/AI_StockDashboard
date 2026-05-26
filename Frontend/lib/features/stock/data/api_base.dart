import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/app_session.dart';

const String kBaseUrl = 'http://localhost:8080';

Map<String, String> authHeaders() => {
      'Content-Type': 'application/json',
      if (AppSession.token != null) 'Authorization': 'Bearer ${AppSession.token}',
    };

Future<dynamic> apiGet(String path) async {
  final res = await http.get(Uri.parse('$kBaseUrl$path'), headers: authHeaders());
  if (res.statusCode == 200) return jsonDecode(utf8.decode(res.bodyBytes));
  throw Exception('GET $path failed: ${res.statusCode} ${res.body}');
}

Future<dynamic> apiPost(String path, Map<String, dynamic> body) async {
  final res = await http.post(Uri.parse('$kBaseUrl$path'),
      headers: authHeaders(), body: jsonEncode(body));
  if (res.statusCode >= 200 && res.statusCode < 300) {
    if (res.body.isEmpty) return {};
    return jsonDecode(utf8.decode(res.bodyBytes));
  }
  final err = jsonDecode(utf8.decode(res.bodyBytes));
  throw Exception(err['error'] ?? 'エラーが発生しました。');
}

Future<dynamic> apiPut(String path, Map<String, dynamic> body) async {
  final res = await http.put(Uri.parse('$kBaseUrl$path'),
      headers: authHeaders(), body: jsonEncode(body));
  if (res.statusCode >= 200 && res.statusCode < 300) {
    if (res.body.isEmpty) return {};
    return jsonDecode(utf8.decode(res.bodyBytes));
  }
  final err = jsonDecode(utf8.decode(res.bodyBytes));
  throw Exception(err['error'] ?? 'エラーが発生しました。');
}

Future<void> apiDelete(String path) async {
  final res = await http.delete(Uri.parse('$kBaseUrl$path'), headers: authHeaders());
  if (res.statusCode >= 200 && res.statusCode < 300) return;
  throw Exception('DELETE $path failed: ${res.statusCode}');
}
