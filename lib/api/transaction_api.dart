import 'dart:convert';
import 'package:my_expense/_index.g.dart';

class TransactionHTTPService {
  Future<TransactionListModel> updateTransaction({
    required TransactionModel txn,
    required TransactionListModel prevTxn
  }) async {
    bool sameDate = txn.date.toLocal().isSameDate(date: prevTxn.date.toLocal());
    String date = Globals.dfyyyyMMdd.format(prevTxn.date.toLocal());
    
    // send the request to update the transaction
    final String result = await NetUtils.put(
      url: '${Globals.apiURL}transactions/${prevTxn.id}',
      body: txn.toJson()
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // fetch the added data and put it into TransactionListModel
    TransactionListModel txnUpdate = TransactionListModel.fromJson(jsonDecode(result));

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
        String txnUpdateDate = Globals.dfyyyyMMdd.format(txnUpdate.date.toLocal());
        
        // ensure to force fetch the transaction
        await fetchTransaction(date: txnUpdateDate, force: true);
      }
    }

    // once all the manipulation finished
    await TransactionSharedPreferences.setTransaction(date, txnListShared);

    // return from the proc
    return txnUpdate;
  }

  Future<TransactionListModel> addTransaction({
    required TransactionModel txn,
    required DateTime selectedDate
  }) async {
    String date = Globals.dfyyyyMMdd.format(txn.date.toLocal());

    // send the request to add the transaction
    final String result = await NetUtils.post(
      url: '${Globals.apiURL}transactions/add',
      body: txn.toJson()
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // fetch the added data and put it into TransactionListModel
    TransactionListModel txnAdd =
        TransactionListModel.fromJson(jsonDecode(result));

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

  Future<List<TransactionListModel>> fetchTransaction({
    required String date,
    bool force = false,
  }) async {
    // check if we got data on the sharedPreferences or not?
    if (!force) {
      List<TransactionListModel>? transactionPref =
        TransactionSharedPreferences.getTransaction(date);
      
      if (transactionPref != null) {
        return transactionPref;
      }
    }

    // send the request to get the transaction
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}transactions/date/$date',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // parse the result and return the transaction list
    List<dynamic> jsonData = jsonDecode(result);
    List<TransactionListModel> transactionModel =
      jsonData.map((e) => TransactionListModel.fromJson(e)).toList();
    TransactionSharedPreferences.setTransaction(date, transactionModel);
    
    return transactionModel;
  }

  Future<List<LastTransactionModel>> fetchLastTransaction({
    required String type,
    bool force = false,
  }) async {
    // check if we got data on the sharedPreferences or not?
    if (!force) {
      List<LastTransactionModel>? transactionPref = TransactionSharedPreferences.getLastTransaction(type);
      if (transactionPref != null) {
        // check if the transaction preference got data or not?
        // if not data, then we just continue the request to the server
        if(transactionPref.isNotEmpty) {
          return transactionPref;
        }
      }
    }

    // send the request to get the last transaction
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}transactions/last/$type',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // parse the result to get the last transaction list
    List<dynamic> jsonData = jsonDecode(result);
    List<LastTransactionModel> transactionModel =
        jsonData.map((e) => LastTransactionModel.fromJson(e)).toList();
    TransactionSharedPreferences.setLastTransaction(type, transactionModel);
    return transactionModel;
  }

  Future<List<TransactionListModel>> fetchTransactionBudget({
    required int categoryId,
    required String date,
    required int currencyId,
    bool force = false,
  }) async {
    // check if we got data on the sharedPreferences or not?
    if (!force) {
      List<TransactionListModel>? transactionPref = TransactionSharedPreferences.getTransactionBudget(categoryId, date);
      if (transactionPref != null) {
        return transactionPref;
      }
    }

    // send the request to get list of transaction on the budget
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}transactions/budget/${categoryId.toString()}/date/$date/currency/${currencyId.toString()}',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // parse the result to get list of transaction based on the budget id
    List<dynamic> jsonData = jsonDecode(result);
    List<TransactionListModel> transactionModel =
        jsonData.map((e) => TransactionListModel.fromJson(e)).toList();
    TransactionSharedPreferences.setTransactionBudget(categoryId, date, transactionModel);
    return transactionModel;
  }

  Future<BudgetStatModel> fetchTransactionBudgetStat({
    required int categoryId,
    required int currencyId
  }) async {
    // send the request to get the transaction statistic
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}transactions/budget/stat/$categoryId/currency/$currencyId',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // parse the budget data
    BudgetStatModel budgetStatModel = BudgetStatModel.fromJson(jsonDecode(result));
    return budgetStatModel;
  }

  Future<BudgetStatModel> fetchTransactionBudgetStatSummary(
    int currencyId
  ) async {
    // send the request to get the transaction summary
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}transactions/budget/stat/currency/$currencyId',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // parse the budget data
    BudgetStatModel budgetStatModel = BudgetStatModel.fromJson(jsonDecode(result));
    return budgetStatModel;
  }

  Future<List<TransactionListModel>> fetchTransactionWallet({
    required int walletId,
    required String date,
    bool force = false,
  }) async {
    // check if we got data on the sharedPreferences or not?
    if (!force) {
      List<TransactionListModel>? transactionPref = TransactionSharedPreferences.getTransactionWallet(walletId, date);
      if (transactionPref != null) {
        return transactionPref;
      }
    }

    // send the request to get the transaction wallet list
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}transactions/wallet/${walletId.toString()}/date/$date',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // parse the wallet list transaction
    List<dynamic> jsonData = jsonDecode(result);
    List<TransactionListModel> transactionModel =
        jsonData.map((e) => TransactionListModel.fromJson(e)).toList();
    TransactionSharedPreferences.setTransactionWallet(walletId, date, transactionModel);
    return transactionModel;
  }

  Future<List<TransactionListModel>> findTransaction({
    required String type,
    required String name,
    required String category,
    required int limit,
    required int start
  }) async {
    String url = '${Globals.apiURL}transactions/search/type/$type';
    
    // check the type, if both then add both name and category, if name then only name, if category then only category
    if (type == "name" || type == "both") {
      url = "$url/search/$name";
    }
    if (type == "category" || type == "both") {
      url = "$url/category/$category";
    }

    // send the request to find transaction
    final String result = await NetUtils.get(
      url: '$url?_limit=$limit&_start=$start',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // parse the result and get the find transaction list
    List<dynamic> jsonData = jsonDecode(result);
    List<TransactionListModel> transactionModel = jsonData.map((e) => TransactionListModel.fromJson(e)).toList();
    return transactionModel;
  }

  Future<IncomeExpenseModel> fetchIncomeExpense({
    required int ccyId,
    required DateTime from,
    required DateTime to,
    bool force = false,
  }) async {
    String dateFrom = Globals.dfyyyyMMdd.format(from.toLocal());
    String dateTo = Globals.dfyyyyMMdd.format(to.toLocal());

    // check if we got data on the sharedPreferences or not?
    if (!force) {
      IncomeExpenseModel? transactionPref = TransactionSharedPreferences.getIncomeExpense(ccyId, dateFrom, dateTo);
      if (transactionPref != null) {
        return transactionPref;
      }
    }

    // send the request to find income and expense
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}transactions/incomeexpense/ccy/${ccyId.toString()}/from/$dateFrom/to/$dateTo',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // get the income and expense data
    Map<String, dynamic> jsonData = jsonDecode(result);
    IncomeExpenseModel incomeExpense = IncomeExpenseModel.fromJson(jsonData);
    TransactionSharedPreferences.setIncomeExpense(ccyId, dateFrom, dateTo, incomeExpense);
    
    return incomeExpense;
  }

  Future<IncomeExpenseCategoryModel> fetchIncomeExpenseCategory({
    required String name,
    required String search,
    required int ccyId,
    required int walletId,
    required DateTime from,
    required DateTime to
  }) async {
    String dateFrom = Globals.dfyyyyMMdd.format(from.toLocal());
    String dateTo = Globals.dfyyyyMMdd.format(to.toLocal());

    // send the request to get income and expense based on category
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}transactions/stats/ccy/${ccyId.toString()}/wallet/${walletId.toString()}/from/$dateFrom/to/$dateTo/name/${(name.isEmpty ? '*' : name)}/search/${search.toLowerCase()}',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // parse the income and expense category data
    Map<String, dynamic> jsonData = jsonDecode(result);
    IncomeExpenseCategoryModel incomeExpenseCategory = IncomeExpenseCategoryModel.fromJson(jsonData);
    
    return incomeExpenseCategory;
  }

  Future<List<TransactionStatsDetailModel>> fetchIncomeExpenseCategoryDetail({
    required String name,
    required String search,
    required String type,
    required int categoryId,
    required int ccyId,
    required int walletId,
    required DateTime from,
    required DateTime to
  }) async {
    String dateFrom = Globals.dfyyyyMMdd.format(from.toLocal());
    String dateTo = Globals.dfyyyyMMdd.format(to.toLocal());

    // send the request to get income and expense category detail
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}transactions/detailstats/type/$type/category/${categoryId.toString()}/ccy/${ccyId.toString()}/wallet/${walletId.toString()}/from/$dateFrom/to/$dateTo/name/${(name.isEmpty ? '*' : name)}/search/${search.toLowerCase()}',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // parse the result
    List<dynamic> jsonData = jsonDecode(result);
    List<TransactionStatsDetailModel> transactionStatsDetail = jsonData.map((e) => TransactionStatsDetailModel.fromJson(e)).toList();
    return transactionStatsDetail;
  }

  Future<void> fetchMinMaxDate() async {
    // send the request to get the min and max user transaction date
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}transactions/minmax',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // parse tje result
    Map<String, dynamic> jsonData = jsonDecode(result);
    
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
  }

  Future<TransactionWalletMinMaxDateModel> fetchWalletMinMaxDate({
    required int walletId
  }) async {
    // send the request to get the min and max user wallet date
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}transactions/minmax/wallet/$walletId',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // parse the result
    Map<String, dynamic> jsonData = jsonDecode(result);
    
    // convert json to get the min and max date
    TransactionWalletMinMaxDateModel ret = TransactionWalletMinMaxDateModel.fromJson(jsonData);
    return ret;
  }

  Future<void> deleteTransaction({
    required TransactionListModel txn
  }) async {
    // send the request to get the min and max user wallet date
    await NetUtils.delete(
      url: '${Globals.apiURL}transactions/${txn.id}',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });
  }

  Future<List<TransactionTopModel>> fetchTransactionTop({
    required String type,
    required int ccy,
    required String from,
    required String to,
    bool force = false,
  }) async {
    // check if we got data on the sharedPreferences or not?
    if (!force) {
      List<TransactionTopModel>? transactionPref =
          TransactionSharedPreferences.getTransactionTop(from, type);
      if (transactionPref != null) {
        return transactionPref;
      }
    }

    // send the request to get the transaction
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}transactions/top/type/$type/ccy/$ccy/from/$from/to/$to',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // parse the result and return the transaction list
    List<dynamic> jsonData = jsonDecode(result);
    List<TransactionTopModel> transactionModel = jsonData.map((e) => TransactionTopModel.fromJson(e)).toList();
    TransactionSharedPreferences.setTransactionTop(from, type, transactionModel);
    return transactionModel;
  }
}
