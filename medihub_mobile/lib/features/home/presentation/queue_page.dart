import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/main_bottom_navigation.dart';
import '../../profile/presentation/widgets/profile_ui.dart';
import '../data/utility_service.dart';

class QueuePage extends StatefulWidget {
  const QueuePage({super.key});

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  final service = UtilityService();
  List<dynamic> departments = [];
  List<dynamic> tickets = [];
  String? selectedDepartment;
  bool loading = true;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final deps = await service.getQueueDepartments();
    final list = await service.getQueueTickets();
    if (!mounted) return;
    setState(() {
      departments = deps;
      tickets = list;
      selectedDepartment = deps.isNotEmpty ? deps.first.toString() : null;
      loading = false;
    });
  }

  Future<void> createTicket() async {
    if (selectedDepartment == null) return;
    setState(() {
      submitting = true;
    });
    await service.createQueueTicket(selectedDepartment!);
    await loadData();
    if (!mounted) return;
    setState(() {
      submitting = false;
    });
  }

  Widget ticketCard(Map<String, dynamic> ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket['department'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chờ khoảng ${ticket['estimatedWaitMinutes'] ?? 8} phút',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              ticket['ticketNumber'] ?? '',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
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
          const ProfileHeader(title: 'Số thứ tự'),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'QUY TRÌNH BỐC SỐ\nLựa chọn phòng khoa phục vụ quý khách bên dưới. Hệ thống sẽ tự động phát sinh số thứ tự sắp xếp theo thứ tự ưu tiên của bạn hằng ngày.',
                                style: TextStyle(height: 1.45),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'LỰA CHỌN PHÒNG KHOA THỰC HIỆN',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: departments.map((item) {
                                final name = item.toString();
                                final selected = selectedDepartment == name;
                                return ChoiceChip(
                                  label: Text(name),
                                  selected: selected,
                                  showCheckmark: false,
                                  selectedColor: AppColors.primaryLight,
                                  onSelected: (_) {
                                    setState(() {
                                      selectedDepartment = name;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),
                            ProfilePrimaryButton(
                              label: submitting
                                  ? 'Đang xác nhận...'
                                  : 'Xác nhận bốc số thứ tự',
                              onPressed: submitting ? null : createTicket,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'DANH SÁCH LƯỢT ĐANG CHỜ CỦA BẠN',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (tickets.isEmpty)
                        const Text('Bạn chưa có lượt đang chờ')
                      else
                        ...tickets.map(
                          (item) => ticketCard(Map<String, dynamic>.from(item)),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
