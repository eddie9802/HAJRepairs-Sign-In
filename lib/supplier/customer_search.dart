import 'package:flutter/material.dart';
import 'supplierHAJ.dart';
import 'customer_sign_out_details.dart';

import '../google_sheets_talker.dart';

class CustomerFormSignOut extends StatefulWidget {
  const CustomerFormSignOut({super.key}); // Optional constructor with key

  @override
    _CustomerFormSignOutState createState() => _CustomerFormSignOutState();
}

class _CustomerFormSignOutState extends State<CustomerFormSignOut> {

  bool _signButtonPressed = false;
  final Future<List<SupplierHAJ>> _allCustomersFuture = GoogleSheetsTalker().retrieveCustomers();


    List<SupplierHAJ> _matchedCustomers = [];

  // Function to get matched customers based on search input
  Future<List<SupplierHAJ>> getMatchingCustomers(String reg) async {
    List<SupplierHAJ> matched = [];
    final allCustomers = await _allCustomersFuture;
    for (var customer in allCustomers) {
      if (customer.registration.toLowerCase().startsWith(reg.toLowerCase()) && reg.isNotEmpty) {
        matched.add(customer);
      }
    }
    return matched;
  }

  void setMatchedCustomers(String reg) async {
    List<SupplierHAJ> matches = await getMatchingCustomers(reg);
    setState(() => 
    _matchedCustomers = matches
    ,);
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
        title: Text("Customer Search"),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppbar(),
      body: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
          alignment: Alignment.topCenter, // Ensures horizontal centering, vertical top
          child:
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Text(
                    "Please enter your vehicle's registration number",
                    style: TextStyle(fontSize: 24),
                  ),
                ),
                Padding(
                    padding: EdgeInsets.only(top: 20.0),
                    child:
                    SizedBox(
                      width: 400,
                      child: TextField(
                        textCapitalization: TextCapitalization.characters,
                        enabled: _signButtonPressed ? false : true,
                        onChanged: (value) => setMatchedCustomers(value),
                        decoration: InputDecoration(
                          //labelText: _fieldText[_currentTextField],
                          labelStyle: TextStyle(color: Colors.red),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    )
                ),
              Expanded(
                child:
                SizedBox(
                width: 400,
                height: 600,
                child: ListView(
                  padding: EdgeInsets.all(16.0),
                  children: [
                    ...List.generate(_matchedCustomers.length, (index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                            title: Text(_matchedCustomers[index].registration),
                            onTap: () async {
                              FocusManager.instance.primaryFocus?.unfocus(); // Dismiss keyboard
                              // Wait a little to ensure the keyboard is fully gone
                              await Future.delayed(const Duration(milliseconds: 200));
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => CustomerSignOutDetails(customer: _matchedCustomers[index])),
                              );
                            },
                          ),
                        );
                      }),
                    ]
                  ),
                ),
              ),
            ],
          ),
        )
    );
  }
}