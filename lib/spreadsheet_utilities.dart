import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import '../secret_manager.dart';



final String _driveId = "b!9fsUyKGke0y1U3QDUBNiD0pi50qUMWlEob3HI9NOb-Zyp0whTvCySa-hJq1U89Sd";
final String clientId = '5a2d0943-6c4b-469f-ad01-3b7f33f06e81';




class TimesheetDetails {
  String name;
  DateTime date;
  String? month;
  String? year;

  TimesheetDetails({required this.name, required this.date});

  // Gets a month string from the month number
  String getMonthName() {
    int month = date.month;
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    if (month < 1 || month > 12) {
      throw ArgumentError('Month must be between 1 and 12');
    }

    return monthNames[month - 1];
  }
}



  // Reads the spreadsheet denoted by fileId, at the sheet dentoed by worksheetId
  Future<List<dynamic>?> readSpreadsheet(String fileId, String worksheetId, String accessToken) async {
    // Sends a http request to read the spreadsheet
    final url = Uri.parse(
      'https://graph.microsoft.com/v1.0/drives/$_driveId/items/$fileId/workbook/worksheets/$worksheetId/usedRange(valuesOnly=true)'
    );


    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
      },
    );

    if (response.statusCode != 200) {
      print('Error fetching Excel data: ${response.statusCode}');
      return null;
    }

    final Map<String, dynamic> spreadsheetJson = jsonDecode(response.body);
    final List<dynamic>? values = spreadsheetJson['values'];

    return values;
  }



    // Writes to the spreadsheet denoted by fileId and the sheet denoted by worksheetId
  Future<bool> writeRowToSpreadsheet(String fileId, String worksheetId, String accessToken,List<String> row, String range) async {

    // Sends a http request to read the spreadsheet
    final url = Uri.parse(
      'https://graph.microsoft.com/v1.0/drives/$_driveId/items/$fileId/workbook/worksheets/$worksheetId/range(address=\'$range\')'
    );


    final body = jsonEncode({
      'values': [row],  // single row, so 2D array with one inner array
    });


    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body
    );

    return response.statusCode == 200;
  }



// Gets the timesheet name for the week
TimesheetDetails getTimesheetDetails() {
  var today = DateTime.now();
  var dayOfWeek = today.weekday; // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
  var daysUntilSunday = (7 - dayOfWeek) % 7;

  // If today is Sunday, treat it as the end of this week
  if (daysUntilSunday == 0) {
    daysUntilSunday = 7;
  }

  var nextSunday = today.add(Duration(days: daysUntilSunday));

  DateFormat formatter = DateFormat('dd-MM-yyyy');
  final String formatted = formatter.format(nextSunday);

  TimesheetDetails timesheet = TimesheetDetails(name: "Week_ending_on_$formatted.xlsx", date: nextSunday);


  return timesheet;
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



  Future<String?> authenticateWithClientSecret() async {
    final tokenEndpoint = 'https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token';
    final secretManager = await SecretManager.create();
    await secretManager.loadAndEncrypt();

    print('This is the client secret: ${secretManager.getDecryptedSecret()}');

    final response = await http.post(
      Uri.parse(tokenEndpoint),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'client_id': clientId,
        'scope': 'https://graph.microsoft.com/.default',
        'client_secret': secretManager.getDecryptedSecret(),
        'grant_type': 'client_credentials',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse['access_token'] as String?;
    } else {
      print('Failed to get token: ${response.statusCode} - ${response.body}');
      return null;
    }
  }