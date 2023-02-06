import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:my_expense/model/category_model.dart';
import 'package:my_expense/model/users_me_model.dart';
import 'package:my_expense/utils/globals.dart';
import 'package:my_expense/utils/prefs/shared_category.dart';
import 'package:my_expense/utils/prefs/shared_user.dart';

class CategoryHTTPService {
  //late LoginModel _loginModel;
  late String _bearerToken;

  CategoryHTTPService() {
    //_loginModel = UserSharedPreferences.getUserLogin();
    _bearerToken = UserSharedPreferences.getJWT();
  }

  void refreshJWTToken() {
    _bearerToken = UserSharedPreferences.getJWT();
  }

  Future<void> updateDefaultCategory(String type, int categoryID) async {
    // check from shared preferences if we already have loaded category data
    _checkJWT();
    UsersMeModel _userMe = UserSharedPreferences.getUserMe();

    // check if we got JWT token or not?
    if (_bearerToken.length > 0) {
      var _body = {
        'category': {'id': categoryID},
        'users_permissions_user': {'id': _userMe.id}
      };

      final response = await http.put(
          Uri.parse(
              Globals.apiURL + 'categories/default/' + type.toLowerCase()),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer " + _bearerToken,
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(_body));

      if (response.statusCode == 200) {
        // success, it will return the userMe model, so we can just replace the current userMe
        _userMe = UsersMeModel.fromJson(jsonDecode(response.body));
        await UserSharedPreferences.setUserMe(_userMe);
        return;
      }

      print("Got error <updateDefaultCategory>");
      throw Exception("res=" + response.body);
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<void> fetchCategory([bool? force]) async {
    bool _force = (force ?? false);

    if (!_force) {
      // check whether we have data on shared preferences or not?
      Map<int, CategoryModel> _expensePref =
          CategorySharedPreferences.getCategory("expense");
      Map<int, CategoryModel> _incomePref =
          CategorySharedPreferences.getCategory("income");

      // check if we got data there or not?
      if (_expensePref.length > 0 && _incomePref.length > 0) {
        return;
      }
    }

    // check from shared preferences if we already have loaded category data
    _checkJWT();
    // check if we got JWT token or not?
    if (_bearerToken.length > 0) {
      final response =
          await http.get(Uri.parse(Globals.apiURL + 'categories'), headers: {
        HttpHeaders.authorizationHeader: "Bearer " + _bearerToken,
      });

      if (response.statusCode == 200) {
        List<dynamic> _jsonData = jsonDecode(response.body);
        List<CategoryModel> _categoryList =
            _jsonData.map((e) => CategoryModel.fromJson(e)).toList();

        List<CategoryModel> expenseModel = [];
        List<CategoryModel> incomeModel = [];
        _categoryList.forEach((category) {
          // check if this is expense or income
          if (category.type.toLowerCase() == "expense") {
            expenseModel.add(category);
          } else if (category.type.toLowerCase() == "income") {
            incomeModel.add(category);
          }
        });

        // saved the expense and income category model
        CategorySharedPreferences.setCategory(expenseModel, incomeModel);

        // since this is void no need to return anything
        return;
      }

      print("Got error <fetchCategory>");
      throw Exception("res=" + response.body);
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  void _checkJWT() {
    if (_bearerToken.length <= 0) {
      _bearerToken = UserSharedPreferences.getJWT();
    }
  }
}
