import 'package:flutter/material.dart';

import '../data/appointment_service.dart';
import 'package:go_router/go_router.dart';
import 'appointment_detail_page.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/medihub_page.dart';
import '../../../shared/widgets/main_bottom_navigation.dart';

class AppointmentsPage
    extends StatefulWidget {

  const AppointmentsPage({
    super.key,
  });

  @override
  State<AppointmentsPage> createState() =>
      _AppointmentsPageState();
}

class _AppointmentsPageState
    extends State<AppointmentsPage> {

        String getStatusText(
            String status,
            ) {
            switch (status) {

                case 'REQUESTED':
                return 'Đang chờ xác nhận';

                case 'PROPOSED':
                return 'BV đề xuất lịch';

                case 'CONFIRMED':
                return 'Đã xác nhận';

                case 'COMPLETED':
                return 'Đã khám';

                case 'CANCELLED':
                return 'Đã hủy';

                default:
                return status;
            }
        }

        Color getStatusColor(
            String status,
            ) {
            switch (status) {
                case 'REQUESTED':
                return AppColors.warning;

                case 'PROPOSED':
                return AppColors.secondary;

                case 'CONFIRMED':
                return AppColors.success;

                case 'COMPLETED':
                return AppColors.textSecondary;

                case 'CANCELLED':
                return AppColors.error;

                default:
                return AppColors.textSecondary;
            }
            }

  final service =
      AppointmentService();

  List<dynamic> appointments = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();

    loadAppointments();
  }

  Future<void> loadAppointments() async {

    try {

      final result =
          await service
              .getMyAppointments();

      if (!mounted) return;

      setState(() {
        appointments = result;
        loading = false;
      });

    } catch (e) {

      debugPrint(
        'LOAD APPOINTMENTS ERROR = $e',
      );

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return MediHubPage(
  title: 'Lịch khám',
bottomNavigationBar:
    const MainBottomNavigation(
  currentIndex: 1,
),
  floatingActionButton:
      FloatingActionButton(
    backgroundColor:
        AppColors.primary,
    onPressed: () async {
      await context.push(
        '/appointments/create',
      );

      await loadAppointments();
    },
    child: const Icon(
      Icons.add,
      color: AppColors.white,
    ),
  ),

  child:       
     loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : appointments.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có lịch khám',
                  ),
                )
              : ListView.builder(
                  itemCount:
                      appointments.length,
                  itemBuilder:
                      (context, index) {

                    final item =
                        appointments[index];
//print(item);
                    return InkWell(
  borderRadius:
      BorderRadius.circular(20),

  onTap: () async {

    final result =
        await Navigator.push(
        context,
        MaterialPageRoute(
        builder: (_) =>
            AppointmentDetailPage(
            appointment: item,
        ),
        ),
    );

    if (result == true) {
        await loadAppointments();
    }
},

  child: Card(
  color: AppColors.card,
  elevation: 0,
    shape:
        RoundedRectangleBorder(
      side: BorderSide(
        color: getStatusColor(
          item['status'] ?? '',
        ),
        width: 1,
      ),
      borderRadius:
          BorderRadius.circular(20),
    ),

    margin:
        const EdgeInsets.all(8),

    child: ListTile(
      title: Text(
        getStatusText(
          item['status'] ?? '',
        ),
        style: TextStyle(
          color: getStatusColor(
            item['status'] ?? '',
          ),
          fontWeight:
              FontWeight.bold,
        ),
      ),

      subtitle: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          if (item['requestedDate'] !=
              null)
            Text(
              'Ngày mong muốn: '
              '${item['requestedDate'].toString().substring(0, 10)}',
            ),

          const SizedBox(
            height: 4,
          ),

          Text(
            item['note'] ?? '',
          ),
        ],
      ),
    ),
  
  
  ),
  );
},
              ),
    );
  }
}