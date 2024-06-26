import 'dart:convert';
import 'package:my_expense/model/pin_model.dart';
import 'package:my_expense/utils/globals.dart';
import 'package:my_expense/utils/net/netutils.dart';
import 'package:my_expense/utils/prefs/shared_pin.dart';

class PinHTTPService {
  Future<PinModel> getPin([bool? force]) async {
    bool isForce = (force ?? false);

    // check if we got data on the sharedPreferences or not?
    if (!isForce) {
      PinModel? pinPref = PinSharedPreferences.getPin();
      if (pinPref != null) {
        // check if we got data on the pin or not?
        return pinPref;
      }
    }

    // send the request to get the PIN to API
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}pins',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // parse the login data and get the login model
    PinModel pin = PinModel.fromJson(jsonDecode(result));
    
    // stored pin on the shared preferences
    PinSharedPreferences.setPin(pin);
    return pin;
  }

  Future<PinModel> setPin(String pinNumber) async {
    // send the request to set the PIN to API
    final String result = await NetUtils.post(
      url: '${Globals.apiURL}pins',
      body: {"pin": pinNumber}
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // parse the login data and get the login model
    PinModel pin = PinModel.fromJson(jsonDecode(result));
    // stored pin on the shared preferences
    PinSharedPreferences.setPin(pin);
    return pin;
  }

  Future<PinModel> updatePin(String pinNumber) async {
    // send the request to update the PIN to API
    final String result = await NetUtils.put(
      url: '${Globals.apiURL}pins',
      body: {"pin": pinNumber}
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // parse the login data and get the login model
    PinModel pin = PinModel.fromJson(jsonDecode(result));

    // stored pin on the shared preferences
    PinSharedPreferences.setPin(pin);
    return pin;
  }

  Future<void> deletePin() async {
    // send the request to delete the PIN to API
    await NetUtils.delete(
      url: '${Globals.apiURL}pins',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // set the pin as NULL
    PinModel pin = PinModel(hashKey: null, hashPin: null);
    PinSharedPreferences.setPin(pin);
  }
}