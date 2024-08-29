import 'dart:convert';
import 'package:my_expense/_index.g.dart';

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

    await MyBox.putStringList(
      key: "$_keyBudgetModel${currencyID}_$date",
      value: jsonBudget,
    );
  }

  static List<BudgetModel>? getBudget(int currencyID, String date) {
    List<String>? data = MyBox.getStringList(
      key: "$_keyBudgetModel${currencyID}_$date"
    );

    if(data != null) {
      List<BudgetModel> listBudgetModel = data.map((e) => BudgetModel.fromJson(jsonDecode(e))).toList();
      return listBudgetModel;
    }
    else {
      return null;
    }
  }

  static Future setBudgetCurrent(DateTime date) async {
    String strDate = Globals.dfyyyyMMdd.format(DateTime(date.toLocal().year, date.toLocal().month, 1));
    await MyBox.putString(key: _keyCurrentBudgetDate, value: strDate);
  }

  static String getBudgetCurrent() {
    String? date = MyBox.getString(key: _keyCurrentBudgetDate);

    if(date != null) {
      return date;
    }
    else {
      return Globals.dfyyyyMMdd.format(DateTime(DateTime.now().toLocal().year, DateTime.now().toLocal().month, 1));
    }
  }

  static Future<void> setBudgetList(int currencyID, BudgetListModel budgetList) async {
    await MyBox.putString(
      key: _keyBudgetList + currencyID.toString(),
      value: jsonEncode(budgetList.toJson())
    );
  }

  static BudgetListModel? getBudgetList(int currencyID) {
    String? data = MyBox.getString(key: _keyBudgetList + currencyID.toString());

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