import '../../../core/api/api_client.dart';

class ProfileService {
  String errorMessage(Object error) {
    try {
      final dynamic e = error;
      final data = e.response?.data;

      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    } catch (_) {}

    return error.toString();
  }

  Future<Map<String, dynamic>> getPatient(String patientId) async {
    final response = await ApiClient.dio.get('/patients/$patientId');

    return response.data;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await ApiClient.dio.get('/profile/me');

    return response.data;
  }

  Future<Map<String, dynamic>> updatePatient({
    required String patientId,
    required Map<String, dynamic> data,
  }) async {
    final response = await ApiClient.dio.put(
      '/patients/$patientId',
      data: data,
    );

    return response.data;
  }

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) async {
    final response = await ApiClient.dio.put('/profile/me', data: data);

    return response.data;
  }

  Future<Map<String, dynamic>> getRelatives() async {
    final response = await ApiClient.dio.get('/profile/relatives');

    return response.data;
  }

  Future<Map<String, dynamic>> createRelative(Map<String, dynamic> data) async {
    final response = await ApiClient.dio.post('/profile/relatives', data: data);

    return response.data;
  }

  Future<Map<String, dynamic>> updateRelative({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final response = await ApiClient.dio.put(
      '/profile/relatives/$id',
      data: data,
    );

    return response.data;
  }

  Future<Map<String, dynamic>> deleteRelative(String id) async {
    final response = await ApiClient.dio.delete('/profile/relatives/$id');

    return response.data;
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await ApiClient.dio.post(
      '/profile/change-password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );

    return response.data;
  }

  Future<Map<String, dynamic>> requestPhoneOtp(String phone) async {
    final response = await ApiClient.dio.post(
      '/profile/phone/request-otp',
      data: {'phone': phone},
    );

    return response.data;
  }

  Future<Map<String, dynamic>> verifyPhoneOtp({
    required String otpId,
    required String phone,
    required String code,
  }) async {
    final response = await ApiClient.dio.post(
      '/profile/phone/verify-otp',
      data: {'otpId': otpId, 'phone': phone, 'code': code},
    );

    return response.data;
  }

  Future<Map<String, dynamic>> createReferral(Map<String, dynamic> data) async {
    final response = await ApiClient.dio.post('/profile/referrals', data: data);

    return response.data;
  }

  Future<Map<String, dynamic>> getReferralInfo() async {
    final response = await ApiClient.dio.get('/profile/referral-info');

    return response.data;
  }
}
