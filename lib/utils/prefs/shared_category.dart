import 'dart:convert';
import 'package:my_expense/_index.g.dart';

class CategorySharedPreferences {
  static const _keyCategoryExpenseModel = 'category_expense';
  static const _keyCategoryIncomeModel = 'category_income';

  static Future setCategory({
    required List<CategoryModel> expense,
    required List<CategoryModel> income
  }) async {
    // convert both expense and income into List<String>
    List<String> jsonExpense = [];
    List<String> jsonIncome = [];

    if(expense.isNotEmpty) {
      jsonExpense = expense.map((e) => jsonEncode(e.toJson())).toList();
    }

    if(income.isNotEmpty) {
      jsonIncome = income.map((e) => jsonEncode(e.toJson())).toList();
    }

    await Future.wait([
      MyBox.putStringList(
        key: _keyCategoryExpenseModel,
        value: jsonExpense
      ),
      MyBox.putStringList(
        key: _keyCategoryIncomeModel,
        value: jsonIncome
      ),
    ]);
  }

  static Map<int, CategoryModel> getCategory({required String type}) {
    String key = "";

    if(type.toLowerCase() == "expense") {
      key = _keyCategoryExpenseModel;
    }
    else {
      key = _keyCategoryIncomeModel;
    }

    List<String>? data = MyBox.getStringList(key: key);
    // List<String>? _data = _pref!.getStringList(_key);

    if(data != null) {
      List<CategoryModel> listModel = data.map((e) => CategoryModel.fromJson(jsonDecode(e))).toList();
      Map<int, CategoryModel> mapCategory = { for (var e in listModel) e.id : e };
      return mapCategory;
    }
    else {
      return {};
    }
  }
}