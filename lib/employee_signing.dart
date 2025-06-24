import 'package:flutter/material.dart';
import 'google_sheets_talker.dart';
import 'dart:developer' as developer;

class EmployeeReception extends StatefulWidget {

  final Employee employee;

  const EmployeeReception({super.key, required this.employee});


  @override
  _EmployeeReceptionState createState() => _EmployeeReceptionState();

}

class _EmployeeReceptionState extends State<EmployeeReception> {
  late Future<String> _buttonTextFuture;
  bool _signButtonPressed = false;

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

  Future<void> signEmployee(BuildContext context, String? signing) async {
    await GoogleSheetsTalker.sign(widget.employee).writeSigning();
    await showEmployeeDialog(context, signing);
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
        title: Text("Colleague Reception"),
      )
    );
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

      return
        Stack(
          children: [
            Scaffold(
            appBar: getAppbar(),
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

                        setState(() {
                          _signButtonPressed = true;
                        });

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
                    ),
                  ],
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
      },
    );
  }
}
