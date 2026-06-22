import '../../../core/api/api_client.dart';

class UtilityService {
  Future<List<dynamic>> getGuides() async {
    final response = await ApiClient.dio.get('/utilities/guides');
    return response.data['data'];
  }

  Future<void> sendFeedback({
    required int rating,
    String? fullName,
    String? phone,
    String? content,
  }) async {
    await ApiClient.dio.post(
      '/utilities/feedback',
      data: {
        'rating': rating,
        'fullName': fullName,
        'phone': phone,
        'content': content,
      },
    );
  }

  Future<Map<String, dynamic>> getHotline() async {
    final response = await ApiClient.dio.get('/utilities/hotline');
    return response.data['data'];
  }

  Future<void> requestCallback({
    required String phone,
    String? fullName,
    String? note,
  }) async {
    await ApiClient.dio.post(
      '/utilities/callback-requests',
      data: {'phone': phone, 'fullName': fullName, 'note': note},
    );
  }

  Future<List<dynamic>> getQueueDepartments() async {
    final response = await ApiClient.dio.get('/utilities/queue/departments');
    return response.data['data'];
  }

  Future<List<dynamic>> getQueueTickets() async {
    final response = await ApiClient.dio.get('/utilities/queue/tickets');
    return response.data['data'];
  }

  Future<void> createQueueTicket(String department) async {
    await ApiClient.dio.post(
      '/utilities/queue/tickets',
      data: {'department': department},
    );
  }

  Future<List<dynamic>> getLabResults() async {
    final response = await ApiClient.dio.get('/utilities/lab-results');
    return response.data['data'];
  }

  Future<List<dynamic>> getImagingResults() async {
    final response = await ApiClient.dio.get('/utilities/imaging-results');
    return response.data['data'];
  }

  Future<List<dynamic>> getSurgeryCases() async {
    final response = await ApiClient.dio.get('/utilities/surgery-cases');
    return response.data['data'];
  }
}
