import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:my_expense/themes/colors.dart';

void showLoaderDialog(BuildContext context) {
  if (context.mounted) {
    AlertDialog alert = AlertDialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: Center(
        child: SpinKitFadingCube(
          color: accentColors[6],
          size: 25,
        ),
      ),
    );

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return alert;
        }
    );
  }
}