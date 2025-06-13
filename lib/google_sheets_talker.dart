import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:intl/intl.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;


class Employee {
  final String forename;
  final String surname;
  String? lastSigningTime;
  List<String> signings = [];

  Employee({required this.forename, required this.surname});


  String getFullName() {
    return '${this.forename} ${this.surname}';
  }
}

class GoogleSheetsTalker {
  static const _scopes = ['https://www.googleapis.com/auth/spreadsheets'];
  static const _spreadsheetId = '15cVVDR83OxLY0WP_H2oamygbSX6MnAKyJyX_M37VPRk';
  static const _employeeSpreadSheetId = '1HU9r0InSuab5ydG1HPMG72uhgvfcZJbcDabw5MMApnM';
  static final String _currentSheet = getTodaysSheet();
  static const _employeeListSheetName = 'List';
  static const _range = 'Signings!A1';

  static String getTodaysSheet() {
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
  
  final Employee? employee;

  GoogleSheetsTalker() : employee = null;
  GoogleSheetsTalker.sign(this.employee);


  Future<String> getButtonText() async {
    String? signing;
    sheets.SheetsApi sheetsApi = await getSheetsApi();

    final response = await sheetsApi.spreadsheets.values.get(_spreadsheetId, _currentSheet,);

    if (response.values != null) {
      for (final row in response.values!) {
        if (row.isNotEmpty && row[0].toString() == employee!.getFullName()) {
          // Finds out if the user is signing in or out
          if (row.length % 2 == 0) {
            signing = "Sign Out";
          } else {
            signing = "Sign In";
          }
          employee?.signings = [];
          for (int i = 1; i < row.length; i++) {
            employee?.signings.add(row[i].toString());
          }
          break;
        }
      }
    }
    signing ??= "Could not find user on signings sheet";
    return signing;
  }


  List<Employee> processEmployeeList(List<dynamic>? employeesData) {
    if (employeesData == null || employeesData.isEmpty) {
      return [];
    }

    List<Employee> employees = [];
    for (var row in employeesData) {
      if (row.length < 2 || row[0] == '') {
        developer.log('Row does not contain enough data: $row');
        continue; // Skip rows that do not have at least two columns
      }
      // Extract forename and surname from the row
      String forename = row[0]?.toString() ?? '';
      String surname = row[1]?.toString() ?? '';
      Employee employee = Employee(
        forename: forename,
        surname: surname,
      );
      employees.add(employee);   
    }
    // Assuming the employee names are in the first column
    return employees;
  }


  // Retrieves the Google Sheets API client using service account credentials.
  Future<sheets.SheetsApi> getSheetsApi() async {
    final jsonStr = await rootBundle.loadString('assets/haj-reception.json');
    final credentials = ServiceAccountCredentials.fromJson(json.decode(jsonStr));
    final scopes = [sheets.SheetsApi.spreadsheetsScope];

    final httpClient = await clientViaServiceAccount(credentials, scopes);

    return sheets.SheetsApi(httpClient);
  }



  double getTimeAsFraction(String timeString) {
    // Parses a time string in the format "hh:mm" or "hh:mm AM/PM"
    final time = DateFormat('h:mm a').parse(timeString);
    // Converts the time to a fraction of a day
    return (time.hour + time.minute / 60 + time.second / 3600) / 24;
  }


  // Creates a new row for the Google Sheet with the given row data.
  // The row data is a list of strings, and the last cell will contain the current time.
  sheets.RowData getNewSigningsRow(List<dynamic> row) {
    sheets.RowData newRow = sheets.RowData(values: []);
    developer.log('Creating new signings row: $row');
    for (var cellValue in row.skip(1)) {
      double timeAsFraction = getTimeAsFraction(cellValue.toString());
      final cell = sheets.CellData.fromJson({
        'userEnteredValue': {'numberValue': timeAsFraction},
        'userEnteredFormat': {
          'numberFormat': {
            'type': 'TIME',
            'pattern': 'h:mm AM/PM',
          }
        }
      });
      newRow.values!.add(cell);
    }

    // Add new signing
    DateTime now = DateTime.now();
    String formattedTime = DateFormat('h:mm a').format(now);
    employee?.signings.add(formattedTime);
    double timeAsFraction = getTimeAsFraction(formattedTime.toString());
    final cell = sheets.CellData.fromJson({
      'userEnteredValue': {'numberValue': timeAsFraction},
      'userEnteredFormat': {
        'numberFormat': {
          'type': 'TIME',
          'pattern': 'h:mm AM/PM',
        }
      }
    });
    employee!.lastSigningTime = formattedTime.toString();
    developer.log('Signing time has been set: ${employee!.lastSigningTime!}');
    newRow.values!.add(cell);
    return newRow;
  }


  sheets.RowData getNewHeaders(List<String> headers) {
    sheets.RowData newHeaders = sheets.RowData(values: []);
    for (String header in headers) {
      newHeaders.values!.add(sheets.CellData.fromJson({
        'userEnteredValue': {'stringValue': header},
        'userEnteredFormat': {
          'textFormat': {'bold': true}
        }
      }));
    }

    newHeaders.values!.add(sheets.CellData.fromJson({
      'userEnteredValue': {'stringValue': 'In'},
      'userEnteredFormat': {
        'textFormat': {'bold': true}
      }
    }));

    newHeaders.values!.add(sheets.CellData.fromJson({
      'userEnteredValue': {'stringValue': 'Out'},
      'userEnteredFormat': {
        'textFormat': {'bold': true}
      }
    }));
    return newHeaders;
  }


  Future<List<dynamic>?> retrieveEmployees() async {
    final jsonStr = await rootBundle.loadString('assets/haj-reception.json');
    final serviceAccount = ServiceAccountCredentials.fromJson(json.decode(jsonStr));

    // Get authenticated HTTP client
    final client = await clientViaServiceAccount(serviceAccount, _scopes);

    // Make the API request
    final url = Uri.parse('https://sheets.googleapis.com/v4/spreadsheets/$_employeeSpreadSheetId/values/$_employeeListSheetName');

    final response = await client.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<dynamic>? employeesData = data['values'];
      developer.log('Data retrieved successfully: $employeesData');
      List<Employee> employees = processEmployeeList(employeesData);
      return employees;
    } else {
      developer.log('Error retrieving data: ${response.statusCode}');
      return null;
    }
  }


