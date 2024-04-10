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
    bool isForce = (force ?? false);

    // check if we got data on the sharedPreferences or not?
    if (!isForce) {
      PinModel? pinPref = PinSharedPreferences.getPin();
      if (pinPref != null) {
        // check if we got data on the pin or not?
        return pinPref;
      }
    }

    // if not null then we will try to get the data from the backend.
    // in case user not set the pin, it will be filled with both null.
    _checkJWT();
    final response = await http.get(
      Uri.parse('${Globals.apiURL}pins'),
      headers: {
        HttpHeaders.authorizationHeader: "Bearer $_bearerToken",
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    // print("AAA " + response.body);
    if (response.statusCode == 200) {
      // parse the login data and get the login model
      PinModel pin = PinModel.fromJson(jsonDecode(response.body));
      // print("BBB " + _pin.hashKey!);
      // print("CCC " + _pin.hashPin!);
      // stored pin on the shared preferences
      PinSharedPreferences.setPin(pin);
      return pin;
    }

    throw Exception("res=${response.body}");
  }

  Future<PinModel> setPin(String pinNumber) async {
    // if not null then we will try to get the data from the backend.
    // in case user not set the pin, it will be filled with both null.
    _checkJWT();
    final response = await http.post(
      Uri.parse('${Globals.apiURL}pins'),
      headers: {
        HttpHeaders.authorizationHeader: "Bearer $_bearerToken",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({"pin": pinNumber})
    );

    if (response.statusCode == 200) {
      // parse the login data and get the login model
      PinModel pin = PinModel.fromJson(jsonDecode(response.body));
      // stored pin on the shared preferences
      PinSharedPreferences.setPin(pin);
      return pin;
    }

    throw Exception("res=${response.body}");
  }

  Future<PinModel> updatePin(String pinNumber) async {
    // if not null then we will try to get the data from the backend.
    // in case user not set the pin, it will be filled with both null.
    _checkJWT();
    final response = await http.put(
      Uri.parse('${Globals.apiURL}pins'),
      headers: {
        HttpHeaders.authorizationHeader: "Bearer $_bearerToken",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({"pin": pinNumber})
    );

    if (response.statusCode == 200) {
      // parse the login data and get the login model
      PinModel pin = PinModel.fromJson(jsonDecode(response.body));
      // stored pin on the shared preferences
      PinSharedPreferences.setPin(pin);
      return pin;
    }

    throw Exception("res=${response.body}");
  }

  Future<void> deletePin() async {
    // if not null then we will try to get the data from the backend.
    // in case user not set the pin, it will be filled with both null.
    _checkJWT();
    final response = await http.delete(
      Uri.parse('${Globals.apiURL}pins'),
      headers: {
        HttpHeaders.authorizationHeader: "Bearer $_bearerToken",
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      // set the pin as NULL
      PinModel pin = PinModel(hashKey: null, hashPin: null);
      PinSharedPreferences.setPin(pin);
      return;
    }

    throw Exception("res=${response.body}");
  }

  void _checkJWT() {
    if (_bearerToken.isEmpty) {
      _bearerToken = UserSharedPreferences.getJWT();
    }
  }
}