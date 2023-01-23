import 'dart:collection';
import 'dart:convert';
import 'package:my_expense/model/income_expense_model.dart';
import 'package:my_expense/model/last_transaction_model.dart';
import 'package:my_expense/model/transaction_list_model.dart';
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

  static Future setTransaction(String date, List<TransactionListModel> model) async {
    String _key = _transactionKey + "_" + date;
    List<String> _data = model.map((e) => jsonEncode(e.toJson())).toList();

    // print("setTransaction (${date}): " + _data.toString());
    await MyBox.putStringList(_key, _data);
    //await _pref!.setStringList(_key, _data);
  }

  static List<TransactionListModel>? getTransaction(String date) {
    String _key = _transactionKey + "_" + date;

    List<String>? _data = MyBox.getStringList(_key);
    // List<String>? _data = _pref!.getStringList(_key);

    if(_data != null) {
      List<TransactionListModel> _transaction = _data.map((e) => TransactionListModel.fromJson(jsonDecode(e))).toList();
      return _transaction;
    }
    else {
      return null;
    }
  }

  static Future setLastTransaction(String type, List<LastTransactionModel> model) async {
    String _key = "";
    if(type == "expense") {
      _key = _transactionLastExpenseKey;
    }
    else {
      _key = _transactionLastIncomeKey;
    }
    List<String> _data = model.map((e) => jsonEncode(e.toJson())).toList();

    // print("setTransaction (${date}): " + _data.toString());
    await MyBox.putStringList(_key, _data);
    //await _pref!.setStringList(_key, _data);
  }

  static List<LastTransactionModel>? getLastTransaction(String type) {
    String _key = "";
    if(type == "expense") {
      _key = _transactionLastExpenseKey;
    }
    else {
      _key = _transactionLastIncomeKey;
    }

    List<String>? _data = MyBox.getStringList(_key);
    // List<String>? _data = _pref!.getStringList(_key);

    if(_data != null) {
      List<LastTransactionModel> _transaction = _data.map((e) => LastTransactionModel.fromJson(jsonDecode(e))).toList();
      return _transaction;
    }
    else {
      return null;
    }
  }

  static Future setTransactionBudget(int categoryId, String date, List<TransactionListModel> model) async {
    String _key = _transactionBudget + "_" + categoryId.toString() + "_" + date;
    List<String> _data = model.map((e) => jsonEncode(e.toJson())).toList();

    await MyBox.putStringList(_key, _data);
  }

  static List<TransactionListModel>? getTransactionBudget(int categoryId, String date) {
    String _key = _transactionBudget + "_" + categoryId.toString() + "_" + date;

    List<String>? _data = MyBox.getStringList(_key);
    // List<String>? _data = _pref!.getStringList(_key);

    if(_data != null) {
      List<TransactionListModel> _transaction = _data.map((e) => TransactionListModel.fromJson(jsonDecode(e))).toList();
      return _transaction;
    }
    else {
      return null;
    }
  }

  static Future<void> setTransactionMinDate(DateTime date) async {
    await MyBox.putString(_transactionMinDate, date.toString());
  }

  static DateTime getTransactionMinDate() {
    String? _data = MyBox.getString(_transactionMinDate);
    // List<String>? _data = _pref!.getStringList(_key);

    if(_data != null) {
      DateTime _date = DateTime.parse(_data);
      return _date;
    }
    else {
      return DateTime(DateTime.now().year, DateTime.now().month, 1);
    }
  }

  static Future<void> setTransactionMaxDate(DateTime date) async {
    await MyBox.putString(_transactionMaxDate, date.toString());
  }

  static DateTime getTransactionMaxDate() {
    String? _data = MyBox.getString(_transactionMaxDate);
    // List<String>? _data = _pref!.getStringList(_key);

    if(_data != null) {
      DateTime _date = DateTime.parse(_data);
      return _date;
    }
    else {
      return DateTime(DateTime.now().year, DateTime.now().month + 1, 1).subtract(Duration(days: 1));
    }
  }

  static Future setTransactionWallet(int walletId, String date, List<TransactionListModel> model) async {
    String _key = _transactionWallet + "_" + walletId.toString() + "_" + date;
    List<String> _data = model.map((e) => jsonEncode(e.toJson())).toList();

    await MyBox.putStringList(_key, _data);
  }

  static List<TransactionListModel>? getTransactionWallet(int walletId, String date) {
    String _key = _transactionWallet + "_" + walletId.toString() + "_" + date;

    List<String>? _data = MyBox.getStringList(_key);

    if(_data != null) {
      List<TransactionListModel> _transaction = _data.map((e) => TransactionListModel.fromJson(jsonDecode(e))).toList();
      return _transaction;
    }
    else {
      return null;
    }
  }

  static Future<void> deleteTransactionWallet(int walletId, String date, TransactionListModel txn) async {
    String _key = _transactionWallet + "_" + walletId.toString() + "_" + date;
    
    List<String>? _data = MyBox.getStringList(_key);

    List<TransactionListModel> _transaction;
    if(_data != null) {
      _transaction = _data.map((e) => TransactionListModel.fromJson(jsonDecode(e))).toList();
    }
    else {
      // means we don't have the data, no need to add this, as we will fetch it
      // from backend when user select the wallet, and at the end they will still
      // get the same data.
      return;
    }

    int index = -1;
    for(int i=0;i<_transaction.length;i++) {
      if(_transaction[i].id == txn.id) {
        index = i;
        break;
      }
    }

    // remove the transaction
    if(index > -1) {
      _transaction.removeAt(index);
    }

    // set the wallet transaction after we delete the transaction
    await setTransactionWallet(walletId, date, _transaction);
  }

  static Future<void> updateTransactionWallet(int walletId, String date, TransactionListModel txn) async {
    String _key = _transactionWallet + "_" + walletId.toString() + "_" + date;
    
    List<String>? _data = MyBox.getStringList(_key);

    List<TransactionListModel> _transaction;
    if(_data != null) {
      _transaction = _data.map((e) => TransactionListModel.fromJson(jsonDecode(e))).toList();
    }
    else {
      // means we don't have the data, no need to add this, as we will fetch it
      // from backend when user select the wallet, and at the end they will still
      // get the same data.
      return;
    }

    for(int i=0;i<_transaction.length;i++) {
      if(_transaction[i].id == txn.id) {
        _transaction[i] = txn;
        break;
      }
    }

    // set the wallet transaction after we delete the transaction
    await setTransactionWallet(walletId, date, _transaction);
  }

  static Future<void> addTransactionWallet(int walletId, String date, TransactionListModel txn) async {
    String _key = _transactionWallet + "_" + walletId.toString() + "_" + date;
    
    List<String>? _data = MyBox.getStringList(_key);

    List<TransactionListModel> _transaction;
    if(_data != null) {
      _transaction = _data.map((e) => TransactionListModel.fromJson(jsonDecode(e))).toList();
      _transaction.add(txn);
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
    for(int i=0; i<_transaction.length - 1; i++) {
      for(int j=(i+1); j<_transaction.length; j++) {
        if(_transaction[j].date.toLocal().isBefore(_transaction[i].date.toLocal())) {
          // swap the data
          swp = _transaction[i];
          _transaction[i] = _transaction[j];
          _transaction[j] = swp;
        }
        else {
          if(isSameDay(_transaction[i].date.toLocal(), _transaction[j].date.toLocal())) {
            // check which ID is bigger
            if(_transaction[i].id > _transaction[j].id) {
              // swap the data
              swp = _transaction[i];
              _transaction[i] = _transaction[j];
              _transaction[j] = swp;
            }
          }
        }
      }
    }

    // set the transaction wallet after we sort it out
    await setTransactionWallet(walletId, date, _transaction);
  }

  static Future<void> clearTransaction() async {
    final keys = MyBox.keyBox!.keys;
    //final keys = _pref!.getKeys();
    keys.forEach((key) async {
      // check if this key is trx?
      if(key.toLowerCase().startsWith('trx')) {
        // this is transaction key, we can clear this shared preferences
        await MyBox.keyBox!.delete(key);
      }
    });
  }

  static Future<void> setIncomeExpense(int ccyId, String dateFrom, String dateTo, IncomeExpenseModel incomeExpense) async {
    String _key = _transactionIncomeExpense + "_" + ccyId.toString() + "_" + dateFrom + "_" + dateTo;
    String? _incomeExpense = jsonEncode(incomeExpense.toJson());
    //print("Income Expense : " + _incomeExpense);

    await MyBox.putString(_key, _incomeExpense);
  }

  static IncomeExpenseModel? getIncomeExpense(int ccyId, String dateFrom, String dateTo) {
    String _key = _transactionIncomeExpense + "_" + ccyId.toString() + "_" + dateFrom + "_" + dateTo;

    String? _data = MyBox.getString(_key);

    if(_data != null) {
      IncomeExpenseModel _incomeExpense = IncomeExpenseModel.fromJson(jsonDecode(_data));
      return _incomeExpense;
    }
    else {
      return null;
    }
  }

  static Future<IncomeExpenseModel> addIncomeExpense(int ccyId, String dateFrom, String dateTo, TransactionListModel txn) async {
    IncomeExpenseModel? _incomeExpense = getIncomeExpense(ccyId, dateFrom, dateTo);
    if(_incomeExpense == null) {
      _incomeExpense = IncomeExpenseModel(income: {}, expense: {});
    }

    // now check what transaction is this?
    SplayTreeMap<DateTime, double> _sortedMap = SplayTreeMap<DateTime, double>();
    if(txn.type == "expense") {
      // check if this ccy exists or not in expense
      if(_incomeExpense.expense.containsKey(txn.date)) {
        _incomeExpense.expense[txn.date] = _incomeExpense.expense[txn.date]! + (txn.amount * -1);
      }
      else {
        _incomeExpense.expense[txn.date] = (txn.amount * -1);
      }

      // put the expense on the SplayTreeMap
      _incomeExpense.expense.forEach((key, value) {
        _sortedMap[key] = value;
      });

      // create new variable for expense
      Map<DateTime, double> _expense = {};
      _sortedMap.forEach((key, value) {
        _expense[key] = value;
      });

      // put the new expense to new income expense model
      IncomeExpenseModel _newIncomeExpense = IncomeExpenseModel(income: _incomeExpense.income, expense: _expense);
      await setIncomeExpense(ccyId, dateFrom, dateTo, _newIncomeExpense);
      return _newIncomeExpense;
    }
    else if(txn.type == "income") {
      // check if this ccy exists or not in expense
      if(_incomeExpense.income.containsKey(txn.date)) {
        _incomeExpense.income[txn.date] = _incomeExpense.income[txn.date]! + txn.amount;
      }
      else {
        _incomeExpense.income[txn.date] = txn.amount;
      }

      // put the income on the SplayTreeMap
      _incomeExpense.income.forEach((key, value) {
        _sortedMap[key] = value;
      });

      // create new variable for income
      Map<DateTime, double> _income = {};
      _sortedMap.forEach((key, value) {
        _income[key] = value;
      });

      // put the new expense to new income expense model
      IncomeExpenseModel _newIncomeExpense = IncomeExpenseModel(income: _income, expense: _incomeExpense.expense);
      await setIncomeExpense(ccyId, dateFrom, dateTo, _newIncomeExpense);
      return _newIncomeExpense; 
    }

    // return current value
    return _incomeExpense;
  }

  static Future<void> setTransactionListCurrentDate(DateTime date) async {
    await MyBox.putString(_transactionListCurrentDate, date.toString());
  }

  static DateTime? getTransactionListCurrentDate() {
    String? _data = MyBox.getString(_transactionListCurrentDate);
    // List<String>? _data = _pref!.getStringList(_key);

    if(_data != null) {
      DateTime _date = DateTime.parse(_data);
      return _date;
    }
    else {
      return null;
    }
  }
}