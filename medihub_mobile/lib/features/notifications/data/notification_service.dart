import '../../../core/api/api_client.dart';

class NotificationService {
  Future<List<Map<String, dynamic>>> list() async {
    final response = await ApiClient.dio.get('/notifications');
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> markRead(String id) async {
    await ApiClient.dio.patch('/notifications/$id/read');
  }

  Future<int> unreadCount() async {
    final response = await ApiClient.dio.get('/notifications/unread-count');
    return int.tryParse(response.data['data']?.toString() ?? '0') ?? 0;
  }
}
