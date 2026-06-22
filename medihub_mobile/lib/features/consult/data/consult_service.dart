import '../../../core/api/api_client.dart';

class ConsultService {
  Future<List<Map<String, dynamic>>> messages() async {
    final response = await ApiClient.dio.get('/consult/messages');
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> send(String content) async {
    final response = await ApiClient.dio.post(
      '/consult/messages',
      data: {'content': content},
    );
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }
}
