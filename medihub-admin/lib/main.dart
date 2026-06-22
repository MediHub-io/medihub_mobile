import 'package:flutter/material.dart';

import 'core/admin_api_service.dart';
import 'core/admin_models.dart';
import 'core/admin_shell.dart';
import 'pages/dashboard_page.dart';
import 'pages/billing_workspace.dart';
import 'pages/doctor_workspace.dart';
import 'pages/imaging_workspace.dart';
import 'pages/admission_workspace.dart';
import 'pages/insurance_workspace.dart';
import 'pages/lab_workspace.dart';
import 'pages/login_page.dart';
import 'pages/medical_timeline_workspace.dart';
import 'pages/module_page.dart';
import 'pages/pharmacy_workspace.dart';
import 'pages/reception_workspace.dart';
import 'pages/surgery_workspace.dart';
import 'pages/visit_workspace.dart';

void main() {
  runApp(const MediHubAdminApp());
}

class MediHubAdminApp extends StatefulWidget {
  const MediHubAdminApp({super.key});

  @override
  State<MediHubAdminApp> createState() => _MediHubAdminAppState();
}

class _MediHubAdminAppState extends State<MediHubAdminApp> {
  final service = AdminApiService();
  AdminRoute route = AdminRoute.dashboard;

  @override
  void initState() {
    super.initState();
    service.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediHub Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007A3D)),
        useMaterial3: true,
        fontFamily: 'Arial',
        visualDensity: VisualDensity.compact,
        dataTableTheme: const DataTableThemeData(
          headingRowColor: WidgetStatePropertyAll(Color(0xFF005AA8)),
          headingTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
          dataTextStyle: TextStyle(fontSize: 12.5),
          headingRowHeight: 36,
          dataRowMinHeight: 32,
          horizontalMargin: 8,
          columnSpacing: 14,
        ),
      ),
      home: service.authenticated
          ? AdminShell(
              service: service,
              route: route,
              onRouteChanged: (next) => setState(() {
                route = next;
              }),
              child: content(),
            )
          : LoginPage(service: service),
    );
  }

  Widget content() {
    if (route == AdminRoute.dashboard) {
      return DashboardPage(
        service: service,
        onOpenModule: (next) => setState(() {
          route = next;
        }),
      );
    }

    if (route == AdminRoute.reception ||
        route == AdminRoute.queue ||
        route == AdminRoute.queueTickets) {
      return ReceptionWorkspace(service: service);
    }

    if (route == AdminRoute.visits) {
      return VisitWorkspace(service: service);
    }

    if (route == AdminRoute.outpatient ||
        route == AdminRoute.encounters ||
        route == AdminRoute.serviceOrders ||
        (route == AdminRoute.prescriptions && service.adminRole == 'DOCTOR')) {
      return DoctorWorkspace(
        service: service,
        onRouteChanged: (next) => setState(() {
          route = next;
        }),
      );
    }

    if (route == AdminRoute.labResults) {
      return LabWorkspace(service: service);
    }

    if (route == AdminRoute.imagingResults) {
      return ImagingWorkspace(service: service);
    }

    if (route == AdminRoute.inpatient || route == AdminRoute.admissions) {
      return AdmissionWorkspace(service: service);
    }

    if (route == AdminRoute.billingInvoices || route == AdminRoute.payments) {
      return BillingWorkspace(service: service);
    }

    if (route == AdminRoute.prescriptions) {
      return PharmacyWorkspace(service: service);
    }

    if (route == AdminRoute.surgeries) {
      return SurgeryWorkspace(service: service);
    }

    if (route == AdminRoute.insuranceClaims) {
      return InsuranceWorkspace(service: service);
    }

    if (route == AdminRoute.medicalTimeline) {
      return MedicalTimelineWorkspace(service: service);
    }

    final module = adminModules.firstWhere((item) => item.route == route);
    return ModulePage(
      service: service,
      module: module,
      onRouteChanged: (next) => setState(() {
        route = next;
      }),
    );
  }
}
