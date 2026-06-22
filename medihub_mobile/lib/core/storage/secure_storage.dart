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
    return await _storage.read(
      key: 'access_token',
    );
  } catch (e) {
    rethrow;
  }
}

static Future<void> saveUser({
  required String fullName,
  required String phone,
  required String role,
  required String organizationId,
  String? organizationCode,
  String? organizationName,
  required String patientId,
  required String patientCode,
}) async {
  await _storage.write(
    key: 'full_name',
    value: fullName,
  );

  await _storage.write(
  key: 'phone',
  value: phone,
);

  await _storage.write(
    key: 'role',
    value: role,
  );

  await _storage.write(
    key: 'organization_id',
    value: organizationId,
  );

  await _storage.write(
    key: 'organization_code',
    value: organizationCode ?? '',
  );

  await _storage.write(
    key: 'organization_name',
    value: organizationName ?? '',
  );

  await _storage.write(
    key: 'patient_id',
    value: patientId,
    );

    await _storage.write(
    key: 'patient_code',
    value: patientCode,
    );
}

static Future<void> updateFullName(
  String fullName,
) async {
  await _storage.write(
    key: 'full_name',
    value: fullName,
  );
}

static Future<void> updatePhone(
  String phone,
) async {
  await _storage.write(
    key: 'phone',
    value: phone,
  );
}

static Future<void> updatePatientId(
  String patientId,
) async {
  await _storage.write(
    key: 'patient_id',
    value: patientId,
  );
}

static Future<String?> getFullName() async {
  return _storage.read(
    key: 'full_name',
  );
}

static Future<String?> getPhone() async {
  return _storage.read(
    key: 'phone',
  );
}

static Future<String?> getRole() async {
  return _storage.read(
    key: 'role',
  );
}

static Future<String?> getPatientId() async {
  return _storage.read(
    key: 'patient_id',
  );
}

static Future<String?> getPatientCode() async {
  return _storage.read(
    key: 'patient_code',
  );
}

static Future<String?> getOrganizationId() async {
  return _storage.read(
    key: 'organization_id',
  );
}

static Future<String?> getOrganizationCode() async {
  return _storage.read(
    key: 'organization_code',
  );
}

static Future<String?> getOrganizationName() async {
  return _storage.read(
    key: 'organization_name',
  );
}


  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}
