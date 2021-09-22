import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/api/pin_api.dart';
import 'package:my_expense/model/pin_model.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/misc/show_loader_dialog.dart';
import 'package:my_expense/utils/misc/snack_bar.dart';
import 'package:my_expense/utils/prefs/shared_pin.dart';
import 'package:my_expense/widgets/input/pin_pad.dart';

class PinRemovePage extends StatefulWidget {
  const PinRemovePage({ Key? key }) : super(key: key);

  @override
  PinRemovePageState createState() => PinRemovePageState();
}

class PinRemovePageState extends State<PinRemovePage> {
  late PinModel? pin;
  final PinHTTPService pinHttp = PinHTTPService();

  @override
  void initState() {
    super.initState();
    pin = PinSharedPreferences.getPin();
  }

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
                    showLoaderDialog(context);
                    _removePin();
                  }),
                  // getPin: (value) {
                  //   debugPrint("Get Pin : " + value);
                  // },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _removePin() async {
    await pinHttp.deletePin().then((_) {
      // pop the loader
      Navigator.pop(context);

      // pin already removed, and by right it should be already updated
      // the pin information on the shared preferences.
      Navigator.pop(context, true);
    }).onError((error, stackTrace) {
      // pop the loader
      Navigator.pop(context);

      debugPrint("Error when <_removePin>");
      debugPrint(error.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        createSnackBar(
          message: "Error when Remove PIN",
        )
      );
    });
  }
}