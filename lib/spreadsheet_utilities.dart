import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import '../secret_manager.dart';



final String _driveId = "b!9fsUyKGke0y1U3QDUBNiD0pi50qUMWlEob3HI9NOb-Zyp0whTvCySa-hJq1U89Sd";
final String clientId = '5a2d0943-6c4b-469f-ad01-3b7f33f06e81';
final String tenantId = 'dd11dc3e-0fa8-4004-9803-70a802de0faf';


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




  // Gets the fileID from the name of the given file and directory path
  Future<String?> getFileId(String fileName, List<String> pathSegments, String accessToken) async {
    final encodedSegments = pathSegments.map(Uri.encodeComponent).join('/');

    final url = Uri.parse(
      'https://graph.microsoft.com/v1.0/drives/$_driveId/root:/$encodedSegments:/children'
    );


    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      print('Error fetching Excel data: ${response.statusCode}');
      return null;
    }

    final Map<String, dynamic> json = jsonDecode(response.body);

    if (json['value'] == null || json['value'] is! List) {
      print('Unexpected response format: ${response.body}');
      return null;
    }

    final List<dynamic> items = json['value'];



    for(var item in items) {
      if (item['name'] == fileName) {
        return item['id'];
      }
    }
    
    return null;
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



String excelFractionToTimeAmPm(double fraction) {
  final totalSeconds = (fraction * 24 * 60 * 60).round();
  final now = DateTime.now();
  final time = DateTime(now.year, now.month, now.day).add(Duration(seconds: totalSeconds));
  
  return DateFormat('h:mm a').format(time); // e.g. "12:42 PM"
}


Future<bool> appendRowToTable({
  required String fileId,
  required String tableId, // e.g., "Table1"
  required String accessToken,
  required List<String> row,
}) async {
  
  final url = Uri.parse(
    'https://graph.microsoft.com/v1.0/drives/$_driveId/items/$fileId/workbook/tables/$tableId/rows/add'
  );

  final body = jsonEncode({
    'values': [row], // must be a 2D array
  });

  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
    body: body,
  );


  return response.statusCode == 201;
}



 Future<String?> getRowId({
  required String fileId,
  required String tableName,
  required String identifier,
  required String accessToken,
}) async {
  final rowsUrl = Uri.parse(
    'https://graph.microsoft.com/v1.0/drives/$_driveId/items/$fileId/workbook/tables/$tableName/rows'
  );

  final rowsResponse = await http.get(
    rowsUrl,
    headers: {
      'Authorization': 'Bearer $accessToken',
    },
  );

  if (rowsResponse.statusCode != 200) {
    print('Failed to fetch rows: ${rowsResponse.statusCode}');
    return null;
  }

  final rowsJson = jsonDecode(rowsResponse.body);
  final List<dynamic> rows = rowsJson['value'];

  for (var row in rows) {
    // row['values'] is a list of lists, each inner list is a row of cell values
    if (row['values'][0][0] == identifier) {
      print(row);
      return row['@odata.id'];
    }
  }

  print('No matching row found for: $identifier');
  return null;
}



  Future<bool> deleteTableRow({
  required String fileId,
  required String tableName,
  required String rowId,
  required String accessToken,
}) async {

  final String odataId = rowId; // e.g. "/drives('driveId')/items('fileId')/workbook/tables('{guid}')/rows/itemAt(index=0)"

  // The API expects the DELETE to be called at the full path after /workbook, so build URL accordingly:
  final deleteUrl = Uri.parse(
    'https://graph.microsoft.com/v1.0$odataId'
  );

  final deleteResponse = await http.delete(
    deleteUrl,
    headers: {
      'Authorization': 'Bearer $accessToken',
    },
  );

  return deleteResponse.statusCode == 204;
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