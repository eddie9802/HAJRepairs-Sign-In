import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'colleague/colleague_search.dart';
import 'customer/customer_form.dart';
import 'supplier/supplier_form.dart';
import 'hidden-menu/hidden_menu.dart';
import 'hidden-menu/fire_report_service.dart';




void main() async {
  //await dotenv.load(fileName: "assets/.env");
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);
  runApp(
    ChangeNotifierProvider(
      create: (_) => FireReportService(),
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HAJ Reception',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Color.fromARGB(255, 0, 0, 0),             // 🔴 Blinking text cursor color
        ),
        scaffoldBackgroundColor: Color.fromARGB(255, 255, 255, 255), // global background
        appBarTheme: AppBarTheme(
          backgroundColor: Color.fromARGB(255, 255, 255, 255), // app bar background
          foregroundColor: Color.fromARGB(255, 0, 0, 0), // app bar text color
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Color(0xFFC10007), // text color
            backgroundColor: Color.fromARGB(255, 255, 255, 255),   // optional: button background
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: Color.fromARGB(255, 0, 0, 0)), // label text color
          floatingLabelStyle: TextStyle(color: Color(0xFFC10007)), // floating label text color
          border: OutlineInputBorder(), // default border
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFC10007), width: 2.0),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.deepOrange, width: 2.0),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
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


class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {

  int _tapCount = 0;
  Timer? _resetTimer;

  static const List<String> _employeeTypes = [
    'Customer',
    'Supplier',
    'HAJ Colleague'
  ];


  void _handleImageTap() {
    // Handle the image tap if needed
    // For example, you could show a dialog or perform some action

    _tapCount++;
    if (_resetTimer?.isActive ?? false) {
      _resetTimer!.cancel(); // Cancel the previous timer if it's still active
    }

    // Start a new timer that resets tap count after 10 seconds
    _resetTimer = Timer(Duration(seconds: 2), () {
      setState(() {
        _tapCount = 0;
      });
    });

    if (_tapCount >= 7) {
      _tapCount = 0; // Reset tap count
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HiddenMenu()),
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    Provider.of<FireReportService>(context, listen: false);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 50.0, right: 50.0, top: 50.0),
        child: Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _handleImageTap,
                child: Image.asset(
                  'assets/images/haj-logo-tablet.png',
                ),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'Welcome to HAJ Repairs.  Are you a Customer, Supplier or HAJ Colleague?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40.0),
              ..._employeeTypes.map((type) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: TextButton(
                    child: Text(type, style: const TextStyle(fontSize: 28, color: Color(0xFFC10007))),
                    onPressed: () {
                      Widget targetPage;


                      if (type == _employeeTypes[0]) {
                        targetPage = CustomerForm();
                      } else if (type == _employeeTypes[1]) {
                        targetPage = SupplierForm();
                      }else if (type == _employeeTypes[2]) {
                        targetPage = ColleagueSearch();
                      } else{
                        return;
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






