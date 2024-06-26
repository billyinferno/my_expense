import 'dart:collection';
import 'dart:convert';
import 'package:my_expense/model/income_expense_model.dart';
import 'package:my_expense/model/last_transaction_model.dart';
import 'package:my_expense/model/transaction_list_model.dart';
import 'package:my_expense/model/transaction_top_model.dart';
import 'package:my_expense/utils/prefs/shared_box.dart';
import 'package:table_calendar/table_calendar.dart';

class TransactionSharedPreferences {
  static const _transactionKey = "trx";
  static const _transactionLastExpenseKey = "trx_last_expense";
  static const _transactionLastIncomeKey = "trx_last_income";
  static const _transactionBudget = "trx_budget";
  static const _transactionMinDate = "trx_min_date";
  static const _transactionMaxDate = "trx_max_date";
  static const _transactionWallet = "trx_wallet";
  static const _transactionIncomeExpense = "trx_income_expense";
  static const _transactionListCurrentDate = "trx_list_current_date";
  static const _transactionTop = "trx_top";
  static const _transactionStatDateFrom = "trx_stat_date_from";
  static const _transactionStatDateTo = "trx_stat_date_to";

  static Future setTransaction(String date, List<TransactionListModel> model) async {
    String key = "${_transactionKey}_$date";
    List<String> data = model.map((e) => jsonEncode(e.toJson())).toList();

    await MyBox.putStringList(key, data);
  }

  static List<TransactionListModel>? getTransaction(String date) {
    String key = "${_transactionKey}_$date";

    List<String>? data = MyBox.getStringList(key);

    if(data != null) {
      List<TransactionListModel> transaction = data.map((e) => TransactionListModel.fromJson(jsonDecode(e))).toList();
      return transaction;
    }
    else {
      return null;
    }
  }

  static Future setLastTransaction(String type, List<LastTransactionModel> model) async {
    String key = "";
    if(type == "expense") {
      key = _transactionLastExpenseKey;
    }
    else {
      key = _transactionLastIncomeKey;
    }
    List<String> data = model.map((e) => jsonEncode(e.toJson())).toList();

    await MyBox.putStringList(key, data);
  }

  static List<LastTransactionModel>? getLastTransaction(String type) {
    String key = "";
    if(type == "expense") {
      key = _transactionLastExpenseKey;
    }
    else {
      key = _transactionLastIncomeKey;
    }

    List<String>? data = MyBox.getStringList(key);

    if(data != null) {
      List<LastTransactionModel> transaction = data.map((e) => LastTransactionModel.fromJson(jsonDecode(e))).toList();
      return transaction;
    }
    else {
      return null;
    }
  }

  static Future setTransactionBudget(int categoryId, String date, List<TransactionListModel> model) async {
    String key = "${_transactionBudget}_${categoryId}_$date";
    List<String> data = model.map((e) => jsonEncode(e.toJson())).toList();

    await MyBox.putStringList(key, data);
  }

  static List<TransactionListModel>? getTransactionBudget(int categoryId, String date) {
    String key = "${_transactionBudget}_${categoryId}_$date";

    List<String>? data = MyBox.getStringList(key);

    if(data != null) {
      List<TransactionListModel> transaction = data.map((e) => TransactionListModel.fromJson(jsonDecode(e))).toList();
      return transaction;
    }
    else {
      return null;
    }
  }

  static Future<void> setTransactionMinDate(DateTime date) async {
    await MyBox.putString(_transactionMinDate, date.toString());
  }

  static DateTime getTransactionMinDate() {
    String? data = MyBox.getString(_transactionMinDate);

    if(data != null) {
      DateTime date = DateTime.parse(data);
      return date;
    }
    else {
      return DateTime(DateTime.now().year, DateTime.now().month, 1);
    }
  }

  static Future<void> setTransactionMaxDate(DateTime date) async {
    await MyBox.putString(_transactionMaxDate, date.toString());
  }

  static DateTime getTransactionMaxDate() {
    String? data = MyBox.getString(_transactionMaxDate);

    if(data != null) {
      DateTime date = DateTime.parse(data);
      return date;
    }
    else {
      return DateTime(DateTime.now().year, DateTime.now().month + 1, 1).subtract(const Duration(days: 1));
    }
  }

  static Future setTransactionWallet(int walletId, String date, List<TransactionListModel> model) async {
    String key = "${_transactionWallet}_${walletId}_$date";
    List<String> data = model.map((e) => jsonEncode(e.toJson())).toList();

    await MyBox.putStringList(key, data);
  }

