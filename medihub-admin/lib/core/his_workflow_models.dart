class VisitDto {
  const VisitDto(this.data);
  final Map<String, dynamic> data;

  factory VisitDto.fromJson(Map<String, dynamic> json) => VisitDto(json);

  String get id => data['id']?.toString() ?? '';
  String get visitCode => data['visitCode']?.toString() ?? '';
  String get patientId => data['patientId']?.toString() ?? '';
  String get patientCode => data['patientCode']?.toString() ?? '';
  String get patient => data['patient']?.toString() ?? '';
  String get department => data['department']?.toString() ?? '';
  String get doctor => data['doctor']?.toString() ?? '';
  String get status => data['status']?.toString() ?? '';
}

class ReceptionDto extends VisitDto {
  const ReceptionDto(super.data);

  factory ReceptionDto.fromJson(Map<String, dynamic> json) =>
      ReceptionDto(json);

  String get queueNumber => data['ticketNumber']?.toString() ?? '';
  String get roomName => data['roomName']?.toString() ?? '';
}

class DoctorEncounterDto {
  const DoctorEncounterDto(this.data);
  final Map<String, dynamic> data;

  factory DoctorEncounterDto.fromJson(Map<String, dynamic> json) =>
      DoctorEncounterDto(json);

  String get id => data['id']?.toString() ?? '';
  String get encounterCode => data['encounterCode']?.toString() ?? '';
  String get visitId => data['visitId']?.toString() ?? '';
  String get patient => data['patient']?.toString() ?? '';
  String get diagnosis =>
      data['finalDiagnosis']?.toString() ??
      data['diagnosisText']?.toString() ??
      '';
  String get status => data['status']?.toString() ?? '';
}

class LabWorkflowDto {
  const LabWorkflowDto(this.data);
  final Map<String, dynamic> data;

  factory LabWorkflowDto.fromJson(Map<String, dynamic> json) =>
      LabWorkflowDto(json);

  String get id => data['id']?.toString() ?? '';
  String get orderCode => data['orderCode']?.toString() ?? '';
  String get patient => data['patient']?.toString() ?? '';
  String get testName =>
      data['testName']?.toString() ?? data['itemName']?.toString() ?? '';
  String get status => data['status']?.toString() ?? '';
}

class ImagingWorkflowDto {
  const ImagingWorkflowDto(this.data);
  final Map<String, dynamic> data;

  factory ImagingWorkflowDto.fromJson(Map<String, dynamic> json) =>
      ImagingWorkflowDto(json);

  String get id => data['id']?.toString() ?? '';
  String get orderCode => data['orderCode']?.toString() ?? '';
  String get patient => data['patient']?.toString() ?? '';
  String get serviceName =>
      data['title']?.toString() ?? data['itemName']?.toString() ?? '';
  String get status => data['status']?.toString() ?? '';
}

class PrescriptionWorkflowDto {
  const PrescriptionWorkflowDto(this.data);
  final Map<String, dynamic> data;

  factory PrescriptionWorkflowDto.fromJson(Map<String, dynamic> json) =>
      PrescriptionWorkflowDto(json);

  String get id => data['id']?.toString() ?? '';
  String get prescriptionCode => data['prescriptionCode']?.toString() ?? '';
  String get patient => data['patient']?.toString() ?? '';
  String get status => data['status']?.toString() ?? '';
  List<Map<String, dynamic>> get items => (data['items'] as List? ?? const [])
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

class BillingInvoiceDto {
  const BillingInvoiceDto(this.data);
  final Map<String, dynamic> data;

  factory BillingInvoiceDto.fromJson(Map<String, dynamic> json) =>
      BillingInvoiceDto(json);

  String get id => data['id']?.toString() ?? '';
  String get invoiceCode => data['invoiceCode']?.toString() ?? '';
  String get patient => data['patient']?.toString() ?? '';
  String get status => data['status']?.toString() ?? '';
  int get totalAmount => int.tryParse('${data['totalAmount'] ?? 0}') ?? 0;
}

class AdmissionWorkflowDto {
  const AdmissionWorkflowDto(this.data);
  final Map<String, dynamic> data;

  factory AdmissionWorkflowDto.fromJson(Map<String, dynamic> json) =>
      AdmissionWorkflowDto(json);

  String get id => data['id']?.toString() ?? '';
  String get admissionCode => data['admissionCode']?.toString() ?? '';
  String get patient => data['patient']?.toString() ?? '';
  String get room => data['roomName']?.toString() ?? '';
  String get bed => data['bedCode']?.toString() ?? '';
  String get status => data['status']?.toString() ?? '';
}

class InsuranceClaimDto {
  const InsuranceClaimDto(this.data);
  final Map<String, dynamic> data;

  factory InsuranceClaimDto.fromJson(Map<String, dynamic> json) =>
      InsuranceClaimDto(json);

  String get id => data['id']?.toString() ?? '';
  String get claimCode => data['claimCode']?.toString() ?? '';
  String get patient => data['patient']?.toString() ?? '';
  String get patientCode => data['patientCode']?.toString() ?? '';
  String get insuranceNo => data['insuranceNo']?.toString() ?? '';
  String get visitCode => data['visitCode']?.toString() ?? '';
  String get admissionCode => data['admissionCode']?.toString() ?? '';
  String get status => data['status']?.toString() ?? '';
  int get totalAmount => int.tryParse('${data['totalAmount'] ?? 0}') ?? 0;
  int get coveredAmount => int.tryParse('${data['coveredAmount'] ?? 0}') ?? 0;
  int get approvedAmount => int.tryParse('${data['approvedAmount'] ?? 0}') ?? 0;
  int get patientAmount => int.tryParse('${data['patientAmount'] ?? 0}') ?? 0;
}

class MedicalTimelineEventDto {
  const MedicalTimelineEventDto(this.data);
  final Map<String, dynamic> data;

  factory MedicalTimelineEventDto.fromJson(Map<String, dynamic> json) =>
      MedicalTimelineEventDto(json);

  String get id => data['id']?.toString() ?? '';
  String get patient => data['patient']?.toString() ?? '';
  String get patientCode => data['patientCode']?.toString() ?? '';
  String get visitCode => data['visitCode']?.toString() ?? '';
  String get admissionCode => data['admissionCode']?.toString() ?? '';
  String get module => data['module']?.toString() ?? '';
  String get eventType => data['eventType']?.toString() ?? '';
  String get status => data['status']?.toString() ?? '';
  String get title => data['title']?.toString() ?? '';
  String get description => data['description']?.toString() ?? '';
  DateTime? get occurredAt =>
      DateTime.tryParse(data['occurredAt']?.toString() ?? '');
}
