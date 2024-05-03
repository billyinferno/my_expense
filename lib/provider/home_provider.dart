import 'package:flutter/material.dart';
import 'package:my_expense/model/budget_model.dart';
import 'package:my_expense/model/currency_model.dart';
import 'package:my_expense/model/income_expense_model.dart';
import 'package:my_expense/model/transaction_list_model.dart';
import 'package:my_expense/model/transaction_top_model.dart';
import 'package:my_expense/model/wallet_model.dart';
import 'package:my_expense/model/worth_model.dart';

class HomeProvider extends ChangeNotifier {
  List<TransactionListModel> transactionList = [];
  List<WalletModel> walletList = [];
  List<BudgetModel> budgetList = [];
  List<BudgetModel> budgetAddList = [];
  List<CurrencyModel> walletCurrency = [];
  List<WorthModel> netWorth = [];
  Map<int, IncomeExpenseModel> incomeExpense = {};
  Map<int, Map<String, List<TransactionTopModel>>> topTransaction = {};

  setTransactionList(List<TransactionListModel> newTransactionList) {
    transactionList = newTransactionList;
    notifyListeners();
  }

  popTransactionList(TransactionListModel txnData) {
    // loop transaction list until find the same id
    for(int i=0; i<transactionList.length; i++) {
      if (transactionList[i].id == txnData.id) {
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

  setWalletList(List<WalletModel> newWalletList) {
    walletList = newWalletList;
    notifyListeners();
  }

  setBudgetList(List<BudgetModel> newBudgetList) {
    budgetList = newBudgetList;
    notifyListeners();
  }

  clearBudgetList() {
    budgetList.clear();
    budgetList = [];
    notifyListeners();
  }

  setBudgetAddList(List<BudgetModel> budgetList) {
    budgetAddList = budgetList;
    notifyListeners();
  }

  clearBudgetAddList() {
    budgetAddList.clear();
    budgetAddList = [];
    notifyListeners();
  }

  setWalletCurrency(List<CurrencyModel> newWalletCurrency) {
    walletCurrency = newWalletCurrency;
    notifyListeners();
  }

  setNetWorth(List<WorthModel> newNetWorth) {
    netWorth = newNetWorth;
    notifyListeners();
  }

  clearNetWorth() {
    netWorth.clear();
    netWorth = [];
    notifyListeners();
  }

  setIncomeExpense(int ccyId, IncomeExpenseModel updateIncomeExpense) {
    incomeExpense[ccyId] = updateIncomeExpense;
    notifyListeners();
  }

  setTopTransaction(int ccy, String type, List<TransactionTopModel> data) {
    // check if ccy already exists or not?
    if (!topTransaction.containsKey(ccy)) {
      topTransaction[ccy] = {};
    }

    // add the type to the top transaction for this ccy    
    topTransaction[ccy]![type] = data;
    notifyListeners();
  }
  
  addTopTransaction(int ccy, String type, TransactionListModel txn) {
    // check whether this ccy already exists in topTransaction?
    if(topTransaction.containsKey(ccy)) {
      // it means we already have data for this
      // create the transaction top model for this transaction
      TransactionTopModel txnTop = TransactionTopModel(
        transactionName: txn.name,
        transactionAmount: txn.amount,
        transactionCategoryId: txn.category!.id,
        transactionCategoryName: txn.category!.name,
        transactionWalletId: txn.wallet.id,
        transactionWalletName: txn.wallet.name
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
            if (topTransaction[ccy]![type]![i].transactionAmount < txn.amount && !isAdded) {
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
