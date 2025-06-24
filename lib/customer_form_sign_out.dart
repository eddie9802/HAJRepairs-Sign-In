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
    return Stack(
      children: [
        Scaffold(
        appBar: getAppbar(),
        body: Center(
          child:
            SingleChildScrollView(
              child:
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 800,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: 
                          Text(
                            "Question ${_currentStep + 1} of ${_customerFormSignOutQuestions.length}",
                            style: TextStyle(fontSize: 18),
                          ),
                      ),
                    ),
                    Center(
                      child: Text(
                        _customerFormSignOutQuestions[_currentStep],
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    Padding(
                        padding: EdgeInsets.only(bottom: 20.0, top: 20.0),
                        child:
                        SizedBox(
                          width: 800,
                          child: TextField(
                            enabled: _signButtonPressed ? false : true,
                            controller: _controllers[_currentStep],
                            maxLength: isReasonForVisit ? 250 : null,
                            keyboardType: isReasonForVisit ? TextInputType.multiline : null,
                            maxLines: isReasonForVisit ? null : 1,
                            decoration: InputDecoration(
                              labelText: _fieldText[_currentTextField],
                              labelStyle: TextStyle(color: Colors.red),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        )
                    ),
                  Center(
                    child:
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: _currentStep == 0 ? null : _goToPreviousQuestion,
                            child: Text("Back", style: TextStyle(fontSize: 24)),
                          ),
                          SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: _validateQuestion,
                            child: Text( _currentStep == _customerFormSignOut.length - 1 ? "Submit" : "Next", style: TextStyle(fontSize: 24)),
                          )
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}