import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

class PinRemovePage extends StatefulWidget {
  const PinRemovePage({super.key});

  @override
  State<PinRemovePage> createState() => _PinRemovePageState();
}

class _PinRemovePageState extends State<PinRemovePage> {
  late PinModel? _pin;
  late int _tries;
  final PinHTTPService _pinHttp = PinHTTPService();

  @override
  void initState() {
    super.initState();

    _pin = PinSharedPreferences.getPin();
    _tries = 1;
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
                const SizedBox(
                  height: 5,
                ),
                const Text("Your passcode is required"),
                const SizedBox(
                  height: 25,
                ),
                PinPad(
                  hashPin: (_pin!.hashPin ?? ''),
                  hashKey: (_pin!.hashKey ?? ''),
                  onError: (() async {
                    // show the error dialog
                    await ShowMyDialog(
                      cancelEnabled: false,
                      confirmText: "OK",
                      dialogTitle: "Error",
                      dialogText: "Wrong Passcode ($_tries tries)."
                    ).show(context);

                    // add tries
                    _tries += 1;
                  }),
                  onSuccess: (() async {
                    await _removePin().onError((error, stackTrace) async {
                      if (context.mounted) {
                        // show the error dialog
                        await ShowMyDialog(
                          cancelEnabled: false,
                          confirmText: "OK",
                          dialogTitle: "Error",
                          dialogText: "Error when removing PIN from backend.")
                        .show(context);
                      }
                    },);
                  }),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _removePin() async {
    // show loading screen
    LoadingScreen.instance().show(context: context);

    // delete pin on the backend
    await _pinHttp.deletePin().then((_) {
      if (mounted) {
        // pin already removed, and by right it should be already updated
        // the pin information on the shared preferences.
        Navigator.pop(context, true);
      }
    }).onError((error, stackTrace) async {
      Log.error(
        message: "Error when delete PIN",
        error: error,
        stackTrace: stackTrace,
      );
    }).whenComplete(() {
      // remove the loading screen
      LoadingScreen.instance().hide();
    },);
  }
}
