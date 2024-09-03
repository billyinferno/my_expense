import 'dart:async';
import 'dart:convert';
import 'package:my_expense/_index.g.dart';

class UserHTTPService {
  Future<UsersMeModel> fetchMe() async {
    // get user information from API
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}users/me',
    ).onError((error, stackTrace) {
      Log.error(
        message: 'Error on fetchMe',
        error: error,
        stackTrace: stackTrace,
      );
      throw error as NetException;
    });

    // fetch the user information once we got it from API
    UsersMeModel userModel = UsersMeModel.fromJson(jsonDecode(result));
    await UserSharedPreferences.setUserMe(userModel);
    return userModel;
  }

  Future<LoginModel> login({
    required String identifier,
    required String password
  }) async {
    // create the body request for login
    var body = {'identifier': identifier, 'password': password};

    // send the login post to API
    final String result = await NetUtils.post(
      url: '${Globals.apiURL}auth/local',
      body: body,
      requiredJWT: false,
    ).onError((error, stackTrace) {
      Log.error(
        message: 'Error on login',
        error: error,
        stackTrace: stackTrace,
      );
      throw error as NetException;
    });

    // parse the login data and get the login model
    LoginModel loginModel = LoginModel.fromJson(jsonDecode(result));
    return loginModel;
  }

  Future<void> updatePassword({
    required String userName,
    required String oldPassword,
    required String newPassword
  }) async {
    // prepare the data request for update password
    var body = {
      "username": userName,
      "password": oldPassword,
      "newPassword": newPassword,
      "confirmPassword": newPassword
    };

    // send the login post to API
    final String result = await NetUtils.post(
      url: '${Globals.apiURL}password',
      body: body,
    ).onError((error, stackTrace) {
      Log.error(
        message: 'Error on updatePassword',
        error: error,
        stackTrace: stackTrace,
      );
      throw error as NetException;
    });

    // this will response back our JWT token
    LoginModel loginModel = LoginModel.fromJson(jsonDecode(result));

    // replace the login model on shared preferences
    await UserSharedPreferences.setUserLogin(login: loginModel);
  }
}
