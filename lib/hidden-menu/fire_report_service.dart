import 'dart:async';

import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:haj_repairs_sign_in/customer/customer_excel_talker.dart';
import 'package:haj_repairs_sign_in/customer/customerHAJ.dart';
import 'package:haj_repairs_sign_in/supplier/supplier_excel_talker.dart';
import 'package:haj_repairs_sign_in/supplier/supplierHAJ.dart';
import 'package:haj_repairs_sign_in/hidden-menu/hidden_menu_excel_talker.dart';


class FireReportService extends ChangeNotifier {
  final Map<String, List<dynamic>> _personnelMap = {};
  final Map<String, ScrollController> _controllerMap = {};
  late String _lastTimeSignature;
  Timer? _timer;

  Map<String, List<dynamic>> get data => _personnelMap;
  Map<String, ScrollController> get controller => _controllerMap;
  String get time => _lastTimeSignature;

  FireReportService() {
    _startUpdating();
  }

  void _startUpdating() {
    _loadData(); // Initial load
    _timer = Timer.periodic(Duration(minutes: 1), (_) => _loadData());
  }

  Future<void> _loadData() async {
    
    _lastTimeSignature = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());

    try {
      final colleagues = await HiddenMenuExcelTalker().getSignedInColleagues();
      final suppliers = await SupplierExcelTalker().retrieveSuppliers();
      final customers = await CustomerExcelTalker().retrieveCustomers();


      if (colleagues.statusCode != 504 || suppliers.statusCode != 504 || customers.statusCode != 504) {
        if (colleagues.isSuccess) {
          String personnelType = "Colleagues";
          _personnelMap[personnelType] = colleagues.body;
          _controllerMap[personnelType] = new ScrollController();
        }

        if (suppliers.isSuccess) {
          final today = DateTime.now();
          final todaySuppliers = (suppliers.body as List<SupplierHAJ>).where((s) {
            final d = s.date;
            return d.year == today.year && d.month == today.month && d.day == today.day;
          }).toList();
          String personnelType = "Suppliers";
          _personnelMap[personnelType] = todaySuppliers;
          _controllerMap[personnelType] = new ScrollController();
        }

        if (customers.isSuccess) {
          final today = DateTime.now();
          final todayCustomers = (customers.body as List<CustomerHAJ>).where((c) {
            final d = c.signInDate;
            return d.year == today.year && d.month == today.month && d.day == today.day;
          }).toList();
          String personnelType = "Customers";
          _personnelMap[personnelType] = todayCustomers;
          _controllerMap[personnelType] = new ScrollController();
        }

        notifyListeners();

      } else {

        print("No Internet Connection To Update the Fire Report");

      }


    } catch (e) {
      print("🔥 FireReportService load error: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
