import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:developer' as developer;


Future<void> callAppsScript() async {
  final serviceAccountString = await rootBundle.loadString('assets/haj-reception.json');
  final serviceAccountJson = jsonDecode(serviceAccountString); // Now it's usable
  final credentials = ServiceAccountCredentials.fromJson(serviceAccountJson);

  const scopes = [
    'https://www.googleapis.com/auth/script.projects',
    'https://www.googleapis.com/auth/script.external_request',
  ];

  // Get an authenticated HTTP client
  final client = await clientViaServiceAccount(credentials, scopes);

  final scriptId = 'AKfycbwXWqC9vbsD61grGS42hpHeszebutBx4Cc2UOqohTBOT1F15qsxhQr8UMsk8qsTUoH9pQ'; // Get from Apps Script project URL

  final response = await client.post(
    Uri.parse('https://script.google.com/macros/s/AKfycbyhlGLPByK0C4feg0poB-ycCi3-Qvzd-E0ENdXMA5c1TqqwSf42_zq8Mw-2WtKyQfF8bQ/exec'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'function': 'createWeeklyTimesheets',
      'parameters': ['Hello from Dart'],
      'devMode': true
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    developer.log('Script response: ${data['response']['result']}');
  } else {
    developer.log('Error: ${response.statusCode} ${response.body}');
  }

  client.close();
}