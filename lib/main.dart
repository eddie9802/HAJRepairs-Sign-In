import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'employee_search.dart';
import 'google_sheets_talker.dart';

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
                  onPressed: () async {
                    if (_employeeTypes[index] == 'Employee') {
                      // String weeklyTimesheetName = GoogleSheetsTalker.getTimesheetName();
                      
                      // // if timesheet is not found, create the timesheet
                      // if (!await GoogleSheetsTalker.checkForTimesheets(weeklyTimesheetName)) {
                      //     GoogleSheetsTalker().createTimesheet(weeklyTimesheetName);
                      // }
                      
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







