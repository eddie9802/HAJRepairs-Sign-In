import 'package:flutter/material.dart';
import 'colleague_excel_talker.dart';
import 'colleague.dart';


class ColleagueReception extends StatefulWidget {

  final Colleague colleague;

  const ColleagueReception({super.key, required this.colleague});


  @override
  _ColleagueReceptionState createState() => _ColleagueReceptionState();

}

class _ColleagueReceptionState extends State<ColleagueReception> {
  late Future<String> _buttonTextFuture;
  bool _signButtonPressed = false;
  late Colleague _colleague;

  @override
  void initState() {
    super.initState();
     _colleague = widget.colleague;
    _buttonTextFuture = _getButtonTextFuture(_colleague);
  }

  Future<dynamic> showColleagueDialog(BuildContext context, String dialogMessage) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(''),
        content: Text(dialogMessage),
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

  // Writes the signing to excel online spreadsheet and then displays popup
  Future<void> signColleague(BuildContext context, String? signing) async {
    (bool?, String) res = await ColleagueExcelTalker().writeSigning(_colleague);
    bool success = res.$1!;
    String time = res.$2;
    String dialogMessage;
    if (success) {
      dialogMessage = '$signing at $time successful!';
    } else {
      dialogMessage = 'Error:  Failed to write to timesheet';
    }
    await showColleagueDialog(context, dialogMessage);
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


  // Returns a future which when awaited will return the text the signing button should display
  Future<String> _getButtonTextFuture(Colleague colleague) async {

    // Updates the signing details of the colleague
    await ColleagueExcelTalker().setSigningDetails(colleague);

    String buttonText;
    // Finds out if the user is signing in or out
    if (colleague.signings.length % 2 == 0) {
      buttonText = "Sign In";
    } else {
      buttonText = "Sign Out";
    }
    return buttonText;
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
                      child: Text('What would you like to do, ${_colleague.forename}?', style: TextStyle(fontSize: 24)),
                    ),
                    ElevatedButton(
                      onPressed:() async {
                        String? signing = snapshot.data;

                        // Locks the screen while the signing data is being uploaded
                        setState(() {
                          _signButtonPressed = true;
                        });

                        await signColleague(context, signing);

                        setState(() {
                          _buttonTextFuture = _getButtonTextFuture(_colleague);
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
                              ...List.generate(_colleague.signings.length, (index) {
                                if (index % 2 == 0) {
                                  return 
                                    Center(child: 
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 20.0),
                                      child: Text('Sign In: ${_colleague.signings[index]}', style: TextStyle(fontSize: 20)))
                                      );
                                } else {
                                  return
                                    Center(child: 
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 20.0),
                                      child: Text('Sign Out: ${_colleague.signings[index]}', style: TextStyle(fontSize: 20)))
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
