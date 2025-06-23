import 'package:flutter/material.dart';
import 'dart:developer' as developer;

class CustomerForm extends StatefulWidget {
  const CustomerForm({super.key}); // Optional constructor with key

  @override
    _CustomerFormState createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {

  final List<String> _customerForm = ["Name", "Company", "Contact Number", "Registration Number", "Reason For Visit"];
  late List<TextEditingController> _controllers;

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


  @override
  Widget build(BuildContext context) {
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
                  Padding(padding: EdgeInsets.only(top: 40.0)),
                    ...List.generate(_customerForm.length, (index) {
                      bool isReasonForVisit = _customerForm[index] == "Reason For Visit";
                      return Padding(
                        padding: EdgeInsets.only(bottom: 40.0),
                        child:
                        SizedBox(
                          width: 800,
                          child: TextField(
                            controller: _controllers[index],
                            maxLength: isReasonForVisit ? 250 : null,
                            keyboardType: isReasonForVisit ? TextInputType.multiline : null,
                            maxLines: isReasonForVisit ? null : 1,
                            onChanged: (value) => developer.log("Hello"),
                            decoration: InputDecoration(
                            labelText: _customerForm[index],
                            border: OutlineInputBorder(),
                            ),
                          ),
                        )
                      );
                    }),
                Padding(
                  padding: EdgeInsets.only(bottom: 40.0),
                  child:
                  ElevatedButton(
                    onPressed: () {
                      
                    },
                    child: Text("Submit"))
                )
              ],
            ),
          ),
        ),
    );
  }
}