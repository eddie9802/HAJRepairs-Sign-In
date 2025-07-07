import 'dart:convert';
import 'package:intl/intl.dart';



import 'package:flutter_appauth/flutter_appauth.dart';

import 'package:http/http.dart' as http;
import 'colleague.dart';
import '../spreadsheet_utilities.dart';
import '../secret_manager.dart';
import '../updated_row.dart';




  
class ExcelSheetsTalker {

  final FlutterAppAuth appAuth = FlutterAppAuth();

  final String clientId = '5a2d0943-6c4b-469f-ad01-3b7f33f06e81';
  final String tenantId = 'dd11dc3e-0fa8-4004-9803-70a802de0faf';
  final String _driveId = "b!9fsUyKGke0y1U3QDUBNiD0pi50qUMWlEob3HI9NOb-Zyp0whTvCySa-hJq1U89Sd";
  final String redirectUrl = 'https://login.microsoftonline.com/common/oauth2/nativeclient';


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


  // Retrieves all the colleauges from the colleagues file
  Future<List<Colleague>?> retrieveColleagues() async {
    String? accessToken = await authenticateWithClientSecret();

    String fileName = "Colleagues.xlsx";
    final pathSegments = ['HAJ-Reception', 'Colleague'];
    String? fileId = await getFileId(fileName, pathSegments, accessToken!);

    if (fileId == null) {
      print("Could not find colleagues file");
      return null;
    }

    String worksheetId = 'List';
    List<dynamic>? values = await readSpreadsheet(fileId, worksheetId, accessToken);

    if (values == null || values.isEmpty) {
      print('No colleagues found');
      return [];
    }

    final List<Colleague> allColleagues = [];

    for (var row in values.skip(1)) {
      final String forename = row.length > 0 ? row[0]?.toString() ?? '' : '';
      final String surname = row.length > 1 ? row[1]?.toString() ?? '' : '';
      allColleagues.add(Colleague(forename: forename, surname: surname));
    }

    return allColleagues;
  }


  String getFractionAsTimeString(String fractionStr) {
    double fraction = double.parse(fractionStr);

    // Convert fraction of day to total seconds
    int totalSeconds = (fraction * 24 * 60 * 60).round();
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;

    // Create a DateTime object with hours and minutes (date is arbitrary)
    final time = DateTime(2000, 1, 1, hours, minutes);

    // Format as "h:mm a"
    return DateFormat('h:mm a').format(time);
  }




