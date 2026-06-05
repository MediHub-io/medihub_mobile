import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../appointment/data/appointment_service.dart';
import '../../../shared/widgets/medihub_page.dart';
import '../../../shared/widgets/medihub_card.dart';
import '../../../core/theme/app_colors.dart';
import '../data/admin_appointment_service.dart';


class AdminAppointmentDetailPage
extends StatefulWidget {

final String appointmentId;

const AdminAppointmentDetailPage({
super.key,
required this.appointmentId,
});

@override
State<AdminAppointmentDetailPage>
createState() =>
_AdminAppointmentDetailPageState();
}

class _AdminAppointmentDetailPageState
extends State<AdminAppointmentDetailPage> {

final service =
AppointmentService();
final adminservice =
    AdminAppointmentService();

bool loading = true;

Map<String, dynamic>? appointment;

@override
void initState() {
super.initState();
loadDetail();
}

String getStatusText(
  String? status,
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
      return status ?? '';
  }
}

String formatDate(
  String? value,
) {
  if (value == null ||
      value.isEmpty) {
    return '';
  }

  final date =
      DateTime.parse(value);

  return
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

Future<void> showProposeDialog(
    Map<String, dynamic> item,
  ) async {
    final doctorController =
        TextEditingController();

    final departmentController =
        TextEditingController();

    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Đề xuất lịch khám',
          ),
          content: StatefulBuilder(
            builder: (
              context,
              setDialogState,
            ) {
              return SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    TextField(
                      controller:
                          doctorController,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Bác sĩ',
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller:
                          departmentController,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Khoa',
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final date =
                            await showDatePicker(
                          context:
                              context,
                          firstDate:
                              DateTime.now(),
                          lastDate:
                              DateTime(
                            2030,
                          ),
                          initialDate:
                              DateTime.now(),
                        );

                        if (date == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedDate =
                              date;
                        });
                      },
                      icon: const Icon(
                        Icons.calendar_month,
                      ),
                      label: Text(
                        selectedDate ==
                                null
                            ? 'Chọn ngày khám'
                            : selectedDate!
                                .toString()
                                .substring(
                                  0,
                                  10,
                                ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child: const Text(
                'Hủy',
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (
                    doctorController.text.trim().isEmpty
                ) {
                ScaffoldMessenger.of(
                    context,
                ).showSnackBar(
                    const SnackBar(
                    content: Text(
                        'Vui lòng nhập bác sĩ',
                    ),
                    ),
                );
                return;
                }

                if (
                    departmentController.text.trim().isEmpty
                ) {
                ScaffoldMessenger.of(
                    context,
                ).showSnackBar(
                    const SnackBar(
                    content: Text(
                        'Vui lòng nhập khoa',
                    ),
                    ),
                );
                return;
                }

                final appointmentDate =
                        selectedDate != null
                            ? selectedDate!
                                .toString()
                                .substring(0, 10)
                            : item['requestedDate']
                                .toString()
                                .substring(0, 10);

                    await adminservice.proposeAppointment(
                    id: item['id'],
                    appointmentDate: appointmentDate,
                    doctorName: doctorController.text,
                    department: departmentController.text,
                    );

                    if (!mounted) return;

                    // Đóng dialog
                    Navigator.pop(context);

                    // Reload dữ liệu detail
                    await loadDetail();
              },
              child: const Text(
                'Đề xuất',
              ),
            ),
          ],
        );
      },
    );
  }

Future<void> loadDetail() async {


final data =
    await service
        .getAppointmentDetail(
  widget.appointmentId,
);

if (!mounted) return;

setState(() {
  appointment = data;
  loading = false;
});


}

