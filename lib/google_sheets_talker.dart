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
    return '$forename $surname';
  }
}

class GoogleSheetsTalker {
  static const _spreadsheetId = '15cVVDR83OxLY0WP_H2oamygbSX6MnAKyJyX_M37VPRk';
  static final String _currentSheetId = getTodaysSheet();
  static final String _employeeSheetId = "1HU9r0InSuab5ydG1HPMG72uhgvfcZJbcDabw5MMApnM";


  // Returns the day of the week as a string depending on the day of the week
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

    final response = await sheetsApi.spreadsheets.values.get(_spreadsheetId, _currentSheetId,);

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
  sheets.RowData getNewSigningsRow(List<String>? row) {
    sheets.RowData newRow = sheets.RowData(values: []);
    developer.log('Creating new signings row: $row');
    for (var cellValue in row!) {
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



  // Returns a list of all the employees
  Future<List<dynamic>?> retrieveEmployees() async {
    final range = "A:B"; // Reads all the values in columns A and B
    sheets.SheetsApi sheetsApi = await getSheetsApi();
    final response = await sheetsApi.spreadsheets.values.get(_employeeSheetId, range);
    final values = response.values;
    final allEmployees = [];
    if (values == null || values.isEmpty) {
      developer.log("No employees found");
    } else {

      // .skip(1) skips the header row
      for (var row in values.skip(1)) {
        String forename = row[0].toString();
        String surname = row[1].toString();
        allEmployees.add(Employee(forename: forename, surname: surname));
      }
    }
    return allEmployees;
  }


  // Creates the spreadsheet requests
  List<dynamic> getSpreadsheetRequests(List<dynamic> allRowUpdateDetails, int? sheetId) {
    final allUpdateRequests = [];
    for(var rowDetails in allRowUpdateDetails){
      final request = sheets.BatchUpdateSpreadsheetRequest(
        requests: [
          sheets.Request(
            updateCells: sheets.UpdateCellsRequest(
              rows: [rowDetails.data],
              fields: 'userEnteredValue,userEnteredFormat',
              start: sheets.GridCoordinate(
                sheetId: sheetId,

                // Inserts the row at the top
                rowIndex: rowDetails.row,
                columnIndex: rowDetails.col,
              ),
            ),
          ),
        ],
      );
      allUpdateRequests.add(request);
    }
    return allUpdateRequests;
  }


  // Writes the current time to the Google Sheet for the given user.
  Future<void> writeSigning() async {

    // Reads the whole signings sheet
    sheets.SheetsApi sheetsApi = await getSheetsApi();
    final response = await sheetsApi.spreadsheets.values.get(_spreadsheetId, _currentSheetId);
    final signingsSheet = response.values;
    if (signingsSheet == null || signingsSheet.isEmpty) {
      developer.log('Error retrieving data');
      return;
    } else {
      developer.log('Data retrieved successfully: $signingsSheet');
    }

    // Check if the user is already in the sheet
    int userIndex = -1; // If userIndex is not found, it will remain -1
    for (List<dynamic> row in signingsSheet) {
      if (row[0] == employee!.getFullName()) {
        developer.log('Found user ${employee!.getFullName()} in row: $row');
        userIndex = signingsSheet.indexOf(row);
        break;
      }
    }

    // If the user is not on the signings sheet the function return
    if (userIndex == -1) {
      developer.log('${employee!.getFullName()} was not found on signings sheet.');
      return;
    }


    // Takes the signing sheet data and creates a new row with the current time.
    final signingsRow = getNewSigningsRow(employee?.signings);

    // Gets a new headers row if the headers need to be extended
    sheets.RowData newHeaders = sheets.RowData(values: []);
    List<String> currentHeaders = signingsSheet[0].cast<String>();
    
    // The + 1 includes the name in the row length
    if (signingsRow.values!.length + 1 > currentHeaders.length) {
      newHeaders = getNewHeaders(currentHeaders);
    }


    // Gets the sheetID which is needed to build requests
    final spreadsheet = await sheetsApi.spreadsheets.get(_spreadsheetId);
    final sheet = spreadsheet.sheets?.firstWhere((s) => s.properties?.title == _currentSheetId,);
    final sheetId = sheet?.properties?.sheetId;

    // Builds an array of all the rows that need to be updated in the sheet
    final allRowUpdateDetails = [];
    allRowUpdateDetails.add((data: signingsRow, row:userIndex, col:1));
    if (newHeaders.values!.isNotEmpty) {
      allRowUpdateDetails.add((data: newHeaders, row:0, col:0));
    }

    List<dynamic> allSpreadsheetRequests = getSpreadsheetRequests(allRowUpdateDetails, sheetId);


    // Submits header and signing request
    for (var request in allSpreadsheetRequests) {
      await sheetsApi.spreadsheets.batchUpdate(request, _spreadsheetId);
    }
  }
}