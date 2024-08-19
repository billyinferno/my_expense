import 'dart:convert';
import 'package:my_expense/_index.g.dart';

class BudgetHTTPService {
  Future<void> updateBudgetCurrency(int currencyID) async {
    // check from shared preferences if we already have loaded category data
    UsersMeModel userMe = UserSharedPreferences.getUserMe();

    // prepare the body we will sent to API
    var body = {
      'currency': {'id': currencyID},
      'users_permissions_user': {'id': userMe.id}
    };

    final String result = await NetUtils.put(
      url: '${Globals.apiURL}budgets/defaultcurrency',
      body: body,
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // parse the result
    userMe = UsersMeModel.fromJson(jsonDecode(result));
    await UserSharedPreferences.setUserMe(userMe);
  }

  Future<BudgetModel> addBudgetList(int currencyId, int categoryId) async {
    // check from shared preferences if we already have loaded category data
    UsersMeModel userMe = UserSharedPreferences.getUserMe();

    // create the body we will sent to API
    var body = {
      "category": {"id": categoryId},
      "amount": 0,
      "users_permissions_user": {"id": userMe.id},
      "currency": {"id": currencyId}
    };

    final String result = await NetUtils.post(
      url: '${Globals.apiURL}budgets',
      body: body,
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // success, it will return the complete budget model
    BudgetModel budget = BudgetModel.fromJson(jsonDecode(result));
    // let the caller be the one who manipulate the shared preferences and
    // the provider
    return budget;
  }

  Future<List<BudgetModel>> updateBudgetList(int currencyId, List<BudgetModel> budgetList) async {
    // check from shared preferences if we already have loaded category data
    UsersMeModel userMe = UserSharedPreferences.getUserMe();

    // create the body request we will sent to API
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

    final String result = await NetUtils.putArray(
      url: '${Globals.apiURL}budgets/currency/$currencyId',
      body: body,
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // success, decode the response as budget model
    List<dynamic> jsonData = jsonDecode(result);
    List<BudgetModel> listBudget = jsonData.map((e) => BudgetModel.fromJson(e)).toList();
    return listBudget;
  }

  Future<BudgetModel> deleteBudgetList(int currencyId, int budgetId) async {
    // send delete request to API
    final String result = await NetUtils.delete(
      url: '${Globals.apiURL}budgets/currency/${currencyId.toString()}/id/${budgetId.toString()}',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // success, it will return the complete budget model
    BudgetModel budget = BudgetModel.fromJson(jsonDecode(result));
    // let the caller be the one who manipulate the shared preferences and
    // the provider
    return budget;
  }

  Future<BudgetListModel> fetchBudgetsList(int currencyID,
      [bool? force]) async {
    bool isForce = (force ?? false);

    // if not force, then get it from the shared preferences
    if (!isForce) {
      BudgetListModel? budgetListPref = BudgetSharedPreferences.getBudgetList(currencyID);
      if (budgetListPref != null) {
        return budgetListPref;
      }
    }

    // send get request to API
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}budgets/list/$currencyID',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // if got success response, then parse json data and then put on the budget list model
    BudgetListModel budgetListData = BudgetListModel.fromJson(json.decode(result));
    await BudgetSharedPreferences.setBudgetList(currencyID, budgetListData);

    return budgetListData;
  }

  Future<List<BudgetModel>> fetchBudgetDate(int currencyID, String date,
      [bool? force]) async {
    bool isForce = (force ?? false);

    // check if this is being force or not?
    if (!isForce) {
      List<BudgetModel>? budgetPref = BudgetSharedPreferences.getBudget(currencyID, date);
      if (budgetPref != null) {
        return budgetPref;
      }
    }

    // send get request to API
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}budgets/currency/$currencyID/date/$date',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // success, it will return the List of Budget Model
    List<dynamic> jsonData = jsonDecode(result);
    List<BudgetModel> listBudget =
        jsonData.map((e) => BudgetModel.fromJson(e)).toList();
    BudgetSharedPreferences.setBudget(currencyID, date, listBudget);
    return listBudget;
  }
}
