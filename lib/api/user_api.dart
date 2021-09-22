import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_expense/model/login_model.dart';
import 'package:my_expense/model/users_me_model.dart';
import 'package:my_expense/utils/globals.dart';
import 'package:my_expense/utils/prefs/shared_user.dart';

class UserHTTPService {
  //late LoginModel _loginModel;
  late String _bearerToken;

  UserHTTPService() {
    //_loginModel = UserSharedPreferences.getUserLogin();
    _bearerToken = UserSharedPreferences.getJWT();
  }

  Future<UsersMeModel> fetchMe() async {
    _checkJWT();
    //print("<fetchMe>" + _bearerToken);

    // check if we got JWT token or not?
    if (_bearerToken.length > 0) {
      final response =
          await http.get(Uri.parse(Globals.apiURL + 'users/me'), headers: {
        HttpHeaders.authorizationHeader: "Bearer " + _bearerToken,
      });

      if (response.statusCode == 200) {
        UsersMeModel _userModel =
            UsersMeModel.fromJson(jsonDecode(response.body));
        await UserSharedPreferences.setUserMe(_userModel);
        return _userModel;
      }

      print("Got error <fetchMe>");
      throw Exception("res=" + response.body);
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token when fetch user data"}');
    }
  }

  Future<LoginModel> login(String identifier, String password) async {
    final response = await http.post(
      Uri.parse(Globals.apiURL + 'auth/local'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'identifier': identifier, 'password': password}),
    );

    if (response.statusCode == 200) {
      // parse the login data and get the login model
      LoginModel _loginModel = LoginModel.fromJson(jsonDecode(response.body));

      return _loginModel;
    }

    print("Got error <login>");
    throw Exception("res=" + response.body);
  }

  Future<void> updatePassword(
      String userName, String oldPassword, String newPassword) async {
    _checkJWT();

    // check if we got JWT token or not?
    if (_bearerToken.length > 0) {
      //await Future.delayed(Duration(seconds: 3));

      var _data = {
        "username": userName,
        "password": oldPassword,
        "newPassword": newPassword,
        "confirmPassword": newPassword
      };

      final response = await http.post(Uri.parse(Globals.apiURL + 'password'),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer " + _bearerToken,
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(_data));

      // check the response from the password update
      if (response.statusCode == 200) {
        // this will response back our JWT token
        LoginModel _loginModel = LoginModel.fromJson(jsonDecode(response.body));

        // replace the login model on shared preferences
        await UserSharedPreferences.setUserLogin(_loginModel);
      } else {
        print("Got error <updatePassword>");
        throw Exception("res=" + response.body);
      }

      /*print("Got error <fetchMe>");
      throw Exception("res=" + response.body);*/
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token when changing user password"}');
    }
  }

  void _checkJWT() {
    _bearerToken = UserSharedPreferences.getJWT();
  }
}
