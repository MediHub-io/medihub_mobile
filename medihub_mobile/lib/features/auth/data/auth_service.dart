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

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String phone,
    required String password,
    String? organizationId,
    String? organizationCode,
    String? dob,
    String? gender,
  }) async {
    final data = <String, dynamic>{
      'fullName': fullName,
      'phone': phone,
      'password': password,
      'organizationId': organizationId,
      'organizationCode': organizationCode,
      'dob': dob,
      'gender': gender,
    }..removeWhere((key, value) => value == null);

    final response = await ApiClient.dio.post(
      '/auth/register',
      data: data,
    );

    return response.data;
  }

  Future<Map<String, dynamic>> requestPasswordReset({
    required String phone,
  }) async {
    final response = await ApiClient.dio.post(
      '/auth/password-reset/request',
      data: {'phone': phone},
    );

    return response.data;
  }

  Future<Map<String, dynamic>> confirmPasswordReset({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    final response = await ApiClient.dio.post(
      '/auth/password-reset/confirm',
      data: {
        'phone': phone,
        'code': code,
        'newPassword': newPassword,
      },
    );

    return response.data;
  }
}
