import '../../../core/api/api_client.dart';

class AdminAppointmentService {

  Future<List<dynamic>> getAppointments() async {

    final response =
        await ApiClient.dio.get(
      '/appointments',
    );

    return response.data['data'];
  }

  Future<void> proposeAppointment({
    required String id,
    required String appointmentDate,
    required String doctorName,
    required String department,
  }) async {

    await ApiClient.dio.patch(
      '/appointments/$id/propose',
      data: {
        'appointmentDate':
            appointmentDate,
        'doctorName':
            doctorName,
        'department':
            department,
      },
    );
  }

    Future<void> completeAppointment(
        String id,
        ) async {

        await ApiClient.dio.patch(
            '/appointments/$id/complete',
        );
    }


}
