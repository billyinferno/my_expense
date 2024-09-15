import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_expense/_index.g.dart';

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
        try {
          _saveTransaction(value);
        }
        catch (error) {
          // show the error dialog
          ShowMyDialog(
            cancelEnabled: false,
            confirmText: "OK",
            dialogTitle: "Error Refresh",
            dialogText: error.toString())
          .show(context);
        }
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
    await _transactionHttp.updateTransaction(
      txn: txn!,
      prevTxn: _paramsData
    ).then((txnUpdate) async {
      // update necessary information after we add the transaction
      await _updateInformation(txnUpdate).then((_) async {
        // for transaction that actually add on the different date, we cannot notify the home list
        // to show this transaction, because currently we are in a different date between the transaction
        // being add and the date being selected on the home list
        DateTime currentListTxnDate = (
          TransactionSharedPreferences.getTransactionListCurrentDate() ??
          DateTime.now()
        );

        // default the date as the same as the home list date
        String date = Globals.dfyyyyMMdd.formatLocal(currentListTxnDate);

        // check if this is the same date or not?
        // if not the same then we will need to refresh bot transaction list
        // both on the transaction update date and the home list date.
        if (!txnUpdate.date.isSameDate(date: currentListTxnDate)) {
          // since the update transaction and current home list is different date
          // get both data and stored it on the transaction shared preferences
          await _refreshHomeList(
            txnDate: txnUpdate.date,
            homeListDate: currentListTxnDate
          ).onError((error, stackTrace) async {
            Log.error(
              message: "Error when update the home list transaction",
              error: error,
              stackTrace: stackTrace,
            );

            throw Exception("Error when refresh home list.");
          });
        }

        // this is success, so we can pop the loader
        if (mounted) {
          // get the transaction list from shared preferences
          List<TransactionListModel>? txnListShared = TransactionSharedPreferences.getTransaction(date);

          // once add on the shared preferences, we can change the
          // TransactionListModel provider so it will update the home list page
          Provider.of<HomeProvider>(
            context,
            listen: false
          ).setTransactionList(transactions: txnListShared ?? []);

          // since we already finished, we can pop to return back to the
          // previous page
          Navigator.pop(context, txnUpdate);
        }
      }).onError((error, stackTrace) async {
        // print the error
        Log.error(
          message: "Error when refresh information",
          error: error,
          stackTrace: stackTrace,
        );

        throw Exception("Error when refresh information.");
      });
    }).onError((error, stackTrace) async {
      // print the error
      Log.error(
        message: "Error when update information",
        error: error,
        stackTrace: stackTrace,
      );

      throw Exception("Error when update transaction.");
    }).whenComplete(() {
        // remove the loading screen
        LoadingScreen.instance().hide();
      },
    );
  }

  Future<void> _refreshHomeList({
    required DateTime txnDate,
    required DateTime homeListDate
  }) async {
    await Future.wait([
      _transactionHttp.fetchTransaction(
        date: Globals.dfyyyyMMdd.formatLocal(txnDate),
        force: true
      ).then((resp) {
        // once got the response store this on the TransactionSharedPreferences
        TransactionSharedPreferences.setTransaction(
          date: Globals.dfyyyyMMdd.formatLocal(txnDate),
          txn: resp
        );
      }).onError(
        (error, stackTrace) {
          throw Exception("Error when update for $txnDate");
        },
      ),

      _transactionHttp.fetchTransaction(
        date: Globals.dfyyyyMMdd.formatLocal(homeListDate),
        force: true
      ).then((resp) {
        // once got the response store this on the TransactionSharedPreferences
        TransactionSharedPreferences.setTransaction(
          date: Globals.dfyyyyMMdd.formatLocal(homeListDate),
          txn: resp
        );
      }).onError(
        (error, stackTrace) {
          throw Exception("Error when update for $homeListDate");
        },
      ),
    ]);
  }

  Future<void> _updateInformation(TransactionListModel txnUpdate) async {
    Future<List<BudgetModel>> futureBudgets;
    Future<List<WalletModel>> futureWallets;
    Future<List<WorthModel>> futureNetWorth;

    String refreshDay = Globals.dfyyyyMMdd.format(
      DateTime(
        txnUpdate.date.year,
        txnUpdate.date.month,
        1
      ).toLocal()
    );

    String prevDay = Globals.dfyyyyMMdd.format(
      DateTime(
        _paramsData.date.year,
        _paramsData.date.month,
        1
      ).toLocal()
    );

    DateTime from = DateTime(DateTime.now().year, DateTime.now().month, 1);
    DateTime to = DateTime(
      DateTime.now().year,
      DateTime.now().month + 1,
      1
    ).subtract(const Duration(days: 1));
    String fromString = Globals.dfyyyyMMdd.formatLocal(from);
    String toString = Globals.dfyyyyMMdd.formatLocal(to);

    // check whether this transaction moved from one wallet to another wallet?
    // first check whether this is expense, income, or transfer?
    bool isWalletMoved = false;
    if (txnUpdate.type == "expense" || txnUpdate.type == "income") {
      if (_paramsData.wallet.id == txnUpdate.wallet.id) {
        // do nothing
      } else {
        // change wallet
        isWalletMoved = true;
      }
    } else {
      // this is transfer, check both
      if (_paramsData.wallet.id == txnUpdate.wallet.id &&
          _paramsData.walletTo?.id == txnUpdate.walletTo?.id) {
        // do nothing
      } else {
        // change wallet for transfer
        isWalletMoved = true;
      }
    }

    // if there are no wallet moved, then we can just update the wallet
    if (!isWalletMoved) {
      // update the new transaction to the wallet transaction
      await TransactionSharedPreferences.updateTransactionWallet(
        walletId: txnUpdate.wallet.id,
        date: refreshDay,
        txn: txnUpdate
      );
      if (txnUpdate.walletTo != null) {
        await TransactionSharedPreferences.updateTransactionWallet(
          walletId: txnUpdate.walletTo!.id,
          date: refreshDay,
          txn: txnUpdate
        );
      }
    } else {
      // check which wallet is being moved
      if (_paramsData.wallet.id != txnUpdate.wallet.id) {
        // moved the transaction from previous wallet to the new wallet
        await TransactionSharedPreferences.deleteTransactionWallet(
          walletId: _paramsData.wallet.id,
          date: prevDay,
          txn: _paramsData
        );
        await TransactionSharedPreferences.addTransactionWallet(
          walletId: txnUpdate.wallet.id,
          date: refreshDay,
          txn: txnUpdate
        );
      }

      if (txnUpdate.walletTo != null) {
        // check if both wallet the same or not?
        if (_paramsData.walletTo!.id != txnUpdate.walletTo!.id) {
          // moved the transaction from previous wallet to the new wallet
          await TransactionSharedPreferences.deleteTransactionWallet(
            walletId: _paramsData.walletTo!.id,
            date: prevDay,
            txn: _paramsData
          );
          await TransactionSharedPreferences.addTransactionWallet(
            walletId: txnUpdate.walletTo!.id,
            date: refreshDay,
            txn: txnUpdate
          );
        }
      }
    }

    // check if this is expense or income?
    if (txnUpdate.type == "expense" || txnUpdate.type == "income") {
      // we will only going to update the income expense statistic, if only this transaction
      // is perform on the same month
      if (txnUpdate.date.year == DateTime.now().year &&
          txnUpdate.date.month == DateTime.now().month) {
        await _transactionHttp.fetchIncomeExpense(
          ccyId: txnUpdate.wallet.currencyId,
          from: from,
          to: to,
          force: true
        ).then((incomeExpense) {
          if (mounted) {
            Provider.of<HomeProvider>(
              context,
              listen: false
            ).setIncomeExpense(
              ccyId: txnUpdate.wallet.currencyId,
              data: incomeExpense
            );
          }
        }).onError((error, stackTrace) {
          Log.error(
            message: "Error when fetchIncomeExpense at <updateInformation>",
            error: error,
            stackTrace: stackTrace,
          );
        });
      }
    }

    await Future.wait([
      futureWallets = _walletHttp.fetchWallets(
        showDisabled: true,
        force: true,
      ),
      futureBudgets = _budgetHttp.fetchBudgetDate(
        currencyID: txnUpdate.wallet.currencyId,
        date: refreshDay,
        force: true,
      ),
      futureNetWorth = _walletHttp.fetchWalletsWorth(
        to: txnUpdate.date,
        force: true,
      ),
    ]).then((_) {
      // got the updated wallets
      futureWallets.then((wallets) {
        if (mounted) {
          Provider.of<HomeProvider>(
            context,
            listen: false
          ).setWalletList(wallets: wallets);
        }
      });

      // got the new budgets
      futureBudgets.then((budgets) {
        // now we can set the shared preferences of budget
        BudgetSharedPreferences.setBudget(
          ccyId: txnUpdate.wallet.currencyId,
          date: refreshDay,
          budgets: budgets
        );

        if (mounted) {
          Provider.of<HomeProvider>(
            context,
            listen: false
          ).setBudgetList(budgets: budgets);
        }
      }).then((_) {
        // lastly check whether the date being used on the transaction
        // is more or lesser than the max and min date?
        DateTime minDate = TransactionSharedPreferences.getTransactionMinDate();
        DateTime maxDate = TransactionSharedPreferences.getTransactionMaxDate();

        if (minDate.isAfter(txnUpdate.date)) {
          // set txnAdd as current minDate, as minDate is bigger than current
          // transaction data date.
          TransactionSharedPreferences.setTransactionMinDate(date: txnUpdate.date);
        } else if (maxDate.isBefore(txnUpdate.date)) {
          // set txnAdd as current maxDate, as maxDate is lesser than current
          // transacion data date.
          TransactionSharedPreferences.setTransactionMaxDate(date: txnUpdate.date);
        }
      });

      futureNetWorth.then((worth) {
        String dateTo = Globals.dfyyyyMMdd.format(DateTime(
          txnUpdate.date.toLocal().year,
          txnUpdate.date.toLocal().month + 1,
          1
        ).subtract(const Duration(days: 1)));
        WalletSharedPreferences.setWalletWorth(dateTo: dateTo, walletWorth: worth);
        if (mounted) {
          Provider.of<HomeProvider>(
            context,
            listen: false
          ).setNetWorth(worth: worth);
        }
      });
    }).onError((error, stackTrace) {
      Log.error(
        message: "Error on <updateInformation>",
        error: error,
        stackTrace: stackTrace,
      );
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
      if (txnUpdate.date.isWithin(from: statFrom, to: statTo)) {
        await _transactionHttp.fetchTransactionTop(
          type: txnUpdate.type, 
          ccy: txnUpdate.wallet.currencyId,
          from: fromString,
          to: toString,
          force: true
        ).then((transactionTop) {
          if (mounted) {
            // set the provide for this
            Provider.of<HomeProvider>(
              context,
              listen: false
            ).setTopTransaction(
              ccy: txnUpdate.wallet.currencyId,
              type: txnUpdate.type,
              data: transactionTop
            );
          }
        }).onError(
          (error, stackTrace) {
            Log.error(
              message: "Error on <_fetchTopTransaction>",
              error: error,
              stackTrace: stackTrace,
            );
            throw Exception("Error when fetching top transaction");
          },
        );
      }
    }
  }
}
