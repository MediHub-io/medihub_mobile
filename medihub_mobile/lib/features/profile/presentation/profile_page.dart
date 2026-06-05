import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/profile_service.dart';
import 'package:dio/dio.dart';
import '../../location/data/location_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/widgets/main_bottom_navigation.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() =>
      _ProfilePageState();
}

class _ProfilePageState
    extends State<ProfilePage> {

    List<dynamic> provinces = [];
    List<dynamic> wards = [];

    dynamic selectedProvince;
    dynamic selectedWard;


  bool _loading = true;
  bool isEditing = false;

    final fullNameController =
        TextEditingController();

    final phoneController =
        TextEditingController();

    final citizenController =
        TextEditingController();

    final ethnicController =
        TextEditingController();

    final nationalityController =
        TextEditingController();

    final insuranceController =
        TextEditingController();

    DateTime? dob;

    String gender = 'MALE';

  Map<String, dynamic>? patient;

  @override
    void initState() {
    super.initState();

    initData();
    }

    Future<void> initData() async {
    await loadProfile();
    await loadProvinces();
    }
    Future<void> loadProvinces() async {

  final service =
      LocationService();

  final result =
      await service.getProvinces();

  debugPrint(
    'PROVINCES COUNT = ${result.length}',
  );

  debugPrint(
    'FIRST PROVINCE = ${result.first}',
  );

  provinces = result;

    if (patient != null) {

    try {
        debugPrint(
        'DB PROVINCE = ${patient!['province']}',
        );
        selectedProvince =
            provinces.firstWhere(
        (p) =>
            p['name'] ==
            patient!['province'],
        );

        debugPrint(
        'RESTORED PROVINCE = ${selectedProvince['name']}',
        );

        final service =
            LocationService();

        wards =
            await service.getWardsByProvince(
            selectedProvince['code'],
            );

        selectedWard =
            wards.firstWhere(
            (w) =>
                w['name'] ==
                patient!['ward'],
            );

    } catch (e) {
        debugPrint(
        'RESTORE LOCATION ERROR = $e',
        );
    }
    }

    setState(() {});
}

    Future<void> uploadAvatar() async {
    try {
        final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        );

        if (image == null) return;

        final patientId =
            await SecureStorage.getPatientId();

        if (patientId == null) return;

        final fileName =
            '$patientId-${DateTime.now().millisecondsSinceEpoch}.jpg';

        if (kIsWeb) {
            final bytes = await image.readAsBytes();

            await Supabase.instance.client.storage
                .from('avatars')
                .uploadBinary(
                    fileName,
                    bytes,
                );
            } else {
            await Supabase.instance.client.storage
                .from('avatars')
                .upload(
                    fileName,
                    File(image.path),
                );
            }

        final avatarUrl =
            Supabase.instance.client.storage
                .from('avatars')
                .getPublicUrl(fileName);

        final service = ProfileService();

        await service.updatePatient(
        patientId: patientId,
        data: {
            'avatarUrl': avatarUrl,
        },
        );

        await loadProfile();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
            'Cập nhật ảnh đại diện thành công',
            ),
        ),
        );
    } catch (e, stackTrace) {
        debugPrint('UPLOAD AVATAR ERROR = $e');
        debugPrint(stackTrace.toString());
        }
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
        // selectedProvince =
        //     patient!['province'];

        // selectedDistrict =
        //     patient!['district'];

        // selectedWard =
        //     patient!['ward'];

        fullNameController.text =
            patient!['fullName'] ?? '';

        phoneController.text =
            patient!['phone'] ?? '';

        citizenController.text =
            patient!['citizenId'] ?? '';

        ethnicController.text =
            patient!['ethnic'] ?? '';

        nationalityController.text =
            patient!['nationality'] ?? '';

        insuranceController.text =
            patient!['insuranceNo'] ?? '';
        
        if (patient!['dob'] != null) {
            dob = DateTime.parse(
                patient!['dob'],
            );
            }

            gender =
                patient!['gender'] ??
                'MALE';

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

  Widget editField(
    String label,
    TextEditingController controller,
    ) {
    return Card(
        child: Padding(
        padding:
            const EdgeInsets.all(12),
        child: TextField(
            controller: controller,
            decoration:
                InputDecoration(
            labelText: label,
            border:
                const OutlineInputBorder(),
            ),
        ),
        ),
    );
    }

