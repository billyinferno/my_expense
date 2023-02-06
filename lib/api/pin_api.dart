import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:my_expense/model/pin_model.dart';
import 'package:my_expense/utils/globals.dart';
import 'package:my_expense/utils/prefs/shared_pin.dart';
import 'package:my_expense/utils/prefs/shared_user.dart';

class PinHTTPService {
  //late LoginModel _loginModel;
  late String _bearerToken;

  PinHTTPService() {
    //_loginModel = UserSharedPreferences.getUserLogin();
    _bearerToken = UserSharedPreferences.getJWT();
  }

  void refreshJWTToken() {
    _bearerToken = UserSharedPreferences.getJWT();
  }

  Future<PinModel> getPin([bool? force]) async {
    bool _force = (force ?? false);

    // check if we got data on the sharedPreferences or not?
    if (!_force) {
      PinModel? _pinPref = PinSharedPreferences.getPin();
      if (_pinPref != null) {
        // check if we got data on the pin or not?
        return _pinPref;
      }
    }

    // if not null then we will try to get the data from the backend.
    // in case user not set the pin, it will be filled with both null.
    _checkJWT();
    final response = await http.get(
      Uri.parse(Globals.apiURL + 'pins'),
      headers: {
        HttpHeaders.authorizationHeader: "Bearer " + _bearerToken,
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    // print("AAA " + response.body);
    if (response.statusCode == 200) {
      // parse the login data and get the login model
      PinModel _pin = PinModel.fromJson(jsonDecode(response.body));
      // print("BBB " + _pin.hashKey!);
      // print("CCC " + _pin.hashPin!);
      // stored pin on the shared preferences
      PinSharedPreferences.setPin(_pin);
      return _pin;
    }

    print("Got error <getPin>");
    throw Exception("res=" + response.body);
  }

  Future<PinModel> setPin(String pinNumber) async {
    // if not null then we will try to get the data from the backend.
    // in case user not set the pin, it will be filled with both null.
    _checkJWT();
    final response = await http.post(
      Uri.parse(Globals.apiURL + 'pins'),
      headers: {
        HttpHeaders.authorizationHeader: "Bearer " + _bearerToken,
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({"pin": pinNumber})
    );

    if (response.statusCode == 200) {
      // parse the login data and get the login model
      PinModel _pin = PinModel.fromJson(jsonDecode(response.body));
      // stored pin on the shared preferences
      PinSharedPreferences.setPin(_pin);
      return _pin;
    }

    print("Got error <setPin>");
    throw Exception("res=" + response.body);
  }

  Future<PinModel> updatePin(String pinNumber) async {
    // if not null then we will try to get the data from the backend.
    // in case user not set the pin, it will be filled with both null.
    _checkJWT();
    final response = await http.put(
      Uri.parse(Globals.apiURL + 'pins'),
      headers: {
        HttpHeaders.authorizationHeader: "Bearer " + _bearerToken,
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({"pin": pinNumber})
    );

    if (response.statusCode == 200) {
      // parse the login data and get the login model
      PinModel _pin = PinModel.fromJson(jsonDecode(response.body));
      // stored pin on the shared preferences
      PinSharedPreferences.setPin(_pin);
      return _pin;
    }

    print("Got error <updatePin>");
    throw Exception("res=" + response.body);
  }

  Future<void> deletePin() async {
    // if not null then we will try to get the data from the backend.
    // in case user not set the pin, it will be filled with both null.
    _checkJWT();
    final response = await http.delete(
      Uri.parse(Globals.apiURL + 'pins'),
      headers: {
        HttpHeaders.authorizationHeader: "Bearer " + _bearerToken,
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      // set the pin as NULL
      PinModel _pin = PinModel(hashKey: null, hashPin: null);
      PinSharedPreferences.setPin(_pin);
      return;
    }

    print("Got error <deletePin>");
    throw Exception("res=" + response.body);
  }

  void _checkJWT() {
    if (_bearerToken.length <= 0) {
      _bearerToken = UserSharedPreferences.getJWT();
    }
  }
}