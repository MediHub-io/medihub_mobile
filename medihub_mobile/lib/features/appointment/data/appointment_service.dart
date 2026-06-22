import '../../../core/api/api_client.dart';

class AppointmentService {
  Future<List<dynamic>> getSpecialties() async {
    final response = await ApiClient.dio.get('/appointments/specialties');
    return response.data['data'];
  }

  Future<List<dynamic>> getDoctors({String? specialtyId}) async {
    final queryParameters = <String, dynamic>{};
    if (specialtyId != null) {
      queryParameters['specialtyId'] = specialtyId;
    }

    final response = await ApiClient.dio.get(
      '/appointments/doctors',
      queryParameters: queryParameters,
    );

    return response.data['data'];
  }

  Future<void> confirmAppointment(String id) async {
    await ApiClient.dio.patch('/appointments/$id/confirm');
  }

  Future<void> cancelAppointment(String id) async {
    await ApiClient.dio.patch('/appointments/$id/cancel');
  }

  Future<List<dynamic>> getMyAppointments() async {
    final response = await ApiClient.dio.get('/appointments/my');
    return response.data['data'];
  }

  Future<void> createAppointment({
    required DateTime requestedDate,
    String? note,
  }) async {
    await ApiClient.dio.post(
      '/appointments',
      data: {'requestedDate': requestedDate.toIso8601String(), 'note': note},
    );
  }

  Future<Map<String, dynamic>> getAppointmentDetail(String id) async {
    final response = await ApiClient.dio.get('/appointments/$id');
    return response.data['data'];
  }
}
