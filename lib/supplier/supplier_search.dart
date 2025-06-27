import 'package:flutter/material.dart';
import 'supplierHAJ.dart';
import 'supplier_sign_out.dart';

import '../google_sheets_talker.dart';

class SupplierSearch extends StatefulWidget {
  const SupplierSearch({super.key}); // Optional constructor with key

  @override
    _SupplierSearchState createState() => _SupplierSearchState();
}

class _SupplierSearchState extends State<SupplierSearch> {

  bool _signButtonPressed = false;
  final Future<List<SupplierHAJ>> _allSuppliersFuture = GoogleSheetsTalker().retrieveSuppliers();


    List<SupplierHAJ> _matchedSuppliers = [];

  // Function to get matched suppliers based on search input
  Future<List<SupplierHAJ>> getMatchingSuppliers(String reg) async {
    List<SupplierHAJ> matched = [];
    final allSuppliers = await _allSuppliersFuture;
    for (var supplier in allSuppliers) {
      if (supplier.name.toLowerCase().startsWith(reg.toLowerCase()) && reg.isNotEmpty) {
        matched.add(supplier);
      }
    }
    return matched;
  }

  void setMatchedSuppliers(String reg) async {
    List<SupplierHAJ> matches = await getMatchingSuppliers(reg);
    setState(() => 
    _matchedSuppliers = matches
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
        title: Text("Supplier Search"),
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
                    "Please enter your name",
                    style: TextStyle(fontSize: 24),
                  ),
                ),
                Padding(
                    padding: EdgeInsets.only(top: 20.0),
                    child:
                    SizedBox(
                      width: 400,
                      child: TextField(
                        textCapitalization: TextCapitalization.words,
                        enabled: _signButtonPressed ? false : true,
                        onChanged: (value) => setMatchedSuppliers(value),
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
                    ...List.generate(_matchedSuppliers.length, (index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                            title: Text(_matchedSuppliers[index].name),
                            onTap: () async {
                              FocusManager.instance.primaryFocus?.unfocus(); // Dismiss keyboard
                              // Wait a little to ensure the keyboard is fully gone
                              await Future.delayed(const Duration(milliseconds: 200));
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SupplierSignOut(supplier: _matchedSuppliers[index])),
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