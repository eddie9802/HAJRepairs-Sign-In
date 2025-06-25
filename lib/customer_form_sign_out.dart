import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;


import 'google_sheets_talker.dart';

class CustomerFormSignOut extends StatefulWidget {
  const CustomerFormSignOut({super.key}); // Optional constructor with key

  @override
    _CustomerFormSignOutState createState() => _CustomerFormSignOutState();
}

class _CustomerFormSignOutState extends State<CustomerFormSignOut> {

  bool _signButtonPressed = false;
  final Future<List<dynamic>?> _allCustomers = GoogleSheetsTalker().retrieveCustomers();


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
        title: Text("Customer Form"),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppbar(),
      body: SingleChildScrollView(
          child:
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
              alignment: Alignment.topCenter, // Ensures horizontal centering, vertical top
              child:
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: Text(
                        "Please enter your vehicle's registration number",
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    Padding(
                        padding: EdgeInsets.only(bottom: 20.0, top: 20.0),
                        child:
                        SizedBox(
                          width: 600,
                          child: TextField(
                            enabled: _signButtonPressed ? false : true,
                            decoration: InputDecoration(
                              //labelText: _fieldText[_currentTextField],
                              labelStyle: TextStyle(color: Colors.red),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        )
                    ),
                ],
              ),
            )
        ),
      );
    }
}