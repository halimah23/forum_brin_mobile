import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://forum-brin.test/api';

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['message'] ?? 'Login gagal',
    );
  }

  static Future<List<dynamic>> getTugasFungsi({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tugas-fungsi'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['data'];
    }

    throw Exception(
      data['message'] ?? 'Gagal mengambil data tugas fungsi',
    );
  }

  static Future<List<dynamic>> getQuestions({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/questions'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['data'];
    }

    throw Exception(
      data['message'] ?? 'Gagal mengambil daftar pertanyaan',
    );
  }

  static Future<Map<String, dynamic>> createQuestion({
    required String token,
    required String judul,
    required String isi,
    required List<int> tugasFungsiIds,
    bool isPublic = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/questions'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'judul': judul,
        'isi': isi,
        'tugas_fungsi_ids': tugasFungsiIds,
        'is_public': isPublic,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return data;
    }

    throw Exception(
      data['message'] ?? 'Gagal mengajukan pertanyaan',
    );
  }
}
