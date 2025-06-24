import 'package:flutter/material.dart';
import 'google_sheets_talker.dart';
import 'employee_signing.dart';

class EmployeeSearch extends StatefulWidget {
  const EmployeeSearch({super.key});

  @override
  _EmployeeSearchState createState() => _EmployeeSearchState();
}

class _EmployeeSearchState extends State<EmployeeSearch> {

  final Future<List<dynamic>?> _employees = GoogleSheetsTalker().retrieveEmployees();

  List<Employee> _matchedEmployees = [];

  // Function to get matched employees based on search input
  Future<List<Employee>> getSearchedEmployees(String search) async {
    List<Employee> matched = [];
    final employees = await _employees;
    for (var employee in employees!) {
      String fullName = '${employee.forename} ${employee.surname}';
      if (fullName.toLowerCase().startsWith(search.toLowerCase()) && search.isNotEmpty) {
        matched.add(employee);
      }
    }

  matched.sort((a, b) => a.getFullName().toLowerCase().compareTo(b.getFullName().toLowerCase()));
    return matched;
  }

// Function to update the matched employees based on user input
  void setMatchedEmployees(String search) async {
    final matched = await getSearchedEmployees(search);
    setState(() {
      _matchedEmployees = matched;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Colleague Search')),
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
                        onChanged: (value) => setMatchedEmployees(value),
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
                      ...List.generate(_matchedEmployees.length, (index) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: ListTile(
                              title: Text('${_matchedEmployees[index].forename} ${_matchedEmployees[index].surname}'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => EmployeeReception(employee: _matchedEmployees[index])),
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