// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as web;

import 'surgery_models.dart';

void openSurgeryReport({
  required SurgeryCaseDetailDto report,
  required String organizationName,
}) {
  final html = _SurgeryReportDocument(report, organizationName).build();
  final blob = web.Blob([html], 'text/html;charset=utf-8');
  final url = web.Url.createObjectUrlFromBlob(blob);
  web.window.open(url, '_blank');
  unawaited(
    Future<void>.delayed(
      const Duration(seconds: 20),
      () => web.Url.revokeObjectUrl(url),
    ),
  );
}

class _SurgeryReportDocument {
  const _SurgeryReportDocument(this.report, this.organizationName);

  final SurgeryCaseDetailDto report;
  final String organizationName;

  Map<String, dynamic> get data => report.data;

  String build() =>
      '''
<!doctype html>
<html lang="vi">
<head>
  <meta charset="utf-8">
  <title>Biên bản PTTT ${_text(report.surgeryCode)}</title>
  <style>
    @page { size: A4 portrait; margin: 12mm; }
    * { box-sizing: border-box; }
    body { margin: 0; background: #eef2f6; color: #111827; font: 12px/1.45 Arial, sans-serif; }
    .toolbar { position: sticky; top: 0; padding: 10px; text-align: right; background: white; border-bottom: 1px solid #cbd5e1; }
    button { border: 0; border-radius: 5px; padding: 9px 16px; background: #005aa8; color: white; font-weight: 700; cursor: pointer; }
    main { width: 210mm; min-height: 297mm; margin: auto; padding: 10mm; background: white; }
    .hospital { text-align: center; font-weight: 700; text-transform: uppercase; }
    h1 { margin: 8px 0 2px; text-align: center; font-size: 18px; text-transform: uppercase; }
    .code { text-align: center; margin-bottom: 14px; }
    h2 { margin: 12px 0 5px; padding: 5px 7px; background: #e8f2fb; border-left: 4px solid #005aa8; font-size: 12px; }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 4px 18px; }
    .full { grid-column: 1 / -1; }
    .label { font-weight: 700; }
    .box { min-height: 45px; padding: 6px; border: 1px solid #94a3b8; white-space: pre-wrap; }
    table { width: 100%; border-collapse: collapse; margin-top: 4px; font-size: 11px; }
    th, td { border: 1px solid #64748b; padding: 5px; vertical-align: top; }
    th { background: #f1f5f9; text-align: left; }
    .signatures { display: grid; grid-template-columns: 1fr 1fr; gap: 50px; margin-top: 25px; text-align: center; }
    .signature { min-height: 90px; font-weight: 700; }
    @media print {
      body { background: white; }
      .toolbar { display: none; }
      main { width: auto; min-height: auto; margin: 0; padding: 0; }
    }
  </style>
</head>
<body>
  <div class="toolbar"><button onclick="window.print()">In / Lưu PDF</button></div>
  <main>
    <div class="hospital">${_text(organizationName.isEmpty ? 'BỆNH VIỆN MEDIHUB' : organizationName)}</div>
    <h1>Biên bản phẫu thuật / thủ thuật</h1>
    <div class="code">Mã ca: <strong>${_text(report.surgeryCode)}</strong></div>

    <h2>I. Thông tin người bệnh</h2>
    <div class="grid">
      ${_line('Mã người bệnh', data['patientCode'])}
      ${_line('Họ và tên', data['patient'])}
      ${_line('Ngày sinh', _dateOnly(data['patientDob']))}
      ${_line('Giới tính', _gender(data['patientGender']))}
      ${_line('Mã lượt khám', data['visitCode'])}
      ${_line('Mã nội trú', data['admissionCode'])}
    </div>

    <h2>II. Thông tin phẫu thuật / thủ thuật</h2>
    <div class="grid">
      ${_line('Tên PTTT', data['title'], full: true)}
      ${_line('Khoa thực hiện', data['department'])}
      ${_line('Bác sĩ chính', data['mainDoctor'])}
      ${_line('Phương pháp vô cảm', data['anesthesiaMethod'])}
      ${_line('Thời gian bắt đầu', _dateTime(data['startedAt']))}
      ${_line('Thời gian kết thúc', _dateTime(data['endedAt']))}
      ${_line('Chẩn đoán trước PTTT', data['preDiagnosis'], full: true)}
      ${_line('Chẩn đoán sau PTTT', data['postDiagnosis'], full: true)}
    </div>

    <h2>III. Kíp phẫu thuật / thủ thuật</h2>
    <table>
      <thead><tr><th style="width:35%">Họ tên</th><th style="width:30%">Vai trò</th><th>Ghi chú</th></tr></thead>
      <tbody>${_teamRows()}</tbody>
    </table>

    <h2>IV. Vật tư, thuốc và dịch truyền</h2>
    <table>
      <thead><tr><th>Tên</th><th style="width:14%">Loại</th><th style="width:10%">SL</th><th style="width:12%">Đơn vị</th><th style="width:16%">Thành tiền</th></tr></thead>
      <tbody>${_consumableRows()}</tbody>
    </table>

    <h2>V. Nội dung biên bản</h2>
    ${_box('Mô tả quá trình thực hiện', data['description'])}
    ${_box('Kết quả', data['result'])}
    ${_box('Biến chứng', data['complication'])}
    ${_box('Ghi chú', data['note'])}

    <div class="signatures">
      <div class="signature">BÁC SĨ PHẪU THUẬT<br><small>(Ký, ghi rõ họ tên)</small></div>
      <div class="signature">NGƯỜI LẬP BIÊN BẢN<br><small>(Ký, ghi rõ họ tên)</small></div>
    </div>
  </main>
</body>
</html>
''';

