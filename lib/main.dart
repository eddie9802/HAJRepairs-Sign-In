import 'package:flutter/material.dart';
import 'dart:developer' as developer;

void main() {
  runApp(MaterialApp(home: MainApp()));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {

  final List<String> _drivers = [
    'Derrick',
    'Ian',
    'Kevin',
    'Trevor'
  ];

  final List<String> _employeeTypes = [
    'Customer',
    'Supplier',
    'Employee'
  ];

  List<String> _matchedDrivers = [];

  

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
                        MaterialPageRoute(builder: (context) => Employee()),
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


class Employee extends StatefulWidget {
  @override
  _EmployeeState createState() => _EmployeeState();
}

class _EmployeeState extends State<Employee> {

  final List<String> _employees = [
    'Jason',
    'Erin',
    'Harriet',
    'Brendan',
    'Leo',
    'Jhun Jhun Fernando',
    'Marcus',
    'Adrian',
    'Aidan',
    'Raveena',
    'Kirsty',
    'Carole',
    'Victor',
    'Bethal',
    'Darius',
    'Edward Hamilton',
    'Derrick',
    'Ian',
    'Kevin',
    'Trevor',
  ];

  List<String> _matchedEmployees = [];

  // Function to get matched employees based on search input
  List<String> getSearchedEmployees(String search) {
    List<String> matched = [];
    for (var employee in _employees) {
      if (employee.toLowerCase().startsWith(search.toLowerCase()) && search.isNotEmpty) {
        matched.add(employee);
      }
    }
    return matched;
  }

// Function to update the matched employees based on user input
  void setMatchedEmployees(String search) {
    setState(() {
      _matchedEmployees = getSearchedEmployees(search);
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
                              title: Text(_matchedEmployees[index]),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => EmployeeReception()),
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
  @override
  _EmployeeReception createState() => _EmployeeReception();
}

class _EmployeeReception extends State<EmployeeReception> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Employee Reception')),
      body: 
      Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Welcome to Employee Reception', style: TextStyle(fontSize: 24)),
          ),
          // Add more widgets here as needed
        ],
      ),
    );
  }
}
