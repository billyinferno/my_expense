import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/api/pin_api.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/misc/show_dialog.dart';
import 'package:my_expense/utils/misc/show_loader_dialog.dart';
import 'package:my_expense/widgets/input/pin_pad.dart';

class PinSetupPage extends StatefulWidget {
  const PinSetupPage({ super.key });

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage> {
  String _firstPin = "";
  String _secondPin = "";
  int _stage = 1;

  final PinHTTPService _pinHttp = PinHTTPService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onTap: (() {
              // user cancel the remove PIN
              Navigator.pop(context, false);
            }),
            child: Container(
              width: 50,
              height: 50,
              color: Colors.transparent,
              padding: const EdgeInsets.all(10),
              child: const Center(
                child: Icon(
                  Ionicons.close_circle_outline,
                  color: textColor2,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  (_stage == 1 ? "Enter Passcode" : "Confirm Passcode"),
                  style: const TextStyle(
                    fontSize: 25,
                  ),
                ),
                const SizedBox(height: 5,),
                const Text("Your passcode is required"),
                const SizedBox(height: 25,),
                PinPad(
                  hashPin: '',
                  hashKey: '',
                  getPin: (value) async {
                    // got the pin, check whether this is 1st or 2nd
                    if(_firstPin.isEmpty) {
                      _firstPin = value;
                      setState(() {
                        _stage = 2;
                      });
                    }
                    else {
                      if(_secondPin.isEmpty) {
                        _secondPin = value;

                        // verify whether both pin is the same or not?
                        if(_firstPin != _secondPin) {
                          // show error, and reset all
                          // show the error dialog
                          await ShowMyDialog(
                            cancelEnabled: false,
                            confirmText: "OK",
                            dialogTitle: "Error",
                            dialogText: "PIN didn't match."
                          ).show(context);

                          setState(() {
                            _stage = 1;
                            _firstPin = "";
                            _secondPin = "";
                          });
                        }
                        else {
                          // send this to backend
                          showLoaderDialog(context);
                          _savePin();
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _savePin() async {
    await _pinHttp.setPin(_firstPin).then((_) {
      // pop the loader dialog
      Navigator.pop(context);

      // pin already set, so now we can pop from this page
      // and tell it's true
      Navigator.pop(context, true);
    }).onError((error, stackTrace) async {
      // pop the loader dialog
      Navigator.pop(context);

      debugPrint("Error: ${error.toString()}");
      debugPrintStack(stackTrace: stackTrace);

      // show the error dialog
      await ShowMyDialog(
        cancelEnabled: false,
        confirmText: "OK",
        dialogTitle: "Error Save",
        dialogText: "Error when Save PIN"
      ).show(context);
      
      setState(() {
        _stage = 1;
        _firstPin = "";
        _secondPin = "";
      });
    });
  }
}