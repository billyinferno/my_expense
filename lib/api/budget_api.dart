import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:my_expense/model/budget_list_model.dart';
import 'package:my_expense/model/budget_model.dart';
import 'package:my_expense/model/users_me_model.dart';
import 'package:my_expense/utils/globals.dart';
import 'package:my_expense/utils/prefs/shared_budget.dart';
import 'package:my_expense/utils/prefs/shared_user.dart';

class BudgetHTTPService {
  //late LoginModel _loginModel;
  late String _bearerToken;

  BudgetHTTPService() {
    //_loginModel = UserSharedPreferences.getUserLogin();
    _bearerToken = UserSharedPreferences.getJWT();
  }

  void refreshJWTToken() {
    _bearerToken = UserSharedPreferences.getJWT();
  }

  Future<void> updateBudgetCurrency(int currencyID) async {
    _checkJWT();
    String bearerToken = _bearerToken;

    // check from shared preferences if we already have loaded category data
    UsersMeModel _userMe = UserSharedPreferences.getUserMe();

    // check if we got JWT token or not?
    if (bearerToken.length > 0) {
      var _body = {
        'currency': {'id': currencyID},
        'users_permissions_user': {'id': _userMe.id}
      };

      final response =
          await http.put(Uri.parse(Globals.apiURL + 'budgets/defaultcurrency'),
              headers: {
                HttpHeaders.authorizationHeader: "Bearer " + bearerToken,
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(_body));

      if (response.statusCode == 200) {
        // success, it will return the userMe model, so we can just replace the current userMe
        _userMe = UsersMeModel.fromJson(jsonDecode(response.body));
        await UserSharedPreferences.setUserMe(_userMe);
        return;
      }

      print("Got error <updateDefaultCurrency>");
      throw Exception("res=" + response.body);
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<BudgetModel> addBudgetList(int currencyId, int categoryId) async {
    // get the JWT token
    _checkJWT();

    // check from shared preferences if we already have loaded category data
    UsersMeModel _userMe = UserSharedPreferences.getUserMe();

    // ensure that we have bearer token
    if (_bearerToken.length > 0) {
      var _body = {
        "category": {"id": categoryId},
        "amount": 0,
        "users_permissions_user": {"id": _userMe.id},
        "currency": {"id": currencyId}
      };

      final response = await http.post(Uri.parse(Globals.apiURL + 'budgets'),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer " + _bearerToken,
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(_body));
      
      if (response.statusCode == 200) {
        // success, it will return the complete budget model
        BudgetModel _budget = BudgetModel.fromJson(jsonDecode(response.body));
        // let the caller be the one who manipulate the shared preferences and
        // the provider
        return _budget;
      }
      else {
        print("Got error <addBudgetList>");
        throw Exception("res=" + response.body);
      }
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<List<BudgetModel>> updateBudgetList(int currencyId, List<BudgetModel> budgetList) async {
    // get the JWT token
    _checkJWT();

    // check from shared preferences if we already have loaded category data
    UsersMeModel _userMe = UserSharedPreferences.getUserMe();

    // ensure that we have bearer token
    if (_bearerToken.length > 0) {
      var _body = [];
      budgetList.forEach((element) {
        var _budget = {
          "id": element.id,
          "category": element.category.id,
          "amount": element.amount,
          "users_permissions_user": _userMe.id,
          "currency": element.currency.id
        };
        _body.add(_budget);
      });

      //print(jsonEncode(_body));

      final response = await http.put(Uri.parse(Globals.apiURL + 'budgets/currency/' + currencyId.toString()),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer " + _bearerToken,
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(_body));
      
      if (response.statusCode == 200) {
        // success, decode the response as budget model
        List<dynamic> _jsonData = jsonDecode(response.body);
        List<BudgetModel> _listBudget = _jsonData.map((e) => BudgetModel.fromJson(e)).toList();
        return _listBudget;
      }
      else {
        print("Got error <updateBudgetList>");
        throw Exception("res=" + response.body);
      }
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<BudgetModel> deleteBudgetList(int currencyId, int budgetId) async {
    // get the JWT token
    _checkJWT();

    // ensure that we have bearer token
    if (_bearerToken.length > 0) {
      final response = await http.delete(Uri.parse(Globals.apiURL + 'budgets/currency/' + currencyId.toString() + "/id/" + budgetId.toString()),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer " + _bearerToken,
            'Content-Type': 'application/json; charset=UTF-8',
          });
      
      if (response.statusCode == 200) {
        // success, it will return the complete budget model
        BudgetModel _budget = BudgetModel.fromJson(jsonDecode(response.body));
        // let the caller be the one who manipulate the shared preferences and
        // the provider
        return _budget;
      }
      else {
        print("Got error <deleteBudgetList>");
        throw Exception("res=" + response.body);
      }
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<BudgetListModel> fetchBudgetsList(int currencyID,
      [bool? force]) async {
    bool _force = (force ?? false);

    // get the jwt token
    _checkJWT();

    // if not force, then get it from the shared preferences
    if (!_force) {
      BudgetListModel? _budgetListPref =
          BudgetSharedPreferences.getBudgetList(currencyID);
      if (_budgetListPref != null) {
        return _budgetListPref;
      }
    }

    // budget list is null in the shared preferences, so now just fetch the budget list
    // from backend.
    if (_bearerToken.length > 0) {
      final response = await http.get(
          Uri.parse(Globals.apiURL + 'budgets/list/' + currencyID.toString()),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer " + _bearerToken,
          });

      // if got success response, then parse json data and then put on the budget list model
      if (response.statusCode == 200) {
        BudgetListModel _budgetListData =
            BudgetListModel.fromJson(json.decode(response.body));
        await BudgetSharedPreferences.setBudgetList(
            currencyID, _budgetListData);

        return _budgetListData;
      }

      // got error when fetch the budget list
      print("Got error <fetchBudgetsList>");
      throw Exception("res=" + response.body);
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<List<BudgetModel>> fetchBudgetDate(int currencyID, String date,
      [bool? force]) async {
    bool _force = (force ?? false);

    // get the jwt token from shared preferences
    _checkJWT();
    String bearerToken = _bearerToken;

    if (!_force) {
      List<BudgetModel>? _budgetPref =
          BudgetSharedPreferences.getBudget(currencyID, date);
      if (_budgetPref != null) {
        return _budgetPref;
      }
    }

    // check if we got JWT token or not?
    if (bearerToken.length > 0) {
      final response = await http.get(
          Uri.parse(Globals.apiURL +
              'budgets/currency/' +
              currencyID.toString() +
              '/date/' +
              date),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer " + bearerToken,
          });

      //print(response.body);
      if (response.statusCode == 200) {
        // success, it will return the List of Budget Model
        List<dynamic> _jsonData = jsonDecode(response.body);
        List<BudgetModel> _listBudget =
            _jsonData.map((e) => BudgetModel.fromJson(e)).toList();
        BudgetSharedPreferences.setBudget(currencyID, date, _listBudget);
        return _listBudget;
      }

      print("Got error <fetchBudget>");
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