  // Writes the current time to the Google Sheet for the given user.
  Future<void> writeSigning() async {
    final jsonStr = await rootBundle.loadString('assets/haj-reception.json');
    final serviceAccount = ServiceAccountCredentials.fromJson(json.decode(jsonStr));

    // Get authenticated HTTP client
    final client = await clientViaServiceAccount(serviceAccount, _scopes);

    final urlGet = Uri.parse('https://sheets.googleapis.com/v4/spreadsheets/$_spreadsheetId/values/$_currentSheet');


    final response = await client.get(urlGet);
    List<dynamic>? signingsSheet;
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      signingsSheet = data['values'];
      developer.log('Data retrieved successfully: $signingsSheet');
    } else {
      developer.log('Error retrieving data: ${response.statusCode}');
      return;
    }

    // Check if the user is already in the sheet
    int userIndex = 0; // If userIndex is not found, it will remain 0
    for (List<dynamic> row in signingsSheet!) {
      if (row[0] == employee!.getFullName()) {
        developer.log('Found user ${employee!.getFullName()} in row: $row');
        userIndex = signingsSheet.indexOf(row);
        break;
      }
    }


    // Takes the signing sheet data and creates a new row with the current time.
    final signingsRow = getNewSigningsRow(signingsSheet[userIndex]);
    sheets.RowData newHeaders = sheets.RowData(values: []);
    List<String> headers = signingsSheet[0].cast<String>();
    
    // The + 1 includes the name in the row length
    if (signingsRow.values!.length + 1 > headers.length) {
      newHeaders = getNewHeaders(headers);
    }


    sheets.SheetsApi sheetsApi = await getSheetsApi();

    final spreadsheet = await sheetsApi.spreadsheets.get(_spreadsheetId);
    final sheet = spreadsheet.sheets?.firstWhere(
      (s) => s.properties?.title == _currentSheet,
    );
    final sheetId = sheet?.properties?.sheetId;

    // Build the request
    final signingRequest = sheets.BatchUpdateSpreadsheetRequest(
      requests: [
        sheets.Request(
          updateCells: sheets.UpdateCellsRequest(
            rows: [signingsRow],
            fields: 'userEnteredValue,userEnteredFormat',
            start: sheets.GridCoordinate(
              sheetId: sheetId,
              rowIndex: userIndex,
              columnIndex: 1, // Starting column is after the employee name
            ),
          ),
        ),
      ],
    );
    await sheetsApi.spreadsheets.batchUpdate(signingRequest, _spreadsheetId);

    // Build the request
    final headerRequest = sheets.BatchUpdateSpreadsheetRequest(
      requests: [
        sheets.Request(
          updateCells: sheets.UpdateCellsRequest(
            rows: [newHeaders],
            fields: 'userEnteredValue,userEnteredFormat',
            start: sheets.GridCoordinate(
              sheetId: sheetId,

              // Inserts the row at the top
              rowIndex: 0,
              columnIndex: 0,
            ),
          ),
        ),
      ],
    );
    await sheetsApi.spreadsheets.batchUpdate(headerRequest, _spreadsheetId);
  }
}