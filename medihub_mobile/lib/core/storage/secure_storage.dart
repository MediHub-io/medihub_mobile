import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage =
      FlutterSecureStorage();

  static Future<void> saveToken(
    String token,
  ) async {
    await _storage.write(
      key: 'access_token',
      value: token,
    );
  }

  static Future<String?> getToken() async {
  try {
    final token = await _storage.read(
      key: 'access_token',
    );

    print('READ TOKEN: $token');

    return token;
  } catch (e) {
    print('READ TOKEN ERROR: $e');

    rethrow;
  }
}

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}