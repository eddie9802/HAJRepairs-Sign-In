import 'package:flutter/material.dart';
import 'employee_search.dart';
import 'customer_form_sign_in.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HAJ Reception',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: child!,
        );
      },
      home: MainPage(), // Your first screen (with the Scaffold, logo, etc.)
    );
  }
}


class MainPage extends StatelessWidget {
  const MainPage({super.key});


  static const List<String> _employeeTypes = [
    'Customer',
    'Supplier',
    'Colleague'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 50.0, right: 50.0, top: 50.0),
        child: Center(
          child: Column(
            children: [
              Image.asset('assets/images/haj-logo.png'),
              const SizedBox(height: 10.0),
              const Text(
                'Welcome to HAJ Repairs.  Are you a Customer, Supplier or Colleague?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40.0),
              ..._employeeTypes.map((type) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: TextButton(
                    child: Text(type, style: const TextStyle(fontSize: 28)),
                    onPressed: () {
                      Widget targetPage;

                      if (type == 'Colleague') {
                        targetPage = EmployeeSearch();
                      } else if (type == 'Customer') {
                        targetPage = CustomerForm();
                      } else {
                        return; // Handle Supplier or add more cases
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => targetPage),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}






