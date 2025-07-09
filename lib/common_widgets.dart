import 'package:flutter/material.dart';

Future<dynamic> showDialogPopUp(BuildContext context, String? popUpText) {
  return showDialog(
    context: context,
      builder: (_) => AlertDialog(
        title: Text(''),
        content: Text(popUpText!, style: TextStyle(fontSize: 24, color: Color.fromARGB(255, 0, 0, 0))),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              },
            child: Text('OK', style: TextStyle(fontSize: 24, color: Color(0xFFC10007))),
          ),
        ],
      ),
    );
  }