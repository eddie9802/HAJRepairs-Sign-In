import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';



import 'package:flutter_appauth/flutter_appauth.dart';

import 'package:http/http.dart' as http;
import 'colleague/colleague.dart';
import 'spreadsheet_utilities.dart';
import 'secret_manager.dart';




  
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



  void printInSegments(String text, {int segmentLength = 50}) {
    int start = 0;
    while (start < text.length) {
      final end = (start + segmentLength < text.length) ? start + segmentLength : text.length;
      print(text.substring(start, end));
      start = end;
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
    String fileName = getTimesheetName();
    final pathSegments = ['HAJ-Reception', 'Colleague', 'Timesheets'];
    String? fileId = await getFileId(fileName, pathSegments, accessToken!);

    // Gets all the values from the spreadsheet
    String worksheetId = getTodaysSheet();
    List<dynamic>? values = await readSpreadsheet(fileId!, worksheetId, accessToken);

    if (values == null || values.isEmpty) {
      print("Error: $worksheetId sheet for $fileName spreadsheet empty or not found");
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


  // Takes a colleague and adds a time to their signings array
  void addToColleagueSignings(Colleague colleague) {
    DateTime now = DateTime.now();
    String formattedTime = DateFormat('h:mm a').format(now);
    colleague.signings.add(formattedTime);
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
    print(response.body);

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


  // Writes signing data to excel timesheet
  Future<bool> writeSigning(Colleague colleague) async {


    // Adds signing to colleague
    addToColleagueSignings(colleague);



    // Gets the id of the timesheet that needs to be read
    String? accessToken = await authenticateWithClientSecret();
    String fileName = getTimesheetName();
    final pathSegments = ['HAJ-Reception', 'Colleague', 'Timesheets'];
    String? fileId = await getFileId(fileName, pathSegments, accessToken!);

    // Gets all the values from the spreadsheet
    String worksheetId = getTodaysSheet();

    var newRow = [colleague.getFullName(), ...colleague.signings];
    var paddedRow = addPaddingToRow(3, newRow);
    // Using the row number the colleague exists on in the spreadsheet the range is calculated
    var range = getRangeString(colleague.rowNumber!, 3);
    print(range);
    return await writeRowToSpreadsheet(fileId!, worksheetId, accessToken, paddedRow, range);
  }
}