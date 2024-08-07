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
import 'package:my_expense/utils/function/date_utils.dart';
import 'package:my_expense/utils/misc/show_dialog.dart';
import 'package:my_expense/utils/prefs/shared_budget.dart';
import 'package:my_expense/utils/prefs/shared_transaction.dart';
import 'package:my_expense/utils/prefs/shared_wallet.dart';
import 'package:my_expense/widgets/input/transaction_input.dart';
import 'package:my_expense/widgets/modal/overlay_loading_modal.dart';
import 'package:provider/provider.dart';

class TransactionEditPage extends StatefulWidget {
  final Object? params;

  const TransactionEditPage({super.key, required this.params});

  @override
  State<TransactionEditPage> createState() => _TransactionEditPageState();
}

class _TransactionEditPageState extends State<TransactionEditPage> {
  late TransactionListModel _paramsData;
  final TransactionHTTPService _transactionHttp = TransactionHTTPService();
  final WalletHTTPService _walletHttp = WalletHTTPService();
  final BudgetHTTPService _budgetHttp = BudgetHTTPService();

  @override
  void initState() {
    super.initState();
    _paramsData = widget.params as TransactionListModel;
  }

  @override
  Widget build(BuildContext context) {
    return TransactionInput(
      title: "Edit Transaction",
      type: TransactionInputType.edit,
      saveTransaction: (value) {
        _saveTransaction(value);
      },
      selectedDate: _paramsData.date,
      currentTransaction: _paramsData,
    );
  }

  void _saveTransaction(TransactionModel? txn) async {
    // show the loading screen
    LoadingScreen.instance().show(context: context);

    // send also the date we got from the parent widget, to see whether there
    // are any changes on the date of the transaction. If there are changes
    // then it means we need to manipulate 2 shared preferences instead of one.
    await _transactionHttp.updateTransaction(context, txn!, _paramsData).then((txnUpdate) async {
      // update necessary information after we add the transaction
      await _updateInformation(txnUpdate).then((_) async {
        // for transaction that actually add on the different date, we cannot notify the home list
        // to show this transaction, because currently we are in a different date between the transaction
        // being add and the date being selected on the home list
        DateTime currentListTxnDate = (TransactionSharedPreferences.getTransactionListCurrentDate() ?? DateTime.now());

        // default the date as the same as the home list date
        String date = DateFormat('yyyy-MM-dd').format(currentListTxnDate.toLocal());

        // check if this is the same date or not?
        // if not the same then we will need to refresh bot transaction list
        // both on the transaction update date and the home list date.
        if (!isSameDay(txnUpdate.date.toLocal(), currentListTxnDate.toLocal())) { 
          // since the update transaction and current home list is different date
          // get both data and stored it on the transaction shared preferences
          await _refreshHomeList(
            txnDate: txnUpdate.date.toLocal(),
            homeListDate: currentListTxnDate.toLocal()
          ).onError((error, stackTrace) async {
            debugPrint("Error when update the home list transaction");
            debugPrintStack(stackTrace: stackTrace);

            if (mounted) {
              // show the error dialog
              await ShowMyDialog(
                cancelEnabled: false,
                confirmText: "OK",
                dialogTitle: "Error Refresh",
                dialogText: "Error when refresh home list."
              ).show(context);
            }
          });
        }
        
        // this is success, so we can pop the loader
        if (mounted) {
          // get the transaction list from shared preferences
          List<TransactionListModel>? txnListShared = TransactionSharedPreferences.getTransaction(date);

          // once add on the shared preferences, we can change the
          // TransactionListModel provider so it will update the home list page
          Provider.of<HomeProvider>(context, listen: false).setTransactionList(txnListShared ?? []);

          // since we already finished, we can pop to return back to the
          // previous page
          Navigator.pop(context, txnUpdate);
        }
      }).onError((error, stackTrace) async {
        // print the error
        debugPrint("Error: ${error.toString()}");
        debugPrintStack(stackTrace: stackTrace);
        
        if (mounted) {
          // show the error dialog
          await ShowMyDialog(
            cancelEnabled: false,
            confirmText: "OK",
            dialogTitle: "Error Refresh",
            dialogText: "Error when refresh information."
          ).show(context);
        }
      });
    }).onError((error, stackTrace) async {
      // print the error
      debugPrint("Error: ${error.toString()}");
      debugPrintStack(stackTrace: stackTrace);
      
      if (mounted) {
        // show the error dialog
        await ShowMyDialog(
          cancelEnabled: false,
          confirmText: "OK",
          dialogTitle: "Error Update",
          dialogText: "Error when update transaction."
        ).show(context);
      }
    }).whenComplete(() {
      // remove the loading screen
      LoadingScreen.instance().hide();
    },);
  }

