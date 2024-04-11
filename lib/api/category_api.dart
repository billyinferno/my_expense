import 'dart:convert';
import 'package:my_expense/model/category_model.dart';
import 'package:my_expense/model/users_me_model.dart';
import 'package:my_expense/utils/globals.dart';
import 'package:my_expense/utils/net/netutils.dart';
import 'package:my_expense/utils/prefs/shared_category.dart';
import 'package:my_expense/utils/prefs/shared_user.dart';

class CategoryHTTPService {

  Future<void> updateDefaultCategory(String type, int categoryID) async {
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
      throw Exception(error);
    });

    // success, it will return the userMe model, so we can just replace the current userMe
    userMe = UsersMeModel.fromJson(jsonDecode(result));
    await UserSharedPreferences.setUserMe(userMe);
  }

  Future<void> fetchCategory([bool? force]) async {
    bool isForce = (force ?? false);

    if (!isForce) {
      // check whether we have data on shared preferences or not?
      Map<int, CategoryModel> expensePref =
          CategorySharedPreferences.getCategory("expense");
      Map<int, CategoryModel> incomePref =
          CategorySharedPreferences.getCategory("income");

      // check if we got data there or not?
      if (expensePref.isNotEmpty && incomePref.isNotEmpty) {
        return;
      }
    }

    // send request to API
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}categories',
    ).onError((error, stackTrace) {
      throw Exception(error);
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
    CategorySharedPreferences.setCategory(expenseModel, incomeModel);
  }

}
