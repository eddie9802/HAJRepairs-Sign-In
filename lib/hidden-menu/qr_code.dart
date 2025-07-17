import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../secrets/secret_manager.dart';
import '../common_widgets.dart';

class SecretSetter extends StatefulWidget {
  @override
  State<SecretSetter> createState() => _SecretSetterState();
}

class _SecretSetterState extends State<SecretSetter> {
  String? qrText;
  bool _isScanned = false;


  void _onDetect(BarcodeCapture capture) async{
    if (_isScanned) return; // Prevent multiple scans
    final barcode = capture.barcodes.first;
    final String? code = barcode.rawValue;

    if (code != null) {
      setState(() {
        qrText = code;
        _isScanned = true;
      });

      SecretManager manager = await SecretManager.create();
      await manager.writeNewEncryptedSecret(qrText!); // Call your method to handle the secret

      await showDialogPopUp(context, "Secret has been set successfully!");

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
              child: Text('Scan a code'),
            ),
          ),
        ],
      ),
    );
  }
}

