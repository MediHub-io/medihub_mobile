import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';

class ProfileService {

  Future<Map<String, dynamic>>
      getPatient(
    String patientId,
  ) async {

    final response =
        await ApiClient.dio.get(
      '/patients/$patientId',
    );

    return response.data;
  }
}