import 'package:flutter/material.dart';
import 'dart:developer' as developer;

import 'google_sheets_talker.dart';

class CustomerForm extends StatefulWidget {
  const CustomerForm({super.key}); // Optional constructor with key

  @override
    _CustomerFormState createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {

  final List<String> _customerForm = ["Name", "Company", "Contact Number", "Registration Number", "Reason For Visit"];
  final List<String> _customerFormQuestions = [
                                              "What is your name?",
                                              "What company are you from?",
                                              "What is your contact number?",
                                              "What is your vehicle's registration number?",
                                              "What is your reason for visiting?"
                                              ];

  final Map<String, String> _fieldText = {"default": "", "required": "This field is required"};
  String _currentTextField = "default";
  
  late List<TextEditingController> _controllers;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_customerForm.length, (_) => TextEditingController());
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
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.of(context).pop();
              },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }


  // Checks if the question is not empty
  void _validateQuestion() {
    if (_controllers[_currentStep].text.trim().isEmpty) {
      setState(() {
        _currentTextField = "required";
      });
    } else {

      // Resets the _currentTextField if it was changed
      if (_currentTextField == "required") {
        _currentTextField = "default";
      }

      // Goes to next question if there is another one
      // else, submit the form
      if (_currentStep < _customerForm.length - 1){
        _goToNextQuestion();
      } else {
        _submitForm();
      }
      
    }
  }

  void _goToNextQuestion() {
    FocusScope.of(context).unfocus(); // Puts the keyboard away when the question changes
    setState(() {
      if (_currentStep < _customerForm.length - 1) {
        _currentStep++;
      }
    });
  }

  void _submitForm() async {
    DateTime now = DateTime.now();
    String date = "${now.day}/${now.month}/${now.year}";

    Map<String, String> formData = {};
    for (int i = 0; i < _controllers.length; i++) {
      formData[_customerForm[i]] = _controllers[i].text;
    }
    formData["Date"] = date;

    bool isUploaded = await GoogleSheetsTalker().uploadCustomerData(formData);
    if (isUploaded) {
      FocusManager.instance.primaryFocus?.unfocus();
      await showCustomerDialog("Your details have successfully been taken");
      Navigator.of(context).pop();
    } else {
      await showCustomerDialog("An error has occurred");
    }
  }


  // Goes back to the previous question
  void _goToPreviousQuestion() {

    // Ensures text field label is at the default
    if (_currentTextField == "required") {
      _currentTextField = "default";
    }
    FocusScope.of(context).unfocus(); // Puts the keyboard away when the question changes
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isReasonForVisit = _customerForm[_currentStep] == "Reason For Visit";
    return Scaffold(
      appBar: AppBar(title: Text('Customer Form')),
      body: Center(
        child:
          SingleChildScrollView(
            child:
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(_customerFormQuestions[_currentStep],
                    style: TextStyle(fontSize: 24),),
                  Padding(
                      padding: EdgeInsets.only(bottom: 40.0, top: 40.0),
                      child:
                      SizedBox(
                        width: 800,
                        child: TextField(
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
                Text(
                  "Question ${_currentStep + 1} of ${_customerFormQuestions.length}",
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),
                Center(
                  child:
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: _currentStep == 0 ? null : _goToPreviousQuestion,
                          child: Text("Back", style: TextStyle(fontSize: 24)),
                        ),
                        SizedBox(width: 40),
                        ElevatedButton(
                          onPressed: _validateQuestion,
                          child: Text( _currentStep == _customerForm.length - 1 ? "Submit" : "Next", style: TextStyle(fontSize: 24)),
                        )
                      ],
                    ),
                  )
              ],
            ),
          ),
        ),
    );
  }
}