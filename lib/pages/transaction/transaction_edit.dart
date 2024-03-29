import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_expense/api/budget_api.dart';
import 'package:my_expense/api/transaction_api.dart';
import 'package:my_expense/api/wallet_api.dart';
import 'package:my_expense/model/budget_model.dart';
import 'package:my_expense/model/transaction_list_model.dart';
import 'package:my_expense/model/transaction_model.dart';
import 'package:my_expense/model/wallet_model.dart';
import 'package:my_expense/model/worth_model.dart';
import 'package:my_expense/provider/home_provider.dart';
import 'package:my_expense/utils/misc/show_loader_dialog.dart';
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
  final WalletHTTPService _walletHttp = WalletHTTPService();
  final BudgetHTTPService _budgetHttp = BudgetHTTPService();

  @override
  void initState() {
    super.initState();
    paramsData = widget.params as TransactionListModel;
  }

  @override
  Widget build(BuildContext context) {
    return TransactionInput(
      title: "Edit Transaction",
      type: TransactionInputType.edit,
      saveTransaction: (value) {
        _saveTransaction(value);
      },
      selectedDate: paramsData.date,
      currentTransaction: paramsData,
    );
  }

  void _saveTransaction(TransactionModel? txn) async {
    // show loader dialog
    showLoaderDialog(context);
    
    // send also the date we got from the parent widget, to see whether there
    // are any changes on the date of the transaction. If there are changes
    // then it means we need to manipulate 2 shared preferences instead of one.
    await _transactionHttp.updateTransaction(context, txn!, paramsData).then((txnUpdate) {
      // update necessary information after we add the transaction
      updateInformation(txnUpdate).then((_) {
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

    String _refreshDay = DateFormat('yyyy-MM-dd').format(DateTime(txnUpdate.date.year, txnUpdate.date.month, 1).toLocal());
    String _prevDay = DateFormat('yyyy-MM-dd').format(DateTime(paramsData.date.year, paramsData.date.month, 1).toLocal());

    // check whether this transaction moved from one wallet to another wallet?
    // first check whether this is expense, income, or transfer?
    bool _isWalletMoved = false;
    if(txnUpdate.type == "expense" || txnUpdate.type == "income") {
      if(paramsData.wallet.id == txnUpdate.wallet.id) {
        // do nothing
      }
      else {
        // change wallet
        _isWalletMoved = true;
      }
    }
    else {
      // this is transfer, check both
      if(paramsData.wallet.id == txnUpdate.wallet.id &&
         paramsData.walletTo?.id == txnUpdate.walletTo?.id) {
        // do nothing
      }
      else {
        // change wallet for transfer
        _isWalletMoved = true;
      }
    }

    // if there are no wallet moved, then we can just update the wallet
    if(!_isWalletMoved) {
      // update the new transaction to the wallet transaction
      await TransactionSharedPreferences.updateTransactionWallet(txnUpdate.wallet.id, _refreshDay, txnUpdate);
      if (txnUpdate.walletTo != null) {
        await TransactionSharedPreferences.updateTransactionWallet(txnUpdate.walletTo!.id, _refreshDay, txnUpdate);
      }
    }
    else {
      // check which wallet is being moved
      if(paramsData.wallet.id != txnUpdate.wallet.id) {
        // moved the transaction from previous wallet to the new wallet
        await TransactionSharedPreferences.deleteTransactionWallet(paramsData.wallet.id, _prevDay, paramsData);
        await TransactionSharedPreferences.addTransactionWallet(txnUpdate.wallet.id, _refreshDay, txnUpdate);
      }

      if(txnUpdate.walletTo != null) {
        // check if both wallet the same or not?
        if(paramsData.walletTo!.id != txnUpdate.walletTo!.id) {
          // moved the transaction from previous wallet to the new wallet
          await TransactionSharedPreferences.deleteTransactionWallet(paramsData.walletTo!.id, _prevDay, paramsData);
          await TransactionSharedPreferences.addTransactionWallet(txnUpdate.walletTo!.id, _refreshDay, txnUpdate);
        }
      }
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
}
