



import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';


import 'package:haj_repairs_sign_in/customer/customer_excel_talker.dart';
import 'package:haj_repairs_sign_in/hidden-menu/hidden_menu_excel_talker.dart';

import 'package:haj_repairs_sign_in/supplier/supplier_excel_talker.dart';
import 'package:haj_repairs_sign_in/colleague/colleague_excel_talker.dart';
import 'package:haj_repairs_sign_in/colleague/colleague.dart';
import 'package:haj_repairs_sign_in/supplier/supplierHAJ.dart';
import 'package:haj_repairs_sign_in/customer/customerHAJ.dart';
import 'package:haj_repairs_sign_in/hidden-menu/fire_report_service.dart';


import '../common_widgets.dart';

class FireReport extends StatefulWidget {
  @override
  _FireReportState createState() => _FireReportState();
}

class _FireReportState extends State<FireReport> {

  late final Future<void> _fireReportFuture;
  Map<String, List<dynamic>?> _personnelMap = {};
  Map<String, ScrollController> _controllerMap = {};


  @override
  void initState() {
    super.initState();
    _fireReportFuture = initAllPersonnel();
  }


  List<CustomerHAJ> getTodaysSignedInCustomers(List<CustomerHAJ> allSignedInCustomers) {
    List<CustomerHAJ> todaysSignedInCustomers = [];
    for (var customer in allSignedInCustomers) {
      final today = DateTime.now();
      final todayDateOnly = DateTime(today.year, today.month, today.day);

      final signInDateOnly = DateTime(
        customer.signInDate.year,
        customer.signInDate.month,
        customer.signInDate.day,
      );

      if (todayDateOnly == signInDateOnly) {
        todaysSignedInCustomers.add(customer);
      }
    } 
    return todaysSignedInCustomers;
  }


    List<SupplierHAJ> getTodaysSignedInSuppliers(List<SupplierHAJ> allSignedInSuppliers) {
    List<SupplierHAJ> todaysSignedInSuppliers = [];
    for (var supplier in allSignedInSuppliers) {
      final today = DateTime.now();
      final todayDateOnly = DateTime(today.year, today.month, today.day);

      final signInDateOnly = DateTime(
        supplier.date.year,
        supplier.date.month,
        supplier.date.day,
      );

      if (todayDateOnly == signInDateOnly) {
        todaysSignedInSuppliers.add(supplier);
      }
    } 
    return todaysSignedInSuppliers;
  }



Future<void> initAllPersonnel() async {
  try {
    final signedInColleaguesRes = await HiddenMenuExcelTalker().getSignedInColleagues();
    final signedInSuppliersRes = await SupplierExcelTalker().retrieveSuppliers();
    final signedInCustomersRes = await CustomerExcelTalker().retrieveCustomers();

    if (signedInColleaguesRes.isSuccess) {
      String personnelType = "Colleagues";
      _personnelMap[personnelType] = signedInColleaguesRes.body as List<String>;
      _controllerMap[personnelType] = new ScrollController();
    } else {
      print("Error retrieving signed-in colleagues: ${signedInColleaguesRes.message}");
    }

    if (signedInSuppliersRes.isSuccess) {
      String personnelType = "Suppliers";
      List<SupplierHAJ> allSignedInSuppliers = signedInSuppliersRes.body;
      List<SupplierHAJ> todaysSignedInSuppliers = getTodaysSignedInSuppliers(allSignedInSuppliers);
      _personnelMap[personnelType] = todaysSignedInSuppliers;
      _controllerMap[personnelType] = new ScrollController();
    } else {
      print("Error retrieving signed-in suppliers: ${signedInSuppliersRes.message}");
    }

    if (signedInCustomersRes.isSuccess) {
      String personnelType = "Customers";
      List<CustomerHAJ> allSignedInCustomers = signedInCustomersRes.body;
      List<CustomerHAJ> todaysSignedInCustomers = getTodaysSignedInCustomers(allSignedInCustomers);
      _personnelMap[personnelType] = todaysSignedInCustomers;
      _controllerMap[personnelType] = new ScrollController();
    } else {
      print("Error retrieving signed-in customers: ${signedInCustomersRes.message}");
    }

  } catch (e, stackTrace) {
    print("🔥 initAllPersonnel error: $e");
    print("📍 Stack trace: $stackTrace");
    rethrow; // Let FutureBuilder catch it and show snapshot.hasError
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fire Report'),
      ),
      body: Center(
        child: Consumer<FireReportService>(
          builder: (context, service, child) {
            final personnelMap = service.data;
            final controllerMap = service.controller;
            final lastTimeSignature = service.time;

            if (personnelMap.isEmpty) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 40),
                  loadingIndicator(),
                ],
              );
            }

            return Stack(
              children: [
                CarouselSlider(
                  options: CarouselOptions(
                    height: 500.0,
                    viewportFraction: 1,
                  ),
                  items: personnelMap.entries.map((item) {
                    final key = item.key;
                    final value = item.value;

                    String header = 'Number Of $key Signed In: ${value.length}';

                    return Builder(
                      builder: (BuildContext context) {
                        return Align(
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: 400,
                            child: Column(
                              children: [
                                Text(
                                  header,
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                                Expanded(
                                  child: Scrollbar(
                                    thumbVisibility: true,
                                    controller: controllerMap[key],
                                    child: ListView.builder(
                                      controller: controllerMap[key],
                                      padding: const EdgeInsets.all(16.0),
                                      itemCount: value.length,
                                      itemBuilder: (context, index) {
                                        String? name;
                                        if (key == 'Colleagues') {
                                          name = value[index];
                                        } else if (key == "Suppliers") {
                                          name = '${value[index].name} from ${value[index].company}';
                                        } else if (key == "Customers") {
                                          name = '${value[index].signInDriverName}';
                                        } else {
                                          name = "Error";
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: ListTile(title: Text(name!)),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),

                Align(
                  alignment: Alignment.bottomRight,
                  child:
                    Padding(
                      padding: const EdgeInsets.only(right: 50),
                      child: 
                        Text('Last Updated: $lastTimeSignature'),)),

                // 🔼 Arrow overlay on top of carousel
                Positioned(
                  right: 10,
                  top: 0,
                  bottom: 0,
                  child: Icon(Icons.arrow_forward_ios, color: Colors.black45),
                ),
                Positioned(
                  left: 10,
                  top: 0,
                  bottom: 0,
                  child: Icon(Icons.arrow_back_ios, color: Colors.black45),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}