  static List<TransactionListModel>? getTransactionWallet(int walletId, String date) {
    String key = "${_transactionWallet}_${walletId}_$date";

    List<String>? data = MyBox.getStringList(key);

    if(data != null) {
      List<TransactionListModel> transaction = data.map((e) => TransactionListModel.fromJson(jsonDecode(e))).toList();
      return transaction;
    }
    else {
      return null;
    }
  }

  static Future<void> deleteTransactionWallet(int walletId, String date, TransactionListModel txn) async {
    String key = "${_transactionWallet}_${walletId}_$date";
    
    List<String>? data = MyBox.getStringList(key);

    List<TransactionListModel> transaction;
    if(data != null) {
      transaction = data.map((e) => TransactionListModel.fromJson(jsonDecode(e))).toList();
    }
    else {
      // means we don't have the data, no need to add this, as we will fetch it
      // from backend when user select the wallet, and at the end they will still
      // get the same data.
      return;
    }

    int index = -1;
    for(int i=0;i<transaction.length;i++) {
      if(transaction[i].id == txn.id) {
        index = i;
        break;
      }
    }

    // remove the transaction
    if(index > -1) {
      transaction.removeAt(index);
    }

    // set the wallet transaction after we delete the transaction
    await setTransactionWallet(walletId, date, transaction);
  }

  static Future<void> updateTransactionWallet(int walletId, String date, TransactionListModel txn) async {
    String key = "${_transactionWallet}_${walletId}_$date";
    
    List<String>? data = MyBox.getStringList(key);

    List<TransactionListModel> transaction;
    if(data != null) {
      transaction = data.map((e) => TransactionListModel.fromJson(jsonDecode(e))).toList();
    }
    else {
      // means we don't have the data, no need to add this, as we will fetch it
      // from backend when user select the wallet, and at the end they will still
      // get the same data.
      return;
    }

    for(int i=0;i<transaction.length;i++) {
      if(transaction[i].id == txn.id) {
        transaction[i] = txn;
        break;
      }
    }

    // set the wallet transaction after we delete the transaction
    await setTransactionWallet(walletId, date, transaction);
  }

  static Future<void> addTransactionWallet(int walletId, String date, TransactionListModel txn) async {
    String key = "${_transactionWallet}_${walletId}_$date";
    
    List<String>? data = MyBox.getStringList(key);

    List<TransactionListModel> transaction;
    if(data != null) {
      transaction = data.map((e) => TransactionListModel.fromJson(jsonDecode(e))).toList();
      transaction.add(txn);
    }
    else {
      // means we don't have the data, no need to add this, as we will fetch it
      // from backend when user select the wallet, and at the end they will still
      // get the same data.
      return;
    }

    // in case user insert the transaction in the middle (not current date), then we need to
    // sorted the transaction
    TransactionListModel swp;
    for(int i=0; i<transaction.length - 1; i++) {
      for(int j=(i+1); j<transaction.length; j++) {
        if(transaction[j].date.toLocal().isBefore(transaction[i].date.toLocal())) {
          // swap the data
          swp = transaction[i];
          transaction[i] = transaction[j];
          transaction[j] = swp;
        }
        else {
          if(isSameDay(transaction[i].date.toLocal(), transaction[j].date.toLocal())) {
            // check which ID is bigger
            if(transaction[i].id > transaction[j].id) {
              // swap the data
              swp = transaction[i];
              transaction[i] = transaction[j];
              transaction[j] = swp;
            }
          }
        }
      }
    }

    // set the transaction wallet after we sort it out
    await setTransactionWallet(walletId, date, transaction);
  }

  static Future<void> clearTransaction() async {
    final keys = MyBox.keyBox!.keys;
    for(var key in keys) {
      // check if this key is trx?
      if(key.toLowerCase().startsWith('trx')) {
        // this is transaction key, we can clear this shared preferences
        await MyBox.keyBox!.delete(key);
      }
    }
  }

  static Future<void> setIncomeExpense(int ccyId, String dateFrom, String dateTo, IncomeExpenseModel incomeExpense) async {
    String key = "${_transactionIncomeExpense}_${ccyId}_${dateFrom}_$dateTo";
    String? incomeExpense0 = jsonEncode(incomeExpense.toJson());

    await MyBox.putString(key, incomeExpense0);
  }

  static IncomeExpenseModel? getIncomeExpense(int ccyId, String dateFrom, String dateTo) {
    String key = "${_transactionIncomeExpense}_${ccyId}_${dateFrom}_$dateTo";

    String? data = MyBox.getString(key);

    if(data != null) {
      IncomeExpenseModel incomeExpense = IncomeExpenseModel.fromJson(jsonDecode(data));
      return incomeExpense;
    }
    else {
      return null;
    }
  }

