import 'package:flutter/material.dart';
import 'package:flutter_keyboard_size/flutter_keyboard_size.dart';
import 'package:intl/intl.dart';
import 'package:my_expense/api/budget_api.dart';
import 'package:my_expense/api/category_api.dart';
import 'package:my_expense/api/transaction_api.dart';
import 'package:my_expense/api/wallet_api.dart';
import 'package:my_expense/model/budget_model.dart';
import 'package:my_expense/model/transaction_list_model.dart';
import 'package:my_expense/model/transaction_model.dart';
import 'package:my_expense/model/wallet_model.dart';
import 'package:my_expense/model/worth_model.dart';
import 'package:my_expense/provider/home_provider.dart';
import 'package:my_expense/utils/misc/snack_bar.dart';
import 'package:my_expense/utils/prefs/shared_budget.dart';
import 'package:my_expense/utils/prefs/shared_transaction.dart';
import 'package:my_expense/utils/prefs/shared_wallet.dart';
import 'package:my_expense/widgets/input/transaction_input.dart';
import 'package:provider/provider.dart';

class TransactionEditPage extends StatefulWidget {
  final Object? params;

  TransactionEditPage(this.params);

  @override
  _TransactionEditPageState createState() => _TransactionEditPageState();
}

class _TransactionEditPageState extends State<TransactionEditPage> {
  late TransactionListModel paramsData;
  final TransactionHTTPService _transactionHttp = TransactionHTTPService();
  final CategoryHTTPService _categoryHttp = CategoryHTTPService();
  final WalletHTTPService _walletHttp = WalletHTTPService();
  final BudgetHTTPService _budgetHttp = BudgetHTTPService();

  @override
  void initState() {
    super.initState();
    paramsData = widget.params as TransactionListModel;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardSizeProvider(
      child: TransactionInput(
        title: "Edit Transaction",
        saveTransaction: (value) {
          saveTransaction(value);
        },
        refreshCategory: refreshCategory,
        refreshWallet: refreshWallet,
        currentTransaction: paramsData,
      ),
    );
  }

  void saveTransaction(TransactionModel? txn) async {
    // now we can try to send updated data to the backend
    TransactionModel _txn = txn!;
    // send also the date we got from the parent widget, to see whether there
    // are any changes on the date of the transaction. If there are changes
    // then it means we need to manipulate 2 shared preferences instead of one.
    await _transactionHttp.updateTransaction(context, _txn, paramsData).then((txnUpdate) {
      // update necessary information after we add the transaction
      updateInformation(txnUpdate).then((_) {
        //debugPrint("Success got the updated information");

        // this is success, so we can pop the loader
        Navigator.pop(context);

        // since we already finished, we can pop again to return back to the
        // previous page
        Navigator.pop(context, txnUpdate);
      }).onError((error, stackTrace) {
        // pop the loader
        Navigator.pop(context);

        // on error showed the snackBar
        ScaffoldMessenger.of(context).showSnackBar(
          createSnackBar(
            message: "Error when refresh information",
          )
        );
      });
    }).onError((error, stackTrace) {
      // pop the loader
      Navigator.pop(context);

      // on error showed the snackBar
      ScaffoldMessenger.of(context).showSnackBar(
        createSnackBar(
          message: "Error when update transaction",
        )
      );
    });
  }

