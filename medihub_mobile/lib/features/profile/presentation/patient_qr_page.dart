import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/main_bottom_navigation.dart';
import 'widgets/profile_ui.dart';

class PatientQrPage extends StatelessWidget {
  final String patientId;
  final String patientCode;
  final String fullName;
  final String? phone;
  final String? dob;

  const PatientQrPage({
    super.key,
    required this.patientId,
    required this.patientCode,
    required this.fullName,
    this.phone,
    this.dob,
  });

  List<int> barcodeBars() {
    final source = patientCode.isEmpty ? patientId : patientCode;

    return source.codeUnits
        .expand((unit) => [2 + unit % 5, 1, 1 + unit % 3, 1])
        .take(80)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final qrData = '{"patientId":"$patientId","patientCode":"$patientCode"}';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 3),
      body: Column(
        children: [
          const ProfileHeader(title: 'Mã bệnh nhân'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 44, 18, 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x18000000),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 94,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: barcodeBars()
                                .map(
                                  (width) => Container(
                                    width: width.toDouble(),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: .8,
                                    ),
                                    color: Colors.black,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          patientCode,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 12,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/logo_icon.png',
                              width: 74,
                              height: 74,
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Text(
                                fullName.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(
                          color: Colors.black,
                          thickness: 1.4,
                          height: 28,
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.badge_outlined,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(patientCode)),
                            const Icon(
                              Icons.phone_outlined,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(phone ?? ''),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(dob ?? ''),
                            const Spacer(),
                            SizedBox(
                              width: 70,
                              height: 70,
                              child: QrImageView(
                                data: qrData,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  ProfilePrimaryButton(
                    label: 'Đóng',
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
