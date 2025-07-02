import 'dart:convert';

import 'package:flutter_appauth/flutter_appauth.dart';

import 'package:http/http.dart' as http;
import 'colleague/colleague.dart';
import 'spreadsheet_utilities.dart';
import 'secret_manager.dart';




  
class ExcelSheetsTalker {

  final FlutterAppAuth appAuth = FlutterAppAuth();

  final String clientId = '5a2d0943-6c4b-469f-ad01-3b7f33f06e81';
  final String tenantId = 'dd11dc3e-0fa8-4004-9803-70a802de0faf';
  final String redirectUrl = 'https://login.microsoftonline.com/common/oauth2/nativeclient';
  final List<String> scopes = [
    'Files.ReadWrite.All',
    'Sites.Read.All',
  ];


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
        'scope': scopes,
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



  Future<String?> getSharepointId(String? accessToken) async {
    // Gets the site id for the sharepoint
    final response = await http.get(
      Uri.parse('https://graph.microsoft.com/v1.0/sites/hajrepairs.sharepoint.com:/sites/HAJRepairs'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      return response.body;
    }

    print("Failed to get sharepoint id");
    return null;
  }


  Future<List<Colleague>?> retrieveColleagues() async {

    String? accessToken = await authenticateWithClientSecret();
    String worksheetName = 'List';

    print(accessToken);



    var siteId = getSharepointId(accessToken);

    print("This is the site ID: $siteId");

    final range = 'A:B';
    final url = Uri.parse(
      'https://graph.microsoft.com/v1.0/sites/$siteId/drive/root:/Collegues.xlsx',
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
    final List<dynamic>? values = json['values'];

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
}