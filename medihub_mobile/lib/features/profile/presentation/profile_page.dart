import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() =>
      _ProfilePageState();
}

class _ProfilePageState
    extends State<ProfilePage> {

  bool _loading = true;

  Map<String, dynamic>? patient;

  @override
  void initState() {
    super.initState();

    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final patientId =
          await SecureStorage
              .getPatientId();
        debugPrint(
        'PROFILE PATIENT ID = $patientId',
        );

      if (patientId == null) {
        throw Exception(
          'PatientId not found',
        );
      }

      final service =
          ProfileService();

      final result =
          await service.getPatient(
        patientId,
      );

      setState(() {
        patient = result['data'];
        _loading = false;
      });
    } catch (e) {
      debugPrint(
        e.toString(),
      );

      setState(() {
        _loading = false;
      });
    }
  }

  Widget info(
    String label,
    String value,
  ) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
            leading: IconButton(
                icon: const Icon(
                Icons.arrow_back,
                ),
                onPressed: () {
                context.pop();
                },
            ),
            title: const Text(
                'Hồ sơ bệnh nhân',
            ),
        ),

      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : patient == null
              ? const Center(
                  child: Text(
                    'Không tải được hồ sơ',
                  ),
                )
              : ListView(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),

                  children: [

                    const CircleAvatar(
                      radius: 50,
                      child: Icon(
                        Icons.person,
                        size: 50,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    info(
                      'Mã bệnh nhân',
                      patient![
                              'patientCode'] ??
                          '',
                    ),

                    info(
                      'Họ và tên',
                      patient![
                              'fullName'] ??
                          '',
                    ),

                    info(
                      'Giới tính',
                      patient![
                              'gender'] ??
                          '',
                    ),

                    info(
                      'Số điện thoại',
                      patient![
                              'phone'] ??
                          '',
                    ),

                    info(
                      'CCCD',
                      patient![
                              'citizenId'] ??
                          '',
                    ),

                    info(
                      'Quốc tịch',
                      patient![
                              'nationality'] ??
                          '',
                    ),

                    info(
                      'Tỉnh/Thành',
                      patient![
                              'province'] ??
                          '',
                    ),

                    info(
                      'Quận/Huyện',
                      patient![
                              'district'] ??
                          '',
                    ),

                    info(
                      'Phường/Xã',
                      patient![
                              'ward'] ??
                          '',
                    ),

                    info(
                      'BHYT',
                      patient![
                              'insuranceNo'] ??
                          '',
                    ),
                  ],
                ),
    );
  }
}