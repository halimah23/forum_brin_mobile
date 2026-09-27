import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  static Map<String, String> _buildHeaders({String? token}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static dynamic _handleResponse(http.Response response) {
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final message = (data is Map && data.containsKey('message'))
        ? data['message'].toString()
        : 'Terjadi kesalahan pada server (${response.statusCode})';

    throw ApiException(message, statusCode: response.statusCode);
  }

  static Future<dynamic> get(String url, {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _buildHeaders(token: token),
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal terhubung ke server: ${e.toString()}');
    }
  }

  static Future<dynamic> post(
    String url, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _buildHeaders(token: token),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal terhubung ke server: ${e.toString()}');
    }
  }
}
