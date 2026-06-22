// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as web;

void openBillingCostStatement({
  required Map<String, dynamic> data,
  required String organizationName,
}) {
  final document = _BillingCostStatement(data, organizationName).build();
  final blob = web.Blob([document], 'text/html;charset=utf-8');
  final url = web.Url.createObjectUrlFromBlob(blob);
  web.window.open(url, '_blank');
  unawaited(
    Future<void>.delayed(
      const Duration(seconds: 15),
      () => web.Url.revokeObjectUrl(url),
    ),
  );
}

class _BillingCostStatement {
  _BillingCostStatement(this.data, this.fallbackOrganizationName);

  final Map<String, dynamic> data;
  final String fallbackOrganizationName;

  String build() {
    final documentTitle =
        data['documentTitle']?.toString() ??
        'Bảng kê chi phí khám bệnh, chữa bệnh';
    final items = _items();
    final groups = _groups(items);
    final total = _sum(items, 'amount');
    final insurancePaid = _sum(items, 'insurancePaid');
    final coPay = items
        .where((item) => _num(item['insurancePaid']) > 0)
        .fold<num>(0, (sum, item) => sum + _num(item['patientPaid']));
    final selfPay = items
        .where((item) => _num(item['insurancePaid']) <= 0)
        .fold<num>(0, (sum, item) => sum + _num(item['patientPaid']));
    final patientPaid = coPay + selfPay;
    final advancePaid = _num(data['advancePaid']);
    final refund = advancePaid > patientPaid ? advancePaid - patientPaid : 0;
    final mustPay = patientPaid > advancePaid ? patientPaid - advancePaid : 0;

    return '''
<!doctype html>
<html lang="vi">
<head>
  <meta charset="utf-8">
  <title>${_text(documentTitle)}</title>
  <style>
    @page { size: A4 portrait; margin: 9mm; }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: Arial, Helvetica, sans-serif;
      color: #111827;
      font-size: 10px;
      line-height: 1.25;
      background: #f3f4f6;
    }
    .toolbar {
      position: sticky;
      top: 0;
      z-index: 2;
      display: flex;
      justify-content: flex-end;
      gap: 8px;
      padding: 10px;
      background: #ffffff;
      border-bottom: 1px solid #d1d5db;
    }
    .toolbar button {
      border: 0;
      border-radius: 8px;
      padding: 9px 14px;
      background: #007A3D;
      color: #fff;
      font-weight: 700;
      cursor: pointer;
    }
    .page {
      width: 210mm;
      min-height: 297mm;
      margin: 0 auto;
      padding: 0;
      background: #ffffff;
    }
    .topline {
      display: grid;
      grid-template-columns: 1fr 1fr 130px;
      gap: 10px;
      align-items: start;
      margin-bottom: 4px;
    }
    .agency { text-align: center; font-weight: 700; text-transform: uppercase; }
    .form-code { text-align: right; font-weight: 700; }
    h1 {
      margin: 2px 0 6px;
      text-align: center;
      font-size: 15px;
      text-transform: uppercase;
    }
    h2 {
      margin: 8px 0 5px;
      font-size: 11px;
      text-transform: uppercase;
    }
    .grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      column-gap: 12px;
      row-gap: 3px;
    }
    .full { grid-column: 1 / -1; }
    .line span { font-weight: 700; }
    table {
      width: 100%;
      border-collapse: collapse;
      table-layout: fixed;
      font-size: 8px;
      margin-top: 5px;
    }
    th, td {
      border: 1px solid #111827;
      padding: 2px 3px;
      vertical-align: top;
      word-wrap: break-word;
    }
    th { text-align: center; font-weight: 700; }
    td.num { text-align: right; white-space: nowrap; }
    td.center { text-align: center; }
    tr.group td {
      font-weight: 700;
      background: #f3f4f6;
    }
    tr.total td {
      font-weight: 700;
      background: #e5f4eb;
    }
    .summary {
      margin-top: 8px;
      display: grid;
      grid-template-columns: 1.4fr 0.8fr 0.8fr;
      gap: 4px 8px;
      font-size: 10px;
    }
    .summary .label { text-align: right; font-weight: 700; }
    .summary .money { text-align: right; font-weight: 700; }
    .in-words {
      margin-top: 6px;
      font-style: italic;
      font-weight: 700;
    }
    .deposits {
      margin-top: 6px;
      border: 1px solid #111827;
      padding: 4px;
      min-height: 28px;
    }
    .signatures {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 8px;
      margin-top: 16px;
      text-align: center;
      font-size: 10px;
    }
    .signatures div { min-height: 70px; }
    .sign-title { font-weight: 700; text-transform: uppercase; }
    .muted { color: #4b5563; }
    @media print {
      body { background: #fff; }
      .toolbar { display: none; }
      .page { width: auto; min-height: auto; }
    }
  </style>
</head>
<body>
  <div class="toolbar">
    <button onclick="window.print()">In / Lưu PDF</button>
  </div>
  <main class="page">
    <section class="topline">
      <div class="agency">SỞ Y TẾ<br>${_text(_healthDepartment())}</div>
      <div></div>
      <div class="form-code">Mẫu số: 01/KBCB</div>
    </section>
    <h1>${_text(documentTitle)}</h1>
    <h2>I. Phần hành chính</h2>
    <section class="grid">
      <div class="line">(1) Họ tên người bệnh: <span>${_text(data['patient'])}</span></div>
      <div class="line">Ngày sinh: <span>${_text(data['patientDob'])}</span> &nbsp; Giới tính: <span>${_gender(data['patientGender'])}</span></div>
      <div class="line full">(2) Địa chỉ hiện tại: <span>${_text(data['patientAddress'])}</span></div>
      <div class="line">(4) Mã thẻ BHYT: <span>${_text(data['insuranceNo'])}</span></div>
      <div class="line">Mức hưởng: <span>${_benefitPercent(items)}%</span></div>
      <div class="line">(6) Mã số người bệnh: <span>${_text(data['patientCode'])}</span></div>
      <div class="line">Số hồ sơ/lượt khám: <span>${_text(data['encounterCode'])}</span></div>
      <div class="line">(7) Đến khám: <span>${_text(data['treatmentFrom'])}</span></div>
      <div class="line">(9) Kết thúc khám/điều trị: <span>${_text(data['treatmentTo'])}</span></div>
      <div class="line">Khoa: <span>${_text(data['department'])}</span></div>
      <div class="line">Bác sĩ: <span>${_text(data['doctor'])}</span></div>
      <div class="line full">(15) Chẩn đoán xác định: <span>${_text(data['diagnosis'])}</span></div>
    </section>

    <h2>II. Phần chi phí khám bệnh, chữa bệnh</h2>
    <div class="line">Mã thẻ BHYT: <span>${_text(data['insuranceNo'])}</span> &nbsp; Chi phí KBCB tính từ ngày <span>${_text(data['treatmentFrom'])}</span> đến ngày <span>${_text(data['treatmentTo'])}</span></div>
    <table>
      <colgroup>
        <col style="width: 24px">
        <col style="width: 185px">
        <col style="width: 42px">
        <col style="width: 34px">
        <col style="width: 52px">
        <col style="width: 52px">
        <col style="width: 36px">
        <col style="width: 36px">
        <col style="width: 58px">
        <col style="width: 58px">
        <col style="width: 58px">
        <col style="width: 58px">
        <col style="width: 58px">
        <col style="width: 44px">
      </colgroup>
      <thead>
        <tr>
          <th>STT</th>
          <th>Nội dung</th>
          <th>Đơn vị tính</th>
          <th>Số lượng</th>
          <th>Đơn giá BV<br>(đồng)</th>
          <th>Đơn giá BH<br>(đồng)</th>
          <th>Tỷ lệ TT<br>DV (%)</th>
          <th>Tỷ lệ TT<br>BHYT (%)</th>
          <th>Thành tiền BV<br>(đồng)</th>
          <th>Thành tiền BH<br>(đồng)</th>
          <th>Quỹ BHYT</th>
          <th>NB cùng chi trả</th>
          <th>NB tự trả</th>
          <th>Khác</th>
        </tr>
      </thead>
      <tbody>
        ${_tableRows(groups)}
        <tr class="total">
          <td></td>
          <td>Tổng cộng</td>
          <td></td>
          <td></td>
          <td></td>
          <td></td>
          <td></td>
          <td></td>
          <td class="num">${_money(total)}</td>
          <td class="num">${_money(_coveredAmount(items))}</td>
          <td class="num">${_money(insurancePaid)}</td>
          <td class="num">${_money(coPay)}</td>
          <td class="num">${_money(selfPay)}</td>
          <td class="num">0</td>
        </tr>
      </tbody>
    </table>

    <section class="summary">
      <div></div><div class="label">Tổng chi phí lần khám bệnh/cả đợt điều trị:</div><div class="money">${_money(total)} đồng</div>
      <div></div><div class="label">- Quỹ BHYT thanh toán theo giá dịch vụ y tế:</div><div class="money">${_money(insurancePaid)} đồng</div>
      <div></div><div class="label">- Người bệnh trả, trong đó:</div><div class="money">${_money(patientPaid)} đồng</div>
      <div></div><div class="label">+ Cùng chi trả trong phạm vi BHYT:</div><div class="money">${_money(coPay)} đồng</div>
      <div></div><div class="label">+ Các khoản phải trả khác:</div><div class="money">${_money(selfPay)} đồng</div>
      <div></div><div class="label">- Tổng tạm ứng:</div><div class="money">${_money(advancePaid)} đồng</div>
      <div></div><div class="label">- Số tiền người bệnh còn phải nộp:</div><div class="money">${_money(mustPay)} đồng</div>
      <div></div><div class="label">- Số tiền hoàn lại BN:</div><div class="money">${_money(refund)} đồng</div>
    </section>
    <div class="in-words">(Viết bằng chữ: ${_capitalize(_numberToVietnamese(total.round()))} đồng)</div>
    <div class="deposits">
      <strong>Thông tin tạm ứng:</strong>
      <span class="muted">Chưa có dữ liệu chi tiết phiếu tạm ứng. Tổng tạm ứng hiện ghi nhận: ${_money(advancePaid)} đồng.</span>
    </div>
    <div style="text-align:right;margin-top:8px;">Ngày ..... tháng ..... năm ......</div>
    <section class="signatures">
      <div><div class="sign-title">Người lập bảng kê</div><div>(ký, ghi rõ họ tên)</div></div>
      <div><div class="sign-title">Kế toán viện phí</div><div>(ký, ghi rõ họ tên)</div></div>
      <div><div class="sign-title">Giám định BHYT</div><div>(ký, ghi rõ họ tên)</div></div>
      <div><div class="sign-title">Xác nhận của người bệnh</div><div>(ký, ghi rõ họ tên)</div></div>
    </section>
  </main>
  <script>
    window.addEventListener('load', function () {
      setTimeout(function () { window.print(); }, 300);
    });
  </script>
</body>
</html>
''';
  }

