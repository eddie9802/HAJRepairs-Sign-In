import 'package:intl/intl.dart';




// Gets the timesheet name for the week
String getTimesheetName() {
  var today = DateTime.now();
  var dayOfWeek = today.weekday; // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
  var daysUntilSunday = (7 - dayOfWeek) % 7;

  // If today is Sunday, treat it as the end of this week
  if (daysUntilSunday == 0) {
    daysUntilSunday = 7;
  }

  var nextSunday = today.add(Duration(days: daysUntilSunday));

  DateFormat formatter = DateFormat('dd/MM/yyyy');
  final String formatted = formatter.format(nextSunday);

  print("Week_ending_on_$formatted.xlsx");

  return "Week_ending_on_$formatted.xlsx";
}


// Returns the day of the week as a string depending on the day of the week
String getTodaysSheet() {
  DateTime now = DateTime.now();
  int weekday = now.weekday;

  const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];


  return days[weekday - 1];
}