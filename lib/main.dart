import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'google_sheets_talker.dart'; // Import the Timesheets class

void main() {
  runApp(MaterialApp(home: MainApp()));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {

  final List<String> _employeeTypes = [
    'Customer',
    'Supplier',
    'Employee'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(left: 300.0, right: 300.0, top: 50.0),
        child: Column(
          children: [
            Image.asset('assets/images/haj-logo.png'),
            Padding(padding: EdgeInsets.only(bottom: 80.0)),
            Text(
                'Welcome to HAJ Repairs.  Are you a Customer, Supplier or Employee?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center
            ),
            Padding(padding: EdgeInsets.only(bottom: 40.0)),
            ...List.generate(_employeeTypes.length, (index) {
              return Padding(
                padding: EdgeInsets.only(bottom: 20.0),
                child: TextButton(
                  child: Text(
                      _employeeTypes[index],
                      style: TextStyle(fontSize: 28),
                      ),
                  onPressed: () {
                    if (_employeeTypes[index] == 'Employee') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EmployeeSearch()),
                      );
                    }
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}


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
      appBar: AppBar(title: Text('Employee Search')),
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
                              title: Text(_matchedEmployees[index].forename + ' ' + _matchedEmployees[index].surname),
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



class EmployeeReception extends StatefulWidget {

  final Employee employee;

  const EmployeeReception({super.key, required this.employee});


  @override
  _EmployeeReceptionState createState() => _EmployeeReceptionState();

}

class _EmployeeReceptionState extends State<EmployeeReception> {
  late Future<String> _buttonTextFuture;

  @override
  void initState() {
    super.initState();
    _buttonTextFuture = GoogleSheetsTalker.sign(widget.employee).getButtonText();
  }

  Future<dynamic> showEmployeeDialog(BuildContext context, String? signing) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(''),
        content: Text('$signing at ${widget.employee.signings.last} successful!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> signEmployee(BuildContext context, String? signing) async {
    await GoogleSheetsTalker.sign(widget.employee).writeSigning();
    await showEmployeeDialog(context, signing);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _buttonTextFuture, 
      builder: (context, snapshot) {
        String? signingButtonText;
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Future is still loading
          signingButtonText = 'Loading...';
        } else if (snapshot.hasError) {
          // Future completed with error
          signingButtonText = 'Error: ${snapshot.error}';
        } else {
          // Future completed successfully
          signingButtonText = snapshot.data ?? 'No data';
        }

      return(
        Scaffold(
          appBar: AppBar(title: Text('Employee Reception')),
          body:
          Center(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('What would you like to do, ${widget.employee.forename}?', style: TextStyle(fontSize: 24)),
                ),
                TextButton(
                  onPressed:() async {
                    String? signing = snapshot.data;
                    await signEmployee(context, signing);

                  setState(() {
                      _buttonTextFuture = GoogleSheetsTalker.sign(widget.employee).getButtonText();
                    });
                  },
                  child:  
                    Text(signingButtonText, style: TextStyle(fontSize: 24))
                ),
                Padding(padding: EdgeInsets.only(bottom: 40.0)),
                Expanded( 
                  child:
                  SizedBox(
                    width: 400,
                    child: 
                      ListView(
                        children: [
                          ...List.generate(widget.employee.signings.length, (index) {
                            if (index % 2 == 0) {
                              return 
                                Center(child: 
                                Padding(
                                  padding: EdgeInsets.only(bottom: 20.0),
                                  child: Text('Sign In: ${widget.employee.signings[index]}', style: TextStyle(fontSize: 20)))
                                  );
                            } else {
                              return
                                Center(child: 
                                Padding(
                                  padding: EdgeInsets.only(bottom: 20.0),
                                  child: Text('Sign Out: ${widget.employee.signings[index]}', style: TextStyle(fontSize: 20)))
                                  );
                            }
                          })
                        ]
                      ),
                    )
                )
              ],
            ),
          ),
        )
      );
    }
    );
  }
}
