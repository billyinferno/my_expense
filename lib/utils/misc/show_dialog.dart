import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_expense/_index.g.dart';

class ShowMyDialog {
  // const ShowMyDialog({Key? key}) : super(key: key);
  ShowMyDialog({
    this.dialogTitle = "Confirmation",
    this.dialogText = "Are your sure?",
    this.confirmText = "Confirm",
    this.confirmColor,
    this.cancelText = "Cancel",
    this.cancelColor,
    this.cancelEnabled = true,
  });

  final String dialogTitle;
  final String dialogText;
  final String confirmText;
  final Color? confirmColor;
  final String cancelText;
  final Color? cancelColor;
  final bool cancelEnabled;

  Future<bool?> show(BuildContext context) async {
    return showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text(
              dialogTitle,
              style: const TextStyle(
                fontFamily: '--apple-system',
              ),
            ),
            content: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    dialogText,
                    style: const TextStyle(
                      fontFamily: '--apple-system',
                    ),
                  ),
                ],
              ),
            ),
            actions: _generateActionButton(context),
          );
        }
    );
  }

  List<CupertinoDialogAction> _generateActionButton(BuildContext context) {
    List<CupertinoDialogAction> ret = [
      CupertinoDialogAction(
        isDefaultAction: true,
        onPressed: () {
          Navigator.pop(context, true);
        },
        child: Text(
          confirmText,
          style: TextStyle(
            fontFamily: '--apple-system',
            color: (confirmColor ?? accentColors[0]),
          ),
        ),
      ),
    ];

    // check if we need to enabled the cancel button or not?
    if (cancelEnabled) {
      ret.add(
        CupertinoDialogAction(
          child: Text(
            cancelText,
            style: TextStyle(
              fontFamily: '--apple-system',
              color: (cancelColor ?? textColor),
            ),
          ),
          onPressed: () {
            Navigator.pop(context, false);
          },
        )
      );
    }

    // return the dialog button
    return ret;
  }
}
