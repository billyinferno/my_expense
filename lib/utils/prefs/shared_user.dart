/*
  This is the definition of the shared preferences that will be used to
  store user information such as username, jwt token, etc.
 */

import 'dart:convert';
import 'package:my_expense/_index.g.dart';

class UserSharedPreferences {
  static const _userMeModel = 'user_me';

  static Future<void> setUserLogin(LoginModel login) async {
    if (MyBox.encryptedBox == null) {
      await MyBox.init();
    } else {
      MyBox.encryptedBox!.put('jwt', login.jwt);
    }
  }

  static String getJWT() {
    if (MyBox.encryptedBox != null) {
      if (MyBox.encryptedBox!.get('jwt') != null) {
        return MyBox.encryptedBox!.get('jwt');
      } else {
        return '';
      }
    } else {
      return '';
    }
  }

  static Future<void> clearJWT() async {
    if (MyBox.encryptedBox == null) {
      await MyBox.init();
    } else {
      MyBox.encryptedBox!.put('jwt', "");
    }
  }

  static Future setUserMe(UsersMeModel me) async {
    await MyBox.putString(_userMeModel, jsonEncode(me.toJson()));
  }

  static UsersMeModel getUserMe() {
    String? userMeData = MyBox.getString(_userMeModel);
    //String? userMeData = _pref!.getString(_userMeModel);

    UsersMeModel userModel;
    if (userMeData != null) {
      // convert the data into json
      dynamic userJson = jsonDecode(userMeData);
      userModel = UsersMeModel.fromJson(userJson);
    } else {
      // initialize with blank data
      userModel = UsersMeModel(-1, "", "", false, true, -1, -1, -1, -1);
    }

    return userModel;
  }
}
