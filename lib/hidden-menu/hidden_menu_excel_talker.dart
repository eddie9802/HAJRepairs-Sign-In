
import '../haj_response.dart';
import '../spreadsheet_utilities.dart';


class HiddenMenuExcelTalker {



  Future<HAJResponse> getSignedInColleagues() async {
    HAJResponse? authenticateRes = await authenticateWithClientSecret();

    if (authenticateRes == null) {
      print("Failed to authenticate due to an unknown error.");
      return HAJResponse(statusCode: 500, message: "Authentication failed");
    }

    if (!authenticateRes.isSuccess) {
      print(authenticateRes.message);
      return authenticateRes;
    }
    String? accessToken = authenticateRes.body;

    TimesheetDetails details = getTimesheetDetails();
    final pathSegments = ['HAJ-Reception', 'Colleague', 'Timesheets', details.date.year.toString(), details.getMonthName()];
    HAJResponse fileIdResponse = await getFileId(details.name, pathSegments, accessToken!);

    // Gets all the values from the spreadsheet
    String worksheetId = getTodaysSheet();
    String fileId = fileIdResponse.body;
    HAJResponse spreadsheetResponse = await readSpreadsheet(fileId, worksheetId, accessToken);

    if (!spreadsheetResponse.isSuccess) {
      print("Failed to read spreadsheet: ${spreadsheetResponse.message}");
      return spreadsheetResponse;
    }
    List<dynamic>? values = spreadsheetResponse.body;

    if (values == null || values.isEmpty) {
      print("Error: $worksheetId sheet for ${details.name} spreadsheet empty or not found");
      return spreadsheetResponse;
    }

    List<String> signedInColleagues = [];
    HAJResponse result = HAJResponse(statusCode: 200, message: "Success", body: signedInColleagues);

    // Adds all the signings to the colleagues signing array
    for (var i = 1; i < values.length; i++) {
      var row = values[i];
      int count = 0;
      int index = 0;
      while (row[index] != '' && row[index] != null) {
        count++;
        index++;

      }
      if (count % 2 == 0) {
        String name = row[0];
        signedInColleagues.add(name);
      }
    }
    return result;
  }

}