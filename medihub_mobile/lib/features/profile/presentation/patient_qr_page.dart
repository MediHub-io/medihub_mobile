import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PatientQrPage extends StatelessWidget {
  final String patientId;
  final String patientCode;
  final String fullName;

  const PatientQrPage({
    super.key,
    required this.patientId,
    required this.patientCode,
    required this.fullName,
  });

  @override
  Widget build(BuildContext context) {

    final qrData = jsonEncode({
      'patientId': patientId,
      'patientCode': patientCode,
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'QR bệnh nhân',
        ),
      ),

      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            QrImageView(
              data: qrData,
              size: 260,
            ),

            const SizedBox(
              height: 24,
            ),

            Text(
              patientCode,
              style:
                  const TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              fullName,
            ),
          ],
        ),
      ),
    );
  }
}