  Future<void> updateInformation(TransactionListModel txnUpdate) async {
    Future<List<BudgetModel>> _futureBudgets;
    Future<List<WalletModel>> _futureWallets;
    Future<List<WorthModel>> _futureNetWorth;

    String _refreshDay = DateFormat('yyyy-MM-dd').format(DateTime(txnUpdate.date.toLocal().year, txnUpdate.date.toLocal().month, 1));

    // update the new transaction to the wallet transaction
    await TransactionSharedPreferences.updateTransactionWallet(txnUpdate.wallet.id, _refreshDay, txnUpdate);
    if (txnUpdate.walletTo != null) {
      await TransactionSharedPreferences.updateTransactionWallet(txnUpdate.walletTo!.id, _refreshDay, txnUpdate);
    }

    // check if this is expense or income?
    if(txnUpdate.type == "expense" || txnUpdate.type == "income") {
      // we will only going to update the income expense statistic, if only this transaction
      // is perform on the same month
      if(txnUpdate.date.year == DateTime.now().year && txnUpdate.date.month == DateTime.now().month) {
        DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
        DateTime _to = DateTime(DateTime.now().year, DateTime.now().month + 1, 1).subtract(Duration(days: 1));
        await _transactionHttp.fetchIncomeExpense(txnUpdate.wallet.currencyId, _from, _to, true).then((incomeExpense) {
          Provider.of<HomeProvider>(context, listen: false).setIncomeExpense(txnUpdate.wallet.currencyId, incomeExpense);
        }).onError((error, stackTrace) {
          debugPrint("Error when fetchIncomeExpense at <updateInformation>");
          debugPrint(error.toString());
        });
      }
    }

    await Future.wait([
      _futureWallets = _walletHttp.fetchWallets(true, true),
      _futureBudgets = _budgetHttp.fetchBudgetDate(txnUpdate.wallet.currencyId, _refreshDay, true),
      _futureNetWorth = _walletHttp.fetchWalletsWorth(txnUpdate.date, true),
    ]).then((_) {
      // got the updated wallets
      _futureWallets.then((wallets) {
        Provider.of<HomeProvider>(context, listen: false).setWalletList(wallets);
      });

      // got the new budgets
      _futureBudgets.then((budgets) {
        // now we can set the shared preferences of budget
        BudgetSharedPreferences.setBudget(txnUpdate.wallet.currencyId, _refreshDay, budgets);
        Provider.of<HomeProvider>(context, listen: false).setBudgetList(budgets);
      }).then((_) {
        // lastly check whether the date being used on the transaction
        // is more or lesser than the max and min date?
        DateTime _minDate = TransactionSharedPreferences.getTransactionMinDate();
        DateTime _maxDate = TransactionSharedPreferences.getTransactionMaxDate();

        if(_minDate.isAfter(txnUpdate.date)) {
          // set txnAdd as current minDate, as minDate is bigger than current
          // transaction data date.
          TransactionSharedPreferences.setTransactionMinDate(txnUpdate.date);
        }
        else if(_maxDate.isBefore(txnUpdate.date)) {
          // set txnAdd as current maxDate, as maxDate is lesser than current
          // transacion data date.
          TransactionSharedPreferences.setTransactionMaxDate(txnUpdate.date);
        }
      });

      _futureNetWorth.then((worth) {
        String _dateTo = DateFormat("yyyy-MM-dd").format(DateTime(txnUpdate.date.toLocal().year, txnUpdate.date.toLocal().month+1, 1).subtract(Duration(days: 1)));
        WalletSharedPreferences.setWalletWorth(_dateTo, worth);
        Provider.of<HomeProvider>(context, listen: false).setNetWorth(worth);
      });
    }).onError((error, stackTrace) {
      debugPrint("Error on <updateInformation>");
      throw new Exception(error.toString());
    });
  }

  Future<void> refreshWallet() async {
    // fetch again the wallet
    await _walletHttp.fetchWallets(false).then((wallets) {
      // remove the loader dialog
      Navigator.pop(context);
    }).onError((error, stackTrace) {
      print("Error when <refreshWallet>");
      print(error.toString());
      // remove the loader dialog
      Navigator.pop(context);
    });
  }

  Future<void> refreshCategory() async {
    // fetch again the wallet
    await _categoryHttp.fetchCategory(true).then((value) {
      // remove the loader dialog
      Navigator.pop(context);
    }).onError((error, stackTrace) {
      print("Error when <refreshCategory>");
      print(error.toString());
      // remove the loader dialog
      Navigator.pop(context);
    });
  }
}
