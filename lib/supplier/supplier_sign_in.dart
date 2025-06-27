import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


import '../google_sheets_talker.dart';

class SupplierSignIn extends StatefulWidget {
  const SupplierSignIn({super.key}); // Optional constructor with key

  @override
    SupplierSignInState createState() => SupplierSignInState();
}

class SupplierSignInState extends State<SupplierSignIn> {

  final List<String> _supplierSignIn = ["Registration", "Company", "Name", "Driver Number", "Reason For Visit"];
  final List<String> _supplierSignInQuestions = [
                                              "What is your registration?",
                                              "What company are you from?",
                                              "What is your name?",
                                              "What is your contact number?",
                                              "What is your reason for visiting?"
                                              ];

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
    _controllers = List.generate(_supplierSignIn.length, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }


bool isValidPhoneNumber(String input) {
  final phoneRegExp = RegExp(r'^\d{11}$');
  return phoneRegExp.hasMatch(input);
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


  // Checks if the question is not empty
  void _validateQuestion() async {

    String userInput = _controllers[_currentStep].text.trim();
    if (userInput.isEmpty) {
      setState(() {
        _currentTextField = "required";
      });
    } else if (_supplierSignIn[_currentStep] == "Driver Number" && !isValidPhoneNumber(userInput)) {
      setState(() {
        _currentTextField = "invalid phone number";
      });
    } else {


      // Resets the _currentTextField if it was changed
      if (_currentTextField != "default") {
        setState(() {
          _currentTextField = "default";
        });
      }

    if (_supplierSignIn[_currentStep] == "Registration") {
        _controllers[_currentStep].text = userInput.toUpperCase().replaceAll(' ', '');
    }

    // Dismiss keyboard cleanly
    FocusScope.of(context).unfocus();

    // Wait a little to ensure the keyboard is fully gone
    await Future.delayed(const Duration(milliseconds: 200));


      // Goes to next question if there is another one
      // else, submit the form
      if (_currentStep < _supplierSignIn.length - 1){
        _goToNextQuestion();
      } else {
        _submitForm();
      }
    }
  }

  void _goToNextQuestion() {
    setState(() {
      if (_currentStep < _supplierSignIn.length - 1) {
        _currentStep++;
      }
    });
  }

  void _submitForm() async {

    // Signals that the application should block
    setState(() {
      _signButtonPressed = true;
    });


    DateTime now = DateTime.now();
    String date = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

    Map<String, String> formData = {};
    for (int i = 0; i < _controllers.length; i++) {
      formData[_supplierSignIn[i]] = _controllers[i].text;
    }
    formData["Date"] = date;
    formData["Sign in"] = DateFormat('h:mm a').format(now);

    if (formData["Driver Number"]!.trim().isEmpty) {
      formData["Driver Number"] = "N/A";
    }
    

    (bool, String) response = await GoogleSheetsTalker().signCustomerIn(formData);

    // response.$1 is the success of the sign in
    if (response.$1) {
      await showCustomerDialog(response.$2);
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } else {
      await showCustomerDialog("An error has occurred: ${response.$2}");
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
        title: Text("Supplier Sign In"),
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
                            "Question ${_currentStep + 1} of ${_supplierSignInQuestions.length}",
                            style: TextStyle(fontSize: 18),
                          ),
                      ),
                    ),
                    Center(
                      child: Text(
                        _supplierSignInQuestions[_currentStep],
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    Padding(
                        padding: EdgeInsets.only(bottom: 20.0, top: 20.0),
                        child:
                        SizedBox(
                          width: 800,
                          child: TextField(
                            textCapitalization:
                              _supplierSignIn[_currentStep] == "Reason For Visit" ? TextCapitalization.sentences :
                              _supplierSignIn[_currentStep] == "Registration" ?
                              TextCapitalization.characters : TextCapitalization.words,
                            enabled: _signButtonPressed ? false : true,
                            controller: _controllers[_currentStep],
                            maxLength: _supplierSignIn[_currentStep] == "Reason For Visit" ? 250 : null,
                            keyboardType: _supplierSignIn[_currentStep] == "Reason For Visit" ? TextInputType.multiline : null,
                            maxLines: _supplierSignIn[_currentStep] == "Reason For Visit" ? null : 1,
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
                            child: Text( _currentStep == _supplierSignIn.length - 1 ? "Submit" : "Next", style: TextStyle(fontSize: 24)),
                          )
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