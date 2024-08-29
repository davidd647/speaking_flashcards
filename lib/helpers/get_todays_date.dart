import 'package:intl/intl.dart'; // has the DateFormat class

String getTodaysDate() {
  var now = DateTime.now();
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  return formatter.format(now);
}
