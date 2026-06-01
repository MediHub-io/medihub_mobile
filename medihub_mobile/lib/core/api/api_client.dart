import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

class ApiClient {

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout:
          const Duration(seconds: 30),
      receiveTimeout:
          const Duration(seconds: 30),
      headers: {
        'Content-Type':
            'application/json',
      },
    ),
  )

    ..interceptors.add(
      InterceptorsWrapper(

        onRequest: (
          options,
          handler,
        ) async {

          final token =
              await SecureStorage
                  .getToken();

          if (token != null) {

            options.headers[
                'Authorization'] =
                'Bearer $token';
          }

          handler.next(options);
        },
      ),
    );
}