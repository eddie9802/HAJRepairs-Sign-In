import 'package:flutter/material.dart';
import 'colleague_excel_talker.dart';
import 'colleague.dart';
import 'colleague_signing.dart';

class ColleagueSearch extends StatefulWidget {
  const ColleagueSearch({super.key});

  @override
  _ColleagueSearchState createState() => _ColleagueSearchState();
}

class _ColleagueSearchState extends State<ColleagueSearch> {

  final Future<List<dynamic>?> _colleagues = ColleagueExcelTalker().retrieveColleagues();

  List<Colleague> _matchedColleagues = [];

  // Function to get matched colleagues based on search input
  Future<List<Colleague>> getSearchedColleagues(String search) async {
    List<Colleague> matched = [];
    final colleagues = await _colleagues;
    for (var colleague in colleagues!) {
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
              Future.delayed(Duration(milliseconds: 200), () {
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
          child:
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 50.0),
                  child: 
                    SizedBox(
                      width: 400,
                      child: TextField(
                        onChanged: (value) => setMatchedColleagues(value),
                        decoration: InputDecoration(
                        labelText: 'Enter name',
                        border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                ),
                Expanded(
                  child: 
                  SizedBox(
                  width: 400,
                  child: ListView(
                    padding: EdgeInsets.all(16.0),
                    children: [
                      ...List.generate(_matchedColleagues.length, (index) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: ListTile(
                              title: Text('${_matchedColleagues[index].forename} ${_matchedColleagues[index].surname}'),
                              onTap: () async {
                                FocusManager.instance.primaryFocus?.unfocus(); 

                                await Future.delayed(const Duration(milliseconds: 200));
                                
                                // Dismiss keyboard
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ColleagueReception(colleague: _matchedColleagues[index],)),
                                );
                              },
                            ),
                          );
                        }),
                      ]
                    ),
                  ),
                ),
              ],
            ),
        ),
    );
  }
}