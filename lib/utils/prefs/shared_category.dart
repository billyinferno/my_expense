import 'dart:convert';

import 'package:my_expense/model/category_model.dart';
import 'package:my_expense/utils/prefs/shared_box.dart';

class CategorySharedPreferences {
  static const _keyCategoryExpenseModel = 'category_expense';
  static const _keyCategoryIncomeModel = 'category_income';

  static Future setCategory(List<CategoryModel> expense, List<CategoryModel> income) async {
    // convert both expense and income into List<String>
    List<String> _jsonExpense = [];
    List<String> _jsonIncome = [];

    if(expense.length > 0) {
      _jsonExpense = expense.map((e) => jsonEncode(e.toJson())).toList();
    }

    if(income.length > 0) {
      _jsonIncome = income.map((e) => jsonEncode(e.toJson())).toList();
    }

    Future.wait([
      MyBox.putStringList(_keyCategoryExpenseModel, _jsonExpense),
      MyBox.putStringList(_keyCategoryIncomeModel, _jsonIncome),
    ]);
    // await _pref!.setStringList(_keyCategoryExpenseModel, _jsonExpense);
    // await _pref!.setStringList(_keyCategoryIncomeModel, _jsonIncome);
  }

  static Map<int, CategoryModel> getCategory(String type) {
    String _key = "";

    if(type.toLowerCase() == "expense") {
      _key = _keyCategoryExpenseModel;
    }
    else {
      _key = _keyCategoryIncomeModel;
    }

    List<String>? _data = MyBox.getStringList(_key);
    // List<String>? _data = _pref!.getStringList(_key);

    if(_data != null) {
      List<CategoryModel> _listModel = _data.map((e) => CategoryModel.fromJson(jsonDecode(e))).toList();
      Map<int, CategoryModel> _mapCategory = Map.fromIterable(_listModel, key: (e) => e.id, value: (e) => e);
      return _mapCategory;
    }
    else {
      return {};
    }
  }
}