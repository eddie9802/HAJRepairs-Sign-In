import 'package:intl/intl.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

import 'colleague.dart';
import '../spreadsheet_utilities.dart';
import '../updated_row.dart';




  
class ColleagueExcelTalker {

  final FlutterAppAuth appAuth = FlutterAppAuth();

  final String clientId = '5a2d0943-6c4b-469f-ad01-3b7f33f06e81';
  final String tenantId = 'dd11dc3e-0fa8-4004-9803-70a802de0faf';
  final String redirectUrl = 'https://login.microsoftonline.com/common/oauth2/nativeclient';




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