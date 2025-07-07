import 'package:flutter/material.dart';
import 'customerHAJ.dart';
import 'customer_sign_out.dart';
import '../spreadsheet_utilities.dart';


class CustomerSignOutDetails extends StatefulWidget {

  final CustomerHAJ customer;

  const CustomerSignOutDetails({super.key, required this.customer}); // Optional constructor with key

  @override
    CustomerSignOutDetailsState createState() => CustomerSignOutDetailsState();
}

class CustomerSignOutDetailsState extends State<CustomerSignOutDetails> {



  List<String> getCustomerDetailsList() {
    List<String> customerDetailsList = [];
    CustomerHAJ customer = widget.customer;
    customerDetailsList.add("Registration: ${customer.registration}");
    customerDetailsList.add("Company: ${customer.company}");
    customerDetailsList.add("Driver Name: ${customer.signInDriverName}");
    customerDetailsList.add("Contact Number: ${customer.signInDriverNumber}");
    customerDetailsList.add("Reason For Visit: ${customer.reasonForVisit}");
    customerDetailsList.add("Sign In Date: ${customer.signInDate}");
    customerDetailsList.add("Sign In Time: ${excelFractionToTimeAmPm(double.parse(customer.signIn))}");
    return customerDetailsList;
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
        title: Text("Customer Sign Out Details"),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> customerDetailsList = getCustomerDetailsList();
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
                    "Customer details for ${widget.customer.registration}",
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              Padding(padding: EdgeInsets.symmetric(vertical: 15)),
              Expanded(
                child:
                SizedBox(
                width: 600,
                child: ListView(
                  padding: EdgeInsets.all(16.0),
                  children: [
                    ...List.generate(customerDetailsList.length, (index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                            title: Text(customerDetailsList[index], style: TextStyle(fontSize: 20)),
                            onTap: () {
                              FocusManager.instance.primaryFocus?.unfocus(); // Dismiss keyboard
                            },
                          ),
                        );
                      }),
                    ]
                  ),
                ),
              ),
              Padding(padding: EdgeInsets.symmetric(vertical: 10)),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => CustomerSignOut(customer: widget.customer)),
                              );
                },
                child: Text("Sign Out", style: TextStyle(fontSize: 24)),
              ),
            ],
          ),
        )
    );
  }
}