  static Future<IncomeExpenseModel> addIncomeExpense(int ccyId, String dateFrom, String dateTo, TransactionListModel txn) async {
    IncomeExpenseModel? incomeExpense = (getIncomeExpense(ccyId, dateFrom, dateTo) ?? IncomeExpenseModel(income: {}, expense: {}));

    // now check what transaction is this?
    SplayTreeMap<DateTime, double> sortedMap = SplayTreeMap<DateTime, double>();
    if(txn.type == "expense") {
      // check if this ccy exists or not in expense
      if(incomeExpense.expense.containsKey(txn.date)) {
        incomeExpense.expense[txn.date] = incomeExpense.expense[txn.date]! + (txn.amount * -1);
      }
      else {
        incomeExpense.expense[txn.date] = (txn.amount * -1);
      }

      // put the expense on the SplayTreeMap
      incomeExpense.expense.forEach((key, value) {
        sortedMap[key] = value;
      });

      // create new variable for expense
      Map<DateTime, double> expense = {};
      sortedMap.forEach((key, value) {
        expense[key] = value;
      });

      // put the new expense to new income expense model
      IncomeExpenseModel newIncomeExpense = IncomeExpenseModel(income: incomeExpense.income, expense: expense);
      await setIncomeExpense(ccyId, dateFrom, dateTo, newIncomeExpense);
      return newIncomeExpense;
    }
    else if(txn.type == "income") {
      // check if this ccy exists or not in expense
      if(incomeExpense.income.containsKey(txn.date)) {
        incomeExpense.income[txn.date] = incomeExpense.income[txn.date]! + txn.amount;
      }
      else {
        incomeExpense.income[txn.date] = txn.amount;
      }

      // put the income on the SplayTreeMap
      incomeExpense.income.forEach((key, value) {
        sortedMap[key] = value;
      });

      // create new variable for income
      Map<DateTime, double> income = {};
      sortedMap.forEach((key, value) {
        income[key] = value;
      });

      // put the new expense to new income expense model
      IncomeExpenseModel newIncomeExpense0 = IncomeExpenseModel(income: income, expense: incomeExpense.expense);
      await setIncomeExpense(ccyId, dateFrom, dateTo, newIncomeExpense0);
      return newIncomeExpense0; 
    }

    // return current value
    return incomeExpense;
  }

  static Future<void> setTransactionListCurrentDate(DateTime date) async {
    await MyBox.putString(_transactionListCurrentDate, date.toString());
  }

  static DateTime? getTransactionListCurrentDate() {
    String? data = MyBox.getString(_transactionListCurrentDate);
    
    if(data != null) {
      DateTime date = DateTime.parse(data);
      return date;
    }
    else {
      return null;
    }
  }

  static Future setTransactionTop(String date, String type, List<TransactionTopModel> model) async {
    String key = "${_transactionTop}_${date}_$type";
    List<String> data = model.map((e) => jsonEncode(e.toJson())).toList();

    await MyBox.putStringList(key, data);
  }

  static List<TransactionTopModel>? getTransactionTop(String date, String type) {
    String key = "${_transactionTop}_${date}_$type";

    List<String>? data = MyBox.getStringList(key);

    if(data != null) {
      List<TransactionTopModel> transaction = data.map((e) => TransactionTopModel.fromJson(jsonDecode(e))).toList();
      return transaction;
    }
    else {
      return null;
    }
  }

  static Future setStatDate(DateTime from, DateTime to) async {
    String strDateFrom = from.toLocal().toIso8601String();
    String strDateTo = to.toLocal().toIso8601String();

    await MyBox.putString(_transactionStatDateFrom, strDateFrom);
    await MyBox.putString(_transactionStatDateTo, strDateTo);
  }

  static (DateTime, DateTime) getStatDate() {
    String? dateFrom = MyBox.getString(_transactionStatDateFrom);
    String? dateTo = MyBox.getString(_transactionStatDateFrom);

    DateTime from = DateTime(DateTime.now().year, DateTime.now().month, 1);
    DateTime to = DateTime(DateTime.now().year, DateTime.now().month + 1, 1).subtract(const Duration(days: 1));

    if (dateFrom != null) {
      from = DateTime.parse(dateFrom);
    }
    if (dateTo != null) {
      to = DateTime.parse(dateTo);
    }
    
    return (from, to);
  }
}