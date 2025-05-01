import 'dart:convert';
import 'package:my_expense/_index.g.dart';

class BudgetHTTPService {
  Future<void> updateBudgetCurrency({
    required int currencyID
  }) async {
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
      Log.error(
        message: 'Error on updateBudgetCurrency',
        error: error,
        stackTrace: stackTrace,
      );
      throw error as NetException;
    });

    // parse the result
    userMe = UsersMeModel.fromJson(jsonDecode(result));
    await UserSharedPreferences.setUserMe(userMe);
  }

  Future<BudgetModel> addBudgetList({
    required int currencyId,
    required int categoryId
  }) async {
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
      Log.error(
        message: 'Error on addBudgetList',
        error: error,
        stackTrace: stackTrace,
      );
      throw error as NetException;
    });

    // success, it will return the complete budget model
    BudgetModel budget = BudgetModel.fromJson(jsonDecode(result));
    // let the caller be the one who manipulate the shared preferences and
    // the provider
    return budget;
  }

  Future<List<BudgetModel>> updateBudgetList({
    required int currencyId,
    required List<BudgetModel> budgetList
  }) async {
    // check from shared preferences if we already have loaded category data
    UsersMeModel userMe = UserSharedPreferences.getUserMe();

    // create the body request we will sent to API
    var body = [];
    for (BudgetModel currBudget in budgetList) {
      var budget = {
        "id": currBudget.id,
        "category": currBudget.category.id,
        "amount": currBudget.amount,
        "use_for_daily": currBudget.useForDaily,
        "users_permissions_user": userMe.id,
        "currency": currBudget.currency.id
      };
      body.add(budget);
    }

    final String result = await NetUtils.putArray(
      url: '${Globals.apiURL}budgets/currency/$currencyId',
      body: body,
    ).onError((error, stackTrace) {
      Log.error(
        message: 'Error on updateBudgetList',
        error: error,
        stackTrace: stackTrace,
      );
      throw error as NetException;
    });

    // success, decode the response as budget model
    List<dynamic> jsonData = jsonDecode(result);
    List<BudgetModel> listBudget = jsonData.map((e) => BudgetModel.fromJson(e)).toList();
    return listBudget;
  }

  Future<BudgetModel> deleteBudgetList({
    required int currencyId,
    required int budgetId
  }) async {
    // send delete request to API
    final String result = await NetUtils.delete(
      url: '${Globals.apiURL}budgets/currency/${currencyId.toString()}/id/${budgetId.toString()}',
    ).onError((error, stackTrace) {
      Log.error(
        message: 'Error on deleteBudgetList',
        error: error,
        stackTrace: stackTrace,
      );
      throw error as NetException;
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
      BudgetListModel? budgetListPref = BudgetSharedPreferences.getBudgetList(
        ccyId: currencyID
      );

      if (budgetListPref != null) {
        return budgetListPref;
      }
    }

    // send get request to API
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}budgets/list/$currencyID',
    ).onError((error, stackTrace) {
      Log.error(
        message: 'Error on fetchBudgetsList',
        error: error,
        stackTrace: stackTrace,
      );
      throw error as NetException;
    });

    // if got success response, then parse json data and then put on the budget list model
    BudgetListModel budgetListData = BudgetListModel.fromJson(json.decode(result));
    await BudgetSharedPreferences.setBudgetList(
      ccyId: currencyID,
      budgetList: budgetListData
    );

    return budgetListData;
  }

  Future<List<BudgetModel>> fetchBudgetDate({
    required int currencyID,
    required String date,
    bool force = false,
  }) async {
    // check if this is being force or not?
    if (!force) {
      List<BudgetModel>? budgetPref = BudgetSharedPreferences.getBudget(
        ccyId: currencyID,
        date: date
      );

      if (budgetPref != null) {
        return budgetPref;
      }
    }

    // send get request to API
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}budgets/currency/$currencyID/date/$date',
    ).onError((error, stackTrace) {
      Log.error(
        message: 'Error on fetchBudgetDate',
        error: error,
        stackTrace: stackTrace,
      );
      throw error as NetException;
    });

    // success, it will return the List of Budget Model
    List<dynamic> jsonData = jsonDecode(result);
    List<BudgetModel> listBudget =
        jsonData.map((e) => BudgetModel.fromJson(e)).toList();
    BudgetSharedPreferences.setBudget(
      ccyId: currencyID,
      date: date,
      budgets: listBudget
    );
    return listBudget;
  }
}
