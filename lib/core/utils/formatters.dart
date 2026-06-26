import 'package:intl/intl.dart';

class Formatters {
  static String money(num value) {
    return 'L ${NumberFormat('#,##0.00', 'es_HN').format(value)}';
  }

  static String date(DateTime value) {
    return DateFormat('dd/MM/yyyy').format(value);
  }

  static String time(DateTime value) {
    return DateFormat('HH:mm').format(value);
  }

  static String dateTime(DateTime value) {
    return DateFormat('dd/MM/yyyy HH:mm').format(value);
  }
}