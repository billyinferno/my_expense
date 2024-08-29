import 'package:flutter/material.dart';
import 'package:my_expense/_index.g.dart';

class HomeProvider extends ChangeNotifier {
  List<TransactionListModel> transactionList = [];
  List<WalletModel> walletList = [];
  List<BudgetModel> budgetList = [];
  List<BudgetModel> budgetAddList = [];
  List<CurrencyModel> walletCurrency = [];
  List<WorthModel> netWorth = [];
  Map<int, IncomeExpenseModel> incomeExpense = {};
  Map<int, Map<String, List<TransactionTopModel>>> topTransaction = {};

  setTransactionList({required List<TransactionListModel> transactions}) {
    transactionList = transactions;
    notifyListeners();
  }

  popTransactionList({required TransactionListModel transaction}) {
    // loop transaction list until find the same id
    for(int i=0; i<transactionList.length; i++) {
      if (transactionList[i].id == transaction.id) {
        transactionList.removeAt(i);
        break;
      }
    }
    notifyListeners();
  }

  clearTransactionList() {
    transactionList.clear();
    transactionList = [];
    notifyListeners();
  }

  setWalletList({required List<WalletModel> wallets}) {
    walletList = wallets;
    notifyListeners();
  }

  setBudgetList({required List<BudgetModel> budgets}) {
    budgetList = budgets;
    notifyListeners();
  }

  clearBudgetList() {
    budgetList.clear();
    budgetList = [];
    notifyListeners();
  }

  setBudgetAddList({required List<BudgetModel> budgets}) {
    budgetAddList = budgetList;
    notifyListeners();
  }

  clearBudgetAddList() {
    budgetAddList.clear();
    budgetAddList = [];
    notifyListeners();
  }

  setWalletCurrency({required List<CurrencyModel> currencies}) {
    walletCurrency = currencies;
    notifyListeners();
  }

  setNetWorth({required List<WorthModel> worth}) {
    netWorth = worth;
    notifyListeners();
  }

  clearNetWorth() {
    netWorth.clear();
    netWorth = [];
    notifyListeners();
  }

  setIncomeExpense({
    required int ccyId,
    required IncomeExpenseModel data}) {
    incomeExpense[ccyId] = data;
    notifyListeners();
  }

  setTopTransaction({
    required int ccy,
    required String type,
    required List<TransactionTopModel> data
  }) {
    // check if ccy already exists or not?
    if (!topTransaction.containsKey(ccy)) {
      topTransaction[ccy] = {};
    }

    // add the type to the top transaction for this ccy    
    topTransaction[ccy]![type] = data;
    notifyListeners();
  }
  
  addTopTransaction({
    required int ccy,
    required String type,
    required TransactionListModel transaction
  }) {
    // check whether this ccy already exists in topTransaction?
    if(topTransaction.containsKey(ccy)) {
      // it means we already have data for this
      // create the transaction top model for this transaction
      TransactionTopModel txnTop = TransactionTopModel(
        transactionName: transaction.name,
        transactionAmount: transaction.amount,
        transactionCategoryId: transaction.category!.id,
        transactionCategoryName: transaction.category!.name,
        transactionWalletId: transaction.wallet.id,
        transactionWalletName: transaction.wallet.name
      );

      // check if empty or not?
      if (topTransaction[ccy]![type]!.isEmpty) {
        // if empty then we just add this transaction to the top transaction
        topTransaction[ccy]![type]!.add(txnTop);
        notifyListeners();
      }
      else {
        List<TransactionTopModel> newTopList = [];
        bool isAdded = false;
        // loop thru top transaction
        for(int i=0; i<10 && i<topTransaction[ccy]![type]!.length; i++) {
          // only do if the new list still less than 10
          if (newTopList.length < 10) {
            // compare the amount to the current data
            if (topTransaction[ccy]![type]![i].transactionAmount < transaction.amount && !isAdded) {
              // current amount is bigger then this
              // so put the txn top here
              newTopList.add(txnTop);
              isAdded = true;
            }

            // just add the current txn top new top list
            newTopList.add(topTransaction[ccy]![type]![i]);
          }
        }

        // once finished then we can set the current top transaction to this
        topTransaction[ccy]![type]!.clear();
        topTransaction[ccy]![type] = newTopList;
        notifyListeners();
      }
    }
  }

  clearProvider() {
    transactionList.clear();
    transactionList = [];

    walletList.clear();
    walletList = [];

    budgetList.clear();
    budgetList = [];

    budgetAddList.clear();
    budgetAddList = [];

    walletCurrency.clear();
    walletCurrency = [];

    netWorth.clear();
    netWorth = [];

    topTransaction.clear();
    topTransaction = {};
  }
}
