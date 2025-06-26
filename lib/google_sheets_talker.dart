import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis/admin/directory_v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:intl/intl.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis/drive/v3.dart' as drive;
import 'employee.dart';
import 'customerHAJ.dart';




class GoogleSheetsTalker {
  static final String _currentSheetId = getTodaysSheet();
  static final String _employeeSheetId = "1HU9r0InSuab5ydG1HPMG72uhgvfcZJbcDabw5MMApnM";
  static final String _customerSpreadsheetId = "1PR8VlyasFyBFtbWArzMeeRb_OLyubRu7s2qfMBcdctA";
  static final String _signedInCustomerSheet = "Signed In Customers";
    static final String _signedOutCustomerSheet = "Signed Out Customers";


  static Future<String?> getCurrentTimesheetId() async{
    String timesheetName = getTimesheetName();

    final scopes = [ drive.DriveApi.driveReadonlyScope,];
    final jsonStr = await rootBundle.loadString('assets/haj-reception.json');
    final credentials = ServiceAccountCredentials.fromJson(json.decode(jsonStr));
    final client = await clientViaServiceAccount(credentials, scopes);
    final driveApi = drive.DriveApi(client);
    String employeeReceptionFolderId = "1HIiBFszhTKqfa3rS46lkeGobDCf_Iz1F";
    var files = await listFilesInFolder(driveApi, employeeReceptionFolderId);


    String? timesheetId;
    if (files.isNotEmpty) {
      for (var file in files) {
        if (timesheetName == file.name) {
          developer.log('Found: ${file.name} (${file.id})');
          timesheetId = file.id;
        }
      }
    }

    client.close();
    return timesheetId;
  }


sheets.RowData getCustomerRow( List<Object?> customerDetailsList) {
  var row = sheets.RowData(values: []);
  for (var cell in customerDetailsList) {
    row.values!.add(sheets.CellData.fromJson({
      'userEnteredValue': {'stringValue': cell},
      'userEnteredFormat': {
        'textFormat': {'bold': false}
      }
    }));
  }
    return row;
  }


  Future<List<CustomerHAJ>> retrieveCustomers() async {
    sheets.SheetsApi sheetsApi = await getSheetsApi();
    final response = await sheetsApi.spreadsheets.values.get(_customerSpreadsheetId, _signedInCustomerSheet);
    final values = response.values;
    final List<CustomerHAJ> allCustomers = [];
    if (values == null || values.isEmpty) {
      print("No customers found");
    } else {

      // .skip(1) skips the header row
      for (var row in values.skip(1)) {
        String registration = row[0].toString();
        String company = row[1].toString();
        String reasonForVisit = row[2].toString();
        String signInDriverName = row[3].toString();
        String signInDriverNumber = row[4].toString();
        String signInDate = row[5].toString();
        String signIn = row[6].toString();

        // Creates a CustomerHAJ instance for each customer
        allCustomers.add(CustomerHAJ(
          registration: registration,
          company: company,
          reasonForVisit: reasonForVisit,
          signInDriverName: signInDriverName,
          signInDriverNumber: signInDriverNumber,
          signOutDriverName: "",
          signOutDriverNumber: "",
          signInDate: signInDate,
          signOutDate: "",
          signIn: signIn,
          signOut: ""
        ));
      }
    }
    return allCustomers;
  }


  Future<bool> writeToSignedOutCustomers(CustomerHAJ customer) async {
    try {
      sheets.SheetsApi sheetsApi = await getSheetsApi();

      // Creates the row to be inserted into customer details
      List<String>? allCustomerDetails = [
                                          customer.registration,
                                          customer.company,
                                          customer.reasonForVisit,
                                          customer.signInDriverName,
                                          customer.signInDriverNumber,
                                          customer.signInDate,
                                          customer.signIn,
                                          customer.signOutDriverName,
                                          customer.signOutDriverNumber,
                                          customer.signOutDate,
                                          customer.signOut
                                          ];


      // Wraps the customer detauls in a value range
      final valueRange = sheets.ValueRange(
        values: [allCustomerDetails], // <- wrap your List<String> in another list
      );

      // Appends the details to the end of the customer details sheet
      // This allows for concurrency
      await sheetsApi.spreadsheets.values.append(
        valueRange,
        _customerSpreadsheetId,
        "$_signedOutCustomerSheet!A:F",
        valueInputOption: "RAW",
        insertDataOption: "INSERT_ROWS");
    } catch(e) {
      return false;
    }
    return true;
  }


  Future<int?> getCustomerRowNum(CustomerHAJ customer) async {
    sheets.SheetsApi sheetsApi = await getSheetsApi();
    final response = await sheetsApi.spreadsheets.values.get(_customerSpreadsheetId, _signedInCustomerSheet);
    final rows = response.values;

    if (rows == null || rows.isEmpty) {
      print("No customers found");
      return null;
    } else {

      int? customerRowIndex;
      for (var i = 1; i < rows.length; i++) {
        var customerDetailsList = rows[i];
        String registration = customerDetailsList[0].toString();
        if (customer.registration == registration) {
          customerRowIndex = i;
          break;
        }
      }
      return customerRowIndex;
    }
  }



Future<bool> deleteRowfromSignedIn(int rowNumber) async {
  sheets.SheetsApi sheetsApi = await getSheetsApi();

  // Gets the sheetID which is needed to build requests
  final spreadsheet = await sheetsApi.spreadsheets.get(_customerSpreadsheetId);
  final sheet = spreadsheet.sheets?.firstWhere((s) => s.properties?.title == _signedInCustomerSheet,);
  final sheetId = sheet?.properties?.sheetId;


  final request = sheets.BatchUpdateSpreadsheetRequest.fromJson({
    "requests": [
      {
        "deleteDimension": {
          "range": {
            "sheetId": sheetId,
            "dimension": "ROWS",
            "startIndex": rowNumber, // 0-based, inclusive
            "endIndex": rowNumber + 1 // 0-based, exclusive
          }
        }
      }
    ]
  });

  try {
    await sheetsApi.spreadsheets.batchUpdate(request, _customerSpreadsheetId);
    print("Row $rowNumber deleted successfully.");
    return true;
  } catch (e) {
    print("Failed to delete row: $e");
    return false;
  }
}


