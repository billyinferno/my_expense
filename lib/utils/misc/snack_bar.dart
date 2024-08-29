import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

SnackBar createSnackBar({
  required String message,
  Icon? icon,
  int duration = 3,
}) {
  Icon snackBarIcon = (icon ?? Icon(Ionicons.alert_circle_outline, size: 20, color: accentColors[2],));

  SnackBar snackBar = SnackBar(
    duration: Duration(seconds: duration),
    backgroundColor: primaryDark,
    content: Container(
      height: 25,
      color: primaryDark,
      child: Row(
        children: <Widget>[
          snackBarIcon,
          const SizedBox(width: 10,),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: textColor,
                fontSize: 15,
                fontFamily: '--apple-system',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );

  return snackBar;
}