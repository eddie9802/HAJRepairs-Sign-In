import 'package:flutter/material.dart';
import 'supplierHAJ.dart';
import 'package:intl/intl.dart';
import './supplier_excel_talker.dart';


class SupplierSignOut extends StatefulWidget {

  final SupplierHAJ supplier;

  const SupplierSignOut({super.key, required this.supplier}); // Optional constructor with key

  @override
    SupplierSignOutState createState() => SupplierSignOutState();
}

class SupplierSignOutState extends State<SupplierSignOut> {

  bool _signButtonPressed = false;




  Future<dynamic> showSupplierDialog(String? popUpText) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(''),
        content: Text(popUpText!),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }


  // Takes the users details and signs out their vehicles
  void _signOut() async {
    SupplierHAJ supplier = widget.supplier;

    // Signals that the application should block
    setState(() {
      _signButtonPressed = true;
    });
    
    DateTime now = DateTime.now();
    supplier.signOut = DateFormat('h:mm a').format(now);

    (bool, String) response = await SupplierExcelTalker().signSupplierOut(supplier);

    await Future.delayed(Duration(milliseconds: 200));
    if (response.$1) {
      await showSupplierDialog(response.$2);
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } else {
      await showSupplierDialog("Error: ${response.$2}");
      setState(() {
         _signButtonPressed = false;
      });
    }
  }



  List<String> getSupplierDetails() {
    List<String> supplierDetails = [];
    SupplierHAJ supplier = widget.supplier;
    supplierDetails.add("Name: ${supplier.name}");
    supplierDetails.add("Company: ${supplier.company}");
    supplierDetails.add("Reasons For Visit: ${supplier.reasonForVisit}");
    supplierDetails.add("Date: ${supplier.date}");
    supplierDetails.add("Sign In: ${supplier.signIn}");
    return supplierDetails;
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
    List<String> customerDetailsList = getSupplierDetails();

    return Scaffold(
      appBar: getAppbar(),
      body: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Supplier details for ${widget.supplier.name}",
                  style: const TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: SizedBox(
                    width: 600,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: customerDetailsList.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          title: Text(
                            customerDetailsList[index],
                            style: const TextStyle(fontSize: 20),
                          ),
                          onTap: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _signOut,
                  child: const Text("Sign Out", style: TextStyle(fontSize: 24)),
                ),
              ],
            ),
          ),

          if (_signButtonPressed) ...[
            ModalBarrier(
              color: Colors.black.withAlpha(77),
              dismissible: false,
            ),
            const Center(
              child: CircularProgressIndicator(),
            ),
          ],
        ],
      ),
    );
  }
}