import 'package:flutter/material.dart';

enum AdminRoute {
  dashboard,
  reception,
  visits,
  outpatient,
  inpatient,
  admissions,
  encounters,
  serviceOrders,
  billingInvoices,
  queue,
  rooms,
  beds,
  insuranceClaims,
  accounts,
  organizations,
  patients,
  relatives,
  appointments,
  queueTickets,
  news,
  notifications,
  guides,
  feedbacks,
  callbackRequests,
  labResults,
  imagingResults,
  prescriptions,
  surgeries,
  payments,
  serviceUsages,
  doctors,
  departments,
  medicines,
  supplies,
  labServices,
  technicalServices,
  imagingServices,
  examFees,
  bedFees,
  medicalTimeline,
}

enum AdminFieldKind {
  text,
  number,
  organization,
  patient,
  department,
  doctor,
  date,
  dateTime,
  file,
  richText,
  timeline,
  medicineItems,
}

class AdminField {
  final String key;
  final String label;
  final bool required;
  final bool multiline;
  final List<String>? options;
  final AdminFieldKind kind;

  const AdminField({
    required this.key,
    required this.label,
    this.required = false,
    this.multiline = false,
    this.options,
    this.kind = AdminFieldKind.text,
  });
}

class AdminModule {
  final AdminRoute route;
  final String title;
  final String singular;
  final IconData icon;
  final List<String> columns;
  final List<AdminField> fields;
  final bool supportsStatus;

  const AdminModule({
    required this.route,
    required this.title,
    required this.singular,
    required this.icon,
    required this.columns,
    required this.fields,
    this.supportsStatus = true,
  });
}

class AdminRecord {
  final String id;
  final Map<String, dynamic> data;

  AdminRecord({required this.id, required this.data});

  AdminRecord copyWith(Map<String, dynamic> next) {
    return AdminRecord(id: id, data: {...data, ...next});
  }
}