Future<void> saveProfile() async {

  try {

    final patientId =
        await SecureStorage
            .getPatientId();

    if (patientId == null) {
      return;
    }

    final service =
        ProfileService();

    debugPrint(
    'SAVE DATA = ${{
        'fullName': fullNameController.text,
        'phone': phoneController.text,
        'citizenId': citizenController.text,
        'ethnic': ethnicController.text,
        'nationality': nationalityController.text,
        'insuranceNo': insuranceController.text,
        'gender': gender,
        'dob': dob?.toIso8601String(),
    }}',
    );


    await service.updatePatient(
      patientId: patientId,

      data: {

        'fullName':
            fullNameController.text,

        'phone':
            phoneController.text,

        'citizenId':
            citizenController.text,

        'ethnic':
            ethnicController.text,

        'nationality':
            nationalityController.text,

        'insuranceNo':
            insuranceController.text,

        'province':
            selectedProvince?['name'],

        'ward':
            selectedWard?['name'],

        'gender':
            gender,

        'dob':
            dob?.toIso8601String(),
      },
    );

    await SecureStorage.updateFullName(
        fullNameController.text,
        );

        await SecureStorage.updatePhone(
        phoneController.text,
        );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content: Text(
          'Cập nhật hồ sơ thành công',
        ),
      ),
    );

    setState(() {
      isEditing = false;
    });


    await loadProfile();

        } on DioException catch (e) {

        debugPrint(
            'STATUS = ${e.response?.statusCode}',
        );

        debugPrint(
            'RESPONSE = ${e.response?.data}',
        );

        String message =
            'Cập nhật thất bại';

        final data = e.response?.data;

        if (data is Map &&
            data['message'] != null) {
            message = data['message'];
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            ),
        );

        } catch (e) {

        debugPrint(
            'SAVE PROFILE ERROR = $e',
        );

    }
}


  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
        bottomNavigationBar:
            const MainBottomNavigation(
        currentIndex: 3,
        ),
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

                    Center(
                        child: GestureDetector(
                            onTap: uploadAvatar,
                            child: CircleAvatar(
                            radius: 50,

                            backgroundImage:
                                patient?['avatarUrl'] != null &&
                                        patient!['avatarUrl']
                                            .toString()
                                            .isNotEmpty
                                    ? NetworkImage(
                                        patient!['avatarUrl'],
                                        )
                                    : null,

                            child:
                                patient?['avatarUrl'] == null ||
                                        patient!['avatarUrl']
                                            .toString()
                                            .isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        )
                                    : null,
                            ),
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

                    isEditing
                    ? editField(
                        'Họ và tên',
                        fullNameController,
                    )
                    : info(
                        'Họ và tên',
                        patient!['fullName'] ?? '',
                    ),


                    isEditing
                        ? Card(
                            child: ListTile(
                            title:
                                const Text(
                                'Ngày sinh',
                            ),

                            subtitle: Text(
                                dob == null
                                    ? ''
                                    : '${dob!.day}/${dob!.month}/${dob!.year}',
                            ),

                            trailing:
                                const Icon(
                                Icons.calendar_month,
                            ),

                            onTap: () async {

                                final picked =
                                    await showDatePicker(
                                context: context,

                                firstDate:
                                    DateTime(1900),

                                lastDate:
                                    DateTime.now(),

                                initialDate:
                                    dob ??
                                    DateTime(
                                        1990,
                                    ),
                                );

                                if (picked != null) {

                                setState(() {
                                    dob = picked;
                                });

                                }

                            },
                            ),
                        )
                        : info(
                            'Ngày sinh',
                            patient!['dob'] == null
                                ? ''
                                : patient!['dob']
                                    .toString()
                                    .substring(0, 10),
                        ),

                    isEditing
                        ? Card(
                            child: Padding(
                            padding:
                                const EdgeInsets.all(
                                12,
                            ),
                            child:
                                DropdownButtonFormField<
                                    String>(
                                value: gender,

                                decoration:
                                    const InputDecoration(
                                labelText:
                                    'Giới tính',
                                ),

                                items: const [

                                DropdownMenuItem(
                                    value: 'MALE',
                                    child: Text(
                                    'Nam',
                                    ),
                                ),

                                DropdownMenuItem(
                                    value: 'FEMALE',
                                    child: Text(
                                    'Nữ',
                                    ),
                                ),

                                ],

                                onChanged: (value) {

                                setState(() {
                                    gender =
                                        value!;
                                });

                                },
                            ),
                            ),
                        )
                        : info(
                            'Giới tính',
                            patient!['gender'] ?? '',
                        ),

                    isEditing
                        ? editField(
                            'Số điện thoại',
                            phoneController,
                        )
                        : info(
                            'Số điện thoại',
                            patient!['phone'] ?? '',
                        ),

                    isEditing
                        ? editField(
                            'CCCD',
                            citizenController,
                        )
                        : info(
                            'CCCD',
                            patient!['citizenId'] ?? '',
                        ),

                    isEditing
                        ? editField(
                            'Dân tộc',
                            ethnicController,
                        )
                        : info(
                            'Dân tộc',
                            patient!['ethnic'] ?? '',
                        ),

                    isEditing
                        ? editField(
                            'Quốc tịch',
                            nationalityController,
                        )
                        : info(
                            'Quốc tịch',
                            patient!['nationality'] ?? '',
                        ),

                    isEditing
                        ? Card(
                            child: Padding(
                            padding:
                                const EdgeInsets.all(12),
                            child:
                                DropdownButtonFormField<dynamic>(
                                    value: selectedProvince,
                                decoration:
                                    const InputDecoration(
                                labelText:
                                    'Tỉnh/Thành',
                                ),
                                items: provinces.map((p) {
                                return DropdownMenuItem(
                                    value: p,
                                    child: Text(
                                    p['name'],
                                    ),
                                );
                                }).toList(),
                                onChanged: (value) async {

                                    setState(() {
                                        selectedProvince = value;
                                        selectedWard = null;
                                    });

                                    final service = LocationService();

                                    final result =
                                        await service.getWardsByProvince(
                                        (value as Map)['code'],
                                    );

                                    setState(() {
                                        wards = result;
                                    });
                                },
                            ),
                            ),
                        )
                        : info(
                            'Tỉnh/Thành',
                            patient!['province'] ?? '',
                        ),

                    isEditing
                    ? Card(
                        child: Padding(
                        padding:
                            const EdgeInsets.all(12),
                        child:
                            DropdownButtonFormField<dynamic>(
                            value: selectedWard,
                            decoration:
                                const InputDecoration(
                            labelText:
                                'Phường/Xã',
                            ),
                            items: wards.map((w) {
                            return DropdownMenuItem(
                                value: w,
                                child: Text(
                                w['name'],
                                ),
                            );
                            }).toList(),
                            onChanged: (value) async {

                                if (value == null) return;

                            setState(() {
                                selectedWard =
                                    value;
                            });
                            },
                        ),
                        ),
                    )
                    : info(
                        'Phường/Xã',
                        patient!['ward'] ?? '',
                    ),

                    isEditing
                        ? editField(
                            'BHYT',
                            insuranceController,
                        )
                        : info(
                            'BHYT',
                            patient!['insuranceNo'] ?? '',
                        ),

                    const SizedBox(height: 20),

                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                            onPressed: () async {

                                if (!isEditing) {

                                    setState(() {
                                    isEditing = true;
                                    });

                                    return;
                                }

                                await saveProfile();

                                },

                            icon: Icon(
                            isEditing
                                ? Icons.save
                                : Icons.edit,
                            ),

                            label: Text(
                            isEditing
                                ? 'Lưu thay đổi'
                                : 'Chỉnh sửa hồ sơ',
                            ),
                        ),
                        ),



                  ],
                ),
    );
  }
}