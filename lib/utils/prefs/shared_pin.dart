import 'dart:convert';

import 'package:my_expense/model/pin_model.dart';
import 'package:my_expense/utils/prefs/shared_box.dart';

class PinSharedPreferences {
  static const _pinModel = 'pin';

  static Future<void> setPin(PinModel pin) async {
    if (MyBox.encryptedBox == null) {
      await MyBox.init();
    }
    //print(pin.toJson().toString());
    //print("AAAA");
    await MyBox.encryptedBox!.put(_pinModel, jsonEncode(pin.toJson()));
    //print("BBBB");
  }

  static PinModel? getPin() {
    if (MyBox.encryptedBox != null) {
      if (MyBox.encryptedBox!.get(_pinModel) != null) {
        // get the pin data
        String _pinData = MyBox.encryptedBox!.get(_pinModel);
        // print(_pinData);
        // decode the json data
        PinModel _pin = PinModel.fromJson(jsonDecode(_pinData));
        return _pin;
      } else {
        return null;
      }
    } else {
      return null;
    }
  }
}