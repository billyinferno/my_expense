import 'dart:convert';
import 'package:my_expense/_index.g.dart';

class CategoryHTTPService {

  Future<void> updateDefaultCategory({
    required String type,
    required int categoryID
  }) async {
    // get user information from the shared preferences
    UsersMeModel userMe = UserSharedPreferences.getUserMe();

    // prepare the request for update default category
    var body = {
      'category': {'id': categoryID},
      'users_permissions_user': {'id': userMe.id}
    };

    final String result = await NetUtils.put(
      url: '${Globals.apiURL}categories/default/${type.toLowerCase()}',
      body: body,
    ).onError((error, stackTrace) {
      Log.error(
        message: 'Error on updateDefaultCategory',
        error: error,
        stackTrace: stackTrace,
      );
      throw error as NetException;
    });

    // success, it will return the userMe model, so we can just replace the current userMe
    userMe = UsersMeModel.fromJson(jsonDecode(result));
    await UserSharedPreferences.setUserMe(userMe);
  }

  Future<void> fetchCategory({
    bool force = false
  }) async {
    if (!force) {
      // check whether we have data on shared preferences or not?
      Map<int, CategoryModel> expensePref =
          CategorySharedPreferences.getCategory(type: "expense");
      Map<int, CategoryModel> incomePref =
          CategorySharedPreferences.getCategory(type: "income");

      // check if we got data there or not?
      if (expensePref.isNotEmpty && incomePref.isNotEmpty) {
        return;
      }
    }

    // send request to API
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}categories',
    ).onError((error, stackTrace) {
      Log.error(
        message: 'Error on fetchCategory',
        error: error,
        stackTrace: stackTrace,
      );
      throw error as NetException;
    });

    // parse the category data
    List<dynamic> jsonData = jsonDecode(result);
    List<CategoryModel> categoryList =
        jsonData.map((e) => CategoryModel.fromJson(e)).toList();

    // generate the category for expense and income
    List<CategoryModel> expenseModel = [];
    List<CategoryModel> incomeModel = [];
    for (var category in categoryList) {
      // check if this is expense or income
      if (category.type.toLowerCase() == "expense") {
        expenseModel.add(category);
      } else if (category.type.toLowerCase() == "income") {
        incomeModel.add(category);
      }
    }

    // saved the expense and income category model
    CategorySharedPreferences.setCategory(
      expense: expenseModel,
      income: incomeModel
    );
  }

}