Widget infoRow(
IconData icon,
String title,
String value,
) {
return Padding(
padding:
const EdgeInsets.only(
bottom: 16,
),
child: Row(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [


      Icon(
        icon,
        color: AppColors.secondary,
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
              title,
              style:
                  const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              value,
              style:
                  const TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
);


}

@override
Widget build(
BuildContext context,
) {


if (loading) {
  return const Scaffold(
    body: Center(
      child:
          CircularProgressIndicator(),
    ),
  );
}

final item = appointment!;

return MediHubPage(
  title: 'Chi tiết lịch khám',

  child: SingleChildScrollView(
    padding:
        const EdgeInsets.all(
      16,
    ),
    child: Column(
      children: [

        MediHubCard(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [

  Container(
    padding:
        const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 8,
    ),
    decoration:
        BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius:
          BorderRadius.circular(
        30,
      ),
    ),
    child: const Text(
      'LỊCH KHÁM',
      style: TextStyle(
        color:
            AppColors.success,
        fontWeight:
            FontWeight.bold,
      ),
    ),
  ),

  const SizedBox(
    height: 20,
  ),

  Text(
    item['doctorName'] ?? '',
    style:
        const TextStyle(
      fontSize: 24,
      fontWeight:
          FontWeight.bold,
    ),
  ),

  const SizedBox(
    height: 6,
  ),

  Text(
    item['department'] ?? '',
    style:
        const TextStyle(
      fontSize: 16,
      color: AppColors.textSecondary,
    ),
  ),

  const SizedBox(
    height: 24,
  ),

  Container(
    width: double.infinity,
    padding:
        const EdgeInsets.all(
      16,
    ),
    decoration:
        BoxDecoration(
     color:
            AppColors.primaryLight,
      borderRadius:
          BorderRadius.circular(
        20,
      ),
    ),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        const Text(
          'Ngày khám',
          style: TextStyle(
            color:
                AppColors.textSecondary,
          ),
        ),

        const SizedBox(
          height: 6,
        ),

        Text(
          formatDate(
            item['appointmentDate']
                ?.toString(),
            ),
          style:
              const TextStyle(
            fontSize: 22,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    ),
  ),

  const SizedBox(
    height: 18,
  ),

  Row(
    children: [

      Expanded(
        child: Container(
          padding:
              const EdgeInsets.all(
            14,
          ),
          decoration:
              BoxDecoration(
            color:
                AppColors.card,
            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),
          child: Column(
            children: [

              const Text(
                'Ngày mong muốn',
                style:
                    TextStyle(
                  color:
                      AppColors.textSecondary,
                  fontSize:
                      12,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              Text(
                formatDate(
                    item['requestedDate']
                        ?.toString(),
                    ),
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),

      const SizedBox(
        width: 12,
      ),

      Expanded(
        child: Container(
          padding:
              const EdgeInsets.all(
            14,
          ),
          decoration:
              BoxDecoration(
            color:
                AppColors.card,
            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),
          child: Column(
            children: [
                const Text(
                'Trạng thái',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                ),
                ),

                const SizedBox(
                height: 6,
                ),

                Text(
                getStatusText(
                    item['status'],
                ),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                ),
                ),
            ],
            ),
        ),
      ),
    ],
  ),
],

),
),


//const SizedBox(
  //height: 10,
//),

if (item['status'] == 'REQUESTED')
SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor:
          AppColors.primary,
      foregroundColor:
          AppColors.white,
      padding:
          const EdgeInsets.symmetric(
        vertical: 16,
      ),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
    ),
    onPressed: () {
      showProposeDialog(item);
    },
    icon: const Icon(
      Icons.schedule,
    ),
    label: const Text(
      'Đề xuất lịch khám',
    ),
  ),
),

if (item['status'] == 'CONFIRMED')
SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor:
          AppColors.success,
      foregroundColor:
          Colors.white,
      padding:
          const EdgeInsets.symmetric(
        vertical: 16,
      ),
    ),
    onPressed: () async {

      final result =
          await context.push(
        '/doctor-complete/${item['id']}',
      );

      if (result == true) {
        await loadDetail();
      }
    },
    icon: const Icon(
      Icons.medical_services,
    ),


    label: const Text(
      'Bắt đầu khám',
    ),
  ),
),

const SizedBox(
  height: 20,
),

        MediHubCard(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [

              const Text(
                'Ghi chú',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                item['note'] ?? '',
              ),
            ],
          ),
        ),

        
        if (
            item['medicalRecord'] != null
            )
            MediHubCard(
            child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [

                const Text(
                'Kết quả khám',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                ),
                ),

                const SizedBox(
                height: 24,
                ),

                Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(
                    16,
                ),
                decoration:
                    BoxDecoration(
                    color:
                        AppColors.primaryLight,
                    borderRadius:
                        BorderRadius.circular(
                    18,
                    ),
                ),
                child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                    const Text(
                        '🩺 Chẩn đoán',
                        style: TextStyle(
                        color:
                            AppColors.textSecondary,
                        ),
                    ),

                    const SizedBox(
                        height: 8,
                    ),

                    Text(
                        item['medicalRecord']
                                ['diagnosis'] ??
                            '',
                        style:
                            const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                        ),
                    ),
                    ],
                ),
                ),

                const SizedBox(
                height: 14,
                ),

                Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(
                    16,
                ),
                decoration:
                    BoxDecoration(
                    color:
                        AppColors.primaryLight,
                    borderRadius:
                        BorderRadius.circular(
                    18,
                    ),
                ),
                child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                    const Text(
                        '📋 Kết luận',
                        style: TextStyle(
                        color:
                            AppColors.textSecondary,
                        ),
                    ),

                    const SizedBox(
                        height: 8,
                    ),

                    Text(
                        item['medicalRecord']
                                ['conclusion'] ??
                            '',
                        style:
                            const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                        ),
                    ),
                    ],
                ),
                ),

                const SizedBox(
                height: 14,
                ),

                Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(
                    16,
                ),
                decoration:
                    BoxDecoration(
                    color:
                        AppColors.primaryLight,
                    borderRadius:
                        BorderRadius.circular(
                    18,
                    ),
                ),
                child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                    const Text(
                        '💊 Hướng điều trị',
                        style: TextStyle(
                        color:
                            AppColors.textSecondary,
                        ),
                    ),

                    const SizedBox(
                        height: 8,
                    ),

                    Text(
                        item['medicalRecord']
                                ['note'] ??
                            '',
                        style:
                            const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w500,
                        ),
                    ),
                    ],
                ),
                ),
            ],
            
            
            ),
          ),
      ],
    ),
  ),
);


}
}