  List<Map<String, dynamic>> _items() {
    final raw = data['items'];
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<_BillingGroup> _groups(List<Map<String, dynamic>> items) {
    final order = <String>[
      'EXAM_FEE',
      'BED',
      'LAB',
      'IMAGING',
      'SERVICE',
      'MEDICINE',
      'SUPPLY',
      'OTHER',
    ];
    final byKey = <String, _BillingGroup>{};
    for (final item in items) {
      final key = _groupKey(item['itemType']);
      byKey
          .putIfAbsent(key, () => _BillingGroup(key, _groupTitle(key)))
          .items
          .add(item);
    }
    return order.where(byKey.containsKey).map((key) => byKey[key]!).toList();
  }

  String _tableRows(List<_BillingGroup> groups) {
    final rows = <String>[];
    for (var groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      final group = groups[groupIndex];
      final amount = _sum(group.items, 'amount');
      final covered = _coveredAmount(group.items);
      final insurance = _sum(group.items, 'insurancePaid');
      final coPay = group.items
          .where((item) => _num(item['insurancePaid']) > 0)
          .fold<num>(0, (sum, item) => sum + _num(item['patientPaid']));
      final selfPay = group.items
          .where((item) => _num(item['insurancePaid']) <= 0)
          .fold<num>(0, (sum, item) => sum + _num(item['patientPaid']));
      rows.add('''
        <tr class="group">
          <td>${groupIndex + 1}</td>
          <td>${_text(group.title)}</td>
          <td></td><td></td><td></td><td></td><td></td><td></td>
          <td class="num">${_money(amount)}</td>
          <td class="num">${_money(covered)}</td>
          <td class="num">${_money(insurance)}</td>
          <td class="num">${_money(coPay)}</td>
          <td class="num">${_money(selfPay)}</td>
          <td class="num">0</td>
        </tr>
      ''');
      for (var itemIndex = 0; itemIndex < group.items.length; itemIndex++) {
        final item = group.items[itemIndex];
        final insurance = _num(item['insurancePaid']);
        final patient = _num(item['patientPaid']);
        final insurancePercent = _num(item['insurancePercent']).round();
        rows.add('''
          <tr>
            <td class="center">${itemIndex + 1}</td>
            <td>${_text(item['itemName'])}</td>
            <td class="center">${_text(item['unit'] ?? 'Lần')}</td>
            <td class="num">${_quantity(item['quantity'])}</td>
            <td class="num">${_money(item['unitPrice'])}</td>
            <td class="num">${insurancePercent > 0 ? _money(item['unitPrice']) : '0'}</td>
            <td class="center">100</td>
            <td class="center">$insurancePercent</td>
            <td class="num">${_money(item['amount'])}</td>
            <td class="num">${insurancePercent > 0 ? _money(item['amount']) : '0'}</td>
            <td class="num">${_money(insurance)}</td>
            <td class="num">${insurance > 0 ? _money(patient) : '0'}</td>
            <td class="num">${insurance <= 0 ? _money(patient) : '0'}</td>
            <td class="num">0</td>
          </tr>
        ''');
      }
    }
    return rows.join();
  }

  String _groupKey(dynamic type) {
    switch (type?.toString()) {
      case 'EXAM_FEE':
        return 'EXAM_FEE';
      case 'BED':
      case 'BED_FEE':
        return 'BED';
      case 'LAB':
      case 'LAB_SERVICE':
        return 'LAB';
      case 'IMAGING':
      case 'IMAGING_SERVICE':
        return 'IMAGING';
      case 'SERVICE':
      case 'TECHNICAL_SERVICE':
        return 'SERVICE';
      case 'MEDICINE':
      case 'PRESCRIPTION':
        return 'MEDICINE';
      case 'SUPPLY':
        return 'SUPPLY';
      default:
        return 'OTHER';
    }
  }

  String _groupTitle(String key) {
    switch (key) {
      case 'EXAM_FEE':
        return 'Khám bệnh';
      case 'BED':
        return 'Ngày giường';
      case 'LAB':
        return 'Xét nghiệm';
      case 'IMAGING':
        return 'Chẩn đoán hình ảnh';
      case 'SERVICE':
        return 'Thăm dò chức năng / dịch vụ kỹ thuật';
      case 'MEDICINE':
        return 'Thuốc, dịch truyền';
      case 'SUPPLY':
        return 'Vật tư y tế';
      default:
        return 'Chi phí khác';
    }
  }

  String _healthDepartment() {
    final organization = data['organizationName']?.toString().trim();
    final fallback = fallbackOrganizationName.trim();
    final name = organization?.isNotEmpty == true ? organization! : fallback;
    return name.isEmpty ? 'BỆNH VIỆN' : name.toUpperCase();
  }

  String _gender(dynamic value) {
    switch (value?.toString()) {
      case 'MALE':
        return 'Nam';
      case 'FEMALE':
        return 'Nữ';
      default:
        return _text(value);
    }
  }

  int _benefitPercent(List<Map<String, dynamic>> items) {
    final values = items
        .map((item) => _num(item['insurancePercent']).round())
        .where((value) => value > 0)
        .toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a > b ? a : b);
  }

