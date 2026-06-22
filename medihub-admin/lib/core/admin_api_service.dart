import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'admin_config.dart';
import 'admin_models.dart';
import 'his_workflow_models.dart';
import 'surgery_models.dart';

class AdminApiService extends ChangeNotifier {
  bool authenticated = false;
  bool loading = false;
  String adminPhone = '';
  String adminRole = '';
  String organizationName = '';
  String organizationCode = '';
  String? errorMessage;

  String? _token;
  final Map<AdminRoute, List<AdminRecord>> _cache = {};
  Map<String, dynamic> _dashboard = {};

  Future<bool> login(String phone, String password) async {
    final normalizedPhone = phone.trim();
    loading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        _uri('/auth/login'),
        headers: _headers(),
        body: jsonEncode({'phone': normalizedPhone, 'password': password}),
      );
      final decoded = _decode(response);
      if (response.statusCode >= 400 || decoded['success'] != true) {
        errorMessage = decoded['message']?.toString() ?? 'Đăng nhập thất bại';
        return false;
      }

      final data = decoded['data'] as Map<String, dynamic>;
      final role = data['role']?.toString() ?? '';
      const allowedRoles = {
        'SUPER_ADMIN',
        'ADMIN',
        'RECEPTIONIST',
        'DOCTOR',
        'NURSE',
        'LAB_TECHNICIAN',
        'RAD_TECHNICIAN',
        'PHARMACIST',
        'CASHIER',
        'ACCOUNTANT',
        'INSURANCE_STAFF',
      };
      if (!allowedRoles.contains(role)) {
        errorMessage = 'Tài khoản này không có quyền truy cập Admin';
        return false;
      }

