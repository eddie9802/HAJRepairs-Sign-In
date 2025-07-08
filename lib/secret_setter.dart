import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SecretSetter extends StatefulWidget {
  @override
  State<SecretSetter> createState() => _SecretSetterState();
}

class _SecretSetterState extends State<SecretSetter> {
  String? qrText;
  bool _isScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return; // Prevent multiple scans
    final barcode = capture.barcodes.first;
    final String? code = barcode.rawValue;

    if (code != null) {
      setState(() {
        qrText = code;
        _isScanned = true;
      });

      // Optionally close the scanner or do something with the result
      Future.delayed(Duration(seconds: 1), () {
        Navigator.pop(context, qrText); // Return value if needed
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code'),
        leading: BackButton(), // 👈 optional, added automatically by default
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: RotatedBox(
              quarterTurns: 3, // 👈 rotates 270° counterclockwise (i.e. 90° clockwise back to normal)
              child: MobileScanner(
                onDetect: _onDetect,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(qrText ?? 'Scan a code'),
            ),
          ),
        ],
      ),
    );
  }
}

