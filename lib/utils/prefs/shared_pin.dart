import 'dart:convert';
import 'package:my_expense/_index.g.dart';

class PinSharedPreferences {
  static const _pinModel = 'pin';

  static Future<void> setPin({required PinModel pin}) async {
    if (MyBox.encryptedBox == null) {
      await MyBox.init();
    }
    await MyBox.encryptedBox!.put(_pinModel, jsonEncode(pin.toJson()));
  }

  static PinModel? getPin() {
    if (MyBox.encryptedBox != null) {
      if (MyBox.encryptedBox!.get(_pinModel) != null) {
        // get the pin data
        String pinData = MyBox.encryptedBox!.get(_pinModel);
        // decode the json data
        PinModel pin = PinModel.fromJson(jsonDecode(pinData));
        return pin;
      } else {
        return null;
      }
    } else {
      return null;
    }
  }
}