import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../profile/presentation/patient_qr_page.dart';
import '../../../core/storage/secure_storage.dart';
import 'widgets/home_banner.dart';
import 'widgets/menu_card.dart';
import '../../profile/data/profile_service.dart';
import '../../news/data/news_service.dart';
import '../../../core/theme/app_colors.dart';

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

  List<dynamic> news = [];
  bool loadingNews = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadNews();
  }

    Future<void> _loadNews() async {
    try {
        
        final result =
            await NewsService().getNews(
            page: 1,
            limit: 6,
            );

        if (!mounted) return;

        setState(() {
        news = result['data'];
        loadingNews = false;
        });
    } catch (e) {
        debugPrint(
        'LOAD NEWS ERROR = $e',
        );

        if (!mounted) return;

        setState(() {
        loadingNews = false;
        });
    }
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


    Widget newsCard(
Map<String, dynamic> item,
) {
final createdAt =
DateTime.tryParse(
item['createdAt']
?.toString() ??
'',
);

final dateText =
createdAt == null
? ''
: '${createdAt.day.toString().padLeft(2, '0')}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.year}';

return InkWell(
borderRadius:
BorderRadius.circular(
24,
),
onTap: () {
context.push(
'/news/${item['id']}',
);
},
child: Container(
margin:
const EdgeInsets.only(
bottom: 12,
),
decoration:
BoxDecoration(
color:
AppColors.card,
borderRadius:
BorderRadius.circular(
24,
),
boxShadow: const [
BoxShadow(
color:
AppColors.shadow,
blurRadius: 16,
offset:
Offset(0, 6),
),
],
),
child: Padding(
padding:
const EdgeInsets.all(
12,
),
child: Row(
children: [

        item['imageUrl'] != null &&
                item['imageUrl']
                    .toString()
                    .isNotEmpty
            ? ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                child:
                    Image.network(
                  item['imageUrl'],
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                width: 90,
                height: 90,
                decoration:
                    BoxDecoration(
                  color:
                      AppColors.primaryLight,
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                child:
                    const Icon(
                  Icons.article,
                  size: 40,
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
                dateText,
                style:
                    const TextStyle(
                  fontSize: 12,
                  color:
                      AppColors.textSecondary,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              Text(
                item['title'] ?? '',
                maxLines: 2,
                overflow:
                    TextOverflow
                        .ellipsis,
                style:
                    const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              Text(
                item['summary'] ??
                    '',
                maxLines: 2,
                overflow:
                    TextOverflow
                        .ellipsis,
                style:
                    const TextStyle(
                  color:
                      AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
),

);
}

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
        body: Container(
            decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.gradient,
            ),
            ),

      child: SafeArea(
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
                  color: AppColors.card,
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
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
                                   color: AppColors.secondary,
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
                        AppColors.secondary,
                        onTap: () {
                        context.push(
                            '/appointments',
                        );
                        },

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
                        AppColors.success,
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
                    onPressed: () {
                        context.push('/news');
                    },
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

              if (loadingNews)
                const Center(
                    child:
                        CircularProgressIndicator(),
                )
                else if (news.isEmpty)
                const Card(
                    child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                        'Chưa có tin tức',
                    ),
                    ),
                    
                )
                else
                ...news.map(
                    (item) => newsCard(item),
                ),
            ],
          ),
        ),
      ),
      ),
    );
    
  }
}