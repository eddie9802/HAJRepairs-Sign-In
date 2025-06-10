import 'package:flutter/material.dart';
import 'dart:developer' as developer;

void main() {
  runApp(const MainApp());
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

  List<String> _matchedDrivers = [];


  // Function to get matched drivers based on search input
  List<String> getMatchedDrivers(String search) {
    List<String> matched = [];
    for (var driver in _drivers) {
      if (driver.toLowerCase().startsWith(search.toLowerCase()) && search.isNotEmpty) {
        matched.add(driver);
      }
    }
    return matched;
  }
  
  // Function to update the matched drivers based on user input
  void setMatchedDrivers(String search) {
    setState(() {
      _matchedDrivers = getMatchedDrivers(search);
    });
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: EdgeInsets.only(left: 300.0, right: 300.0, top: 50.0),
          child: Column(
            children: [
              Image.asset('assets/images/haj-logo.png'),
              Padding(padding: EdgeInsets.only(bottom: 80.0)),
              Text(
                  'Welcome to HAJ Repairs.  Are you a Customer, Supplier, Driver or Employee?',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center
              ),
              TextField(
                onChanged: (value) => setMatchedDrivers(value),
                decoration: InputDecoration(
                  labelText: 'Enter name',
                  border: OutlineInputBorder(),
                ),
              ),
              _matchedDrivers.isNotEmpty
                  ? Expanded(
                      child: ListView.builder(
                        itemCount: _matchedDrivers.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_matchedDrivers[index]),
                            tileColor: Colors.red,
                            onTap: () {
                              developer.log('Selected driver: ${_matchedDrivers[index]}');
                              // You can add more actions here, like navigating to a details page
                            },
                          );
                        },
                      ),
                    ) 
                  :
                  const Text('No matches found'),
            ],
          ),
        ),
      ),
    );
  }
}