  Future<void> _refreshHomeList({required DateTime txnDate, required DateTime homeListDate}) async {
    final dfyyyMMdd = DateFormat('yyyy-MM-dd');
    await Future.wait([
      _transactionHttp.fetchTransaction(dfyyyMMdd.format(txnDate), true).then((resp) {
        // once got the response store this on the TransactionSharedPreferences
        TransactionSharedPreferences.setTransaction(dfyyyMMdd.format(txnDate), resp);
      }).onError((error, stackTrace) {
        throw Exception("Error when update for $txnDate");
      },),

      _transactionHttp.fetchTransaction(dfyyyMMdd.format(homeListDate), true).then((resp) {
        // once got the response store this on the TransactionSharedPreferences
        TransactionSharedPreferences.setTransaction(dfyyyMMdd.format(homeListDate), resp);
      }).onError((error, stackTrace) {
        throw Exception("Error when update for $homeListDate");
      },),
    ]);
  }

  Future<void> _updateInformation(TransactionListModel txnUpdate) async {
    Future<List<BudgetModel>> futureBudgets;
    Future<List<WalletModel>> futureWallets;
    Future<List<WorthModel>> futureNetWorth;

    String refreshDay = DateFormat('yyyy-MM-dd').format(DateTime(txnUpdate.date.year, txnUpdate.date.month, 1).toLocal());
    String prevDay = DateFormat('yyyy-MM-dd').format(DateTime(_paramsData.date.year, _paramsData.date.month, 1).toLocal());

    DateTime from = DateTime(DateTime.now().year, DateTime.now().month, 1);
    DateTime to = DateTime(DateTime.now().year, DateTime.now().month + 1, 1).subtract(const Duration(days: 1));
    String fromString = DateFormat('yyyy-MM-dd').format(from);
    String toString = DateFormat('yyyy-MM-dd').format(to);

    // check whether this transaction moved from one wallet to another wallet?
    // first check whether this is expense, income, or transfer?
    bool isWalletMoved = false;
    if(txnUpdate.type == "expense" || txnUpdate.type == "income") {
      if(_paramsData.wallet.id == txnUpdate.wallet.id) {
        // do nothing
      }
      else {
        // change wallet
        isWalletMoved = true;
      }
    }
    else {
      // this is transfer, check both
      if(_paramsData.wallet.id == txnUpdate.wallet.id &&
         _paramsData.walletTo?.id == txnUpdate.walletTo?.id) {
        // do nothing
      }
      else {
        // change wallet for transfer
        isWalletMoved = true;
      }
    }

    // if there are no wallet moved, then we can just update the wallet
    if(!isWalletMoved) {
      // update the new transaction to the wallet transaction
      await TransactionSharedPreferences.updateTransactionWallet(txnUpdate.wallet.id, refreshDay, txnUpdate);
      if (txnUpdate.walletTo != null) {
        await TransactionSharedPreferences.updateTransactionWallet(txnUpdate.walletTo!.id, refreshDay, txnUpdate);
      }
    }
    else {
      // check which wallet is being moved
      if(_paramsData.wallet.id != txnUpdate.wallet.id) {
        // moved the transaction from previous wallet to the new wallet
        await TransactionSharedPreferences.deleteTransactionWallet(_paramsData.wallet.id, prevDay, _paramsData);
        await TransactionSharedPreferences.addTransactionWallet(txnUpdate.wallet.id, refreshDay, txnUpdate);
      }

      if(txnUpdate.walletTo != null) {
        // check if both wallet the same or not?
        if(_paramsData.walletTo!.id != txnUpdate.walletTo!.id) {
          // moved the transaction from previous wallet to the new wallet
          await TransactionSharedPreferences.deleteTransactionWallet(_paramsData.walletTo!.id, prevDay, _paramsData);
          await TransactionSharedPreferences.addTransactionWallet(txnUpdate.walletTo!.id, refreshDay, txnUpdate);
        }
      }
    }

    // check if this is expense or income?
    if(txnUpdate.type == "expense" || txnUpdate.type == "income") {
      // we will only going to update the income expense statistic, if only this transaction
      // is perform on the same month
      if(txnUpdate.date.year == DateTime.now().year && txnUpdate.date.month == DateTime.now().month) {
        await _transactionHttp.fetchIncomeExpense(txnUpdate.wallet.currencyId, from, to, true).then((incomeExpense) {
          if (mounted) {
            Provider.of<HomeProvider>(context, listen: false).setIncomeExpense(txnUpdate.wallet.currencyId, incomeExpense);
          }
        }).onError((error, stackTrace) {
          debugPrint("Error when fetchIncomeExpense at <updateInformation>");
          debugPrint(error.toString());
        });
      }
    }

    await Future.wait([
      futureWallets = _walletHttp.fetchWallets(true, true),
      futureBudgets = _budgetHttp.fetchBudgetDate(txnUpdate.wallet.currencyId, refreshDay, true),
      futureNetWorth = _walletHttp.fetchWalletsWorth(txnUpdate.date, true),
    ]).then((_) {
      // got the updated wallets
      futureWallets.then((wallets) {
        if (mounted) {
          Provider.of<HomeProvider>(context, listen: false).setWalletList(wallets);
        }
      });

      // got the new budgets
      futureBudgets.then((budgets) {
        // now we can set the shared preferences of budget
        BudgetSharedPreferences.setBudget(txnUpdate.wallet.currencyId, refreshDay, budgets);
        if (mounted) {
          Provider.of<HomeProvider>(context, listen: false).setBudgetList(budgets);
        }
      }).then((_) {
        // lastly check whether the date being used on the transaction
        // is more or lesser than the max and min date?
        DateTime minDate = TransactionSharedPreferences.getTransactionMinDate();
        DateTime maxDate = TransactionSharedPreferences.getTransactionMaxDate();

        if(minDate.isAfter(txnUpdate.date)) {
          // set txnAdd as current minDate, as minDate is bigger than current
          // transaction data date.
          TransactionSharedPreferences.setTransactionMinDate(txnUpdate.date);
        }
        else if(maxDate.isBefore(txnUpdate.date)) {
          // set txnAdd as current maxDate, as maxDate is lesser than current
          // transacion data date.
          TransactionSharedPreferences.setTransactionMaxDate(txnUpdate.date);
        }
      });

      futureNetWorth.then((worth) {
        String dateTo = DateFormat("yyyy-MM-dd").format(DateTime(txnUpdate.date.toLocal().year, txnUpdate.date.toLocal().month+1, 1).subtract(const Duration(days: 1)));
        WalletSharedPreferences.setWalletWorth(dateTo, worth);
        if (mounted) {
          Provider.of<HomeProvider>(context, listen: false).setNetWorth(worth);
        }
      });
    }).onError((error, stackTrace) {
      debugPrint("Error on <updateInformation>");
      throw Exception(error.toString());
    });

    // if expense or income then fetch the top transaction information
    if (txnUpdate.type == 'expense' || txnUpdate.type == 'income') {
      // check if transaction year and month is the same as today?
      // we will just assume that the stats is showed current mont
      DateTime statFrom;
      DateTime statTo;

      (statFrom, statTo) = TransactionSharedPreferences.getStatDate();

      // check if txn update is within stat from and to date
      if (isWithin(txnUpdate.date, statFrom, statTo)) {
        await _transactionHttp.fetchTransactionTop(
          txnUpdate.type,
          txnUpdate.wallet.currencyId,
          fromString,
          toString,
        true).then((transactionTop) {
          if (mounted) {
            // set the provide for this
            Provider.of<HomeProvider>(context, listen: false).setTopTransaction(
              txnUpdate.wallet.currencyId,
              txnUpdate.type,
              transactionTop
            );
          }
        }).onError((error, stackTrace) {
          debugPrint("Error on <_fetchTopTransaction>");
          debugPrint(error.toString());
          debugPrintStack(stackTrace: stackTrace);
          throw Exception("Error when fetching top transaction");
        },);
      }
    }
  }
}
