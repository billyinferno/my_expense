import 'dart:convert';
import 'package:my_expense/_index.g.dart';

class PinHTTPService {
  Future<PinModel> getPin({
    bool force = false,
  }) async {
    // check if we got data on the sharedPreferences or not?
    if (!force) {
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
      Log.error(
        message: 'Error on getPin',
        error: error,
        stackTrace: stackTrace,
      );
      throw error as NetException;
    });

    // parse the login data and get the login model
    PinModel pin = PinModel.fromJson(jsonDecode(result));
    
    // stored pin on the shared preferences
    PinSharedPreferences.setPin(pin: pin);
    return pin;
  }

  Future<PinModel> setPin({
    required String pinNumber
  }) async {
    // send the request to set the PIN to API
    final String result = await NetUtils.post(
      url: '${Globals.apiURL}pins',
      body: {"pin": pinNumber}
    ).onError((error, stackTrace) {
      Log.error(
        message: 'Error on setPin',
        error: error,
        stackTrace: stackTrace,
      );
      throw error as NetException;
    });

    // parse the login data and get the login model
    PinModel pin = PinModel.fromJson(jsonDecode(result));
    // stored pin on the shared preferences
    PinSharedPreferences.setPin(pin: pin);
    return pin;
  }

  Future<PinModel> updatePin({
    required String pinNumber
  }) async {
    // send the request to update the PIN to API
    final String result = await NetUtils.put(
      url: '${Globals.apiURL}pins',
      body: {"pin": pinNumber}
    ).onError((error, stackTrace) {
      Log.error(
        message: 'Error on updatePin',
        error: error,
        stackTrace: stackTrace,
      );
      throw error as NetException;
    });

    // parse the login data and get the login model
    PinModel pin = PinModel.fromJson(jsonDecode(result));

    // stored pin on the shared preferences
    PinSharedPreferences.setPin(pin: pin);
    return pin;
  }

  Future<void> deletePin() async {
    // send the request to delete the PIN to API
    await NetUtils.delete(
      url: '${Globals.apiURL}pins',
    ).onError((error, stackTrace) {
      Log.error(
        message: 'Error on deletePin',
        error: error,
        stackTrace: stackTrace,
      );
      throw error as NetException;
    });

    // set the pin as NULL
    PinModel pin = PinModel(hashKey: null, hashPin: null);
    PinSharedPreferences.setPin(pin: pin);
  }
}