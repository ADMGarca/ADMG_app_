import 'package:intl/intl.dart';

String formatarData(String data) {
  try {
    final dateTime = DateTime.parse(data);
    final format = DateFormat('dd/MM/yyyy HH:mm');
    return format.format(dateTime);
  } catch (e) {
    return data;
  }
}