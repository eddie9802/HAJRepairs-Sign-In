import 'package:flutter/material.dart';
import 'package:haj_repairs_sign_in/customer/customer_sign_in.dart';
import 'package:haj_repairs_sign_in/customer/customer_search.dart';

class CustomerForm extends StatefulWidget {
  const CustomerForm({super.key}); // Optional constructor with key

  @override
    _CustomerFormState createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {


  @override
  void initState() {
    super.initState();
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
                      child: 
                        Stack(
                          children: [
                            Center(
                              child: Text(
                                "Would you like to sign in or out?",
                                style: TextStyle(fontSize: 24),
                              ),
                            ),
                          ],
                        ),
                      ),
                  Padding(padding: EdgeInsets.symmetric(vertical: 10)),
                  Center(
                    child:
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => CustomerSignIn()),
                                );
                            },
                            child: Text("Sign in", style: TextStyle(fontSize: 24)),
                          ),
                          SizedBox(width: 40),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => CustomerFormSignOut()),
                                );
                            },
                            child: Text("Sign out", style: TextStyle(fontSize: 24)),
                          )
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}