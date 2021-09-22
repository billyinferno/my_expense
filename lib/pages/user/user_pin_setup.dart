import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/api/pin_api.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/misc/show_loader_dialog.dart';
import 'package:my_expense/utils/misc/snack_bar.dart';
import 'package:my_expense/widgets/input/pin_pad.dart';

class PinSetupPage extends StatefulWidget {
  const PinSetupPage({ Key? key }) : super(key: key);

  @override
  _PinSetupPageState createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage> {
  String _firstPin = "";
  String _secondPin = "";
  int _stage = 1;

  final PinHTTPService pinHttp = PinHTTPService();

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
              padding: EdgeInsets.all(10),
              child: Center(
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
                  style: TextStyle(
                    fontSize: 25,
                  ),
                ),
                SizedBox(height: 5,),
                Text("Your passcode is required"),
                SizedBox(height: 25,),
                PinPad(
                  hashPin: '',
                  hashKey: '',
                  getPin: (value) {
                    // got the pin, check whether this is 1st or 2nd
                    if(_firstPin.length <= 0) {
                      _firstPin = value;
                      setState(() {
                        _stage = 2;
                      });
                    }
                    else {
                      if(_secondPin.length <= 0) {
                        _secondPin = value;

                        // verify whether both pin is the same or not?
                        if(_firstPin != _secondPin) {
                          // show error, and reset all
                          ScaffoldMessenger.of(context).showSnackBar(
                            createSnackBar(
                              message: "PIN didn't match",
                            )
                          );
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
    await pinHttp.setPin(_firstPin).then((_) {
      // pop the loader dialog
      Navigator.pop(context);

      // pin already set, so now we can pop from this page
      // and tell it's true
      Navigator.pop(context, true);
    }).onError((error, stackTrace) {
      // pop the loader dialog
      Navigator.pop(context);

      debugPrint("Error on <_savePin>");
      debugPrint(error.toString());
      
      ScaffoldMessenger.of(context).showSnackBar(
        createSnackBar(
          message: "Error when Save PIN",
        )
      );
      setState(() {
        _stage = 1;
        _firstPin = "";
        _secondPin = "";
      });
    });
  }
}