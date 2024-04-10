import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:my_expense/model/budget_list_model.dart';
import 'package:my_expense/model/budget_model.dart';
import 'package:my_expense/utils/prefs/shared_box.dart';

class BudgetSharedPreferences {
  static const _keyBudgetModel = 'budget_'; // key will be budget_{ccy}_{date}
  static const _keyBudgetList = 'budget_list_'; // key will be budget_list_{ccy}
  static const _keyCurrentBudgetDate = 'budget_current';

  static Future setBudget(int currencyID, String date, List<BudgetModel> budgets) async {
    // convert both expense and income into List<String>
    List<String> jsonBudget = [];

    if(budgets.isNotEmpty) {
      jsonBudget = budgets.map((e) => jsonEncode(e.toJson())).toList();
    }

    await MyBox.putStringList("$_keyBudgetModel${currencyID}_$date", jsonBudget);
    //await _pref!.setStringList(_keyBudgetModel + currencyID.toString() + "_" + date, _jsonBudget);
  }

  static List<BudgetModel>? getBudget(int currencyID, String date) {
    List<String>? data = MyBox.getStringList("$_keyBudgetModel${currencyID}_$date");
    //List<String>? _data = _pref!.getStringList(_keyBudgetModel + currencyID.toString() + "_" + date);

    if(data != null) {
      List<BudgetModel> listBudgetModel = data.map((e) => BudgetModel.fromJson(jsonDecode(e))).toList();
      return listBudgetModel;
    }
    else {
      return null;
    }
  }

  static Future setBudgetCurrent(DateTime date) async {
    String strDate = DateFormat('yyyy-MM-dd').format(DateTime(date.toLocal().year, date.toLocal().month, 1));
    await MyBox.putString(_keyCurrentBudgetDate, strDate);
    //await _pref!.setString(_keyCurrentBudgetDate, _date);
  }

  static String getBudgetCurrent() {
    String? date = MyBox.getString(_keyCurrentBudgetDate);
    //String? _date = _pref!.getString(_keyCurrentBudgetDate);

    if(date != null) {
      return date;
    }
    else {
      return DateFormat('yyyy-MM-dd').format(DateTime(DateTime.now().toLocal().year, DateTime.now().toLocal().month, 1));
    }
  }

  static Future<void> setBudgetList(int currencyID, BudgetListModel budgetList) async {
    await MyBox.putString(_keyBudgetList + currencyID.toString(), jsonEncode(budgetList.toJson()));
    //await _pref!.setString(_keyBudgetList + currencyID.toString(), jsonEncode(budgetList.toJson()));
  }

  static BudgetListModel? getBudgetList(int currencyID) {
    String? data = MyBox.getString(_keyBudgetList + currencyID.toString());
    //String? _data = _pref!.getString(_keyBudgetList + currencyID.toString());

    if(data != null) {
      BudgetListModel listBudgetListModel = BudgetListModel.fromJson(jsonDecode(data));
      return listBudgetListModel;
    }
    else {
      return null;
    }
  }

  static Future<void> clearBudget() async {
    final keys = MyBox.keyBox!.keys;
    for(var key in keys) {
      // check if this key is trx?
      if(key.toLowerCase().startsWith('budget_')) {
        // this is transaction key, we can clear this shared preferences
        await MyBox.keyBox!.delete(key);
      }
    }
  }
}