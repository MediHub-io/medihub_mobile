import '../../../core/api/api_client.dart';

class OrganizationService {
  Future<List<Map<String, dynamic>>> list() async {
    final response = await ApiClient.dio.get('/organizations');
    final rows = response.data['data'] as List<dynamic>? ?? [];
    return rows.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>?> getByCode(String code) async {
    if (code.trim().isEmpty) return null;
    final response = await ApiClient.dio.get('/organizations/$code');
    final data = response.data['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }
}
