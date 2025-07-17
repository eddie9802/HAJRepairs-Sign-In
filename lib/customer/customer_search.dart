import 'package:flutter/material.dart';
import 'package:haj_repairs_sign_in/customer/customer_excel_talker.dart';

import '../common_widgets.dart';
import 'customerHAJ.dart';
import 'customer_sign_out_details.dart';
import '../haj_response.dart';
class CustomerFormSignOut extends StatefulWidget {
  const CustomerFormSignOut({super.key}); // Optional constructor with key

  @override
    _CustomerFormSignOutState createState() => _CustomerFormSignOutState();
}

class _CustomerFormSignOutState extends State<CustomerFormSignOut> {

  final TextEditingController _controller = TextEditingController();
  late final Future<void> _customerFuture;
  List<CustomerHAJ> _allCustomers = <CustomerHAJ>[];
  List<CustomerHAJ> _matchedCustomers = [];
  bool _signButtonPressed = false;



  @override
  void dispose() {
    _controller.dispose(); // Don't forget to dispose the controller
    super.dispose();
  }


  @override
  void initState() {
    super.initState();
    _customerFuture = initCustomers();
  }


  Future<void> initCustomers() async {
    HAJResponse response = await CustomerExcelTalker().retrieveCustomers();
    if (response.isSuccess) {
      _allCustomers = response.body as List<CustomerHAJ>;
    } else {
      await showDialogPopUp(context, response.message);
      Navigator.of(context).pop();
    }
  }

  // Function to get matched customers based on search input
  Future<List<CustomerHAJ>> getMatchingCustomers(String reg) async {
    List<CustomerHAJ> matched = [];
    for (var customer in _allCustomers) {
      if (customer.registration.toLowerCase().startsWith(reg.toLowerCase()) && reg.isNotEmpty) {
        matched.add(customer);
      }
    }
    return matched;
  }

  void setMatchedCustomers(String reg) async {
    await _customerFuture;
    List<CustomerHAJ> matches = await getMatchingCustomers(reg);
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
          padding: EdgeInsets.only(top: 50),
          alignment: Alignment.topCenter, // Ensures horizontal centering, vertical top
          child:
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 400,
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.characters,
                    enabled: _signButtonPressed ? false : true,
                    onChanged: (value) => setMatchedCustomers(value),
                    decoration: InputDecoration(
                      //labelText: _fieldText[_currentTextField],
                      labelText: 'Please enter your vehicle\'s registration number',
                    ),
                  ),
                ),
               Expanded( // gives height to FutureBuilder result
                child: FutureBuilder<void>(
                  future: _customerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(height: 40), // Push it down a bit from the top
                          loadingIndicator(),
                        ],
                      );
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error loading colleagues'));
                    } else {
                      return Column(
                        children: [
                          showNResults(_controller.text.isNotEmpty, _matchedCustomers.length, "vehicle"),
                          Expanded(
                            child:
                            SizedBox(
                            width: 400,
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
                      );
                    }
                  },
                ),
              ),
            ],
          ),
      ),
    );
  }
}