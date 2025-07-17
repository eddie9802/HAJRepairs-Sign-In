



import 'package:flutter/material.dart';

import './hidden_menu_excel_talker.dart';
import '../haj_response.dart';

class FireReport extends StatefulWidget {
  @override
  _FireReportState createState() => _FireReportState();
}

class _FireReportState extends State<FireReport> {


  Future<List<String>> retrieveAllPersonel() async {
    HAJResponse signedInColleaguesRes = await HiddenMenuExcelTalker().getSignedInColleagues();

    if (signedInColleaguesRes.isSuccess) {
      return List<String>.from(signedInColleaguesRes.body);
    } else {
      print("Error retrieving signed-in colleagues: ${signedInColleaguesRes.message}");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fire Report'),
      ),
      body: Center(
        child: Text('This is the Fire Report page'),
      ),
    );
  }
}