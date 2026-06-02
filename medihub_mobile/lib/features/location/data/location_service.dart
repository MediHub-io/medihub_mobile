import 'package:dio/dio.dart';

class LocationService {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://provinces.open-api.vn/api',
    ),
  );

  Future<List<dynamic>> getProvinces() async {
  final res = await dio.get('/v2/p/');

  print('PROVINCES RESPONSE = ${res.data}');

  return res.data;
}

  Future<List<dynamic>> getWardsByProvince(
    int provinceCode,
    ) async {

    final res = await dio.get(
        '/v2/p/$provinceCode?depth=2',
    );

    return res.data['wards'] ?? [];
    }

  
}