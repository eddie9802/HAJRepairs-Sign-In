import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'customer_sign_out.dart';
import 'customerHAJ.dart';
import 'dart:developer' as developer;


import 'google_sheets_talker.dart';

class CustomerSignOut extends StatefulWidget {

  final CustomerHAJ customer;

  const CustomerSignOut({super.key, required this.customer}); // Optional constructor with key

  @override
    CustomerSignOutState createState() => CustomerSignOutState();
}

class CustomerSignOutState extends State<CustomerSignOut> {

  final List<String> _customerFormSignOut = ["Initial", "Name", "Number"];
  final Map<String, String> _customerFormSignOutQuestions = {};

   final Map<String, String> _fieldText = {
                                        "default": "",
                                        "required": "This field is required",
                                        "invalid phone number": "Please enter a valid 11 digit phone number"
                                        };
  String _currentTextField = "default";
  bool _signButtonPressed = false;
  
  late List<TextEditingController> _controllers;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_customerFormSignOut.length - 1, (_) => TextEditingController()); // Creates two controllers for the name and number
    _customerFormSignOutQuestions[_customerFormSignOut[0]] = "Are you ${widget.customer.signInDriverName}?";
    _customerFormSignOutQuestions[_customerFormSignOut[1]] = "What is your name?";
    _customerFormSignOutQuestions[_customerFormSignOut[2]] = "What is your contact number?";
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }


  Future<dynamic> showCustomerDialog(String? popUpText) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(''),
        content: Text(popUpText!),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }


  bool isValidPhoneNumber(String input) {
    final phoneRegExp = RegExp(r'^\d{11}$');
    return phoneRegExp.hasMatch(input);
  }


  // Checks if the question is not empty
  void _validateQuestion() async {
    if (_currentStep == 0) {
      return;
    }

    String? input = _controllers[_currentStep - 1].text;
    print(input);
    if (input.isEmpty) {

      setState(() {
        _currentTextField = "required";
      });

    } else if (_customerFormSignOut[_currentStep] == "Number" && !isValidPhoneNumber(input)) {
      setState(() {
        _currentTextField = "invalid phone number";
      });

    } else {
      // Resets the _currentTextField if it was changed
      if (_currentTextField == "required") {
        _currentTextField = "default";
      }


    // Dismiss keyboard cleanly
    FocusScope.of(context).unfocus();

    // Wait a little to ensure the keyboard is fully gone
    await Future.delayed(const Duration(milliseconds: 200));


      // Goes to next question if there is another one
      // else, submit the form
      if (_currentStep < _customerFormSignOut.length - 1){
        _goToNextQuestion();
      } else {
        String driverName = _controllers[0].text;
        String driverNumber = _controllers[1].text;
        _signOut(driverName, driverNumber);
      }
    }
  }

  void _goToNextQuestion() {
    setState(() {
      if (_currentStep < _customerFormSignOut.length - 1) {
        _currentStep++;
      }
    });
  }


  // Takes the users details and signs out their vehicles
  void _signOut(String driverName, String driverNumber) async {
    CustomerHAJ customer = widget.customer;

    // Signals that the application should block
    setState(() {
      _signButtonPressed = true;
    });


    DateTime now = DateTime.now();
    Map<String, String> formData = {};
    for (int i = 0; i < _controllers.length; i++) {
      formData[_customerFormSignOut[i]] = _controllers[i].text;
    }


    widget.customer.signOutDriverName = driverName;
    widget.customer.signOutDriverNumber = driverNumber;
    widget.customer.signOut = DateFormat('h:mm a').format(now);
    widget.customer.signOutDate = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
    

    bool isUploaded = await GoogleSheetsTalker().signCustomerOut(customer);

    await Future.delayed(Duration(milliseconds: 200));
    if (isUploaded) {
      await showCustomerDialog("Your details have successfully been taken");
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } else {
      await showCustomerDialog("An error has occurred");
      setState(() {
         _signButtonPressed = false;
      });
    }
  }


  // Goes back to the previous question
  void _goToPreviousQuestion() {

    FocusScope.of(context).unfocus(); // Puts the keyboard away when the question changes

    // Ensures text field label is at the default
    if (_currentTextField == "required") {
      _currentTextField = "default";
    }
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      }
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
        title: Text("Customer Sign Out"),
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
                    Center(
                      child: Text(
                        _customerFormSignOutQuestions[_customerFormSignOut[_currentStep]]!,
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    if (_currentStep > 0)
                      Padding(
                          padding: EdgeInsets.only(bottom: 20.0, top: 20.0),
                          child:
                          SizedBox(
                            width: 800,
                            child: TextField(
                              enabled: _signButtonPressed ? false : true,
                              controller:  _currentStep > 0 ? _controllers[_currentStep-1] : null,
                              decoration: InputDecoration(
                                labelText: _fieldText[_currentTextField],
                                labelStyle: TextStyle(color: Colors.red),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          )
                      ),
                  if (_currentStep == 0)
                    SizedBox(height:20),
                  Center(
                    child:
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        if (_currentStep > 0)  
                          ElevatedButton(
                            onPressed: _currentStep == 0 ? null : _goToPreviousQuestion,
                            child: Text("Back", style: TextStyle(fontSize: 24)),
                          ),
                          SizedBox(width: 20),
                          Row(
                            children: [
                              if (_currentStep == 0)
                                ElevatedButton(
                                  onPressed: () {
                                    String driverName = widget.customer.signInDriverName;
                                    String driverNumber = widget.customer.signInDriverNumber;
                                    _signOut(driverName, driverNumber);
                                  },
                                  child: Text("Yes", style: TextStyle(fontSize: 24)),
                                ),
                              if (_currentStep == 0)
                                SizedBox(width: 20),
                              if (_currentStep == 0)
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _currentStep++;
                                    });
                                  },
                                  child: Text("No", style: TextStyle(fontSize: 24)),
                                ),
                              if (_currentStep > 1)
                                SizedBox(width: 20),
                              if (_currentStep > 0)
                                ElevatedButton(
                                  onPressed: _validateQuestion,
                                  child: Text( _currentStep == 1 ? "Next" : "Submit", style: TextStyle(fontSize: 24)),
                                )
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
                  // Blocks all user input while the signing occurs
        if (_signButtonPressed) ...[
          ModalBarrier(
            color: Colors.black.withAlpha(77),
            dismissible: false,
          ),

          Center(
            child: CircularProgressIndicator(),
          ),
        ]
      ],
    );
  }
}