class DashboardStat {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const DashboardStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

const activeOptions = ['ACTIVE', 'LOCKED'];
const appointmentStatusOptions = [
  'REQUESTED',
  'PROPOSED',
  'CONFIRMED',
  'CONVERTED_TO_VISIT',
  'CHECKED_IN',
  'IN_PROGRESS',
  'COMPLETED',
  'CANCELLED',
];

const _allAdminModules = <AdminModule>[
  AdminModule(
    route: AdminRoute.reception,
    title: 'Tiếp nhận',
    singular: 'lượt tiếp nhận',
    icon: Icons.fact_check_outlined,
    columns: [
      'visitCode',
      'patient',
      'patientPhone',
      'department',
      'receptionTime',
      'status',
    ],
    fields: [
      AdminField(
        key: 'patient',
        label: 'Bệnh nhân',
        required: true,
        kind: AdminFieldKind.patient,
      ),
      AdminField(
        key: 'department',
        label: 'Khoa tiếp nhận',
        required: true,
        kind: AdminFieldKind.department,
      ),
      AdminField(key: 'doctor', label: 'Bác sĩ', kind: AdminFieldKind.doctor),
      AdminField(
        key: 'visitType',
        label: 'Loại lượt khám',
        options: ['OUTPATIENT', 'INPATIENT', 'EMERGENCY'],
      ),
      AdminField(
        key: 'reason',
        label: 'Lý do khám / triệu chứng',
        multiline: true,
      ),
      AdminField(
        key: 'status',
        label: 'Trạng thái',
        options: [
          'WAITING_RECEPTION',
          'RECEIVED',
          'WAITING_EXAM',
          'IN_EXAM',
          'WAITING_PAYMENT',
          'COMPLETED',
          'CANCELLED',
          'ADMITTED',
        ],
      ),
    ],
  ),
  AdminModule(
    route: AdminRoute.appointments,
    title: 'Lịch hẹn',
    singular: 'lịch hẹn',
    icon: Icons.event_outlined,
    columns: [
      'patient',
      'patientPhone',
      'department',
      'doctor',
      'appointmentAt',
      'status',
    ],
    fields: [
      AdminField(
        key: 'patient',
        label: 'Bệnh nhân',
        required: true,
        kind: AdminFieldKind.patient,
      ),
      AdminField(
        key: 'appointmentAt',
        label: 'Ngày mong muốn',
        kind: AdminFieldKind.dateTime,
      ),
      AdminField(
        key: 'note',
        label: 'Lý do khám / triệu chứng',
        multiline: true,
      ),
    ],
  ),
  AdminModule(
    route: AdminRoute.visits,
    title: 'Lượt khám',
    singular: 'lượt khám',
    icon: Icons.assignment_ind_outlined,
    columns: [
      'visitCode',
      'patient',
      'patientPhone',
      'department',
      'doctor',
      'receptionTime',
      'status',
    ],
    fields: [
      AdminField(
        key: 'patient',
        label: 'Bệnh nhân',
        required: true,
        kind: AdminFieldKind.patient,
      ),
      AdminField(
        key: 'department',
        label: 'Khoa khám',
        required: true,
        kind: AdminFieldKind.department,
      ),
      AdminField(
        key: 'doctor',
        label: 'Bác sĩ khám',
        kind: AdminFieldKind.doctor,
      ),
      AdminField(
        key: 'visitType',
        label: 'Loại lượt khám',
        options: ['OUTPATIENT', 'INPATIENT', 'EMERGENCY'],
      ),
      AdminField(key: 'reason', label: 'Lý do khám', multiline: true),
      AdminField(
        key: 'insuranceUsed',
        label: 'Sử dụng BHYT',
        options: ['true', 'false'],
      ),
      AdminField(
        key: 'status',
        label: 'Trạng thái',
        options: [
          'WAITING_RECEPTION',
          'RECEIVED',
          'WAITING_EXAM',
          'IN_EXAM',
          'WAITING_PAYMENT',
          'COMPLETED',
          'CANCELLED',
          'ADMITTED',
        ],
      ),
    ],
  ),
  AdminModule(
    route: AdminRoute.outpatient,
    title: 'Khám ngoại trú',
    singular: 'lượt khám ngoại trú',
    icon: Icons.medical_information_outlined,
    columns: [
      'visitCode',
      'patient',
      'department',
      'doctor',
      'receptionTime',
      'status',
    ],
    fields: [
      AdminField(
        key: 'patient',
        label: 'Bệnh nhân',
        required: true,
        kind: AdminFieldKind.patient,
      ),
      AdminField(
        key: 'department',
        label: 'Khoa khám',
        required: true,
        kind: AdminFieldKind.department,
      ),
      AdminField(
        key: 'doctor',
        label: 'Bác sĩ khám',
        kind: AdminFieldKind.doctor,
      ),
      AdminField(key: 'reason', label: 'Lý do khám', multiline: true),
    ],
  ),
  AdminModule(
    route: AdminRoute.encounters,
    title: 'Phiên khám / Bệnh án',
    singular: 'phiên khám',
    icon: Icons.assignment_outlined,
    columns: ['encounterCode', 'patient', 'department', 'doctor', 'status'],
    fields: [
      AdminField(key: 'visitId', label: 'Mã lượt khám', required: true),
      AdminField(key: 'chiefComplaint', label: 'Lý do khám', multiline: true),
      AdminField(
        key: 'clinicalSigns',
        label: 'Dấu hiệu lâm sàng',
        multiline: true,
      ),
      AdminField(key: 'diagnosisText', label: 'Chẩn đoán', multiline: true),
      AdminField(key: 'diagnosisCode', label: 'Mã ICD'),
      AdminField(key: 'conclusion', label: 'Kết luận', multiline: true),
      AdminField(
        key: 'treatmentPlan',
        label: 'Hướng điều trị',
        multiline: true,
      ),
      AdminField(
        key: 'status',
        label: 'Trạng thái',
        options: ['DRAFT', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'],
      ),
    ],
  ),
  AdminModule(
    route: AdminRoute.serviceOrders,
    title: 'Phiếu chỉ định',
    singular: 'phiếu chỉ định',
    icon: Icons.medical_services_outlined,
    columns: [
      'orderCode',
      'patient',
      'department',
      'orderType',
      'orderedAt',
      'status',
    ],
    fields: [
      AdminField(key: 'visitId', label: 'Mã lượt khám', required: true),
      AdminField(key: 'encounterId', label: 'Mã phiên khám'),
      AdminField(
        key: 'orderType',
        label: 'Loại chỉ định',
        options: [
          'LAB',
          'IMAGING',
          'PROCEDURE',
          'MEDICINE',
          'SUPPLY',
          'EXAM_FEE',
          'BED',
          'OTHER',
        ],
      ),
      AdminField(key: 'note', label: 'Ghi chú', multiline: true),
      AdminField(
        key: 'status',
        label: 'Trạng thái',
        options: [
          'DRAFT',
          'ORDERED',
          'WAITING_PAYMENT',
          'PAID',
          'IN_PROGRESS',
          'COMPLETED',
          'CANCELLED',
        ],
      ),
    ],
  ),
  AdminModule(
    route: AdminRoute.inpatient,
    title: 'Nội trú',
    singular: 'bệnh án nội trú',
    icon: Icons.bed_outlined,
    columns: [
      'admissionCode',
      'patient',
      'patientPhone',
      'department',
      'roomName',
      'bedCode',
      'admittedAt',
      'status',
    ],
    fields: [
      AdminField(
        key: 'patient',
        label: 'Bệnh nhân',
        required: true,
        kind: AdminFieldKind.patient,
      ),
      AdminField(
        key: 'department',
        label: 'Khoa điều trị',
        kind: AdminFieldKind.department,
      ),
      AdminField(
        key: 'doctor',
        label: 'Bác sĩ điều trị',
        kind: AdminFieldKind.doctor,
      ),
      AdminField(key: 'roomName', label: 'Phòng'),
      AdminField(key: 'bedCode', label: 'Giường'),
      AdminField(
        key: 'admittedAt',
        label: 'Ngày vào viện',
        kind: AdminFieldKind.dateTime,
      ),
      AdminField(
        key: 'dischargedAt',
        label: 'Ngày ra viện',
        kind: AdminFieldKind.dateTime,
      ),
      AdminField(key: 'reason', label: 'Lý do vào viện', multiline: true),
      AdminField(key: 'diagnosis', label: 'Chẩn đoán', multiline: true),
      AdminField(key: 'note', label: 'Ghi chú điều trị', multiline: true),
      AdminField(
        key: 'status',
        label: 'Trạng thái',
        options: ['ADMITTED', 'IN_TREATMENT', 'DISCHARGED', 'CANCELLED'],
      ),
    ],
  ),
  AdminModule(
    route: AdminRoute.rooms,
    title: 'Buồng / phòng nội trú',
    singular: 'phòng nội trú',
    icon: Icons.meeting_room_outlined,
    columns: ['code', 'name', 'department', 'roomType', 'status'],
    fields: [
      AdminField(
        key: 'department',
        label: 'Khoa điều trị',
        kind: AdminFieldKind.department,
      ),
      AdminField(key: 'code', label: 'Mã phòng', required: true),
      AdminField(key: 'name', label: 'Tên phòng', required: true),
      AdminField(key: 'roomType', label: 'Loại phòng'),
      AdminField(
        key: 'status',
        label: 'Trạng thái',
        options: ['ACTIVE', 'LOCKED'],
      ),
    ],
  ),
  AdminModule(
    route: AdminRoute.beds,
    title: 'Giường bệnh',
    singular: 'giường bệnh',
    icon: Icons.hotel_outlined,
    columns: ['code', 'name', 'roomName', 'dailyPrice', 'status'],
    fields: [
      AdminField(key: 'roomName', label: 'Phòng', required: true),
      AdminField(key: 'code', label: 'Mã giường', required: true),
      AdminField(key: 'name', label: 'Tên giường'),
      AdminField(
        key: 'dailyPrice',
        label: 'Giá giường/ngày',
        kind: AdminFieldKind.number,
      ),
      AdminField(
        key: 'status',
        label: 'Trạng thái',
        options: ['AVAILABLE', 'OCCUPIED', 'LOCKED'],
      ),
    ],
  ),
  AdminModule(
    route: AdminRoute.insuranceClaims,
    title: 'Hồ sơ bảo hiểm',
    singular: 'hồ sơ bảo hiểm',
    icon: Icons.health_and_safety_outlined,
    columns: [
      'claimCode',
      'patient',
      'insuranceNo',
      'totalAmount',
      'approvedAmount',
      'status',
    ],
    fields: [
      AdminField(
        key: 'patient',
        label: 'Bệnh nhân',
        required: true,
        kind: AdminFieldKind.patient,
      ),
      AdminField(key: 'claimCode', label: 'Mã hồ sơ'),
      AdminField(key: 'insuranceNo', label: 'Số thẻ BHYT'),
      AdminField(
        key: 'totalAmount',
        label: 'Tổng chi phí',
        kind: AdminFieldKind.number,
      ),
      AdminField(
        key: 'coveredAmount',
        label: 'BHYT dự kiến thanh toán',
        kind: AdminFieldKind.number,
      ),
      AdminField(
        key: 'approvedAmount',
        label: 'BHYT duyệt thanh toán',
        kind: AdminFieldKind.number,
      ),
      AdminField(
        key: 'patientAmount',
        label: 'Người bệnh thanh toán',
        kind: AdminFieldKind.number,
      ),
      AdminField(key: 'note', label: 'Ghi chú', multiline: true),
      AdminField(
        key: 'status',
        label: 'Trạng thái',
        options: ['DRAFT', 'SUBMITTED', 'APPROVED', 'REJECTED', 'CANCELLED'],
      ),
    ],
  ),
  AdminModule(
    route: AdminRoute.queueTickets,
    title: 'Hàng đợi khám',
    singular: 'số thứ tự',
    icon: Icons.confirmation_number_outlined,
    columns: ['ticketNumber', 'patient', 'department', 'roomName', 'status'],
    fields: [
      AdminField(
        key: 'patient',
        label: 'Bệnh nhân',
        kind: AdminFieldKind.patient,
      ),
      AdminField(key: 'department', label: 'Khoa/phòng', required: true),
      AdminField(key: 'roomName', label: 'Phòng thực hiện'),
      AdminField(key: 'ticketNumber', label: 'Số thứ tự'),
      AdminField(
        key: 'estimatedWaitMinutes',
        label: 'Thời gian chờ (phút)',
        kind: AdminFieldKind.number,
      ),
      AdminField(
        key: 'status',
        label: 'Trạng thái',
        options: ['WAITING', 'DONE', 'CANCELLED'],
      ),
    ],
  ),
  AdminModule(
    route: AdminRoute.labResults,
    title: 'Xét nghiệm',
    singular: 'kết quả xét nghiệm',
    icon: Icons.science_outlined,
    columns: [
      'patient',
      'testType',
      'performedAt',
      'statusLabel',
      'conclusion',
    ],
    fields: [
      AdminField(
        key: 'patient',
        label: 'Bệnh nhân',
        required: true,
        kind: AdminFieldKind.patient,
      ),
      AdminField(key: 'testType', label: 'Loại xét nghiệm', required: true),
      AdminField(
        key: 'performedAt',
        label: 'Ngày thực hiện',
        kind: AdminFieldKind.date,
      ),
      AdminField(key: 'conclusion', label: 'Kết luận'),
      AdminField(key: 'doctorNote', label: 'Bác sĩ nhận định', multiline: true),
      AdminField(
        key: 'pdfUrl',
        label: 'File kết quả',
        kind: AdminFieldKind.file,
      ),
      AdminField(
        key: 'statusLabel',
        label: 'Trạng thái',
        options: [
          'Chờ lấy mẫu',
          'Đã lấy mẫu',
          'Đang chạy máy',
          'Chờ duyệt',
          'Đã duyệt',
        ],
      ),
    ],
  ),
  AdminModule(
    route: AdminRoute.imagingResults,
    title: 'Chẩn đoán hình ảnh',
    singular: 'kết quả CĐHA',
    icon: Icons.image_search_outlined,
    columns: ['patient', 'title', 'technique', 'performedAt', 'statusLabel'],
    fields: [
      AdminField(
        key: 'patient',
        label: 'Bệnh nhân',
        required: true,
        kind: AdminFieldKind.patient,
      ),
      AdminField(key: 'title', label: 'Tên chẩn đoán', required: true),
      AdminField(key: 'technique', label: 'Kỹ thuật'),
      AdminField(key: 'imageUrl', label: 'Hình ảnh', kind: AdminFieldKind.file),
      AdminField(
        key: 'conclusion',
        label: 'Kết luận chuyên môn',
        multiline: true,
      ),
      AdminField(key: 'doctorName', label: 'Bác sĩ chẩn đoán'),
      AdminField(
        key: 'performedAt',
        label: 'Ngày thực hiện',
        kind: AdminFieldKind.date,
      ),
      AdminField(
        key: 'statusLabel',
        label: 'Trạng thái',
        options: [
          'Chờ thực hiện',
          'Đã chụp',
          'Chờ đọc',
          'Chờ duyệt',
          'Đã duyệt',
        ],
      ),
    ],
  ),
  AdminModule(
    route: AdminRoute.prescriptions,
    title: 'Đơn thuốc',
    singular: 'đơn thuốc',
    icon: Icons.medication_outlined,
    columns: ['patient', 'doctor', 'prescribedAt', 'status'],
    fields: [
      AdminField(
        key: 'patient',
        label: 'Bệnh nhân',
        required: true,
        kind: AdminFieldKind.patient,
      ),
      AdminField(key: 'doctor', label: 'Bác sĩ', kind: AdminFieldKind.doctor),
      AdminField(
        key: 'prescribedAt',
        label: 'Ngày kê',
        kind: AdminFieldKind.date,
      ),
      AdminField(
        key: 'medicines',
        label: 'Dòng thuốc',
        kind: AdminFieldKind.medicineItems,
        multiline: true,
      ),
      AdminField(
        key: 'status',
        label: 'Trạng thái',
        options: ['Mới', 'Đã phát thuốc'],
      ),
    ],
  ),
  AdminModule(
    route: AdminRoute.payments,
    title: 'Thanh toán viện phí',
    singular: 'viện phí',
    icon: Icons.payments_outlined,
    columns: ['patient', 'amount', 'createdAt', 'status'],
    fields: [
      AdminField(
        key: 'patient',
        label: 'Bệnh nhân',
        kind: AdminFieldKind.patient,
      ),
      AdminField(key: 'amount', label: 'Số tiền', kind: AdminFieldKind.number),
      AdminField(
        key: 'createdAt',
        label: 'Ngày phát sinh',
        kind: AdminFieldKind.date,
      ),
      AdminField(key: 'note', label: 'Ghi chú', multiline: true),
      AdminField(
        key: 'status',
        label: 'Trạng thái',
        options: ['Chưa thanh toán', 'Đã thanh toán', 'Đã hủy'],
      ),
    ],
  ),
  AdminModule(
    route: AdminRoute.billingInvoices,
    title: 'Hóa đơn viện phí',
    singular: 'hóa đơn viện phí',
    icon: Icons.receipt_long_outlined,
    columns: [
      'invoiceCode',
      'patient',
      'totalAmount',
      'insurancePayAmount',
      'patientPayAmount',
      'paidAmount',
      'status',
    ],
    fields: [
      AdminField(key: 'visitId', label: 'Mã lượt khám'),
      AdminField(key: 'invoiceCode', label: 'Mã hóa đơn'),
      AdminField(key: 'patient', label: 'Bệnh nhân'),
      AdminField(
        key: 'totalAmount',
        label: 'Tổng tiền',
        kind: AdminFieldKind.number,
      ),
      AdminField(
        key: 'insurancePayAmount',
        label: 'BHYT thanh toán',
        kind: AdminFieldKind.number,
      ),
      AdminField(
        key: 'patientPayAmount',
        label: 'Người bệnh thanh toán',
        kind: AdminFieldKind.number,
      ),
      AdminField(
        key: 'discountAmount',
        label: 'Miễn giảm',
        kind: AdminFieldKind.number,
      ),
      AdminField(
        key: 'paidAmount',
        label: 'Đã thu',
        kind: AdminFieldKind.number,
      ),
      AdminField(
        key: 'status',
        label: 'Trạng thái',
        options: ['UNPAID', 'PARTIALLY_PAID', 'PAID', 'CANCELLED', 'REFUNDED'],
      ),
    ],
  ),
  AdminModule(
    route: AdminRoute.serviceUsages,
    title: 'Chỉ định dịch vụ',
    singular: 'chỉ định dịch vụ',
    icon: Icons.receipt_long_outlined,
    columns: ['patient', 'itemName', 'quantity', 'amount', 'usedAt', 'status'],
    fields: [
      AdminField(
        key: 'patient',
        label: 'Bệnh nhân',
        required: true,
        kind: AdminFieldKind.patient,
      ),
      AdminField(key: 'itemType', label: 'Loại dịch vụ'),
      AdminField(key: 'itemName', label: 'Tên dịch vụ', required: true),
      AdminField(
        key: 'quantity',
        label: 'Số lượng',
        kind: AdminFieldKind.number,
      ),
      AdminField(
        key: 'unitPrice',
        label: 'Đơn giá',
        kind: AdminFieldKind.number,
      ),
      AdminField(
        key: 'amount',
        label: 'Thành tiền',
        kind: AdminFieldKind.number,
      ),
      AdminField(
        key: 'usedAt',
        label: 'Ngày phát sinh',
        kind: AdminFieldKind.date,
      ),
      AdminField(key: 'note', label: 'Ghi chú', multiline: true),
      AdminField(
        key: 'status',
        label: 'Trạng thái',
        options: ['UNPAID', 'PAID', 'CANCELLED'],
      ),
    ],
  ),
  AdminModule(
    route: AdminRoute.callbackRequests,
    title: 'Yêu cầu gọi lại',
    singular: 'yêu cầu gọi lại',
    icon: Icons.phone_callback_outlined,
    columns: ['fullName', 'phone', 'status', 'createdAt'],
    fields: [
      AdminField(
        key: 'patient',
        label: 'Bệnh nhân',
        kind: AdminFieldKind.patient,
      ),
      AdminField(key: 'fullName', label: 'Họ tên'),
      AdminField(key: 'phone', label: 'Số điện thoại', required: true),
      AdminField(key: 'note', label: 'Ghi chú', multiline: true),
      AdminField(
        key: 'status',
        label: 'Trạng thái',
        options: ['PENDING', 'CALLED', 'CANCELLED'],
      ),
    ],
  ),
  AdminModule(
    route: AdminRoute.patients,
    title: 'Hồ sơ bệnh nhân',
    singular: 'bệnh nhân',
    icon: Icons.people_alt_outlined,
    columns: ['patientCode', 'fullName', 'phone', 'dob', 'gender', 'status'],
    fields: [
      AdminField(key: 'fullName', label: 'Họ tên', required: true),
      AdminField(key: 'phone', label: 'Số điện thoại'),
      AdminField(key: 'citizenId', label: 'CCCD/CMND'),
      AdminField(key: 'dob', label: 'Ngày sinh', kind: AdminFieldKind.date),
      AdminField(
        key: 'gender',
        label: 'Giới tính',
        options: ['MALE', 'FEMALE'],
      ),
      AdminField(key: 'status', label: 'Trạng thái', options: activeOptions),
    ],
  ),
  AdminModule(
    route: AdminRoute.relatives,
    title: 'Người thân',
    singular: 'người thân',
    icon: Icons.family_restroom_outlined,
    columns: ['patient', 'relationship', 'fullName', 'phone', 'status'],
    fields: [
      AdminField(
        key: 'patient',
        label: 'Bệnh nhân',
        kind: AdminFieldKind.patient,
      ),
      AdminField(key: 'relationship', label: 'Quan hệ', required: true),
      AdminField(key: 'fullName', label: 'Họ tên', required: true),
      AdminField(key: 'phone', label: 'Số điện thoại'),
      AdminField(key: 'dob', label: 'Ngày sinh', kind: AdminFieldKind.date),
      AdminField(
        key: 'gender',
        label: 'Giới tính',
        options: ['MALE', 'FEMALE'],
      ),
      AdminField(key: 'status', label: 'Trạng thái', options: activeOptions),
    ],
  ),
  AdminModule(
    route: AdminRoute.doctors,
    title: 'Bác sĩ',
    singular: 'bác sĩ',
    icon: Icons.medical_services_outlined,
    columns: ['fullName', 'department', 'phone', 'status'],
    fields: [
      AdminField(key: 'fullName', label: 'Họ tên', required: true),
      AdminField(
        key: 'department',
        label: 'Khoa',
        kind: AdminFieldKind.department,
      ),
      AdminField(key: 'phone', label: 'Số điện thoại'),
      AdminField(key: 'title', label: 'Chức danh'),
      AdminField(key: 'status', label: 'Trạng thái', options: activeOptions),
    ],
  ),
  AdminModule(
    route: AdminRoute.departments,
    title: 'Khoa phòng',
    singular: 'khoa',
    icon: Icons.apartment_outlined,
    columns: ['name', 'code', 'status'],
    fields: [
      AdminField(key: 'name', label: 'Tên khoa', required: true),
      AdminField(key: 'code', label: 'Mã khoa'),
      AdminField(key: 'description', label: 'Mô tả', multiline: true),
      AdminField(key: 'status', label: 'Trạng thái', options: activeOptions),
    ],
  ),
  AdminModule(
    route: AdminRoute.accounts,
    title: 'Tài khoản',
    singular: 'tài khoản',
    icon: Icons.manage_accounts_outlined,
    columns: ['fullName', 'phone', 'role', 'organization', 'patient', 'status'],
    fields: [
      AdminField(key: 'fullName', label: 'Họ tên', required: true),
      AdminField(key: 'phone', label: 'Số điện thoại'),
      AdminField(key: 'email', label: 'Email'),
      AdminField(key: 'password', label: 'Mật khẩu mới'),
      AdminField(
        key: 'organization',
        label: 'Bệnh viện',
        required: true,
        kind: AdminFieldKind.organization,
      ),
      AdminField(
        key: 'patient',
        label: 'Bệnh nhân liên kết',
        kind: AdminFieldKind.patient,
      ),
      AdminField(
        key: 'role',
        label: 'Vai trò',
        options: ['ADMIN', 'DOCTOR', 'PATIENT'],
      ),
      AdminField(key: 'status', label: 'Trạng thái', options: activeOptions),
    ],
  ),
  AdminModule(
    route: AdminRoute.organizations,
    title: 'Bệnh viện',
    singular: 'bệnh viện',
    icon: Icons.business_outlined,
    columns: ['code', 'name', 'phone', 'status'],
    fields: [
      AdminField(key: 'code', label: 'Mã bệnh viện', required: true),
      AdminField(key: 'name', label: 'Tên bệnh viện', required: true),
      AdminField(key: 'phone', label: 'Số điện thoại'),
      AdminField(key: 'email', label: 'Email'),
      AdminField(key: 'address', label: 'Địa chỉ', multiline: true),
      AdminField(key: 'status', label: 'Trạng thái', options: activeOptions),
    ],
  ),
  AdminModule(
    route: AdminRoute.notifications,
    title: 'Thông báo',
    singular: 'thông báo',
    icon: Icons.notifications_outlined,
    columns: ['title', 'recipient', 'sentAt', 'status'],
    fields: [
      AdminField(key: 'title', label: 'Tiêu đề', required: true),
      AdminField(key: 'content', label: 'Nội dung', multiline: true),
      AdminField(
        key: 'recipient',
        label: 'Người nhận',
        options: ['Tất cả bệnh nhân', 'Theo bệnh nhân'],
      ),
      AdminField(
        key: 'patient',
        label: 'Bệnh nhân',
        kind: AdminFieldKind.patient,
      ),
      AdminField(
        key: 'sentAt',
        label: 'Ngày gửi',
        kind: AdminFieldKind.dateTime,
      ),
      AdminField(
        key: 'status',
        label: 'Trạng thái',
        options: ['Đã gửi', 'Nháp'],
      ),
    ],
  ),
  AdminModule(
    route: AdminRoute.news,
    title: 'Tin tức',
    singular: 'tin tức',
    icon: Icons.article_outlined,
    columns: [
      'imageUrl',
      'title',
      'summary',
      'category',
      'publishedAt',
      'status',
    ],
    fields: [
      AdminField(key: 'title', label: 'Tiêu đề', required: true),
      AdminField(key: 'category', label: 'Danh mục'),
      AdminField(key: 'summary', label: 'Mô tả ngắn', multiline: true),
      AdminField(
        key: 'content',
        label: 'Nội dung',
        multiline: true,
        kind: AdminFieldKind.richText,
      ),
      AdminField(
        key: 'imageUrl',
        label: 'Ảnh đại diện',
        kind: AdminFieldKind.file,
      ),
      AdminField(
        key: 'publishedAt',
        label: 'Ngày đăng',
        kind: AdminFieldKind.date,
      ),
      AdminField(
        key: 'status',
        label: 'Trạng thái',
        options: ['Hiển thị', 'Ẩn'],
      ),
    ],
  ),
  AdminModule(
    route: AdminRoute.guides,
    title: 'Hướng dẫn',
    singular: 'hướng dẫn',
    icon: Icons.help_outline,
    columns: ['title', 'sortOrder', 'status'],
    fields: [
      AdminField(key: 'title', label: 'Câu hỏi', required: true),
      AdminField(key: 'content', label: 'Nội dung hướng dẫn', multiline: true),
      AdminField(
        key: 'sortOrder',
        label: 'Thứ tự',
        kind: AdminFieldKind.number,
      ),
      AdminField(key: 'status', label: 'Trạng thái', options: activeOptions),
    ],
  ),
  AdminModule(
    route: AdminRoute.feedbacks,
    title: 'Góp ý',
    singular: 'góp ý',
    icon: Icons.star_outline,
    columns: ['fullName', 'phone', 'rating', 'status', 'createdAt'],
    fields: [
      AdminField(
        key: 'patient',
        label: 'Bệnh nhân',
        kind: AdminFieldKind.patient,
      ),
      AdminField(key: 'fullName', label: 'Họ tên'),
      AdminField(key: 'phone', label: 'Số điện thoại'),
      AdminField(key: 'rating', label: 'Số sao', kind: AdminFieldKind.number),
      AdminField(key: 'content', label: 'Nội dung đánh giá', multiline: true),
      AdminField(
        key: 'status',
        label: 'Trạng thái',
        options: ['NEW', 'REVIEWED'],
      ),
    ],
  ),
  AdminModule(
    route: AdminRoute.medicines,
    title: 'Danh mục thuốc',
    singular: 'thuốc',
    icon: Icons.medication_liquid_outlined,
    columns: ['code', 'name', 'unit', 'price', 'status'],
    fields: catalogFields,
  ),
  AdminModule(
    route: AdminRoute.supplies,
    title: 'Vật tư y tế',
    singular: 'vật tư',
    icon: Icons.inventory_2_outlined,
    columns: ['code', 'name', 'unit', 'price', 'status'],
    fields: catalogFields,
  ),
  AdminModule(
    route: AdminRoute.labServices,
    title: 'Danh mục xét nghiệm',
    singular: 'xét nghiệm',
    icon: Icons.biotech_outlined,
    columns: ['code', 'name', 'unit', 'price', 'status'],
    fields: catalogFields,
  ),
  AdminModule(
    route: AdminRoute.technicalServices,
    title: 'Dịch vụ kỹ thuật',
    singular: 'dịch vụ kỹ thuật',
    icon: Icons.medical_information_outlined,
    columns: ['code', 'name', 'unit', 'price', 'status'],
    fields: catalogFields,
  ),
  AdminModule(
    route: AdminRoute.imagingServices,
    title: 'Dịch vụ CĐHA',
    singular: 'dịch vụ CĐHA',
    icon: Icons.image_search_outlined,
    columns: ['code', 'name', 'unit', 'price', 'status'],
    fields: catalogFields,
  ),
  AdminModule(
    route: AdminRoute.examFees,
    title: 'Giá khám',
    singular: 'giá khám',
    icon: Icons.fact_check_outlined,
    columns: ['code', 'name', 'price', 'status'],
    fields: catalogFields,
  ),
  AdminModule(
    route: AdminRoute.bedFees,
    title: 'Giá giường',
    singular: 'giá giường',
    icon: Icons.bed_outlined,
    columns: ['code', 'name', 'unit', 'price', 'status'],
    fields: catalogFields,
  ),
];

final adminModules = _allAdminModules
    .where(
      (module) =>
          module.route != AdminRoute.insuranceClaims &&
          module.route != AdminRoute.surgeries &&
          module.route != AdminRoute.medicalTimeline,
    )
    .toList(growable: false);

const catalogFields = [
  AdminField(key: 'code', label: 'Mã'),
  AdminField(key: 'name', label: 'Tên', required: true),
  AdminField(key: 'unit', label: 'Đơn vị'),
  AdminField(key: 'price', label: 'Giá', kind: AdminFieldKind.number),
  AdminField(key: 'description', label: 'Mô tả', multiline: true),
  AdminField(key: 'status', label: 'Trạng thái', options: activeOptions),
];
