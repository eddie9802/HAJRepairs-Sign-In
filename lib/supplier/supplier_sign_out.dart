import 'package:flutter/material.dart';
import 'supplierHAJ.dart';
import 'supplier_sign_out.dart';


class SupplierSignOutDetails extends StatefulWidget {

  final SupplierHAJ supplier;

  const SupplierSignOutDetails({super.key, required this.supplier}); // Optional constructor with key

  @override
    SupplierSignOutDetailsState createState() => SupplierSignOutDetailsState();
}

class SupplierSignOutDetailsState extends State<SupplierSignOutDetails> {



  List<String> getSupplierDetailsList() {
    List<String> supplierDetailsList = [];
    SupplierHAJ supplier = widget.supplier;
    supplierDetailsList.add("Name: ${supplier.name}");
    supplierDetailsList.add("Company: ${supplier.company}");
    supplierDetailsList.add("Driver Name: ${supplier.reasonForVisit}");
    return supplierDetailsList;
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
        title: Text("Supplier Sign Out Details"),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> customerDetailsList = getSupplierDetailsList();
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
                    "Supplier details for ${widget.supplier.name}",
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
                  // Navigator.push(
                  //               context,
                  //               MaterialPageRoute(builder: (context) => SupplierSignOut(customer: widget.supplier)),
                  //             );
                },
                child: Text("Sign Out", style: TextStyle(fontSize: 24)),
              ),
            ],
          ),
        )
    );
  }
}