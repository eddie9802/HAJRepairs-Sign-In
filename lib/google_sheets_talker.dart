import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:intl/intl.dart';


class Employee {
  final String forename;
  final String surname;

  Employee({required this.forename, required this.surname});
}

class GoogleSheetsTalker {
  static const _scopes = ['https://www.googleapis.com/auth/spreadsheets'];
  static const _spreadsheetId = '15cVVDR83OxLY0WP_H2oamygbSX6MnAKyJyX_M37VPRk';
  static const _employeeSpreadSheetId = '1HU9r0InSuab5ydG1HPMG72uhgvfcZJbcDabw5MMApnM';
  static const _sheetName = 'Signings';
  static const _employeeListSheetName = 'List';
  static const _range = 'Signings!A1';
  final String? user;

  GoogleSheetsTalker() : user = null;
  GoogleSheetsTalker.sign(this.user);


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


  Future<void> writeToSheet() async {
    final jsonStr = await rootBundle.loadString('assets/haj-reception.json');
    final serviceAccount = ServiceAccountCredentials.fromJson(json.decode(jsonStr));

    // Get authenticated HTTP client
    final client = await clientViaServiceAccount(serviceAccount, _scopes);

    // Make the write API request
    final urlwrite = Uri.parse('https://sheets.googleapis.com/v4/spreadsheets/$_spreadsheetId/values/$_range?valueInputOption=RAW');

    final urlGet = Uri.parse('https://sheets.googleapis.com/v4/spreadsheets/$_spreadsheetId/values/$_sheetName');


    final response = await client.get(urlGet);
    List<dynamic>? sheet;
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      sheet = data['values'];
      developer.log('Data retrieved successfully: $sheet');
    } else {
      developer.log('Error retrieving data: ${response.statusCode}');
      return;
    }

    // Check if the user is already in the sheet
    int userIndex = 0; // If userIndex is not found, it will remain 0
    for (List<dynamic> row in sheet!) {
      if (row[0] == user) {
        developer.log('Found user $user in row: $row');
        userIndex = sheet.indexOf(row);
        break;
      }
    }

    // Gets the current time in the format hh:mm a
    // e.g. 02:30 PM
    final now = DateTime.now();
    final formattedTime = DateFormat('hh:mm a').format(now);
    List<dynamic> headers = sheet[0];

    if (userIndex == 0) {
      sheet.add([user, formattedTime]);

    } else {
      List<dynamic> userRow = sheet[userIndex];
      int rowLength = userRow.length;
      userRow.add(formattedTime);
      
      if (headers.length <= rowLength) {
        // If the headers are not long enough, add a new header
        if (headers.length % 2 == 0) {
          headers.add('Out');
        } else {
          headers.add('In');
        }
        

      }
    }

    final writeResponse= await client.put(
      urlwrite,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'values': sheet,
      }),
    );

    if (writeResponse.statusCode == 200) {
      developer.log('Data written successfully');
    } else {
      developer.log('Error writing data: ${writeResponse.statusCode}');
    }
  }
}