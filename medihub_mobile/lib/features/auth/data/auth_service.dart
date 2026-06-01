import '../../../core/api/api_client.dart';

class AuthService {
  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final response =
        await ApiClient.dio.post(
      '/auth/login',
      data: {
        'phone': phone,
        'password': password,
      },
    );

    return response.data;
  }
}