import 'package:intl/intl.dart';

String formatCurrency(num amount) {
  final fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return fmt.format(amount);
}

String formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '-';
  try {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  } catch (_) {
    return dateStr;
  }
}

String formatDateTime(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '-';
  try {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(date);
  } catch (_) {
    return dateStr;
  }
}

String namaBulan(int bulan) {
  const bulanNames = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];
  if (bulan >= 1 && bulan <= 12) return bulanNames[bulan];
  return '';
}
