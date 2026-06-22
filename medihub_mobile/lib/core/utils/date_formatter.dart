class DateFormatter {
  const DateFormatter._();

  static String displayDate(dynamic value, {String separator = '-'}) {
    if (value == null) return '';

    final raw = value.toString();
    if (raw.isEmpty) return '';

    final date = DateTime.tryParse(raw);
    if (date == null) return raw;

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day$separator$month$separator${date.year}';
  }
}