  String _teamRows() {
    if (report.teamMembers.isEmpty) {
      return '<tr><td colspan="3">Chưa ghi nhận thành viên kíp PTTT</td></tr>';
    }
    return report.teamMembers
        .map(
          (item) =>
              '<tr><td>${_text(item.staffName)}</td><td>${_text(_role(item.role))}</td><td>${_text(item.note)}</td></tr>',
        )
        .join();
  }

  String _consumableRows() {
    if (report.consumables.isEmpty) {
      return '<tr><td colspan="5">Chưa ghi nhận vật tư sử dụng</td></tr>';
    }
    return report.consumables
        .map(
          (item) =>
              '<tr><td>${_text(item.itemName)}</td><td>${_text(item.itemType)}</td><td>${_number(item.quantity)}</td><td>${_text(item.unit)}</td><td>${_money(item.totalPrice)}</td></tr>',
        )
        .join();
  }

  String _line(String label, dynamic value, {bool full = false}) =>
      '<div class="${full ? 'full' : ''}"><span class="label">${_text(label)}:</span> ${_text(value)}</div>';

  String _box(String label, dynamic value) =>
      '<div class="label" style="margin-top:7px">${_text(label)}</div><div class="box">${_text(value)}</div>';

  String _text(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return const HtmlEscape().convert(
      text.isEmpty ? '................................' : text,
    );
  }

  String _gender(dynamic value) => switch (value?.toString()) {
    'MALE' => 'Nam',
    'FEMALE' => 'Nữ',
    _ => value?.toString() ?? '',
  };

  String _role(String value) =>
      const {
        'MAIN_SURGEON': 'Bác sĩ chính',
        'ANESTHESIOLOGIST': 'Bác sĩ gây mê',
        'ASSISTANT_SURGEON': 'Phụ mổ',
        'SCRUB_NURSE': 'Điều dưỡng dụng cụ',
        'CIRCULATING_NURSE': 'Điều dưỡng vòng ngoài',
        'TECHNICIAN': 'Kỹ thuật viên',
        'OTHER': 'Khác',
      }[value] ??
      value;

  String _dateOnly(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '';
    return '${_two(date.day)}/${_two(date.month)}/${date.year}';
  }

  String _dateTime(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '';
    return '${_two(date.day)}/${_two(date.month)}/${date.year} ${_two(date.hour)}:${_two(date.minute)}';
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  String _number(num value) =>
      value == value.roundToDouble() ? '${value.round()}' : value.toString();

  String _money(dynamic value) {
    final amount = num.tryParse('${value ?? 0}')?.round() ?? 0;
    return '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')} đ';
  }
}