  // Set colleague signing details
  Future<void> setSigningDetails(Colleague colleague) async {

    // Gets the id of the timesheet that needs to be read
    String? accessToken = await authenticateWithClientSecret();
    TimesheetDetails details = getTimesheetDetails();
    final pathSegments = ['HAJ-Reception', 'Colleague', 'Timesheets', details.date.year.toString(), details.getMonthName()];
    String? fileId = await getFileId(details.name, pathSegments, accessToken!);

    // Gets all the values from the spreadsheet
    String worksheetId = getTodaysSheet();
    List<dynamic>? values = await readSpreadsheet(fileId!, worksheetId, accessToken);

    if (values == null || values.isEmpty) {
      print("Error: $worksheetId sheet for ${details.name} spreadsheet empty or not found");
      return;
    }

    // Adds all the signings to the colleagues signing array
    for (var i = 1; i < values.length; i++) {
      var row = values[i];
      String name = row[0];
      if (row.isNotEmpty && name.toString() == colleague.getFullName()) {

        // Sets the row number that the colleague exists on
        colleague.rowNumber = i + 1;

        // Adds all the signings of the colleague
        colleague.signings = [];
        for (int i = 1; i < row.length; i++) {
          String cell = row[i].toString();
          if (cell.isNotEmpty) {
            String time = getFractionAsTimeString(cell);
            colleague.signings.add(time);
          }
        }
        break;
      }
    }
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


  // Adds empty cells to the ends of the rows
  List<String> addPaddingToRow(int nColumns, List<String> row) {
    if (row.length < nColumns) {
      int nPads = nColumns - row.length;
      for (int i = 0; i < nPads; i++) {
        row.add('');
      }
    }
    return row;
  }




  // Returns a range for a row to be inserted into
  String getRangeString(int startRow, int nColumns) {
    // Convert column number (1-based) to Excel column letters, e.g., 1 -> A, 3 -> C, 27 -> AA
    String columnNumberToLetter(int columnNumber) {
      var dividend = columnNumber;
      var columnName = '';
      while (dividend > 0) {
        var modulo = (dividend - 1) % 26;
        columnName = String.fromCharCode(65 + modulo) + columnName;
        dividend = (dividend - modulo - 1) ~/ 26;
      }
      return columnName;
    }

    String startColumnLetter = columnNumberToLetter(1);  // Always start from column A
    String endColumnLetter = columnNumberToLetter(nColumns);

    return "$startColumnLetter$startRow:$endColumnLetter$startRow";
  }


  // Returns the number of columns in the sheet
  Future<int> getHeaderSize(String fileId, String worksheetId, String accessToken) async {
    List<dynamic>? values = await readSpreadsheet(fileId, worksheetId, accessToken);

    List<dynamic> headerRow = values![0];
    int nColumns = headerRow.length;
    return nColumns;
  }

  UpdatedRow? getNewHeaderRow(List<String> newRow, int headerSize) {

    // Creates a new header row if need by
    if (newRow.length > headerSize) {
      var newHeaderRow = ["Name", "Sign In", "Sign Out"];
      headerSize = headerSize + 2;
      for (int i = 3; i < headerSize; i+=2) {
        newHeaderRow.add('Sign In');
        newHeaderRow.add('Sign Out');
      }
      var headerRange = getRangeString(1, headerSize);
      UpdatedRow updatedHeaderRow = UpdatedRow(row: newHeaderRow, range: headerRange);
      return updatedHeaderRow;
    } else {
      return null;
    }
  }


  // Writes signing data to excel timesheet
  Future<(bool?, String)> writeSigning(Colleague colleague) async {

    // Gets the id of the timesheet that needs to be read
    String? accessToken = await authenticateWithClientSecret();
    TimesheetDetails details = getTimesheetDetails();
    final pathSegments = ['HAJ-Reception', 'Colleague', 'Timesheets', details.date.year.toString(), details.getMonthName()];
    print(pathSegments);
    String? fileId = await getFileId(details.name, pathSegments, accessToken!);

    // Gets all the values from the spreadsheet
    String worksheetId = getTodaysSheet();

    // Creates a new row
    DateTime now = DateTime.now();
    String newSigningTime = DateFormat('h:mm a').format(now);
    var newRow = [colleague.getFullName(), ...colleague.signings, newSigningTime];


    // All the rows that need updating
    List<UpdatedRow> updatedRows = [];

    // Gets the number of columns in the spreadsheet
    int headerSize = await getHeaderSize(fileId!, worksheetId, accessToken);


    // Gets the new header row.  If there isn't one newHeaderRow is null
    UpdatedRow? newHeaderRow = getNewHeaderRow(newRow, headerSize);
    if (newHeaderRow != null) {
      updatedRows.add(newHeaderRow);
      headerSize = newHeaderRow.row.length;
    }

    // Pads the row with extra empty cells
    var paddedRow = addPaddingToRow(headerSize, newRow);
    var range = getRangeString(colleague.rowNumber!, headerSize);
    UpdatedRow updatedRow = UpdatedRow(row: paddedRow, range: range);
    updatedRows.add(updatedRow);


    // Writes the updated rows to the spreadsheet
    bool? success;
    for (var row in updatedRows) {
      success = await writeRowToSpreadsheet(fileId, worksheetId, accessToken, row.row, row.range);

      if (!success) {
        return (false, newSigningTime); // early exit on failure
      }
    }

    return (true, newSigningTime);
  }
}