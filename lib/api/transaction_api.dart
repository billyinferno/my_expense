import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:my_expense/model/budget_stat_model.dart';
import 'package:my_expense/model/income_expense_category_model.dart';
import 'package:my_expense/model/income_expense_model.dart';
import 'package:my_expense/model/last_transaction_model.dart';
import 'package:my_expense/model/transaction_list_model.dart';
import 'package:my_expense/model/transaction_model.dart';
import 'package:my_expense/model/transaction_stats_detail_model.dart';
import 'package:my_expense/model/transaction_wallet_minmax_date_model.dart';
import 'package:my_expense/utils/function/date_utils.dart';
import 'package:my_expense/utils/globals.dart';
import 'package:my_expense/utils/prefs/shared_user.dart';
import 'package:my_expense/utils/prefs/shared_transaction.dart';

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
    bool sameDate = isSameDay(txn.date.toLocal(), prevTxn.date.toLocal());
    _checkJWT();

    // in case there are date change on the transaction it means that we need
    // to remove the transaction in the prevDate, and fetch the new transaction
    // data from the txn.date.

    // check if we got JWT token or not?
    if (_bearerToken.isNotEmpty) {
      final response = await http.put(
          Uri.parse('${Globals.apiURL}transactions/${prevTxn.id}'),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer $_bearerToken",
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(txn.toJson()));

      if (response.statusCode == 200) {
        String date = DateFormat('yyyy-MM-dd').format(prevTxn.date.toLocal());

        // fetch the added data and put it into TransactionListModel
        TransactionListModel txnUpdate =
            TransactionListModel.fromJson(jsonDecode(response.body));

        // get the list of previous transaction date from shared preferences
        List<TransactionListModel>? txnListShared = TransactionSharedPreferences.getTransaction(date);

        // the transaction list shouldn't be NULL, since we update it
        // in case null, then we just add this transaction to the transaction
        // list? (don't want to throw any unnecessary error to GUI).
        if (txnListShared == null) {
          txnListShared = [];
          txnListShared.add(txnUpdate);
        } else {
          // now we can check if this is still the same date or not?
          // if same date, then it will be an easy job, since we just need to
          // update the transaction by forLoop it, and then just replace when
          // we find the matching id
          if (sameDate) {
            for (int idx = 0; idx < txnListShared.length; idx++) {
              if (txnListShared[idx].id == txnUpdate.id) {
                // this is the transaction we need to change
                txnListShared[idx] = txnUpdate;
                // break from the for-loop
                break;
              }
            }
          } else {
            // this means that we have 2 separate day, the first one is
            // we need to remove the previous transaction on the _prevDate,
            // then after that we will need to fetch the data on the current
            // txn.date
            List<TransactionListModel> removeTxnList = txnListShared;
            for (int idx = 0; idx < txnListShared.length; idx++) {
              // check if the id is the same or not?
              if (txnListShared[idx].id == prevTxn.id) {
                removeTxnList.removeAt(idx);
              }
            }
            
            // set the _txnListShared with the _removeTxnList
            txnListShared = removeTxnList;
            
            // fetch the date that we got from then _txnUpdate
            String txnUpdateDate = DateFormat('yyyy-MM-dd').format(txnUpdate.date.toLocal());
            
            // ensure to force fetch the transaction
            await fetchTransaction(txnUpdateDate, true);
          }
        }

        // once all the manipulation finished
        await TransactionSharedPreferences.setTransaction(date, txnListShared);

        // return from the proc
        return txnUpdate;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token when adding transaction"}');
    }
  }

  Future<TransactionListModel> addTransaction(BuildContext context, TransactionModel txn, DateTime selectedDate) async {
    _checkJWT();

    // check if we got JWT token or not?
    if (_bearerToken.isNotEmpty) {
      final response =
          await http.post(Uri.parse('${Globals.apiURL}transactions/add'),
              headers: {
                HttpHeaders.authorizationHeader: "Bearer $_bearerToken",
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(txn.toJson()));

      if (response.statusCode == 200) {
        String date = DateFormat('yyyy-MM-dd').format(txn.date.toLocal());

        // fetch the added data and put it into TransactionListModel
        TransactionListModel txnAdd =
            TransactionListModel.fromJson(jsonDecode(response.body));

        // now we get the information of the transaction we add, we can directly
        // get the data from the sharedPreferences, add the new one and then
        // store back to the sharedPreferences
        List<TransactionListModel>? txnListShared =
            (TransactionSharedPreferences.getTransaction(date) ?? []);

        // add the new transaction that we add
        txnListShared.add(txnAdd);

        // and set back this shared preferences
        await TransactionSharedPreferences.setTransaction(date, txnListShared);

        // return from the proc
        return txnAdd;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token when adding transaction"}');
    }
  }

  Future<List<TransactionListModel>> fetchTransaction(String date,
      [bool? force]) async {
    bool force0 = (force ?? false);

    // check if we got data on the sharedPreferences or not?
    if (!force0) {
      List<TransactionListModel>? transactionPref =
          TransactionSharedPreferences.getTransaction(date);
      if (transactionPref != null) {
        return transactionPref;
      }
    }

    _checkJWT();

    // check if we got JWT token or not?
    if (_bearerToken.isNotEmpty) {
      final response = await http.get(
          Uri.parse('${Globals.apiURL}transactions/date/$date'),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer $_bearerToken",
          });

      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        List<TransactionListModel> transactionModel =
            jsonData.map((e) => TransactionListModel.fromJson(e)).toList();
        TransactionSharedPreferences.setTransaction(date, transactionModel);
        return transactionModel;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<List<LastTransactionModel>> fetchLastTransaction(String type, [bool? force]) async {
    bool force0 = (force ?? false);

    // check if we got data on the sharedPreferences or not?
    if (!force0) {
      List<LastTransactionModel>? transactionPref = TransactionSharedPreferences.getLastTransaction(type);
      if (transactionPref != null) {
        // check if the transaction preference got data or not?
        // if not data, then we just continue the request to the server
        if(transactionPref.isNotEmpty) {
          return transactionPref;
        }
      }
    }

    _checkJWT();

    // check if we got JWT token or not?
    if (_bearerToken.isNotEmpty) {
      final response = await http.get(
          Uri.parse('${Globals.apiURL}transactions/last/$type'),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer $_bearerToken",
          });
      
      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        List<LastTransactionModel> transactionModel =
            jsonData.map((e) => LastTransactionModel.fromJson(e)).toList();
        TransactionSharedPreferences.setLastTransaction(type, transactionModel);
        return transactionModel;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<List<TransactionListModel>> fetchTransactionBudget(int categoryId, String date, int currencyId, [bool? force]) async {
    bool isForce = (force ?? false);

    // check if we got data on the sharedPreferences or not?
    if (!isForce) {
      List<TransactionListModel>? transactionPref = TransactionSharedPreferences.getTransactionBudget(categoryId, date);
      if (transactionPref != null) {
        return transactionPref;
      }
    }

    _checkJWT();
    
    // check if we got JWT token or not?
    if (_bearerToken.isNotEmpty) {
      final response = await http.get(
          Uri.parse('${Globals.apiURL}transactions/budget/${categoryId.toString()}/date/$date/currency/${currencyId.toString()}'),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer $_bearerToken",
          });

      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        List<TransactionListModel> transactionModel =
            jsonData.map((e) => TransactionListModel.fromJson(e)).toList();
        TransactionSharedPreferences.setTransactionBudget(categoryId, date, transactionModel);
        return transactionModel;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<BudgetStatModel> fetchTransactionBudgetStat(int categoryId, int currencyId) async {
    _checkJWT();
    
    // check if we got JWT token or not?
    if (_bearerToken.isNotEmpty) {
      final response = await http.get(
          Uri.parse('${Globals.apiURL}transactions/budget/stat/$categoryId/currency/$currencyId'),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer $_bearerToken",
          });

      if (response.statusCode == 200) {
        BudgetStatModel budgetStatModel = BudgetStatModel.fromJson(jsonDecode(response.body));
        return budgetStatModel;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<BudgetStatModel> fetchTransactionBudgetStatSummary(int currencyId) async {
    _checkJWT();
    
    // check if we got JWT token or not?
    if (_bearerToken.isNotEmpty) {
      final response = await http.get(
          Uri.parse('${Globals.apiURL}transactions/budget/stat/currency/$currencyId'),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer $_bearerToken",
          });

      if (response.statusCode == 200) {
        BudgetStatModel budgetStatModel = BudgetStatModel.fromJson(jsonDecode(response.body));
        return budgetStatModel;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<List<TransactionListModel>> fetchTransactionWallet(int walletId, String date, [bool? force]) async {
    bool isForce = (force ?? false);

    // check if we got data on the sharedPreferences or not?
    if (!isForce) {
      List<TransactionListModel>? transactionPref = TransactionSharedPreferences.getTransactionWallet(walletId, date);
      if (transactionPref != null) {
        return transactionPref;
      }
    }

    _checkJWT();
    
    // check if we got JWT token or not?
    if (_bearerToken.isNotEmpty) {
      final response = await http.get(
          Uri.parse('${Globals.apiURL}transactions/wallet/${walletId.toString()}/date/$date'),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer $_bearerToken",
          });

      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        List<TransactionListModel> transactionModel =
            jsonData.map((e) => TransactionListModel.fromJson(e)).toList();
        TransactionSharedPreferences.setTransactionWallet(walletId, date, transactionModel);
        return transactionModel;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<List<TransactionListModel>> findTransaction(String type, String name, String category, int limit, int start) async {
    _checkJWT();

    String url = '${Globals.apiURL}transactions/search/type/$type';
    
    // check the type, if both then add both name and category, if name then only name, if category then only category
    if (type == "name" || type == "both") {
      url = "$url/search/$name";
    }
    if (type == "category" || type == "both") {
      url = "$url/category/$category";
    }
    
    // check if we got JWT token or not?
    if (_bearerToken.isNotEmpty) {
      final response = await http.get(
        Uri.parse("$url?_limit=$limit&_start=$start"),
        headers: {
          HttpHeaders.authorizationHeader: "Bearer $_bearerToken",
        }
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        List<TransactionListModel> transactionModel = jsonData.map((e) => TransactionListModel.fromJson(e)).toList();
        return transactionModel;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<IncomeExpenseModel> fetchIncomeExpense(int ccyId, DateTime from, DateTime to, [bool? force]) async {
    bool isForce = (force ?? false);
    String dateFrom = DateFormat('yyyy-MM-dd').format(from.toLocal());
    String dateTo = DateFormat('yyyy-MM-dd').format(to.toLocal());

    // check if we got data on the sharedPreferences or not?
    if (!isForce) {
      IncomeExpenseModel? transactionPref = TransactionSharedPreferences.getIncomeExpense(ccyId, dateFrom, dateTo);
      if (transactionPref != null) {
        return transactionPref;
      }
    }

    _checkJWT();
    
    // check if we got JWT token or not?
    if (_bearerToken.isNotEmpty) {
      final response = await http.get(
        Uri.parse('${Globals.apiURL}transactions/incomeexpense/ccy/${ccyId.toString()}/from/$dateFrom/to/$dateTo'),
        headers: {
          HttpHeaders.authorizationHeader: "Bearer $_bearerToken",
        }
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonData = jsonDecode(response.body);
        IncomeExpenseModel incomeExpense = IncomeExpenseModel.fromJson(jsonData);
        
        TransactionSharedPreferences.setIncomeExpense(ccyId, dateFrom, dateTo, incomeExpense);
        
        return incomeExpense;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception('res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<IncomeExpenseCategoryModel> fetchIncomeExpenseCategory(String name, String search, int ccyId, int walletId, DateTime from, DateTime to) async {
    String dateFrom = DateFormat('yyyy-MM-dd').format(from.toLocal());
    String dateTo = DateFormat('yyyy-MM-dd').format(to.toLocal());

    _checkJWT();
    
    // check if we got JWT token or not?
    if (_bearerToken.isNotEmpty) {
      final response = await http.get(
        Uri.parse('${Globals.apiURL}transactions/stats/ccy/${ccyId.toString()}/wallet/${walletId.toString()}/from/$dateFrom/to/$dateTo/name/${(name.isEmpty ? '*' : name)}/search/${search.toLowerCase()}'),
        headers: {
          HttpHeaders.authorizationHeader: "Bearer $_bearerToken",
        }
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonData = jsonDecode(response.body);
        IncomeExpenseCategoryModel incomeExpenseCategory = IncomeExpenseCategoryModel.fromJson(jsonData);
        return incomeExpenseCategory;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception('res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<List<TransactionStatsDetailModel>> fetchIncomeExpenseCategoryDetail(String name, String search, String type, int categoryId, int ccyId, int walletId, DateTime from, DateTime to) async {
    String dateFrom = DateFormat('yyyy-MM-dd').format(from.toLocal());
    String dateTo = DateFormat('yyyy-MM-dd').format(to.toLocal());

    _checkJWT();
    
    // check if we got JWT token or not?
    if (_bearerToken.isNotEmpty) {
      final response = await http.get(
        Uri.parse('${Globals.apiURL}transactions/detailstats/type/$type/category/${categoryId.toString()}/ccy/${ccyId.toString()}/wallet/${walletId.toString()}/from/$dateFrom/to/$dateTo/name/${(name.isEmpty ? '*' : name)}/search/${search.toLowerCase()}'),
        headers: {
          HttpHeaders.authorizationHeader: "Bearer $_bearerToken",
        }
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        List<TransactionStatsDetailModel> transactionStatsDetail = jsonData.map((e) => TransactionStatsDetailModel.fromJson(e)).toList();
        return transactionStatsDetail;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception('res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<void> fetchMinMaxDate() async {
    _checkJWT();
    
    // check if we got JWT token or not?
    if (_bearerToken.isNotEmpty) {
      final response = await http.get(
          Uri.parse('${Globals.apiURL}transactions/minmax'),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer $_bearerToken",
          });

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonData = jsonDecode(response.body);
        // get the data
        if(jsonData["min"] == null) {
          TransactionSharedPreferences.setTransactionMinDate(DateTime(DateTime.now().year, DateTime.now().month, 1));
        }
        else {
          TransactionSharedPreferences.setTransactionMinDate(DateTime.parse(jsonData["min"]));
        }
        
        if(jsonData["max"] == null) {
          TransactionSharedPreferences.setTransactionMaxDate(DateTime(DateTime.now().year, DateTime.now().month + 1, 1).subtract(const Duration(days: 1)));
        }
        else {
          TransactionSharedPreferences.setTransactionMaxDate(DateTime.parse(jsonData["max"]));
        }
        return;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<TransactionWalletMinMaxDateModel> fetchWalletMinMaxDate(int walletId) async {
    _checkJWT();
    
    // check if we got JWT token or not?
    if (_bearerToken.isNotEmpty) {
      final response = await http.get(
          Uri.parse('${Globals.apiURL}transactions/minmax/wallet/$walletId'),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer $_bearerToken",
          });

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonData = jsonDecode(response.body);
        // convert json to get the min and max date
        TransactionWalletMinMaxDateModel ret = TransactionWalletMinMaxDateModel.fromJson(jsonData);
        return ret;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<void> deleteTransaction(
      BuildContext context, TransactionListModel txn) async {
    _checkJWT();

    // check if we got JWT token or not?
    if (_bearerToken.isNotEmpty) {
      final response = await http.delete(
          Uri.parse('${Globals.apiURL}transactions/${txn.id}'),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer $_bearerToken",
            'Content-Type': 'application/json; charset=UTF-8',
          });

      if (response.statusCode == 200) {
        // all good just return from the API, we will perform the update to
        // listener on the caller widget instead.
        return;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token when adding transaction"}');
    }
  }

  void _checkJWT() {
    if (_bearerToken.isEmpty) {
      _bearerToken = UserSharedPreferences.getJWT();
    }
  }
}
