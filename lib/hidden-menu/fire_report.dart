



import 'package:flutter/material.dart';

class FireReport extends StatefulWidget {
  @override
  _FireReportState createState() => _FireReportState();
}

class _FireReportState extends State<FireReport> {


  List<String> retrieveAllPersonel() {


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