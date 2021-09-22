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
    List<String> _jsonBudget = [];

    if(budgets.length > 0) {
      _jsonBudget = budgets.map((e) => jsonEncode(e.toJson())).toList();
    }

    await MyBox.putStringList(_keyBudgetModel + currencyID.toString() + "_" + date, _jsonBudget);
    //await _pref!.setStringList(_keyBudgetModel + currencyID.toString() + "_" + date, _jsonBudget);
  }

  static List<BudgetModel>? getBudget(int currencyID, String date) {
    List<String>? _data = MyBox.getStringList(_keyBudgetModel + currencyID.toString() + "_" + date);
    //List<String>? _data = _pref!.getStringList(_keyBudgetModel + currencyID.toString() + "_" + date);

    if(_data != null) {
      List<BudgetModel> _listBudgetModel = _data.map((e) => BudgetModel.fromJson(jsonDecode(e))).toList();
      return _listBudgetModel;
    }
    else {
      return null;
    }
  }

  static Future setBudgetCurrent(DateTime date) async {
    String _date = DateFormat('yyyy-MM-dd').format(DateTime(date.toLocal().year, date.toLocal().month, 1));
    await MyBox.putString(_keyCurrentBudgetDate, _date);
    //await _pref!.setString(_keyCurrentBudgetDate, _date);
  }

  static String getBudgetCurrent() {
    String? _date = MyBox.getString(_keyCurrentBudgetDate);
    //String? _date = _pref!.getString(_keyCurrentBudgetDate);

    if(_date != null) {
      return _date;
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
    String? _data = MyBox.getString(_keyBudgetList + currencyID.toString());
    //String? _data = _pref!.getString(_keyBudgetList + currencyID.toString());

    if(_data != null) {
      BudgetListModel _listBudgetListModel = BudgetListModel.fromJson(jsonDecode(_data));
      return _listBudgetListModel;
    }
    else {
      return null;
    }
  }

  static Future<void> clearBudget() async {
    final keys = MyBox.keyBox!.keys;
    keys.forEach((key) async {
      // check if this key is trx?
      if(key.toLowerCase().startsWith('budget_')) {
        // this is transaction key, we can clear this shared preferences
        await MyBox.keyBox!.delete(key);
      }
    });
  }
}