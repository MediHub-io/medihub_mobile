import '../../../core/api/api_client.dart';

class NewsService {
  Future<Map<String, dynamic>> getNews({
  int page = 1,
  int limit = 10,
}) async {

  final response =
      await ApiClient.dio.get(
    '/news',
    queryParameters: {
      'page': page,
      'limit': limit,
    },
  );

  return response.data;
}

  Future<void> createNews({
    required Map<String, dynamic> data,
  }) async {
    await ApiClient.dio.post(
      '/news',
      data: data,
    );
  }

  Future<void> updateNews({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    await ApiClient.dio.put(
      '/news/$id',
      data: data,
    );
  }

  Future<void> deleteNews(
    String id,
  ) async {
    await ApiClient.dio.delete(
      '/news/$id',
    );
  }

  Future<Map<String, dynamic>>
      getNewsById(
    String id,
  ) async {
    final response =
        await ApiClient.dio.get(
      '/news/$id',
    );

    return response.data['data'];
  }
}