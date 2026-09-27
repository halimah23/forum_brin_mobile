import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/category_model.dart';
import '../models/question_model.dart';

class QuestionService {
  static Future<List<CategoryModel>> getTugasFungsi({
    required String token,
  }) async {
    final response = await ApiClient.get(
      ApiEndpoints.tugasFungsi,
      token: token,
    );

    if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map((item) => CategoryModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    throw ApiException('Format respon tugas fungsi tidak valid.');
  }

  static Future<List<QuestionModel>> getQuestions({
    required String token,
  }) async {
    final response = await ApiClient.get(
      ApiEndpoints.questions,
      token: token,
    );

    if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map((item) => QuestionModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    throw ApiException('Format respon daftar pertanyaan tidak valid.');
  }

  static Future<QuestionModel> createQuestion({
    required String token,
    required String judul,
    required String isi,
    required List<int> tugasFungsiIds,
    bool isPublic = true,
  }) async {
    final response = await ApiClient.post(
      ApiEndpoints.questions,
      token: token,
      body: {
        'judul': judul,
        'isi': isi,
        'tugas_fungsi_ids': tugasFungsiIds,
        'is_public': isPublic,
      },
    );

    if (response is Map<String, dynamic>) {
      final questionData = response.containsKey('data') && response['data'] is Map
          ? Map<String, dynamic>.from(response['data'])
          : response;
      return QuestionModel.fromJson(questionData);
    }

    throw ApiException('Gagal mengajukan pertanyaan.');
  }
}
