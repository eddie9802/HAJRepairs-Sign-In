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
  final List<String> _customerFormQuestions = 
                                              ["What is your name?",
                                              "What company are you from?",
                                              "What is your contact number?",
                                              "What is your vehicle's registration number?",
                                              "What is your reason for visiting?"];
  
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
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _goToNextQuestion() {
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
      await showCustomerDialog("Your details have successfully been taken");
      Navigator.of(context).pop();
    } else {
      await showCustomerDialog("An error has occurred");
    }
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
                  Text(_customerFormQuestions[_currentStep]),
                  Padding(
                      padding: EdgeInsets.only(bottom: 40.0),
                      child:
                      SizedBox(
                        width: 800,
                        child: TextField(
                          controller: _controllers[_currentStep],
                          maxLength: isReasonForVisit ? 250 : null,
                          keyboardType: isReasonForVisit ? TextInputType.multiline : null,
                          maxLines: isReasonForVisit ? null : 1,
                          onSubmitted: (_) => _goToNextQuestion(),
                          decoration: InputDecoration(
                            //labelText: _customerForm[_currentStep],
                            border: OutlineInputBorder(),
                          ),
                        ),
                      )
                  ),
                  SizedBox(height: 20),
              if (_currentStep == _customerForm.length - 1)
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text("Submit"),
                )
              else
                ElevatedButton(
                  onPressed: _goToNextQuestion,
                  child: Text("Next"),
                ),
              ],
            ),
          ),
        ),
    );
  }
}