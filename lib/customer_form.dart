import 'package:flutter/material.dart';
import 'dart:developer' as developer;

class CustomerForm extends StatefulWidget {
  const CustomerForm({super.key}); // Optional constructor with key

  @override
    _CustomerFormState createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {

  late List<String> _customerForm;

  @override
  void initState() {
    super.initState();
    _customerForm = ["Name", "Company", "Contact Number"];
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
                      return Padding(
                        padding: EdgeInsets.only(bottom: 40.0),
                        child:
                        SizedBox(
                          width: 800,
                          child: TextField(
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
                  SizedBox(
                    width: 800,
                    child: TextField(
                      maxLength: 250,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      onChanged: (value) => developer.log("Hello"),
                      decoration: InputDecoration(
                        labelText: "Reason For Visit",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  )
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 40.0),
                  child:
                  ElevatedButton(
                    onPressed: () {developer.log("Hello");},
                    child: Text("Submit"))
                )
              ],
            ),
          ),
        ),
    );
  }
}