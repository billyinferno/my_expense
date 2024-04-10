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
    UsersMeModel userMe = UserSharedPreferences.getUserMe();

    // check if we got JWT token or not?
    if (bearerToken.isNotEmpty) {
      var body = {
        'currency': {'id': currencyID},
        'users_permissions_user': {'id': userMe.id}
      };

      final response =
          await http.put(Uri.parse('${Globals.apiURL}budgets/defaultcurrency'),
              headers: {
                HttpHeaders.authorizationHeader: "Bearer $bearerToken",
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(body));

      if (response.statusCode == 200) {
        // success, it will return the userMe model, so we can just replace the current userMe
        userMe = UsersMeModel.fromJson(jsonDecode(response.body));
        await UserSharedPreferences.setUserMe(userMe);
        return;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<BudgetModel> addBudgetList(int currencyId, int categoryId) async {
    // get the JWT token
    _checkJWT();

    // check from shared preferences if we already have loaded category data
    UsersMeModel userMe = UserSharedPreferences.getUserMe();

    // ensure that we have bearer token
    if (_bearerToken.isNotEmpty) {
      var body = {
        "category": {"id": categoryId},
        "amount": 0,
        "users_permissions_user": {"id": userMe.id},
        "currency": {"id": currencyId}
      };

      final response = await http.post(Uri.parse('${Globals.apiURL}budgets'),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer $_bearerToken",
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(body));
      
      if (response.statusCode == 200) {
        // success, it will return the complete budget model
        BudgetModel budget = BudgetModel.fromJson(jsonDecode(response.body));
        // let the caller be the one who manipulate the shared preferences and
        // the provider
        return budget;
      }
      else {
        throw Exception("res=${response.body}");
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
    UsersMeModel userMe = UserSharedPreferences.getUserMe();

    // ensure that we have bearer token
    if (_bearerToken.isNotEmpty) {
      var body = [];
      for (var element in budgetList) {
        var budget = {
          "id": element.id,
          "category": element.category.id,
          "amount": element.amount,
          "users_permissions_user": userMe.id,
          "currency": element.currency.id
        };
        body.add(budget);
      }

      //print(jsonEncode(_body));

      final response = await http.put(Uri.parse('${Globals.apiURL}budgets/currency/$currencyId'),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer $_bearerToken",
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(body));
      
      if (response.statusCode == 200) {
        // success, decode the response as budget model
        List<dynamic> jsonData = jsonDecode(response.body);
        List<BudgetModel> listBudget = jsonData.map((e) => BudgetModel.fromJson(e)).toList();
        return listBudget;
      }
      else {
        throw Exception("res=${response.body}");
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
    if (_bearerToken.isNotEmpty) {
      final response = await http.delete(Uri.parse("${Globals.apiURL}budgets/currency/${currencyId.toString()}/id/${budgetId.toString()}"),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer $_bearerToken",
            'Content-Type': 'application/json; charset=UTF-8',
          });
      
      if (response.statusCode == 200) {
        // success, it will return the complete budget model
        BudgetModel budget = BudgetModel.fromJson(jsonDecode(response.body));
        // let the caller be the one who manipulate the shared preferences and
        // the provider
        return budget;
      }
      else {
        throw Exception("res=${response.body}");
      }
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<BudgetListModel> fetchBudgetsList(int currencyID,
      [bool? force]) async {
    bool isForce = (force ?? false);

    // get the jwt token
    _checkJWT();

    // if not force, then get it from the shared preferences
    if (!isForce) {
      BudgetListModel? budgetListPref =
          BudgetSharedPreferences.getBudgetList(currencyID);
      if (budgetListPref != null) {
        return budgetListPref;
      }
    }

    // budget list is null in the shared preferences, so now just fetch the budget list
    // from backend.
    if (_bearerToken.isNotEmpty) {
      final response = await http.get(
          Uri.parse('${Globals.apiURL}budgets/list/$currencyID'),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer $_bearerToken",
          });

      // if got success response, then parse json data and then put on the budget list model
      if (response.statusCode == 200) {
        BudgetListModel budgetListData =
            BudgetListModel.fromJson(json.decode(response.body));
        await BudgetSharedPreferences.setBudgetList(
            currencyID, budgetListData);

        return budgetListData;
      }

      // got error when fetch the budget list
      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<List<BudgetModel>> fetchBudgetDate(int currencyID, String date,
      [bool? force]) async {
    bool isForce = (force ?? false);

    // get the jwt token from shared preferences
    _checkJWT();
    String bearerToken = _bearerToken;

    if (!isForce) {
      List<BudgetModel>? budgetPref =
          BudgetSharedPreferences.getBudget(currencyID, date);
      if (budgetPref != null) {
        return budgetPref;
      }
    }

    // check if we got JWT token or not?
    if (bearerToken.isNotEmpty) {
      final response = await http.get(
          Uri.parse('${Globals.apiURL}budgets/currency/$currencyID/date/$date'),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer $bearerToken",
          });

      //print(response.body);
      if (response.statusCode == 200) {
        // success, it will return the List of Budget Model
        List<dynamic> jsonData = jsonDecode(response.body);
        List<BudgetModel> listBudget =
            jsonData.map((e) => BudgetModel.fromJson(e)).toList();
        BudgetSharedPreferences.setBudget(currencyID, date, listBudget);
        return listBudget;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  void _checkJWT() {
    if (_bearerToken.isEmpty) {
      _bearerToken = UserSharedPreferences.getJWT();
    }
  }
}
