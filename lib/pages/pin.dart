import 'package:flutter/material.dart';
import 'package:my_expense/model/pin_model.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/misc/snack_bar.dart';
import 'package:my_expense/utils/prefs/shared_pin.dart';
import 'package:my_expense/widgets/input/pin_pad.dart';

class PinPage extends StatefulWidget {
  const PinPage({ Key? key }) : super(key: key);

  @override
  _PinPageState createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  late PinModel? pin;

  @override
  void initState() {
    super.initState();

    // get the pin data
    pin = PinSharedPreferences.getPin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            "Enter Passcode",
            style: TextStyle(
              fontSize: 25,
            ),
          ),
          SizedBox(height: 5,),
          Text("Your passcode is required"),
          SizedBox(height: 25,),
          PinPad(
            hashPin: (pin!.hashPin ?? ''),
            hashKey: (pin!.hashKey ?? ''),
            onError: (() {
              ScaffoldMessenger.of(context).showSnackBar(
                createSnackBar(
                  message: "Wrong Passcode",
                )
              );
            }),
            onSuccess: (() {
              debugPrint("🏠 Go back to home");
              Navigator.pop(context);
            }),
          ),
        ],
      ),
    );
  }
}