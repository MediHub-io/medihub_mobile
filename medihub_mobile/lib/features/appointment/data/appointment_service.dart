import '../../../core/api/api_client.dart';
import 'package:dio/dio.dart';

class AppointmentService {

    Future<void> confirmAppointment(
    String id,
    ) async {
    await ApiClient.dio.patch(
        '/appointments/$id/confirm',
    );
    }

    Future<void> cancelAppointment(
    String id,
    ) async {
    await ApiClient.dio.patch(
        '/appointments/$id/cancel',
    );
    }

  Future<List<dynamic>> getMyAppointments() async {

    final response =
        await ApiClient.dio.get(
      '/appointments',
    );

    return response.data['data'];
  }

  Future<void> createAppointment({
    required DateTime requestedDate,
    String? note,
    }) async {

    await ApiClient.dio.post(
        '/appointments',
        data: {
        'requestedDate':
            requestedDate.toIso8601String(),
        'note': note,
        },
    );
    }


    Future<Map<String, dynamic>> getAppointmentDetail(
        String id,
        ) async {
        final response =
            await ApiClient.dio.get(
            '/doctor/appointments/$id',
        );

        return response.data;
    }


}