      _token = data['token']?.toString();
      authenticated = _token != null && _token!.isNotEmpty;
      adminPhone = normalizedPhone;
      adminRole = role;
      organizationName = data['organizationName']?.toString() ?? '';
      organizationCode = data['organizationCode']?.toString() ?? '';
      if (authenticated) await refreshDashboard();
      return authenticated;
    } catch (error) {
      errorMessage = error.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void logout() {
    authenticated = false;
    adminPhone = '';
    adminRole = '';
    organizationName = '';
    organizationCode = '';
    _token = null;
    _cache.clear();
    _dashboard = {};
    notifyListeners();
  }

  List<AdminRecord> records(AdminRoute route) => [...?_cache[route]];

  Future<List<AdminRecord>> lookup(AdminRoute route) async {
    if (!_cache.containsKey(route)) {
      await loadRecords(route);
    }
    return records(route);
  }

  Future<List<AdminRecord>> doctorsForDepartment(String departmentName) async {
    final doctors = await lookup(AdminRoute.doctors);
    if (departmentName.trim().isEmpty) return doctors;
    return doctors
        .where((doctor) => doctor.data['department'] == departmentName)
        .toList();
  }

  List<DashboardStat> stats() {
    const primary = Color(0xFF007A3D);
    return [
      DashboardStat(
        title: 'Tổng bệnh nhân',
        value: _intValue('patients'),
        icon: Icons.people_alt_outlined,
        color: primary,
      ),
      DashboardStat(
        title: 'Tổng tài khoản',
        value: _intValue('accounts'),
        icon: Icons.manage_accounts_outlined,
        color: const Color(0xFF0F766E),
      ),
      DashboardStat(
        title: 'Tổng lịch hẹn',
        value: _intValue('appointments'),
        icon: Icons.calendar_month_outlined,
        color: const Color(0xFF2563EB),
      ),
      DashboardStat(
        title: 'Lượt khám',
        value: _intValue('visits'),
        icon: Icons.assignment_ind_outlined,
        color: const Color(0xFF007A3D),
      ),
      DashboardStat(
        title: 'Phiếu chỉ định',
        value: _intValue('serviceOrders'),
        icon: Icons.medical_services_outlined,
        color: const Color(0xFF0F766E),
      ),
      DashboardStat(
        title: 'Nội trú',
        value: _intValue('admissions'),
        icon: Icons.bed_outlined,
        color: const Color(0xFF0EA5E9),
      ),
      DashboardStat(
        title: 'Tổng tin tức',
        value: _intValue('news'),
        icon: Icons.article_outlined,
        color: const Color(0xFF7C3AED),
      ),
      DashboardStat(
        title: 'Tổng thông báo',
        value: _intValue('notifications'),
        icon: Icons.notifications_outlined,
        color: const Color(0xFFF59E0B),
      ),
      DashboardStat(
        title: 'Tổng đơn thuốc',
        value: _intValue('prescriptions'),
        icon: Icons.medication_outlined,
        color: const Color(0xFF0F766E),
      ),
      DashboardStat(
        title: 'Tổng xét nghiệm',
        value: _intValue('labResults'),
        icon: Icons.science_outlined,
        color: const Color(0xFFDC2626),
      ),
      DashboardStat(
        title: 'Tổng CĐHA',
        value: _intValue('imagingResults'),
        icon: Icons.image_search_outlined,
        color: const Color(0xFF0891B2),
      ),
      DashboardStat(
        title: 'Tổng phẫu thuật/thủ thuật',
        value: _intValue('surgeries'),
        icon: Icons.local_hospital_outlined,
        color: const Color(0xFFEA580C),
      ),
      DashboardStat(
        title: 'Tổng viện phí',
        value: _intValue('billing'),
        icon: Icons.payments_outlined,
        color: const Color(0xFF0891B2),
      ),
      DashboardStat(
        title: 'Tổng danh mục',
        value: _intValue('catalogs'),
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF475569),
      ),
      DashboardStat(
        title: 'Yêu cầu gọi lại',
        value: _intValue('callbackRequests'),
        icon: Icons.phone_callback_outlined,
        color: const Color(0xFF16A34A),
      ),
      DashboardStat(
        title: 'Giường bệnh',
        value: _intValue('beds'),
        icon: Icons.hotel_outlined,
        color: const Color(0xFF64748B),
      ),
      DashboardStat(
        title: 'Hồ sơ BHYT',
        value: _intValue('insuranceClaims'),
        icon: Icons.health_and_safety_outlined,
        color: const Color(0xFF0891B2),
      ),
    ];
  }

  Map<String, dynamic> operations() {
    final value = _dashboard['operations'];
    return value is Map<String, dynamic> ? value : <String, dynamic>{};
  }

  Map<String, dynamic> hisDashboard() {
    final value = _dashboard['his'];
    return value is Map<String, dynamic>
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
  }

  int _intValue(String key) => int.tryParse('${_dashboard[key] ?? 0}') ?? 0;

  Future<void> refreshDashboard() async {
    final decoded = await _get('/admin/dashboard');
    final data = decoded['data'] as Map<String, dynamic>;
    _dashboard = Map<String, dynamic>.from(data);
    notifyListeners();
  }

  Future<void> loadRecords(AdminRoute route, {String? search}) async {
    if ({AdminRoute.surgeries, AdminRoute.insuranceClaims}.contains(route)) {
      throw StateError('$route chỉ được tải bằng workspace nghiệp vụ riêng');
    }
    loading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final parameters = <String, String>{
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (route == AdminRoute.outpatient) 'visitType': 'OUTPATIENT',
      };
      final query = parameters.isEmpty
          ? ''
          : '?${Uri(queryParameters: parameters).query}';
      final decoded = await _get('/admin/${_resource(route)}$query');
      final rows = decoded['data'] as List<dynamic>;
      _cache[route] = rows.map((item) {
        final map = item as Map<String, dynamic>;
        return AdminRecord(
          id: map['id'].toString(),
          data: Map<String, dynamic>.from(map)..remove('id'),
        );
      }).toList();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> create(AdminRoute route, Map<String, dynamic> data) async {
    if ({AdminRoute.surgeries, AdminRoute.insuranceClaims}.contains(route)) {
      throw StateError('Không được tạo nghiệp vụ này bằng CRUD generic');
    }
    if ({
      AdminRoute.reception,
      AdminRoute.visits,
      AdminRoute.outpatient,
    }.contains(route)) {
      await createVisit(data);
      return;
    }
    await _send('POST', '/admin/${_resource(route)}', data);
    await loadRecords(route);
    await refreshDashboard();
  }

  Future<void> update(
    AdminRoute route,
    String id,
    Map<String, dynamic> data,
  ) async {
    if ({AdminRoute.surgeries, AdminRoute.insuranceClaims}.contains(route)) {
      throw StateError('Không được cập nhật nghiệp vụ này bằng CRUD generic');
    }
    if ({
      AdminRoute.reception,
      AdminRoute.visits,
      AdminRoute.outpatient,
    }.contains(route)) {
      await _send('PUT', '/admin/visits/$id', data);
      await _reloadVisitRoutes();
      return;
    }
    await _send('PUT', '/admin/${_resource(route)}/$id', data);
    await loadRecords(route);
    await refreshDashboard();
  }

  Future<void> delete(AdminRoute route, String id) async {
    if ({AdminRoute.surgeries, AdminRoute.insuranceClaims}.contains(route)) {
      throw StateError('Không được xóa nghiệp vụ này bằng CRUD generic');
    }
    if ({
      AdminRoute.reception,
      AdminRoute.visits,
      AdminRoute.outpatient,
    }.contains(route)) {
      await cancelVisit(id);
      return;
    }
    await _send('DELETE', '/admin/${_resource(route)}/$id');
    await loadRecords(route);
    await refreshDashboard();
  }

  Future<void> lock(AdminRoute route, String id) async {
    if ({AdminRoute.surgeries, AdminRoute.insuranceClaims}.contains(route)) {
      throw StateError('Không được khóa nghiệp vụ này bằng CRUD generic');
    }
    await _send('PATCH', '/admin/${_resource(route)}/$id/lock');
    await loadRecords(route);
    await refreshDashboard();
  }

  Future<void> proposeAppointment({
    required String id,
    required String departmentId,
    required String doctorId,
    required String appointmentDate,
    String? proposalNote,
  }) async {
    await _send('PATCH', '/admin/appointments/$id/propose', {
      'departmentId': departmentId,
      'doctorId': doctorId,
      'appointmentDate': appointmentDate,
      if (proposalNote != null && proposalNote.trim().isNotEmpty)
        'proposalNote': proposalNote.trim(),
    });
    await loadRecords(AdminRoute.appointments);
    await refreshDashboard();
  }

  Future<void> cancelAppointment(String id) async {
    await _send('PATCH', '/admin/appointments/$id/cancel');
    await loadRecords(AdminRoute.appointments);
    await refreshDashboard();
  }

  Future<void> loadVisits({String? search}) =>
      loadRecords(AdminRoute.visits, search: search);

  Future<List<Map<String, dynamic>>> loadOutpatientVisits({
    String? status,
    String? date,
    String? departmentId,
    String? roomId,
    String? doctorId,
  }) async {
    final parameters = <String, String>{
      'visitType': 'OUTPATIENT',
      if (status != null && status.isNotEmpty && status != 'ALL')
        'status': status,
      if (date != null && date.isNotEmpty) 'date': date,
      if (departmentId != null && departmentId.isNotEmpty)
        'departmentId': departmentId,
      if (roomId != null && roomId.isNotEmpty) 'roomId': roomId,
      if (doctorId != null && doctorId.isNotEmpty) 'doctorId': doctorId,
    };
    final decoded = await _get(
      '/admin/visits?${Uri(queryParameters: parameters).query}',
    );
    return (decoded['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<VisitDto>> loadVisitWorkspace({
    String? search,
    String? status,
    String? visitType,
  }) async {
    final parameters = <String, String>{
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (status != null && status.isNotEmpty && status != 'ALL')
        'status': status,
      if (visitType != null && visitType.isNotEmpty && visitType != 'ALL')
        'visitType': visitType,
    };
    final query = parameters.isEmpty
        ? ''
        : '?${Uri(queryParameters: parameters).query}';
    final decoded = await _get('/admin/visits$query');
    return (decoded['data'] as List)
        .map(
          (item) => VisitDto.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<ReceptionDto>> loadReceptionWorkflow() async {
    final rows = await loadReceptionVisits();
    return rows.map(ReceptionDto.fromJson).toList();
  }

  Future<List<DoctorEncounterDto>> loadDoctorWorkflow({String? visitId}) async {
    final decoded = visitId == null
        ? await _get('/admin/encounters')
        : await _get('/admin/visits/$visitId/encounters');
    return (decoded['data'] as List)
        .map(
          (item) => DoctorEncounterDto.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<LabWorkflowDto>> loadTypedLabWorkflow({String? status}) async {
    final rows = await loadLabOrders(status: status);
    return rows.map(LabWorkflowDto.fromJson).toList();
  }

  Future<List<ImagingWorkflowDto>> loadTypedImagingWorkflow({
    String? status,
  }) async {
    final rows = await loadImagingOrders(status: status);
    return rows.map(ImagingWorkflowDto.fromJson).toList();
  }

  Future<List<PrescriptionWorkflowDto>> loadTypedPharmacyWorkflow({
    String? status,
  }) async {
    final rows = await loadPharmacyPrescriptions(status: status);
    return rows.map(PrescriptionWorkflowDto.fromJson).toList();
  }

  Future<List<BillingInvoiceDto>> loadTypedBillingWorkflow({
    String? status,
  }) async {
    final rows = await loadBillingInvoices(status: status);
    return rows.map(BillingInvoiceDto.fromJson).toList();
  }

  Future<List<AdmissionWorkflowDto>> loadTypedAdmissionWorkflow({
    String? status,
  }) async {
    final rows = await loadAdmissions(status: status);
    return rows.map(AdmissionWorkflowDto.fromJson).toList();
  }

  Future<List<Map<String, dynamic>>> searchPatients(String keyword) async {
    final query = Uri(queryParameters: {'keyword': keyword.trim()}).query;
    final decoded = await _get('/admin/reception/patients?$query');
    return (decoded['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createPatientQuick(
    Map<String, dynamic> data,
  ) async {
    final decoded = await _post('/admin/reception/patients', data);
    await loadRecords(AdminRoute.patients);
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<List<Map<String, dynamic>>> loadReceptionVisits() async {
    final decoded = await _get('/admin/reception/visits/today');
    final rows = (decoded['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    _cache[AdminRoute.reception] = rows
        .map(
          (item) => AdminRecord(
            id: item['id'].toString(),
            data: Map<String, dynamic>.from(item)..remove('id'),
          ),
        )
        .toList();
    notifyListeners();
    return rows;
  }

  Future<List<Map<String, dynamic>>> loadTodayAppointments() async {
    final decoded = await _get('/admin/reception/appointments/today');
    return (decoded['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> loadQueueTickets() async {
    final decoded = await _get('/admin/reception/queue-tickets/today');
    final rows = (decoded['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    _cache[AdminRoute.queueTickets] = rows
        .map(
          (item) => AdminRecord(
            id: item['id'].toString(),
            data: Map<String, dynamic>.from(item)..remove('id'),
          ),
        )
        .toList();
    notifyListeners();
    return rows;
  }

  Future<Map<String, dynamic>> createVisit(Map<String, dynamic> data) async {
    final decoded = await _post('/admin/visits', data);
    await loadReceptionVisits();
    await loadQueueTickets();
    await loadRecords(AdminRoute.visits);
    await refreshDashboard();
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> convertAppointmentToVisit(
    String appointmentId, {
    Map<String, dynamic> data = const {},
  }) async {
    final decoded = await _post(
      '/admin/appointments/$appointmentId/convert-to-visit',
      data,
    );
    await loadTodayAppointments();
    await loadReceptionVisits();
    await loadQueueTickets();
    await loadRecords(AdminRoute.appointments);
    await loadRecords(AdminRoute.visits);
    await refreshDashboard();
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> loadVisitDetail(String id) async {
    final decoded = await _get('/admin/visits/$id');
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<void> checkInVisit(String id) async {
    await _send('PATCH', '/admin/visits/$id/check-in');
    await _reloadVisitRoutes();
  }

  Future<Map<String, dynamic>> startVisitExam(String id) async {
    final decoded = await _request('PATCH', '/admin/visits/$id/start-exam');
    await _reloadVisitRoutes();
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> completeVisit(String id) async {
    final decoded = await _request('PATCH', '/admin/visits/$id/complete');
    await _reloadVisitRoutes();
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<void> cancelVisit(String id) async {
    await _send('PATCH', '/admin/visits/$id/cancel');
    await _reloadVisitRoutes();
  }

  Future<List<Map<String, dynamic>>> loadVisitEncounters(String visitId) async {
    final decoded = await _get('/admin/visits/$visitId/encounters');
    return (decoded['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createEncounter(
    String visitId,
    Map<String, dynamic> data,
  ) async {
    final decoded = await _post('/admin/visits/$visitId/encounters', data);
    await loadRecords(AdminRoute.encounters);
    await _reloadVisitRoutes();
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> saveEncounter(
    String encounterId,
    Map<String, dynamic> data,
  ) async {
    final decoded = await _request(
      'PUT',
      '/admin/encounters/$encounterId',
      data,
    );
    await loadRecords(AdminRoute.encounters);
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> updateEncounter(
    String encounterId,
    Map<String, dynamic> data,
  ) => saveEncounter(encounterId, data);

  Future<Map<String, dynamic>> completeEncounter(
    String encounterId, {
    Map<String, dynamic> data = const {},
  }) async {
    final decoded = await _request(
      'PATCH',
      '/admin/encounters/$encounterId/complete',
      data,
    );
    await loadRecords(AdminRoute.encounters);
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<List<Map<String, dynamic>>> loadVisitOrders(String visitId) async {
    final decoded = await _get('/admin/visits/$visitId/service-orders');
    return (decoded['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> loadLabServices() =>
      _loadCatalog('/admin/catalog/lab-services');

  Future<List<Map<String, dynamic>>> loadImagingServices() =>
      _loadCatalog('/admin/catalog/imaging-services');

  Future<List<Map<String, dynamic>>> loadMedicines() =>
      _loadCatalog('/admin/catalog/medicines');

  Future<List<Map<String, dynamic>>> loadTechnicalServices() =>
      _loadCatalog('/admin/catalog/technical-services');

  Future<List<Map<String, dynamic>>> loadSupplies() =>
      _loadCatalog('/admin/catalog/supplies');

  Future<List<Map<String, dynamic>>> _loadCatalog(String path) async {
    final decoded = await _get(path);
    return (decoded['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createServiceOrder(
    String visitId,
    Map<String, dynamic> data,
  ) async {
    final decoded = await _post('/admin/visits/$visitId/service-orders', data);
    await loadRecords(AdminRoute.serviceOrders);
    await _reloadVisitRoutes();
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> submitServiceOrder(String orderId) async {
    final decoded = await _request(
      'PATCH',
      '/admin/service-orders/$orderId/submit',
    );
    await loadRecords(AdminRoute.serviceOrders);
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> cancelServiceOrder(String orderId) async {
    final decoded = await _request(
      'PATCH',
      '/admin/service-orders/$orderId/cancel',
    );
    await loadRecords(AdminRoute.serviceOrders);
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<List<Map<String, dynamic>>> loadLabOrders({
    String? date,
    String? departmentId,
    String? status,
    String? search,
  }) => _loadDiagnosticList('/admin/lab-orders', {
    if (date != null) 'date': date,
    if (departmentId != null) 'departmentId': departmentId,
    if (status != null) 'status': status,
    if (search != null) 'search': search,
  });

  Future<List<Map<String, dynamic>>> loadLabResults({String? visitId}) =>
      _loadDiagnosticList('/admin/lab-results', {
        if (visitId != null) 'visitId': visitId,
      });

  Future<Map<String, dynamic>> ensureLabResult(String orderItemId) =>
      _diagnosticPost('/admin/lab-results/from-order-item/$orderItemId');

  Future<Map<String, dynamic>> takeLabSample(
    String id, {
    String? performedBy,
  }) => _diagnosticPatch('/admin/lab-results/$id/take-sample', {
    if (performedBy != null) 'performedBy': performedBy,
  });

  Future<Map<String, dynamic>> runLabResult(String id, {String? performedBy}) =>
      _diagnosticPatch('/admin/lab-results/$id/run', {
        if (performedBy != null) 'performedBy': performedBy,
      });

  Future<Map<String, dynamic>> saveLabResult(
    String id,
    Map<String, dynamic> data,
  ) => _diagnosticPut('/admin/lab-results/$id', data);

  Future<Map<String, dynamic>> approveLabResult(
    String id, {
    String? approvedBy,
  }) => _diagnosticPatch('/admin/lab-results/$id/approve', {
    if (approvedBy != null) 'approvedBy': approvedBy,
  });

  Future<List<Map<String, dynamic>>> loadImagingOrders({
    String? date,
    String? departmentId,
    String? status,
    String? search,
  }) => _loadDiagnosticList('/admin/imaging-orders', {
    if (date != null) 'date': date,
    if (departmentId != null) 'departmentId': departmentId,
    if (status != null) 'status': status,
    if (search != null) 'search': search,
  });

  Future<List<Map<String, dynamic>>> loadImagingResults({String? visitId}) =>
      _loadDiagnosticList('/admin/imaging-results', {
        if (visitId != null) 'visitId': visitId,
      });

  Future<Map<String, dynamic>> ensureImagingResult(String orderItemId) =>
      _diagnosticPost('/admin/imaging-results/from-order-item/$orderItemId');

  Future<Map<String, dynamic>> performImaging(
    String id, {
    String? performedBy,
  }) => _diagnosticPatch('/admin/imaging-results/$id/perform', {
    if (performedBy != null) 'performedBy': performedBy,
  });

  Future<Map<String, dynamic>> readImaging(String id, {String? readerName}) =>
      _diagnosticPatch('/admin/imaging-results/$id/read', {
        if (readerName != null) 'readerName': readerName,
      });

  Future<Map<String, dynamic>> saveImagingResult(
    String id,
    Map<String, dynamic> data,
  ) => _diagnosticPut('/admin/imaging-results/$id', data);

  Future<Map<String, dynamic>> approveImagingResult(
    String id, {
    String? approverName,
  }) => _diagnosticPatch('/admin/imaging-results/$id/approve', {
    if (approverName != null) 'approverName': approverName,
  });

  Future<List<Map<String, dynamic>>> loadVisitPrescriptions(
    String visitId,
  ) async {
    final decoded = await _get('/admin/visits/$visitId/prescriptions');
    return (decoded['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> loadPharmacyPrescriptions({
    String? status,
  }) async {
    final query = status == null || status == 'ALL'
        ? ''
        : '?${Uri(queryParameters: {'status': status}).query}';
    final decoded = await _get('/admin/pharmacy/prescriptions$query');
    return (decoded['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createPrescription(
    String visitId,
    Map<String, dynamic> data,
  ) async {
    final decoded = await _post('/admin/visits/$visitId/prescriptions', data);
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> updatePrescription(
    String id,
    Map<String, dynamic> data,
  ) async {
    final decoded = await _request('PUT', '/admin/prescriptions/$id', data);
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> prescribePrescription(String id) async {
    final decoded = await _request(
      'PATCH',
      '/admin/prescriptions/$id/prescribe',
    );
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> dispensePrescription(String id) async {
    final decoded = await _request(
      'PATCH',
      '/admin/prescriptions/$id/dispense',
    );
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> cancelPrescription(String id) async {
    final decoded = await _request('PATCH', '/admin/prescriptions/$id/cancel');
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<List<Map<String, dynamic>>> _loadDiagnosticList(
    String path,
    Map<String, String> parameters,
  ) async {
    final values = Map<String, String>.from(parameters)
      ..removeWhere((_, value) => value.trim().isEmpty || value == 'ALL');
    final query = values.isEmpty
        ? ''
        : '?${Uri(queryParameters: values).query}';
    final decoded = await _get('$path$query');
    return (decoded['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> _diagnosticPost(String path) async {
    final decoded = await _post(path, const {});
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> _diagnosticPatch(
    String path, [
    Map<String, dynamic>? data,
  ]) async {
    final decoded = await _request('PATCH', path, data);
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> _diagnosticPut(
    String path,
    Map<String, dynamic> data,
  ) async {
    final decoded = await _request('PUT', path, data);
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<List<Map<String, dynamic>>> loadAdmissions({
    String? search,
    String? departmentId,
    String? roomId,
    String? status,
  }) async {
    final parameters = <String, String>{
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (departmentId != null && departmentId.isNotEmpty)
        'departmentId': departmentId,
      if (roomId != null && roomId.isNotEmpty) 'roomId': roomId,
      if (status != null && status.isNotEmpty && status != 'ALL')
        'status': status,
    };
    final query = parameters.isEmpty
        ? ''
        : '?${Uri(queryParameters: parameters).query}';
    final decoded = await _get('/admin/admissions$query');
    return (decoded['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> loadAdmissionDetail(String id) async {
    final decoded = await _get('/admin/admissions/$id');
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> admitVisit(
    String visitId, [
    Map<String, dynamic> data = const {},
  ]) async {
    final decoded = await _post('/admin/visits/$visitId/admit', data);
    await _reloadVisitRoutes();
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> assignBed(
    String admissionId,
    String bedId,
  ) async {
    final decoded = await _request(
      'PATCH',
      '/admin/admissions/$admissionId/assign-bed',
      {'bedId': bedId},
    );
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> transferBed(
    String admissionId,
    String bedId,
  ) async {
    final decoded = await _request(
      'PATCH',
      '/admin/admissions/$admissionId/transfer-bed',
      {'bedId': bedId},
    );
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> transferAdmissionDepartment(
    String admissionId,
    String departmentId,
  ) async {
    final decoded = await _request(
      'PATCH',
      '/admin/admissions/$admissionId/transfer-department',
      {'departmentId': departmentId},
    );
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> dischargeAdmission(String admissionId) async {
    final decoded = await _request(
      'PATCH',
      '/admin/admissions/$admissionId/discharge',
    );
    await _reloadVisitRoutes();
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<List<Map<String, dynamic>>> loadRooms() async {
    final records = await lookup(AdminRoute.rooms);
    return records.map((item) => {'id': item.id, ...item.data}).toList();
  }

  Future<List<Map<String, dynamic>>> loadBeds() async {
    final records = await lookup(AdminRoute.beds);
    return records.map((item) => {'id': item.id, ...item.data}).toList();
  }

  Future<Map<String, dynamic>> updateBedStatus(
    String bedId,
    String status,
  ) async {
    final decoded = await _request('PATCH', '/admin/beds/$bedId/status', {
      'status': status,
    });
    await loadRecords(AdminRoute.beds);
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<List<SurgeryCaseDto>> loadSurgeryCases({
    String? date,
    String? departmentId,
    String? status,
    String? keyword,
    String? patientId,
    String? visitId,
    String? admissionId,
  }) async {
    final parameters = <String, String>{
      if (date != null && date.isNotEmpty) 'date': date,
      if (departmentId != null && departmentId.isNotEmpty)
        'departmentId': departmentId,
      if (status != null && status.isNotEmpty && status != 'ALL')
        'status': status,
      if (keyword != null && keyword.trim().isNotEmpty)
        'keyword': keyword.trim(),
      if (patientId != null && patientId.isNotEmpty) 'patientId': patientId,
      if (visitId != null && visitId.isNotEmpty) 'visitId': visitId,
      if (admissionId != null && admissionId.isNotEmpty)
        'admissionId': admissionId,
    };
    final query = parameters.isEmpty
        ? ''
        : '?${Uri(queryParameters: parameters).query}';
    final decoded = await _get('/admin/surgeries$query');
    return (decoded['data'] as List)
        .map(
          (item) =>
              SurgeryCaseDto.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<SurgeryCaseDetailDto> loadSurgeryCaseDetail(String id) async {
    final decoded = await _get('/admin/surgeries/$id');
    return SurgeryCaseDetailDto.fromJson(
      Map<String, dynamic>.from(decoded['data'] as Map),
    );
  }

  Future<SurgeryCaseDetailDto> createSurgeryCase(
    Map<String, dynamic> data,
  ) async {
    final visitId = data['visitId']?.toString().trim() ?? '';
    final admissionId = data['admissionId']?.toString().trim() ?? '';
    if ((visitId.isEmpty && admissionId.isEmpty) ||
        (visitId.isNotEmpty && admissionId.isNotEmpty)) {
      throw ArgumentError(
        'Ca PTTT phải gắn đúng một lượt khám hoặc một hồ sơ nội trú',
      );
    }
    final decoded = await _post('/admin/surgeries', data);
    return SurgeryCaseDetailDto.fromJson(
      Map<String, dynamic>.from(decoded['data'] as Map),
    );
  }

  Future<SurgeryCaseDetailDto> saveSurgeryDraft(
    String id,
    Map<String, dynamic> data,
  ) async {
    final decoded = await _request('PATCH', '/admin/surgeries/$id/draft', data);
    return SurgeryCaseDetailDto.fromJson(
      Map<String, dynamic>.from(decoded['data'] as Map),
    );
  }

  Future<SurgeryCaseDetailDto> startSurgeryCase(String id) async {
    final decoded = await _request('PATCH', '/admin/surgeries/$id/start');
    return SurgeryCaseDetailDto.fromJson(
      Map<String, dynamic>.from(decoded['data'] as Map),
    );
  }

  Future<SurgeryCaseDetailDto> completeSurgeryCase(
    String id,
    Map<String, dynamic> data,
  ) async {
    final decoded = await _request(
      'PATCH',
      '/admin/surgeries/$id/complete',
      data,
    );
    return SurgeryCaseDetailDto.fromJson(
      Map<String, dynamic>.from(decoded['data'] as Map),
    );
  }

  Future<SurgeryCaseDetailDto> cancelSurgeryCase(
    String id,
    String reason,
  ) async {
    final decoded = await _request('PATCH', '/admin/surgeries/$id/cancel', {
      'reason': reason,
    });
    return SurgeryCaseDetailDto.fromJson(
      Map<String, dynamic>.from(decoded['data'] as Map),
    );
  }

  Future<List<SurgeryTeamMemberDto>> loadSurgeryTeam(String id) async {
    final decoded = await _get('/admin/surgeries/$id/team');
    return (decoded['data'] as List)
        .map(
          (item) => SurgeryTeamMemberDto.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<SurgeryTeamMemberDto>> saveSurgeryTeam(
    String id,
    List<SurgeryTeamMemberDto> members,
  ) async {
    final decoded = await _request('PUT', '/admin/surgeries/$id/team', {
      'members': members.map((item) => item.toJson()).toList(),
    });
    return (decoded['data'] as List)
        .map(
          (item) => SurgeryTeamMemberDto.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<SurgeryConsumableDto>> loadSurgeryConsumables(String id) async {
    final decoded = await _get('/admin/surgeries/$id/consumables');
    return (decoded['data'] as List)
        .map(
          (item) => SurgeryConsumableDto.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<SurgeryConsumableDto>> saveSurgeryConsumables(
    String id,
    List<SurgeryConsumableDto> items,
  ) async {
    final decoded = await _request('PUT', '/admin/surgeries/$id/consumables', {
      'items': items.map((item) => item.toJson()).toList(),
    });
    return (decoded['data'] as List)
        .map(
          (item) => SurgeryConsumableDto.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<SurgeryCaseDetailDto> printSurgeryReport(String caseId) =>
      loadSurgeryCaseDetail(caseId);

  Future<List<InsuranceClaimDto>> loadInsuranceClaims({
    String? search,
    String? status,
    String? patientId,
    String? visitId,
    String? admissionId,
  }) async {
    final parameters = <String, String>{
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (status != null && status.isNotEmpty && status != 'ALL')
        'status': status,
      if (patientId != null && patientId.isNotEmpty) 'patientId': patientId,
      if (visitId != null && visitId.isNotEmpty) 'visitId': visitId,
      if (admissionId != null && admissionId.isNotEmpty)
        'admissionId': admissionId,
    };
    final query = parameters.isEmpty
        ? ''
        : '?${Uri(queryParameters: parameters).query}';
    final decoded = await _get('/admin/insurance$query');
    return (decoded['data'] as List)
        .map(
          (item) => InsuranceClaimDto.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<InsuranceClaimDto> loadInsuranceClaimDetail(String id) async {
    final decoded = await _get('/admin/insurance/$id');
    return InsuranceClaimDto.fromJson(
      Map<String, dynamic>.from(decoded['data'] as Map),
    );
  }

  Future<InsuranceClaimDto> createInsuranceClaim(
    Map<String, dynamic> data,
  ) async {
    final decoded = await _post('/admin/insurance', data);
    return InsuranceClaimDto.fromJson(
      Map<String, dynamic>.from(decoded['data'] as Map),
    );
  }

  Future<InsuranceClaimDto> updateInsuranceClaim(
    String id,
    Map<String, dynamic> data,
  ) async {
    final decoded = await _request('PUT', '/admin/insurance/$id', data);
    return InsuranceClaimDto.fromJson(
      Map<String, dynamic>.from(decoded['data'] as Map),
    );
  }

  Future<InsuranceClaimDto> transitionInsuranceClaim(
    String id,
    String action, [
    Map<String, dynamic>? data,
  ]) async {
    final decoded = await _request(
      'PATCH',
      '/admin/insurance/$id/$action',
      data ?? const {},
    );
    return InsuranceClaimDto.fromJson(
      Map<String, dynamic>.from(decoded['data'] as Map),
    );
  }

  Future<List<MedicalTimelineEventDto>> loadMedicalTimeline({
    String? patientId,
    String? visitId,
    String? admissionId,
    String? module,
  }) async {
    final parameters = <String, String>{
      if (patientId != null && patientId.isNotEmpty) 'patientId': patientId,
      if (visitId != null && visitId.isNotEmpty) 'visitId': visitId,
      if (admissionId != null && admissionId.isNotEmpty)
        'admissionId': admissionId,
      if (module != null && module.isNotEmpty && module != 'ALL')
        'module': module,
    };
    final query = Uri(queryParameters: parameters).query;
    final decoded = await _get('/admin/medical-timeline?$query');
    return (decoded['data'] as List)
        .map(
          (item) => MedicalTimelineEventDto.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<MedicalTimelineEventDto> createMedicalTimelineEvent(
    Map<String, dynamic> data,
  ) async {
    final decoded = await _post('/admin/medical-timeline', data);
    return MedicalTimelineEventDto.fromJson(
      Map<String, dynamic>.from(decoded['data'] as Map),
    );
  }

  Future<List<Map<String, dynamic>>> loadBillingInvoices({
    String? search,
    String? status,
  }) async {
    final parameters = <String, String>{
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (status != null && status.isNotEmpty && status != 'ALL')
        'status': status,
    };
    final query = parameters.isEmpty
        ? ''
        : '?${Uri(queryParameters: parameters).query}';
    final decoded = await _get('/admin/billing$query');
    return (decoded['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> loadVisitBilling(String visitId) async {
    final decoded = await _get('/admin/visits/$visitId/billing');
    return (decoded['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> searchBillingVisits(String search) async {
    final query = Uri(
      queryParameters: {if (search.trim().isNotEmpty) 'search': search.trim()},
    ).query;
    final decoded = await _get(
      '/admin/visits${query.isEmpty ? '' : '?$query'}',
    );
    return (decoded['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> generateBillingInvoice(String visitId) async {
    final decoded = await _post(
      '/admin/visits/$visitId/billing/generate',
      const {},
    );
    await _reloadVisitRoutes();
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> payBillingInvoice(
    String invoiceId,
    Map<String, dynamic> data,
  ) async {
    final decoded = await _request(
      'PATCH',
      '/admin/billing/$invoiceId/pay',
      data,
    );
    await _reloadVisitRoutes();
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> cancelBillingInvoice(String invoiceId) async {
    final decoded = await _request('PATCH', '/admin/billing/$invoiceId/cancel');
    await _reloadVisitRoutes();
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> loadBillingPrint(String invoiceId) async {
    final decoded = await _get('/admin/billing/$invoiceId/print');
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<void> loadBilling({String? search}) async {
    final rows = await loadBillingInvoices(search: search);
    _cache[AdminRoute.billingInvoices] = rows
        .map(
          (item) => AdminRecord(
            id: item['id'].toString(),
            data: Map<String, dynamic>.from(item)..remove('id'),
          ),
        )
        .toList();
    notifyListeners();
  }

  Future<void> generateBilling(String visitId) async {
    await generateBillingInvoice(visitId);
  }

  Future<void> payBilling(String invoiceId, int amount) async {
    await payBillingInvoice(invoiceId, {'amount': amount});
  }

  Future<void> cancelBilling(String invoiceId) async {
    await cancelBillingInvoice(invoiceId);
  }

  Future<void> _reloadVisitRoutes() async {
    await loadRecords(AdminRoute.visits);
    await loadRecords(AdminRoute.reception);
    await loadRecords(AdminRoute.outpatient);
    await refreshDashboard();
  }

  Future<Map<String, dynamic>> uploadFile({
    required String fileName,
    required List<int> bytes,
  }) async {
    final decoded = await _post('/admin/uploads', {
      'fileName': fileName,
      'contentBase64': base64Encode(bytes),
    });
    return decoded['data'] as Map<String, dynamic>;
  }

  Uri _uri(String path) => Uri.parse('${AdminConfig.apiBaseUrl}$path');

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final response = await http.get(_uri(path), headers: _headers());
    final decoded = _decode(response);
    if (response.statusCode >= 400 || decoded['success'] != true) {
      throw Exception(decoded['message']?.toString() ?? 'API error');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      _uri(path),
      headers: _headers(),
      body: jsonEncode(data),
    );
    final decoded = _decode(response);
    if (response.statusCode >= 400 || decoded['success'] != true) {
      throw Exception(decoded['message']?.toString() ?? 'API error');
    }
    return decoded;
  }

  Future<void> _send(
    String method,
    String path, [
    Map<String, dynamic>? data,
  ]) async {
    await _request(method, path, data);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, [
    Map<String, dynamic>? data,
  ]) async {
    final request = http.Request(method, _uri(path));
    request.headers.addAll(_headers());
    if (data != null) request.body = jsonEncode(data);
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final decoded = _decode(response);
    if (response.statusCode >= 400 || decoded['success'] != true) {
      throw Exception(decoded['message']?.toString() ?? 'API error');
    }
    return decoded;
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) return <String, dynamic>{};
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  String _resource(AdminRoute route) {
    switch (route) {
      case AdminRoute.reception:
      case AdminRoute.visits:
      case AdminRoute.outpatient:
        return 'visits';
      case AdminRoute.inpatient:
      case AdminRoute.admissions:
        return 'admissions';
      case AdminRoute.encounters:
        return 'encounters';
      case AdminRoute.serviceOrders:
        return 'service-orders';
      case AdminRoute.billingInvoices:
        return 'billing';
      case AdminRoute.queue:
        return 'queue-tickets';
      case AdminRoute.rooms:
        return 'rooms';
      case AdminRoute.beds:
        return 'beds';
      case AdminRoute.insuranceClaims:
        return 'insurance-claims';
      case AdminRoute.labResults:
        return 'lab-results';
      case AdminRoute.imagingResults:
        return 'imaging-results';
      case AdminRoute.payments:
        return 'billing';
      case AdminRoute.guides:
        return 'guide-items';
      case AdminRoute.callbackRequests:
        return 'callback-requests';
      case AdminRoute.queueTickets:
        return 'queue-tickets';
      case AdminRoute.labServices:
        return 'lab-services';
      case AdminRoute.technicalServices:
        return 'technical-services';
      case AdminRoute.imagingServices:
        return 'imaging-services';
      case AdminRoute.examFees:
        return 'exam-fees';
      case AdminRoute.bedFees:
        return 'bed-fees';
      case AdminRoute.medicalTimeline:
        return 'medical-timeline';
      case AdminRoute.serviceUsages:
        return 'service-usages';
      case AdminRoute.dashboard:
        return 'dashboard';
      default:
        return route.name;
    }
  }
}
