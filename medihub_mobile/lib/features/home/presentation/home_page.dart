import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../profile/presentation/patient_qr_page.dart';
import '../../../core/storage/secure_storage.dart';
import 'widgets/home_banner.dart';
import 'widgets/menu_card.dart';
import '../../profile/data/profile_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState
    extends State<HomePage> {

  String fullName = '';
  String role = '';
  String patientCode = '';
  String patientId = '';
  String phone = '';
  String ageText = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final name =
        await SecureStorage.getFullName();

    final userRole =
        await SecureStorage.getRole();

    final code =
        await SecureStorage.getPatientCode();

    final pid =
    await SecureStorage.getPatientId();

    final userPhone =
        await SecureStorage.getPhone();

    if (pid != null) {

  final service =
      ProfileService();

  final result =
      await service.getPatient(
    pid,
  );

  final patient =
      result['data'];
      debugPrint(
        'DOB = ${patient['dob']}',
        );

  if (patient['dob'] != null) {

    final dob =
        DateTime.parse(
      patient['dob'],
    );

    final now =
        DateTime.now();

    int age =
        now.year - dob.year;

    if (
      now.month < dob.month ||
      (now.month ==
              dob.month &&
          now.day < dob.day)
    ) {
      age--;
    }

    ageText = '$age tuổi';
  }
}

    if (!mounted) return;

    setState(() {
        fullName = name ?? '';
        role = userRole ?? '';
        phone = userPhone ?? '';
        patientCode = code ?? '';
        patientId = pid ?? '';
        });
  }

  Future<void> _logout() async {
    await SecureStorage.clear();

    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FA),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(16),
          child: Column(
            children: [

              // PROFILE

              Container(
                padding:
                    const EdgeInsets.all(
                  12,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color:
                          Colors.black12,
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [

                    const CircleAvatar(
                      radius: 30,
                      backgroundImage:
                          AssetImage(
                        'assets/images/logo_icon.png',
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [

                          Text(
                           '${fullName.toUpperCase()} - $ageText',
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                            ),
                            ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                                'Mã Bệnh nhân: $patientCode',
                                style: const TextStyle(
                                   color: Color(0xFF039C90),
                                    fontWeight: FontWeight.bold,
                                ),
                            ),
                        ],
                      ),
                    ),

                    IconButton(
                        onPressed: () {

                            Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    PatientQrPage(
                                patientId: patientId,
                                patientCode: patientCode,
                                fullName: fullName,
                                ),
                            ),
                            );

                        },
                        icon: const Icon(
                            Icons.qr_code,
                        ),
                        ),

                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons
                            .notifications_none,
                      ),
                    ),

                    IconButton(
                      onPressed:
                          _logout,
                      icon: const Icon(
                        Icons.logout,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              // BANNER

              const HomeBanner(),

              const SizedBox(
                height: 16,
              ),

              // MENU

              GridView.count(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: .95,
                children: [

                  MenuCard(
                    icon:
                        Icons.calendar_month,
                    title:
                        'Lịch khám',
                    color:
                        Color(
                      0xFF00B4A6,
                    ),
                  ),

                  MenuCard(
                    icon:
                        Icons.science,
                    title:
                        'Xét nghiệm',
                    color:
                        Color(
                      0xFFE53935,
                    ),
                  ),

                  MenuCard(
                    icon:
                        Icons.image,
                    title:
                        'CĐHA',
                    color:
                        Color(
                      0xFF8E24AA,
                    ),
                  ),

                  MenuCard(
                    icon:
                        Icons.medication,
                    title:
                        'Đơn thuốc',
                    color:
                        Color(
                      0xFFFF9800,
                    ),
                  ),

                  MenuCard(
                    icon: Icons.person,
                    title: 'Hồ sơ',
                    color: const Color(0xFF1565C0),
                    onTap: () async {

                        await context.push('/profile');

                        await _loadUser();

                    },
                    ),

                  MenuCard(
                    icon:
                        Icons.badge,
                    title:
                        'BHYT',
                    color:
                        Color(
                      0xFF2E7D32,
                    ),
                  ),

                  MenuCard(
                    icon:
                        Icons.local_hospital,
                    title:
                        'Bác sĩ',
                    color:
                        Color(
                      0xFF6D4C41,
                    ),
                  ),

                  MenuCard(
                    icon:
                        Icons.more_horiz,
                    title:
                        'Khác',
                    color:
                        Color(
                      0xFF546E7A,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 24,
              ),

              // NEWS HEADER

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [

                  const Text(
                    'Tin tức',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  TextButton(
                    onPressed: () {},
                    child:
                        const Text(
                      'Xem thêm',
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 8,
              ),

              // NEWS

              ...List.generate(
                6,
                (index) => Card(
                  margin:
                      const EdgeInsets
                          .only(
                    bottom: 10,
                  ),
                  child: ListTile(
                    leading:
                        const Icon(
                      Icons.article,
                    ),
                    title: Text(
                      'Tin tức sức khỏe #${index + 1}',
                    ),
                    subtitle:
                        const Text(
                      'Nội dung tóm tắt...',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}