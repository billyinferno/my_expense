import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:my_expense/model/income_expense_category_model.dart';
import 'package:my_expense/model/income_expense_model.dart';
import 'package:my_expense/model/last_transaction_model.dart';
import 'package:my_expense/model/transaction_list_model.dart';
import 'package:my_expense/model/transaction_model.dart';
import 'package:my_expense/model/transaction_stats_detail_model.dart';
import 'package:my_expense/provider/home_provider.dart';
import 'package:my_expense/utils/globals.dart';
import 'package:my_expense/utils/prefs/shared_user.dart';
import 'package:my_expense/utils/prefs/shared_transaction.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class TransactionHTTPService {
  //late LoginModel _loginModel;
  late String _bearerToken;

  TransactionHTTPService() {
    //_loginModel = UserSharedPreferences.getUserLogin();
    _bearerToken = UserSharedPreferences.getJWT();
  }

  void refreshJWTToken() {
    _bearerToken = UserSharedPreferences.getJWT();
  }

  Future<TransactionListModel> updateTransaction(BuildContext context, TransactionModel txn, TransactionListModel prevTxn) async {
    bool _sameDate = isSameDay(txn.date.toLocal(), prevTxn.date.toLocal());
    _checkJWT();

    // in case there are date change on the transaction it means that we need
    // to remove the transaction in the prevDate, and fetch the new transaction
    // data from the txn.date.

    // check if we got JWT token or not?
    if (_bearerToken.length > 0) {
      final response = await http.put(
          Uri.parse(Globals.apiURL + 'transactions/' + prevTxn.id.toString()),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer " + _bearerToken,
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(txn.toJson()));

      if (response.statusCode == 200) {
        String date = DateFormat('yyyy-MM-dd').format(prevTxn.date.toLocal());

        // fetch the added data and put it into TransactionListModel
        TransactionListModel _txnUpdate =
            TransactionListModel.fromJson(jsonDecode(response.body));

        // get the list of previous transaction date from shared preferences
        List<TransactionListModel>? _txnListShared = TransactionSharedPreferences.getTransaction(date);

        // the transaction list shouldn't be NULL, since we update it
        // in case null, then we just add this transaction to the transaction
        // list? (don't want to throw any unnecessary error to GUI).
        if (_txnListShared == null) {
          _txnListShared = [];
          _txnListShared.add(_txnUpdate);
        } else {
          // now we can check if this is still the same date or not?
          // if same date, then it will be an easy job, since we just need to
          // update the transaction by forLoop it, and then just replace when
          // we find the matching id
          if (_sameDate) {
            for (int idx = 0; idx < _txnListShared.length; idx++) {
              if (_txnListShared[idx].id == _txnUpdate.id) {
                // this is the transaction we need to change
                _txnListShared[idx] = _txnUpdate;
                // break from the for-loop
                break;
              }
            }
          } else {
            // this means that we have 2 separate day, the first one is
            // we need to remove the previous transaction on the _prevDate,
            // then after that we will need to fetch the data on the current
            // txn.date
            List<TransactionListModel> _removeTxnList = _txnListShared;
            for (int idx = 0; idx < _txnListShared.length; idx++) {
              // check if the id is the same or not?
              if (_txnListShared[idx].id == prevTxn.id) {
                _removeTxnList.removeAt(idx);
              }
            }
            
            // set the _txnListShared with the _removeTxnList
            _txnListShared = _removeTxnList;
            
            // fetch the date that we got from then _txnUpdate
            String _txnUpdateDate = DateFormat('yyyy-MM-dd').format(_txnUpdate.date.toLocal());
            
            // ensure to force fetch the transaction
            await fetchTransaction(_txnUpdateDate, true);
          }
        }

        // once all the manipulation finished
        await TransactionSharedPreferences.setTransaction(date, _txnListShared);

        // for transaction that actually add on the different date, we cannot notify the home list
        // to show this transaction, because currently we are in a different date between the transaction
        // being add and the date being selected on the home list
        DateTime? currentListTxnDate = TransactionSharedPreferences.getTransactionListCurrentDate();
        if (currentListTxnDate == null) {
          currentListTxnDate = DateTime.now();
        }

        if (isSameDay(txn.date.toLocal(), currentListTxnDate.toLocal())) {
          // once add on the shared preferences, we can change the
          // TransactionListModel provider so it will update the home list page
          Provider.of<HomeProvider>(context, listen: false).setTransactionList(_txnListShared);
        }

        // return from the proc
        return _txnUpdate;
      }

      print("Got error <updateTransaction>");
      throw Exception("res=" + response.body);
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token when adding transaction"}');
    }
  }

  Future<TransactionListModel> addTransaction(BuildContext context, TransactionModel txn, DateTime selectedDate) async {
    _checkJWT();

    // check if we got JWT token or not?
    if (_bearerToken.length > 0) {
      final response =
          await http.post(Uri.parse(Globals.apiURL + 'transactions/add'),
              headers: {
                HttpHeaders.authorizationHeader: "Bearer " + _bearerToken,
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(txn.toJson()));

      if (response.statusCode == 200) {
        String date = DateFormat('yyyy-MM-dd').format(txn.date.toLocal());

        // fetch the added data and put it into TransactionListModel
        TransactionListModel _txnAdd =
            TransactionListModel.fromJson(jsonDecode(response.body));

        // now we get the information of the transaction we add, we can directly
        // get the data from the sharedPreferences, add the new one and then
        // store back to the sharedPreferences
        List<TransactionListModel>? _txnListShared =
            TransactionSharedPreferences.getTransaction(date);

        // add the new transaction that we add
        if (_txnListShared == null) {
          _txnListShared = [];
        }
        _txnListShared.add(_txnAdd);

        // and set back this shared preferences
        await TransactionSharedPreferences.setTransaction(date, _txnListShared);

        // for transaction that actually add on the different date, we cannot notify the home list
        // to show this transaction, because currently we are in a different date between the transaction
        // being add and the date being selected on the home list
        if (isSameDay(txn.date.toLocal(), selectedDate.toLocal())) {
          Provider.of<HomeProvider>(context, listen: false).setTransactionList(_txnListShared);
        }

        // return from the proc
        return _txnAdd;
      }

      print("Got error <addTransaction>");
      throw Exception("res=" + response.body);
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token when adding transaction"}');
    }
  }

  Future<List<TransactionListModel>> fetchTransaction(String date,
      [bool? force]) async {
    bool _force = (force ?? false);

    // check if we got data on the sharedPreferences or not?
    if (!_force) {
      List<TransactionListModel>? _transactionPref =
          TransactionSharedPreferences.getTransaction(date);
      if (_transactionPref != null) {
        return _transactionPref;
      }
    }

    _checkJWT();
    //print("<fetchTransaction> : " + _bearerToken);

    // check if we got JWT token or not?
    if (_bearerToken.length > 0) {
      final response = await http.get(
          Uri.parse(Globals.apiURL + 'transactions/date/' + date),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer " + _bearerToken,
          });

      if (response.statusCode == 200) {
        List<dynamic> _jsonData = jsonDecode(response.body);
        List<TransactionListModel> _transactionModel =
            _jsonData.map((e) => TransactionListModel.fromJson(e)).toList();
        TransactionSharedPreferences.setTransaction(date, _transactionModel);
        return _transactionModel;
      }

      print("Got error <fetchTransaction>");
      throw Exception("res=" + response.body);
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<List<LastTransactionModel>> fetchLastTransaction(String type, [bool? force]) async {
    bool _force = (force ?? false);

    // check if we got data on the sharedPreferences or not?
    if (!_force) {
      List<LastTransactionModel>? _transactionPref = TransactionSharedPreferences.getLastTransaction(type);
      if (_transactionPref != null) {
        // check if the transaction preference got data or not?
        // if not data, then we just continue the request to the server
        if(_transactionPref.length > 0) {
          return _transactionPref;
        }
      }
    }

    _checkJWT();

    // check if we got JWT token or not?
    if (_bearerToken.length > 0) {
      final response = await http.get(
          Uri.parse(Globals.apiURL + 'transactions/last/' + type),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer " + _bearerToken,
          });
      
      if (response.statusCode == 200) {
        List<dynamic> _jsonData = jsonDecode(response.body);
        List<LastTransactionModel> _transactionModel =
            _jsonData.map((e) => LastTransactionModel.fromJson(e)).toList();
        TransactionSharedPreferences.setLastTransaction(type, _transactionModel);
        return _transactionModel;
      }

      print("Got error <fetchLastTransaction>");
      throw Exception("res=" + response.body);
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<List<TransactionListModel>> fetchTransactionBudget(int categoryId, String date, int currencyId, [bool? force]) async {
    bool _force = (force ?? false);

    // check if we got data on the sharedPreferences or not?
    if (!_force) {
      List<TransactionListModel>? _transactionPref = TransactionSharedPreferences.getTransactionBudget(categoryId, date);
      if (_transactionPref != null) {
        return _transactionPref;
      }
    }

    _checkJWT();
    
    // check if we got JWT token or not?
    if (_bearerToken.length > 0) {
      final response = await http.get(
          Uri.parse(Globals.apiURL + 'transactions/budget/' + categoryId.toString() + "/date/" + date + "/currency/" + currencyId.toString()),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer " + _bearerToken,
          });

      if (response.statusCode == 200) {
        List<dynamic> _jsonData = jsonDecode(response.body);
        List<TransactionListModel> _transactionModel =
            _jsonData.map((e) => TransactionListModel.fromJson(e)).toList();
        TransactionSharedPreferences.setTransactionBudget(categoryId, date, _transactionModel);
        return _transactionModel;
      }

      print("Got error <fetchTransactionBudget>");
      throw Exception("res=" + response.body);
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<List<TransactionListModel>> fetchTransactionWallet(int walletId, String date, [bool? force]) async {
    bool _force = (force ?? false);

    // check if we got data on the sharedPreferences or not?
    if (!_force) {
      List<TransactionListModel>? _transactionPref = TransactionSharedPreferences.getTransactionWallet(walletId, date);
      if (_transactionPref != null) {
        return _transactionPref;
      }
    }

    _checkJWT();
    
    // check if we got JWT token or not?
    if (_bearerToken.length > 0) {
      final response = await http.get(
          Uri.parse(Globals.apiURL + 'transactions/wallet/' + walletId.toString() + "/date/" + date),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer " + _bearerToken,
          });

      if (response.statusCode == 200) {
        List<dynamic> _jsonData = jsonDecode(response.body);
        List<TransactionListModel> _transactionModel =
            _jsonData.map((e) => TransactionListModel.fromJson(e)).toList();
        TransactionSharedPreferences.setTransactionWallet(walletId, date, _transactionModel);
        return _transactionModel;
      }

      print("Got error <fetchTransactionWallet>");
      throw Exception("res=" + response.body);
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<List<TransactionListModel>> findTransaction(String type, String search, int limit, int start) async {
    _checkJWT();
    
    // check if we got JWT token or not?
    if (_bearerToken.length > 0) {
      final response = await http.get(
        Uri.parse(Globals.apiURL + 'transactions/search/' + search + "/type/" + type + "?_limit=" + limit.toString() + "&_start=" + start.toString()),
        headers: {
          HttpHeaders.authorizationHeader: "Bearer " + _bearerToken,
        }
      );

      if (response.statusCode == 200) {
        List<dynamic> _jsonData = jsonDecode(response.body);
        List<TransactionListModel> _transactionModel = _jsonData.map((e) => TransactionListModel.fromJson(e)).toList();
        return _transactionModel;
      }

      print("Got error <findTransaction>");
      throw Exception("res=" + response.body);
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<IncomeExpenseModel> fetchIncomeExpense(int ccyId, DateTime from, DateTime to, [bool? force]) async {
    bool _force = (force ?? false);
    String _dateFrom = DateFormat('yyyy-MM-dd').format(from.toLocal());
    String _dateTo = DateFormat('yyyy-MM-dd').format(to.toLocal());

    // check if we got data on the sharedPreferences or not?
    if (!_force) {
      IncomeExpenseModel? _transactionPref = TransactionSharedPreferences.getIncomeExpense(ccyId, _dateFrom, _dateTo);
      if (_transactionPref != null) {
        return _transactionPref;
      }
    }

    _checkJWT();
    
    // check if we got JWT token or not?
    if (_bearerToken.length > 0) {
      final response = await http.get(
        Uri.parse(Globals.apiURL + 'transactions/incomeexpense/ccy/' + ccyId.toString() + '/from/' + _dateFrom + "/to/" + _dateTo),
        headers: {
          HttpHeaders.authorizationHeader: "Bearer " + _bearerToken,
        }
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> _jsonData = jsonDecode(response.body);
        IncomeExpenseModel _incomeExpense = IncomeExpenseModel.fromJson(_jsonData);
        
        String _dateFrom = DateFormat("yyyy-MM-dd").format(from.toLocal());
        String _dateTo = DateFormat("yyyy-MM-dd").format(to.toLocal());
        TransactionSharedPreferences.setIncomeExpense(ccyId, _dateFrom, _dateTo, _incomeExpense);
        
        return _incomeExpense;
      }

      print("Got error <fetchIncomeExpense>");
      throw Exception("res=" + response.body);
    } else {
      throw Exception('res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<IncomeExpenseCategoryModel> fetchIncomeExpenseCategory(String name, String search, int ccyId, int walletId, DateTime from, DateTime to) async {
    String _dateFrom = DateFormat('yyyy-MM-dd').format(from.toLocal());
    String _dateTo = DateFormat('yyyy-MM-dd').format(to.toLocal());

    _checkJWT();
    
    // check if we got JWT token or not?
    if (_bearerToken.length > 0) {
      final response = await http.get(
        Uri.parse(Globals.apiURL + 'transactions/stats/ccy/' + ccyId.toString() + '/wallet/' + walletId.toString() + '/from/' + _dateFrom + "/to/" + _dateTo + '/name/' + (name.isEmpty ? '*' : name) + '/search/' + search.toLowerCase()),
        headers: {
          HttpHeaders.authorizationHeader: "Bearer " + _bearerToken,
        }
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> _jsonData = jsonDecode(response.body);
        IncomeExpenseCategoryModel _incomeExpenseCategory = IncomeExpenseCategoryModel.fromJson(_jsonData);
        return _incomeExpenseCategory;
      }

      print("Got error <fetchIncomeExpenseCategory>");
      throw Exception("res=" + response.body);
    } else {
      throw Exception('res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<List<TransactionStatsDetailModel>> fetchIncomeExpenseCategoryDetail(String name, String search, String type, int categoryId, int ccyId, int walletId, DateTime from, DateTime to) async {
    String _dateFrom = DateFormat('yyyy-MM-dd').format(from.toLocal());
    String _dateTo = DateFormat('yyyy-MM-dd').format(to.toLocal());

    _checkJWT();
    
    // check if we got JWT token or not?
    if (_bearerToken.length > 0) {
      final response = await http.get(
        Uri.parse(Globals.apiURL + 'transactions/detailstats/type/' + type + '/category/' + categoryId.toString() + '/ccy/' + ccyId.toString() + '/wallet/' + walletId.toString() + '/from/' + _dateFrom + "/to/" + _dateTo + '/name/' + (name.isEmpty ? '*' : name) + '/search/' + search.toLowerCase()),
        headers: {
          HttpHeaders.authorizationHeader: "Bearer " + _bearerToken,
        }
      );

      if (response.statusCode == 200) {
        List<dynamic> _jsonData = jsonDecode(response.body);
        List<TransactionStatsDetailModel> _transactionStatsDetail = _jsonData.map((e) => TransactionStatsDetailModel.fromJson(e)).toList();
        return _transactionStatsDetail;
      }

      print("Got error <fetchIncomeExpenseCategoryDetail>");
      throw Exception("res=" + response.body);
    } else {
      throw Exception('res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<void> fetchMinMaxDate() async {
    _checkJWT();
    
    // check if we got JWT token or not?
    if (_bearerToken.length > 0) {
      final response = await http.get(
          Uri.parse(Globals.apiURL + 'transactions/minmax'),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer " + _bearerToken,
          });

      if (response.statusCode == 200) {
        Map<String, dynamic> _jsonData = jsonDecode(response.body);
        // get the data
        if(_jsonData["min"] == null) {
          TransactionSharedPreferences.setTransactionMinDate(DateTime(DateTime.now().year, DateTime.now().month, 1));
        }
        else {
          TransactionSharedPreferences.setTransactionMinDate(DateTime.parse(_jsonData["min"]));
        }
        
        if(_jsonData["max"] == null) {
          TransactionSharedPreferences.setTransactionMaxDate(DateTime(DateTime.now().year, DateTime.now().month + 1, 1).subtract(Duration(days: 1)));
        }
        else {
          TransactionSharedPreferences.setTransactionMaxDate(DateTime.parse(_jsonData["max"]));
        }
        return;
      }

      print("Got error <fetchMinMaxDate>");
      throw Exception("res=" + response.body);
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<void> deleteTransaction(
      BuildContext context, TransactionListModel txn) async {
    _checkJWT();

    // check if we got JWT token or not?
    if (_bearerToken.length > 0) {
      final response = await http.delete(
          Uri.parse(Globals.apiURL + 'transactions/' + txn.id.toString()),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer " + _bearerToken,
            'Content-Type': 'application/json; charset=UTF-8',
          });

      if (response.statusCode == 200) {
        // pop the transaction from the provider
        Provider.of<HomeProvider>(context, listen: false)
            .popTransactionList(txn);

        // get the current transaction on the provider
        List<TransactionListModel> _txnListModel =
            Provider.of<HomeProvider>(context, listen: false).transactionList;

        // save the current transaction on the provider to the shared preferences
        String date = DateFormat('yyyy-MM-dd').format(txn.date.toLocal());
        TransactionSharedPreferences.setTransaction(date, _txnListModel);
        return;
      }

      print("Got error <deleteTransaction>");
      throw Exception("res=" + response.body);
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token when adding transaction"}');
    }
  }

  void _checkJWT() {
    if (_bearerToken.length <= 0) {
      _bearerToken = UserSharedPreferences.getJWT();
    }
  }
}
