import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_expense/themes/colors.dart';

class ShowMyDialog {
  // const ShowMyDialog({Key? key}) : super(key: key);
  ShowMyDialog({
    this.dialogTitle,
    this.dialogText,
    this.confirmText,
    this.confirmColor,
    this.cancelText,
    this.cancelColor
  });

  final String? dialogTitle;
  final String? dialogText;
  final String? confirmText;
  final Color? confirmColor;
  final String? cancelText;
  final Color? cancelColor;

  Future<bool?> show(BuildContext context) async {
    return showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text(
              dialogTitle ?? "Confirmation",
              style: TextStyle(
                fontFamily: '--apple-system',
              ),
            ),
            content: SingleChildScrollView(
              padding: EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    dialogText ?? "Are your sure?",
                    style: TextStyle(
                      fontFamily: '--apple-system',
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                child: Text(
                  confirmText ?? "Confirm",
                  style: TextStyle(
                    fontFamily: '--apple-system',
                    color: (confirmColor ?? accentColors[0]),
                  ),
                ),
                isDefaultAction: true,
                onPressed: () {
                  Navigator.pop(context, true);
                },
              ),
              CupertinoDialogAction(
                child: Text(
                  cancelText ?? "Cancel",
                  style: TextStyle(
                    fontFamily: '--apple-system',
                    color: (cancelColor ?? textColor),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
            ],
          );
        }
    );
  }
}
