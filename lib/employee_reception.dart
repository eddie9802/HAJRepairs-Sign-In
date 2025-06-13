import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'google_sheets_talker.dart';

class EmployeeReception extends StatefulWidget {

  final Employee employee;

  const EmployeeReception({super.key, required this.employee});


  @override
  _EmployeeReceptionState createState() => _EmployeeReceptionState();

}

class _EmployeeReceptionState extends State<EmployeeReception> {
  late Future<String> _buttonTextFuture;

  @override
  void initState() {
    super.initState();
    _buttonTextFuture = GoogleSheetsTalker.sign(widget.employee).getButtonText();
  }

  Future<dynamic> showEmployeeDialog(BuildContext context, String? signing) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(''),
        content: Text('$signing at ${widget.employee.signings.last} successful!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> signEmployee(BuildContext context, String? signing) async {
    await GoogleSheetsTalker.sign(widget.employee).writeSigning();
    await showEmployeeDialog(context, signing);
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _buttonTextFuture, 
      builder: (context, snapshot) {
        String? signingButtonText;
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Future is still loading
          signingButtonText = 'Loading...';
        } else if (snapshot.hasError) {
          // Future completed with error
          signingButtonText = 'Error: ${snapshot.error}';
        } else {
          // Future completed successfully
          signingButtonText = snapshot.data ?? 'No data';
        }

      return(
        Scaffold(
          appBar: AppBar(title: Text('Employee Reception')),
          body:
          Center(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('What would you like to do, ${widget.employee.forename}?', style: TextStyle(fontSize: 24)),
                ),
                TextButton(
                  onPressed:() async {
                    String? signing = snapshot.data;
                    await signEmployee(context, signing);

                    setState(() {
                      _buttonTextFuture = GoogleSheetsTalker.sign(widget.employee).getButtonText();
                    });

                    // Returns to home screen
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    
                  },
                  child:  
                    Text(signingButtonText, style: TextStyle(fontSize: 24))
                ),
                Padding(padding: EdgeInsets.only(bottom: 40.0)),
                Expanded( 
                  child:
                  SizedBox(
                    width: 400,
                    child: 
                      ListView(
                        children: [
                          ...List.generate(widget.employee.signings.length, (index) {
                            if (index % 2 == 0) {
                              return 
                                Center(child: 
                                Padding(
                                  padding: EdgeInsets.only(bottom: 20.0),
                                  child: Text('Sign In: ${widget.employee.signings[index]}', style: TextStyle(fontSize: 20)))
                                  );
                            } else {
                              return
                                Center(child: 
                                Padding(
                                  padding: EdgeInsets.only(bottom: 20.0),
                                  child: Text('Sign Out: ${widget.employee.signings[index]}', style: TextStyle(fontSize: 20)))
                                  );
                            }
                          }),
                        ]
                      ),
                    )
                )
              ],
            ),
          ),
        )
      );
    }
    );
  }
}