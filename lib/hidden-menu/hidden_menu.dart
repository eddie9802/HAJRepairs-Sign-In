import 'package:flutter/material.dart';

import 'qr_code.dart';
import 'fire_report.dart';



class HiddenMenu extends StatelessWidget {
  const HiddenMenu({super.key});


  final List<String> menuItems = const [
    'Set Secret',
    'Get Fire Report',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hidden Menu'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...menuItems.map((item) =>
            Padding(padding: EdgeInsets.only(bottom: 30.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(200, 50), // Set a minimum size for the button
                textStyle: TextStyle(fontSize: 24), // Set the text size
              ),
              onPressed: () {
                if (item == 'Set Secret') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => QRCode()),
                  );               
                } else if (item == 'Get Fire Report') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FireReport()),
                  );    
                }
              },
              child: Text(item),
            )))],
        ),
      ),
    );
  }
}