import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/themes/colors.dart';

SnackBar createSnackBar({required String message, Icon? icon, int? duration}) {
  Icon _snackBarIcon = (icon ?? Icon(Ionicons.alert_circle_outline, size: 20, color: accentColors[2],));
  int _duration = (duration ?? 3);

  SnackBar snackBar = SnackBar(
    duration: Duration(seconds: _duration),
    backgroundColor: primaryDark,
    content: Container(
      height: 25,
      color: primaryDark,
      child: Row(
        children: <Widget>[
          _snackBarIcon,
          SizedBox(width: 10,),
          Text(
            message,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
            ),
          ),
        ],
      ),
    ),
  );

  return snackBar;
}