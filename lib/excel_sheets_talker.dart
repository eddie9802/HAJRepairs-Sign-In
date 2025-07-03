import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';



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
    String fileName = "Colleagues.xlsx";

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


  Future<String> getButtonText(Colleague colleague) async {

    // Gets the id of the timesheet that needs to be read
    String? accessToken = await authenticateWithClientSecret();
    String fileName = getTimesheetName();
    final pathSegments = ['HAJ-Reception', 'Timesheets'];
    String? fileId = await getFileId(fileName, pathSegments, accessToken!);

    // Gets all the values from the spreadsheet
    String worksheetId = getTodaysSheet();
    List<dynamic>? values = await readSpreadsheet(fileId!, worksheetId, accessToken);

    if (values == null || values.isEmpty) {
      print('No colleagues found');
      return "Error: $worksheetId sheet for $fileName spreadsheet empty or not found";
    }


    String? signing;
    for (var row in values.skip(1)) {
      String name = row[0];
      if (row.isNotEmpty && name.toString() == colleague.getFullName()) {

        // Finds out if the user is signing in or out
        if (row.length % 2 == 0) {
          signing = "Sign Out";
        } else {
          signing = "Sign In";
        }

        // Adds all the signings of the colleague
        colleague.signings = [];
        for (int i = 1; i < row.length; i++) {
          colleague.signings.add(row[i].toString());
        }
        break;
      }
    }

    // Checks the 
    return signing!;
  }
}