import 'package:intl/intl.dart';

extension MyDateFormat on DateFormat {
  String formatLocal(DateTime date) {
    return format(date.toLocal());
  }
}