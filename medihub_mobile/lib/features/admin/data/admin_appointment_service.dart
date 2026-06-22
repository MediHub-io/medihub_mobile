import '../../../core/api/api_client.dart';

class AdminAppointmentService {
  Future<List<dynamic>> getAppointments({
    String status = 'ALL',
    String search = '',
  }) async {
    final response = await ApiClient.dio.get(
      '/appointments',
      queryParameters: {
        if (status != 'ALL') 'status': status,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    return response.data['data'];
  }

  Future<Map<String, dynamic>> getAppointmentDetail(String id) async {
    final response = await ApiClient.dio.get('/appointments/$id');
    return response.data['data'];
  }

  Future<List<dynamic>> getSpecialties() async {
    final response = await ApiClient.dio.get('/appointments/specialties');
    return response.data['data'];
  }

  Future<List<dynamic>> getDoctors({String? specialtyId}) async {
    final response = await ApiClient.dio.get(
      '/appointments/doctors',
      queryParameters: {
        if (specialtyId != null && specialtyId.isNotEmpty)
          'specialtyId': specialtyId,
      },
    );

    return response.data['data'];
  }

  Future<void> proposeAppointment({
    required String id,
    required String appointmentDate,
    required String departmentId,
    required String doctorId,
    String? proposalNote,
  }) async {
    await ApiClient.dio.patch(
      '/appointments/$id/propose',
      data: {
        'appointmentDate': appointmentDate,
        'departmentId': departmentId,
        'doctorId': doctorId,
        'proposalNote': proposalNote,
        'status': 'PROPOSED',
      },
    );
  }

  Future<void> cancelAppointment(String id) async {
    await ApiClient.dio.patch('/appointments/$id/cancel');
  }
}
