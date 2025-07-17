import 'package:flutter/material.dart';

import '../common_widgets.dart';
import 'supplierHAJ.dart';
import 'supplier_sign_out.dart';
import './supplier_excel_talker.dart';
import '../haj_response.dart';

class SupplierSearch extends StatefulWidget {
  const SupplierSearch({super.key}); // Optional constructor with key

  @override
    _SupplierSearchState createState() => _SupplierSearchState();
}

class _SupplierSearchState extends State<SupplierSearch> {

  final TextEditingController _controller = TextEditingController();
  bool _signButtonPressed = false;
  List<SupplierHAJ> _allSuppliers = [];
  late final Future<void> _supplierFuture;

    List<SupplierHAJ> _matchedSuppliers = [];

  // Function to get matched suppliers based on search input
  Future<List<SupplierHAJ>> getMatchingSuppliers(String reg) async {
    List<SupplierHAJ> matched = [];
    await _supplierFuture;
    for (var supplier in _allSuppliers) {
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

  @override
  void dispose() {
    _controller.dispose(); // Don't forget to dispose the controller
    super.dispose();
  }

    @override
  void initState() {
    super.initState();
    _supplierFuture = initSuppliers();
  }

  Future<void> initSuppliers() async {
    HAJResponse response = await SupplierExcelTalker().retrieveSuppliers();
    if (response.isSuccess) {
      _allSuppliers = response.body as List<SupplierHAJ>;
    } else {
      await showDialogPopUp(context, response.message);
      Navigator.of(context).pop();
    }
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
                SizedBox(
                  width: 400,
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.words,
                    enabled: _signButtonPressed ? false : true,
                    onChanged: (value) => setMatchedSuppliers(value),
                    decoration: InputDecoration(
                      labelText: "Please enter your name",
                    ),
                  ),
                ),
              Expanded( // gives height to FutureBuilder result
              child: FutureBuilder<void>(
                future: _supplierFuture,
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
                        showNResults(_controller.text.isNotEmpty, _matchedSuppliers.length, "supplier"),
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
                                      title: Text('${_matchedSuppliers[index].name} from ${_matchedSuppliers[index].company}'),
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
                    );
                  }
                },
              ),
            ),
          ],
        ),
      )
    );
  }
}