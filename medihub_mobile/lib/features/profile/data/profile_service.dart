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

    Future<Map<String, dynamic>>
        updatePatient({
    required String patientId,
    required Map<String, dynamic> data,
    }) async {

    final response =
        await ApiClient.dio.put(
        '/patients/$patientId',
        data: data,
    );

    return response.data;
    }   
}