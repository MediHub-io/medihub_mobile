import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/main_bottom_navigation.dart';
import '../../profile/presentation/widgets/profile_ui.dart';
import '../data/utility_service.dart';

class LabResultsPage extends StatefulWidget {
  const LabResultsPage({super.key});

  @override
  State<LabResultsPage> createState() => _LabResultsPageState();
}

class _LabResultsPageState extends State<LabResultsPage> {
  final service = UtilityService();
  List<dynamic> results = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final data = await service.getLabResults();
    if (!mounted) return;
    setState(() {
      results = data;
      loading = false;
    });
  }

  bool abnormal(Map<String, dynamic> item) {
    final value = num.tryParse(item['value']?.toString() ?? '');
    final min = num.tryParse(item['normalMin']?.toString() ?? '');
    final max = num.tryParse(item['normalMax']?.toString() ?? '');
    if (value == null) return false;
    if (min != null && value < min) return true;
    if (max != null && value > max) return true;
    return false;
  }

  String reference(Map<String, dynamic> item) {
    if (item['referenceText'] != null) return item['referenceText'].toString();
    return 'CSTC: ${item['normalMin'] ?? ''} - ${item['normalMax'] ?? ''}';
  }

  Widget resultCard(Map<String, dynamic> result) {
    final indicators = (result['indicators'] as List? ?? [])
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final warning = indicators.any(abnormal);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result['testName'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Ngày thực hiện: ${DateFormatter.displayDate(result['performedAt'])}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: warning
                      ? const Color(0xFFFFF0E6)
                      : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  warning
                      ? 'Cần lưu ý'
                      : (result['conclusion']?.toString().isNotEmpty == true
                          ? result['conclusion'].toString()
                          : (result['statusLabel'] ?? 'Đã duyệt').toString()),
                  style: TextStyle(
                    color: warning ? AppColors.error : AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 26),
          ...indicators.map((item) {
            final isBad = abnormal(item);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  if (isBad)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 16,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      item['name'] ?? '',
                      style: TextStyle(
                        color: isBad ? AppColors.error : Colors.black,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item['value']} ${item['unit']}',
                        style: TextStyle(
                          color: isBad ? AppColors.error : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        reference(item),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
              border: const Border(
                left: BorderSide(color: AppColors.primary, width: 3),
              ),
            ),
            child: Text('Bác sĩ nhận định: ${result['doctorNote'] ?? ''}'),
          ),
        ],
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
          const ProfileHeader(title: 'Xét nghiệm'),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      const Text(
                        'Quản lý và tra cứu phiếu kết quả xét nghiệm chi tiết.',
                        style: TextStyle(height: 1.45),
                      ),
                      const SizedBox(height: 16),
                      if (results.isEmpty)
                        const _EmptyResultMessage(
                          message: 'Chưa có kết quả xét nghiệm đã duyệt.',
                        )
                      else
                        ...results.map(
                          (item) =>
                              resultCard(Map<String, dynamic>.from(item)),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResultMessage extends StatelessWidget {
  const _EmptyResultMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
