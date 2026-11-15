import 'package:intl/intl.dart';

String formatDate(DateTime date, {String locale = 'en_IN'}) =>
    DateFormat('d MMM yyyy', locale).format(date);

String formatMonthLabel(DateTime date, {String locale = 'en_IN'}) =>
    DateFormat('MMMM yyyy', locale).format(date);

String formatDateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

String formatMonthKey(DateTime date) => DateFormat('yyyy-MM').format(date);

String formatTime24h(DateTime date) => DateFormat('HH:mm').format(date);
