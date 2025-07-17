



import 'package:flutter/material.dart';

import './hidden_menu_excel_talker.dart';
import '../haj_response.dart';
import '../common_widgets.dart';

class FireReport extends StatefulWidget {
  @override
  _FireReportState createState() => _FireReportState();
}

class _FireReportState extends State<FireReport> {

  late final Future<void> _fireReportFuture;
  List<String> _allPersonnel = [];


  @override
  void initState() {
    super.initState();
    _fireReportFuture = initAllPersonnel();
  }


Future<void> initAllPersonnel() async {
  try {
    final signedInColleaguesRes = await HiddenMenuExcelTalker().getSignedInColleagues();
    print(signedInColleaguesRes.message);

    if (signedInColleaguesRes.isSuccess) {
      _allPersonnel = List<String>.from(signedInColleaguesRes.body);
      print(_allPersonnel);
    } else {
      print("Error retrieving signed-in colleagues: ${signedInColleaguesRes.message}");
      _allPersonnel = [];
    }
  } catch (e, stackTrace) {
    print("🔥 initAllPersonnel error: $e");
    print("📍 Stack trace: $stackTrace");
    rethrow; // Let FutureBuilder catch it and show snapshot.hasError
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fire Report'),
      ),
      body: Center(
        child:
          FutureBuilder<void>(
            future: _fireReportFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: 40), // Push it down a bit from the top
                    loadingIndicator(),
                  ],
                );
              } else if (snapshot.hasError) {
                return Center(child: Text('Error loading fire report'));
              } else {
                return Column(
                  children: [
                    Expanded( // gives height to ListView
                      child: SizedBox(
                        width: 400,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _allPersonnel.length,
                          itemBuilder: (context, index) {
                            final name = _allPersonnel[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: ListTile(
                                title: Text(name),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              }
            }
          ),
      ),
    );
  }
}