import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import 'secrets/secret_manager.dart';
import 'haj_response.dart';



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


  double? toDoubleSafe(dynamic value) {
  if (value == null) return null;

  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value);
  }

  return null; // Not convertible
}



bool isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}


DateTime excelDateToDateTime(num excelSerial) {
  // Excel uses 1899-12-30 as the zero date (not 1900-01-01)
  return DateTime(1899, 12, 30).add(Duration(days: excelSerial.floor()));
}



String formatDateMDY(DateTime date) {
  return "${date.month}/${date.day}/${date.year}";
}

String formatDateDMY(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return "$day/$month/$year";
}



// Gets the file ID from the name of the given file and directory path
Future<HAJResponse> getFileId(String fileName, List<String> pathSegments, String accessToken) async {
  final encodedSegments = pathSegments.map(Uri.encodeComponent).join('/');
  final url = Uri.parse(
    'https://graph.microsoft.com/v1.0/drives/$_driveId/root:/$encodedSegments:/children'
  );

  try {
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      return HAJResponse(statusCode: response.statusCode, message: 'Error fetching folder contents.');
    }

    final Map<String, dynamic> json = jsonDecode(response.body);

    if (json['value'] == null || json['value'] is! List) {
      return HAJResponse(statusCode: 500, message: 'Unexpected response format.');
    }

    final List<dynamic> items = json['value'];

    for (var item in items) {
      if (item['name'] == fileName) {
        return HAJResponse(statusCode: 200, message: 'Success', body: item['id']);
      }
    }

    return HAJResponse(statusCode: 404, message: 'File not found.');
  } on SocketException {
    return HAJResponse(statusCode: 504, message: 'Failed to connect to the server. Please check your internet connection.');
  } catch (e) {
    return HAJResponse(statusCode: 500, message: 'An error occurred while retrieving the file ID.');
  }
}




  // Reads the spreadsheet denoted by fileId, at the sheet dentoed by worksheetId
  Future<HAJResponse> readSpreadsheet(String fileId, String worksheetId, String accessToken) async {
    // Sends a http request to read the spreadsheet
    final url = Uri.parse(
      'https://graph.microsoft.com/v1.0/drives/$_driveId/items/$fileId/workbook/worksheets/$worksheetId/usedRange(valuesOnly=true)'
    );


    try {
    final httpRes = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
      },
    );

    if (httpRes.statusCode != 200) {
      return HAJResponse(statusCode: httpRes.statusCode, message: 'Error fetching Excel data.');
    }

    final Map<String, dynamic> spreadsheetJson = jsonDecode(httpRes.body);
    final List<dynamic>? values = spreadsheetJson['values'];

    if (values == null || values.isEmpty) {
      return HAJResponse(statusCode: 404, message: 'No data found in worksheet $worksheetId');
    }

    return HAJResponse(statusCode: 200, message: 'Success', body: values);

    } on SocketException {
      print('Failed to connect to the server. Please check your internet connection.');
      return HAJResponse(statusCode: 504, message: 'Failed to connect to the server.');
    } catch (e) {
      print('An error occurred while reading the spreadsheet: $e');
      return HAJResponse(statusCode: 500, message: 'An error occurred while reading the spreadsheet.');
    }
  }



String excelFractionToTimeAmPm(double fraction) {
  final totalSeconds = (fraction * 24 * 60 * 60).round();
  final now = DateTime.now();
  final time = DateTime(now.year, now.month, now.day).add(Duration(seconds: totalSeconds));
  
  return DateFormat('h:mm a').format(time); // e.g. "12:42 PM"
}


Future<HAJResponse> appendRowToTable({
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

  try {
    final httpRes = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    return HAJResponse(statusCode: httpRes.statusCode, message: httpRes.body);

  } on SocketException {
    print('Failed to connect to the server. Please check your internet connection.');
    return HAJResponse(statusCode: 504, message: 'Failed to connect to the server.');
  } catch (e) {
    print('An error occurred while appending row to table: $e');
    return HAJResponse(statusCode: 500, message: 'An error occurred while appending row to table.');
  }
}




Future<String?> getRowIdByNumber({
  required String fileId,
  required String tableName,
  required int rowNumber,
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


  if (rows[rowNumber]['values'] == null || rows[rowNumber]['values'].isEmpty) {
    print('Row $rowNumber is empty or does not exist.');
    return null;

  } else {
    // row['values'] is a list of lists, each inner list is a row of cell values
    print(rows[rowNumber]);
    return rows[rowNumber]['@odata.id'];
  }
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



  Future<HAJResponse> deleteTableRow({
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


  try {
    final httpRes = await http.delete(
      deleteUrl,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );


    if (httpRes.statusCode == 204) {
      return HAJResponse(statusCode: 204, message: 'Row deleted successfully');
    } else {
      return HAJResponse(statusCode: httpRes.statusCode, message: 'Failed to delete row: ${httpRes.body}');
    }

    } on SocketException {
      return HAJResponse(statusCode: 504, message: 'Failed to connect to the server.  Please check your internet connection.');
    } catch (e) {
      return HAJResponse(statusCode: 500, message: 'An error occurred while writing to the spreadsheet.');
    }
}






    // Writes to the spreadsheet denoted by fileId and the sheet denoted by worksheetId
  Future<HAJResponse> writeRowToSpreadsheet(String fileId, String worksheetId, String accessToken,List<String> row, String range) async {

    // Sends a http request to read the spreadsheet
    final url = Uri.parse(
      'https://graph.microsoft.com/v1.0/drives/$_driveId/items/$fileId/workbook/worksheets/$worksheetId/range(address=\'$range\')'
    );


    final body = jsonEncode({
      'values': [row],  // single row, so 2D array with one inner array
    });

    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: body
      );

      return HAJResponse(statusCode: response.statusCode, message: 'Successfully wrote to spreadsheet');
    } on SocketException {
      return HAJResponse(statusCode: 504, message: 'Failed to connect to the server.  Please check your internet connection.');
    } catch (e) {
      return HAJResponse(statusCode: 500, message: 'An error occurred while writing to the spreadsheet.');
    }
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



  Future<HAJResponse?> authenticateWithClientSecret() async {
    final tokenEndpoint = 'https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token';
    final secretManager = await SecretManager.create();


    HAJResponse? response;
    dynamic httpRes;
    try {
      httpRes = await http.post(
        Uri.parse(tokenEndpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client_id': clientId,
          'scope': 'https://graph.microsoft.com/.default',
          'client_secret': await secretManager.getDecryptedSecret(),
          'grant_type': 'client_credentials',
        },
      );


      final msg = httpRes.body ?? "Unexpected error: No response body";

      Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = jsonDecode(msg);
      } catch (e) {
        return HAJResponse(
          statusCode: httpRes.statusCode,
          message: 'Invalid JSON from token endpoint.',
        );
      }

      if (httpRes.statusCode == 200) {
        return response = HAJResponse(statusCode: httpRes.statusCode, message: "Success", body: jsonResponse['access_token'] as String?);
      } else {
        return response = HAJResponse(statusCode: httpRes.statusCode, message: jsonResponse['error_description'] ?? 'Unknown error');
      }


    } on SocketException {
      response = HAJResponse(statusCode: 504, message: 'Failed to connect to the server.  Please check your internet connection.');
    } catch (e) {
        final status = httpRes?.statusCode ?? 500;
        final msg = httpRes?.body ?? 'Unexpected error: $e';
        response = HAJResponse(statusCode: status, message: msg);
    }

    return response;
  }