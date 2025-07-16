import 'package:flutter/material.dart';
import 'package:haj_repairs_sign_in/haj_response.dart';

import '../common_widgets.dart';
import 'colleague_excel_talker.dart';
import 'colleague.dart';
import 'colleague_signing.dart';

class ColleagueSearch extends StatefulWidget {
  const ColleagueSearch({super.key});

  @override
  _ColleagueSearchState createState() => _ColleagueSearchState();
}

class _ColleagueSearchState extends State<ColleagueSearch> {

  List<Colleague> _allColleagues = <Colleague>[];
  late final Future<void> _colleaguesFuture;
  final TextEditingController _controller = TextEditingController();
  List<Colleague> _matchedColleagues = [];

  
  @override
  void dispose() {
    _controller.dispose(); // Don't forget to dispose the controller
    super.dispose();
  }


  @override
  void initState() {
    super.initState();
    _colleaguesFuture = initColleagues();
  }



  Future<void> initColleagues() async {
  final response = await ColleagueExcelTalker().retrieveColleagues();
  if (response.statusCode == 200) {
    _allColleagues = response.body as List<Colleague>;
  } else {
    await showDialogPopUp(context, response.message);
    Navigator.of(context).pop();
  }
}

  // Function to get matched colleagues based on search input
  Future<List<Colleague>> getSearchedColleagues(String search) async {
    List<Colleague> matched = [];
    for (var colleague in _allColleagues) {
      String fullName = '${colleague.forename} ${colleague.surname}';
      if (fullName.toLowerCase().startsWith(search.toLowerCase()) && search.isNotEmpty) {
        matched.add(colleague);
      }
    }
    matched.sort((a, b) => a.getFullName().toLowerCase().compareTo(b.getFullName().toLowerCase()));
    return matched;
  }

// Function to update the matched colleagues based on user input
  void setMatchedColleagues(String search) async {
    await _colleaguesFuture;
    final matched = await getSearchedColleagues(search);
    setState(() {
      _matchedColleagues = matched;
    });
  }

  // Returns an AppBar widget which waits for the keyboard to unfocus before popping context
  PreferredSizeWidget? getAppbar() {
    return(
        AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus(); // Dismiss keyboard
              Future.delayed(Duration(milliseconds: 300), () {
                Navigator.of(context).maybePop();
              });
            },
          ),
        title: Text("Colleague Search"),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppbar(),
      body:
      Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 50.0),
              child: 
                SizedBox(
                  width: 400,
                  child: TextField(
                    controller: _controller,
                    onChanged: (value) => setMatchedColleagues(value),
                    decoration: InputDecoration(
                    labelText: 'Enter name',
                    border: OutlineInputBorder(),
                    ),
                  ),
                ),
            ),
            Expanded( // gives height to FutureBuilder result
              child: FutureBuilder<void>(
                future: _colleaguesFuture,
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
                    return Center(child: Text('Error loading colleagues'));
                  } else {
                    return Column(
                      children: [
                        showNResults(_controller.text.isNotEmpty, _matchedColleagues.length, "colleague"),
                        Expanded( // gives height to ListView
                          child: SizedBox(
                            width: 400,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: _matchedColleagues.length,
                              itemBuilder: (context, index) {
                                final colleague = _matchedColleagues[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: ListTile(
                                    title: Text('${colleague.forename} ${colleague.surname}'),
                                    onTap: () async {
                                      FocusManager.instance.primaryFocus?.unfocus();
                                      await Future.delayed(const Duration(milliseconds: 200));
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ColleagueReception(colleague: colleague),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        ],
                      );
                    }
                },
              ),
            ),

            ],
          ),
        ),
    );
  }
}