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


Widget loadingIndicator() {
  return Center(
    child: CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC10007)),
      strokeWidth: 5.0,
    ),
  );
}


Widget showNResults(int resultsLength, String resultType) {
  if (resultsLength == 0) return SizedBox.shrink(); // Return nothing if empty

  return Container(
    width: 400, // Match parent width
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Text(
      resultsLength == 1
          ? "1 $resultType found"
          : "$resultsLength ${resultType}s found",
      textAlign: TextAlign.left,
      style: TextStyle(fontSize: 14),
    ),
  );
}