  num _coveredAmount(List<Map<String, dynamic>> items) {
    return items
        .where((item) => _num(item['insurancePaid']) > 0)
        .fold<num>(0, (sum, item) => sum + _num(item['amount']));
  }

  num _sum(List<Map<String, dynamic>> items, String key) {
    return items.fold<num>(0, (sum, item) => sum + _num(item[key]));
  }

  num _num(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    return num.tryParse(value.toString().replaceAll(RegExp(r'[^0-9.-]'), '')) ??
        0;
  }

  String _money(dynamic value) {
    final number = _num(value);
    final rounded = number.round();
    return rounded.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  String _quantity(dynamic value) {
    final number = _num(value);
    if (number == number.roundToDouble()) return number.round().toString();
    return number
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String _text(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return const HtmlEscape().convert(
      text.isEmpty ? '................................' : text,
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  String _numberToVietnamese(int value) {
    if (value == 0) return 'không';
    final units = ['', 'nghìn', 'triệu', 'tỷ', 'nghìn tỷ', 'triệu tỷ'];
    final parts = <String>[];
    var number = value;
    var unitIndex = 0;
    while (number > 0 && unitIndex < units.length) {
      final block = number % 1000;
      if (block > 0) {
        parts.insert(
          0,
          '${_readThreeDigits(block, number >= 1000)} ${units[unitIndex]}'
              .trim(),
        );
      }
      number ~/= 1000;
      unitIndex += 1;
    }
    return parts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _readThreeDigits(int value, bool full) {
    const digits = [
      'không',
      'một',
      'hai',
      'ba',
      'bốn',
      'năm',
      'sáu',
      'bảy',
      'tám',
      'chín',
    ];
    final hundred = value ~/ 100;
    final ten = (value % 100) ~/ 10;
    final unit = value % 10;
    final words = <String>[];
    if (hundred > 0 || full) {
      words.add('${digits[hundred]} trăm');
    }
    if (ten > 1) {
      words.add('${digits[ten]} mươi');
      if (unit == 1) {
        words.add('mốt');
      } else if (unit == 5) {
        words.add('lăm');
      } else if (unit > 0) {
        words.add(digits[unit]);
      }
    } else if (ten == 1) {
      words.add('mười');
      if (unit == 5) {
        words.add('lăm');
      } else if (unit > 0) {
        words.add(digits[unit]);
      }
    } else if (unit > 0) {
      if (hundred > 0 || full) words.add('lẻ');
      words.add(digits[unit]);
    }
    return words.join(' ');
  }
}

class _BillingGroup {
  _BillingGroup(this.key, this.title);

  final String key;
  final String title;
  final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
}
