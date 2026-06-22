import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/main_bottom_navigation.dart';
import '../../profile/presentation/widgets/profile_ui.dart';
import '../data/utility_service.dart';

class SurgeryPage extends StatefulWidget {
  const SurgeryPage({super.key});

  @override
  State<SurgeryPage> createState() => _SurgeryPageState();
}

class _SurgeryPageState extends State<SurgeryPage> {
  final service = UtilityService();
  List<dynamic> cases = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final data = await service.getSurgeryCases();
    if (!mounted) return;
    setState(() {
      cases = data;
      loading = false;
    });
  }

  String money(dynamic value) {
    final amount = int.tryParse(value?.toString() ?? '') ?? 0;
    return '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}đ';
  }

  void openDetail(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        final timeline = (item['timeline'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.88,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                info('Mã hồ sơ', item['recordCode']),
                info(
                  'Ngày thực hiện',
                  DateFormatter.displayDate(item['startedAt']),
                ),
                info('Khoa thực hiện', item['department']),
                info('Bác sĩ phẫu thuật', item['surgeonName']),
                info('Bác sĩ gây mê', item['anesthetistName']),
                info('Chẩn đoán trước mổ', item['preDiagnosis']),
                info('Chẩn đoán sau mổ', item['postDiagnosis']),
                section('Kết quả', item['result'] ?? ''),
                const Text(
                  'Theo dõi tiến trình mổ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...timeline.map(
                  (step) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 58,
                        child: Text(
                          step['timeLabel'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.check_circle, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(step['title'] ?? '')),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                checklist('Hướng dẫn trước mổ', [
                  'Nhịn ăn từ 22h',
                  'Mang CMND/CCCD',
                  'Ký cam kết phẫu thuật',
                  'Mang kết quả xét nghiệm',
                ]),
                checklist('Hướng dẫn sau mổ', [
                  'Không vận động mạnh trong 7 ngày',
                  'Không để vết mổ tiếp xúc nước',
                  'Tái khám ngày ${DateFormatter.displayDate(item['followUpAt'])}',
                ]),
                section(
                  'Cảnh báo',
                  'Nếu xuất hiện sốt > 38.5°C, chảy máu hoặc đau tăng, vui lòng liên hệ bệnh viện ngay.',
                  warning: true,
                ),
                section(
                  'Chi phí phẫu thuật',
                  'Tổng chi phí: ${money(item['totalCost'])}\nBHYT thanh toán: ${money(item['insurancePaid'])}\nNgười bệnh thanh toán: ${money(item['patientPaid'])}',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text('Xem PDF'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('Tải xuống'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget info(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 138,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(child: Text(value?.toString() ?? '')),
        ],
      ),
    );
  }

  Widget section(String title, String content, {bool warning = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warning ? const Color(0xFFFFF1F2) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: warning ? AppColors.error : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(height: 1.45)),
        ],
      ),
    );
  }

  Widget checklist(String title, List<String> items) {
    return section(title, items.map((item) => '✓ $item').join('\n'));
  }

  Widget caseCard(Map<String, dynamic> item) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => openDetail(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_hospital, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormatter.displayDate(item['startedAt']),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  Text(
                    item['title'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text('Bác sĩ: ${item['surgeonName'] ?? ''}'),
                ],
              ),
            ),
            Text(
              '✓ ${item['status'] ?? ''}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 0),
      body: Column(
        children: [
          const ProfileHeader(title: 'Phẫu thuật'),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      section(
                        'Thông tin phẫu thuật & hậu phẫu',
                        'Theo dõi danh sách ca phẫu thuật, tiến trình mổ, hướng dẫn chăm sóc và chi phí.',
                      ),
                      ...cases.map(
                        (item) => caseCard(Map<String, dynamic>.from(item)),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
