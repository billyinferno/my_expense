import 'package:flutter/cupertino.dart';
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

  setTransactionList(List<TransactionListModel> _transactionList) {
    transactionList = _transactionList;
    notifyListeners();
  }

  popTransactionList(TransactionListModel _txnData) {
    transactionList.remove(_txnData);
    notifyListeners();
  }

  clearTransactionList() {
    transactionList.clear();
    transactionList = [];
    notifyListeners();
  }

  setWalletList(List<WalletModel> _walletList) {
    walletList = _walletList;
    notifyListeners();
  }

  setBudgetList(List<BudgetModel> _budgetList) {
    budgetList = _budgetList;
    notifyListeners();
  }

  clearBudgetList() {
    budgetList.clear();
    budgetList = [];
    notifyListeners();
  }

  setBudgetAddList(List<BudgetModel> _budgetList) {
    budgetAddList = _budgetList;
    notifyListeners();
  }

  clearBudgetAddList() {
    budgetAddList.clear();
    budgetAddList = [];
    notifyListeners();
  }

  setWalletCurrency(List<CurrencyModel> _walletCurrency) {
    walletCurrency = _walletCurrency;
    notifyListeners();
  }

  setNetWorth(List<WorthModel> _netWorth) {
    netWorth = _netWorth;
    notifyListeners();
  }

  clearNetWorth() {
    netWorth.clear();
    netWorth = [];
    notifyListeners();
  }

  setIncomeExpense(int ccyId, IncomeExpenseModel _incomeExpense) {
    incomeExpense[ccyId] = _incomeExpense;
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