  // Writes the customer to the sign out sheet and remove them from the sign in
  Future<bool> signCustomerOut(CustomerHAJ customer) async {
    bool rowDeleted = false;
    bool successfullyWritten = await writeToSignedOutCustomers(customer);

    if (successfullyWritten) {
      int? customerRowNum = await getCustomerRowNum(customer);
      if (customerRowNum != null) {
        rowDeleted = await deleteRowfromSignedIn(customerRowNum);
      }
    }

    return rowDeleted;
  }


  // Checks if the given customer is already signed in
  Future<bool> hasCustomerSignedIn(String customerReg) async {
    sheets.SheetsApi sheetsApi = await getSheetsApi();
    final response = await sheetsApi.spreadsheets.values.get(_customerSpreadsheetId, _signedInCustomerSheet);
    final rows = response.values;

    for (var row in rows!) {
      String reg = row[0].toString();
      if (reg == customerReg) {
        return true;
      } 
    }

    // Customer has not signed in
    return false;
  }



  // Signs the customer in
  Future<(bool, String)> signCustomerIn(Map<String, String> formData) async {
    (bool, String) response = (false, "");
    String registration = formData["Registration"]!;

    bool signedIn = await hasCustomerSignedIn(registration);

    if (!signedIn) {
      if (await uploadCustomerData(formData)) {
        response = (true, "Your vehicle has successfully been signed in");
      } else {
        response = (false, "Sign in failed");
      }
    } else {
      response = (false, "Vehicle has already been signed in");
    }


    return response;
  }


  // Takes all the customer data and uploads it to the customer data spreadsheet
  Future<bool> uploadCustomerData(Map<String, String> formData) async {
    try {
      sheets.SheetsApi sheetsApi = await getSheetsApi();

      // Creates the row to be inserted into customer details
      List<String>? allCustomerDetails = [
                                          formData["Registration"]!,
                                          formData["Company"]!,
                                          formData["Reason For Visit"]!,
                                          formData["Name"]!,
                                          formData["Driver Number"]!.toString(),
                                          formData["Date"]!,
                                          formData["Sign in"]!,
                                          ];


      // Wraps the customer detauls in a value range
      final valueRange = sheets.ValueRange(
        values: [allCustomerDetails], // <- wrap your List<String> in another list
      );

      // Appends the details to the end of the customer details sheet
      // This allows for concurrency
      await sheetsApi.spreadsheets.values.append(
        valueRange,
        _customerSpreadsheetId,
        "Signed In Customers!A:F",
        valueInputOption: "RAW",
        insertDataOption: "INSERT_ROWS"
      );

      // If upload was a success then return true else return false
      return true;
    } catch(e) {
      return false;
    }
  }


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



  // Gets the timesheet name for the week
  static String getTimesheetName() {
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

    return "Week ending on $formatted";
  }

  // folderId = the ID of the folder you want to search
  static Future<List<drive.File>> listFilesInFolder(drive.DriveApi driveApi, String folderId,) async {
    final fileList = await driveApi.files.list(
      q: "'$folderId' in parents and trashed = false",
      $fields: "files(id, name, mimeType)",
      spaces: 'drive',
      supportsAllDrives: true, // optional if using shared/team drives
    );

    return fileList.files ?? [];
  }

  
  sheets.RowData getEmployeeRows(List<Employee>? allEmployees) {
    sheets.RowData employeeRows = sheets.RowData(values: []);
    for (Employee employee in allEmployees!) {
      employeeRows.values!.add(sheets.CellData.fromJson({
        'userEnteredValue': {'stringValue': employee.getFullName()},
        'userEnteredFormat': {
          'textFormat': {'bold': false}
        }
      }));
    }
    return employeeRows;
  }


  Future<String> getButtonText() async {
    String? signing;
    sheets.SheetsApi sheetsApi = await getSheetsApi();

    String? currentTimesheetId = await getCurrentTimesheetId();
    final response = await sheetsApi.spreadsheets.values.get(currentTimesheetId!, _currentSheetId,);

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


  // Retrieves the Google Sheets API client using service account credentials.
  Future<sheets.SheetsApi> getSheetsApi() async {
    final jsonStr = await rootBundle.loadString('assets/haj-reception.json');
    final credentials = ServiceAccountCredentials.fromJson(json.decode(jsonStr));
    final scopes = [sheets.SheetsApi.spreadsheetsScope, 'https://www.googleapis.com/auth/drive.file'];

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
  Future<List<Employee>?> retrieveEmployees() async {
    final range = "A:B"; // Reads all the values in columns A and B
    sheets.SheetsApi sheetsApi = await getSheetsApi();
    final response = await sheetsApi.spreadsheets.values.get(_employeeSheetId, range);
    final values = response.values;
    final List<Employee> allEmployees = [];
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
    String? currentTimesheetId = await getCurrentTimesheetId();
    final response = await sheetsApi.spreadsheets.values.get(currentTimesheetId!, _currentSheetId);
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
    final spreadsheet = await sheetsApi.spreadsheets.get(currentTimesheetId);
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
      await sheetsApi.spreadsheets.batchUpdate(request, currentTimesheetId);
    }
  }
}