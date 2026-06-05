import '../../../core/api/api_client.dart';

class DoctorService {

  Future<void> completeAppointment({
    required String appointmentId,
    required String diagnosis,
    required String conclusion,
    required String note,
  }) async {

    await ApiClient.dio.post(
      '/doctor/appointments/$appointmentId/complete',
      data: {
        'diagnosis': diagnosis,
        'conclusion': conclusion,
        'note': note,
      },
    );
  }
}