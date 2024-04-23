import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/api/pin_api.dart';
import 'package:my_expense/model/pin_model.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/misc/show_dialog.dart';
import 'package:my_expense/utils/misc/show_loader_dialog.dart';
import 'package:my_expense/utils/prefs/shared_pin.dart';
import 'package:my_expense/widgets/input/pin_pad.dart';

class PinRemovePage extends StatefulWidget {
  const PinRemovePage({ super.key });

  @override
  State<PinRemovePage> createState() => _PinRemovePageState();
}

class _PinRemovePageState extends State<PinRemovePage> {
  late PinModel? pin;
  late int tries;
  final PinHTTPService pinHttp = PinHTTPService();

  @override
  void initState() {
    pin = PinSharedPreferences.getPin();
    tries = 1;

    super.initState();
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
                const Text(
                  "Enter Passcode",
                  style: TextStyle(
                    fontSize: 25,
                  ),
                ),
                const SizedBox(height: 5,),
                const Text("Your passcode is required"),
                const SizedBox(height: 25,),
                PinPad(
                  hashPin: (pin!.hashPin ?? ''),
                  hashKey: (pin!.hashKey ?? ''),
                  onError: (() async {
                    // show the error dialog
                    await ShowMyDialog(
                      cancelEnabled: false,
                      confirmText: "OK",
                      dialogTitle: "Error",
                      dialogText: "Wrong Passcode ($tries tries)."
                    ).show(context);

                    // add tries
                    tries += 1;
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
    }).onError((error, stackTrace) async {
      // pop the loader
      Navigator.pop(context);

      debugPrint("Error: ${error.toString()}");
      debugPrintStack(stackTrace: stackTrace);

      // show the error dialog
      await ShowMyDialog(
        cancelEnabled: false,
        confirmText: "OK",
        dialogTitle: "Error",
        dialogText: "Error when removing PIN from backend."
      ).show(context);
    });
  }
}