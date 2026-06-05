import 'package:flutter/material.dart';

import '../data/appointment_service.dart';

class CreateAppointmentPage extends StatefulWidget {
  const CreateAppointmentPage({
    super.key,
  });

  @override
  State<CreateAppointmentPage> createState() =>
      _CreateAppointmentPageState();
}

class _CreateAppointmentPageState
    extends State<CreateAppointmentPage> {

  final service =
      AppointmentService();

  final noteController =
      TextEditingController();

  DateTime? requestedDate;

  bool loading = false;

  Future<void> submit() async {

    if (requestedDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng chọn ngày khám',
          ),
        ),
      );
      return;
    }

    try {

      setState(() {
        loading = true;
      });

      await service.createAppointment(
        requestedDate:
            requestedDate!,
        note:
            noteController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context);

    } catch (e) {

      debugPrint(
        'CREATE APPOINTMENT ERROR = $e',
      );

    } finally {

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Đăng ký khám',
        ),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [

            ListTile(
              title: Text(
                requestedDate == null
                    ? 'Chọn ngày khám'
                    : '${requestedDate!.day}/${requestedDate!.month}/${requestedDate!.year}',
              ),
              trailing: const Icon(
                Icons.calendar_month,
              ),
              onTap: () async {

                final date =
                    await showDatePicker(
                  context: context,
                  firstDate:
                      DateTime.now(),
                  lastDate:
                      DateTime.now()
                          .add(
                    const Duration(
                      days: 365,
                    ),
                  ),
                  initialDate:
                      DateTime.now(),
                );

                if (date != null) {
                  setState(() {
                    requestedDate =
                        date;
                  });
                }
              },
            ),

            const SizedBox(
              height: 16,
            ),

            TextField(
              controller:
                  noteController,
              maxLines: 4,
              decoration:
                  const InputDecoration(
                labelText:
                    'Ghi chú',
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            SizedBox(
              width:
                  double.infinity,
              height: 50,
              child:
                  ElevatedButton(
                onPressed:
                    loading
                        ? null
                        : submit,
                child:
                    loading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'Gửi yêu cầu khám',
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}