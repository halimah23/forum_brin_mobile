import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthService {
  static Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.post(
      ApiEndpoints.login,
      body: {
        'email': email,
        'password': password,
      },
    );

    if (response is Map<String, dynamic>) {
      final userData = Map<String, dynamic>.from(response['user'] ?? {});
      final token = response['token']?.toString();
      return UserModel.fromJson(userData, token: token);
    }

    throw ApiException('Format respon login tidak valid.');
  }
}
