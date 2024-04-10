import 'package:flutter/material.dart';
import 'package:my_expense/model/budget_model.dart';
import 'package:my_expense/model/currency_model.dart';
import 'package:my_expense/model/income_expense_model.dart';
import 'package:my_expense/model/transaction_list_model.dart';
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

  setTransactionList(List<TransactionListModel> newTransactionList) {
    transactionList = newTransactionList;
    notifyListeners();
  }

  popTransactionList(TransactionListModel txnData) {
    transactionList.remove(txnData);
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
  }
}
