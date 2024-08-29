import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_expense/_index.g.dart';

class TransactionAddPage extends StatefulWidget {
  final Object? params;

  const TransactionAddPage({super.key, required this.params});

  @override
  State<TransactionAddPage> createState() => _TransactionAddPageState();
}

class _TransactionAddPageState extends State<TransactionAddPage> {
  DateTime _selectedDate = DateTime.now();

  final WalletHTTPService _walletHttp = WalletHTTPService();
  final TransactionHTTPService _transactionHttp = TransactionHTTPService();
  final BudgetHTTPService _budgetHttp = BudgetHTTPService();

  List<WorthModel> _worth = [];

  @override
  void initState() {
    DateTime? prefCurrentTime;

    _selectedDate = widget.params as DateTime;

    // check on the shared preferences if the transaction list current time is already set or not?
    // if not then use params.
    prefCurrentTime =
        TransactionSharedPreferences.getTransactionListCurrentDate();
    if (prefCurrentTime != null) {
      _selectedDate = prefCurrentTime;
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TransactionInput(
      title: "Add Transaction",
      type: TransactionInputType.add,
      saveTransaction: (value) {
        _saveTransaction(value);
      },
      selectedDate: _selectedDate.toLocal(),
    );
  }

  void _saveTransaction(TransactionModel? txn) async {
    // show the loading screen
    LoadingScreen.instance().show(context: context);

    // now we can try to send updated data to the backend
    await _transactionHttp.addTransaction(
      txn: txn!,
      selectedDate: _selectedDate
    ).then((result) async {
      // update necessary information after we add the transaction
      await _updateInformation(result).then((_) {
        // get the transaction edit date
        String date = Globals.dfyyyyMMdd.format(txn.date.toLocal());

        // get the transaction list from this date
        List<TransactionListModel> txnListShared =
          (TransactionSharedPreferences.getTransaction(date) ?? []);

        // for transaction that actually add on the different date, we cannot notify the home list
        // to show this transaction, because currently we are in a different date between the transaction
        // being add and the date being selected on the home list
        if (
          txn.date.toLocal().isSameDate(date: _selectedDate.toLocal()) &&
          mounted
        ) {
          Provider.of<HomeProvider>(
            context,
            listen: false
          ).setTransactionList(transactions: txnListShared);
        }

        // finished update information, return back to the previous page
        if (mounted) {
          Navigator.pop(context);
        }
      }).onError((error, stackTrace) async {
        // print the error
        Log.error(
          message: "Error when refresh transaction after save",
          error: error,
          stackTrace: stackTrace,
        );

        if (mounted) {
          // show the error dialog
          await ShowMyDialog(
            cancelEnabled: false,
            confirmText: "OK",
            dialogTitle: "Error Refresh",
            dialogText: "Error when refresh information.")
          .show(context);
        }
      });
    }).onError((error, stackTrace) async {
      // print the error
      Log.error(
        message: "Error when add transaction",
        error: error,
        stackTrace: stackTrace,
      );

      if (mounted) {
        // show the error dialog
        await ShowMyDialog(
          cancelEnabled: false,
          confirmText: "OK",
          dialogTitle: "Error Add",
          dialogText: "Error when add transaction.")
        .show(context);
      }
    }).whenComplete(() {
      // remove the loading screen
      LoadingScreen.instance().hide();
    },);
  }

  Future<void> _updateInformation(TransactionListModel txnAdd) async {
    Future<List<BudgetModel>> futureBudgets;
    Future<List<WalletModel>> futureWallets;
    List<BudgetModel> budgets = [];
    String refreshDay = Globals.dfyyyyMMdd.format(
      DateTime(
        txnAdd.date.toLocal().year,
        txnAdd.date.toLocal().month,
        1
      )
    );
    bool isExists = false;

    // try to get the transaction date data from the storage, and see whether we got null or not?
    List<BudgetModel>? budgetPref =
        BudgetSharedPreferences.getBudget(txnAdd.wallet.currencyId, refreshDay);

    if (budgetPref != null) {
      // if this is set into true, it means that we need to calculate the budget manually
      // as we already have data from shared preferences.
      isExists = true;
    }

    // check for the last transaction list, and add the last transaction if the transaction is not
    // on the last transaction list?
    if (txnAdd.type == "expense" || txnAdd.type == "income") {
      List<LastTransactionModel>? lastTransaction = TransactionSharedPreferences.getLastTransaction(txnAdd.type);
      LastTransactionModel lastTxn = LastTransactionModel(
        name: txnAdd.name,
        category: CategoryLastTransaction(
          id: txnAdd.category!.id,
          name: txnAdd.category!.name
        ),
      );

      // get the index  for the last transaction if transaction exists
      int lastLoc = -1;

      if (lastTransaction != null) {
        // already got list, check if this _lastTxn already in the list or not?
        // if not, then just add this transaction to the list
        bool lastTxnExist = false;
        for (int i = 0; i < lastTransaction.length; i++) {
          if (lastTransaction[i].name == lastTxn.name &&
              lastTransaction[i].category.name == lastTxn.category.name) {
            lastTxnExist = true;
            lastLoc = i;
            break;
          }
        }

        // check the _lastTxnExists
        if (!lastTxnExist) {
          lastTransaction.add(lastTxn);

          // then save the _lastTransaction to shared preferences
          TransactionSharedPreferences.setLastTransaction(
              txnAdd.type, lastTransaction);
        } else {
          // last transaction already exists, bump this to first list of the _lastTransaction
          lastTransaction.removeAt(lastLoc);
          List<LastTransactionModel> newLastTransaction = [
            lastTxn,
            ...lastTransaction
          ];

          // then save the _newLastTransaction to shared preferences
          TransactionSharedPreferences.setLastTransaction(
            txnAdd.type,
            newLastTransaction
          );
        }
      } else {
        // means this is the first one?
        lastTransaction = [];
        lastTransaction.add(lastTxn);

        // then save the _lastTransaction to shared preferences
        TransactionSharedPreferences.setLastTransaction(
          txnAdd.type,
          lastTransaction
        );
      }
    }

    // add the new transaction to the wallet transaction
    await TransactionSharedPreferences.addTransactionWallet(
      txnAdd.wallet.id,
      refreshDay,
      txnAdd
    );

    if (txnAdd.walletTo != null) {
      await TransactionSharedPreferences.addTransactionWallet(
        txnAdd.walletTo!.id,
        refreshDay,
        txnAdd
      );
    }

    // add the transaction to the statisctics
    await WalletSharedPreferences.addWalletWorth(txnAdd).then((_) {
      String dateTo = Globals.dfyyyyMMdd.format(
        DateTime(
          txnAdd.date.toLocal().year,
          txnAdd.date.toLocal().month + 1,
          1
        ).subtract(const Duration(days: 1))
      );

      _worth = WalletSharedPreferences.getWalletWorth(dateTo);
      if (mounted) {
        Provider.of<HomeProvider>(
          context,
          listen: false
        ).setNetWorth(worth: _worth);
      }
    }).onError((error, stackTrace) {
      // why got error here?
      Log.error(
        message: "Error when addWalletWorth at <updateInformation>",
        error: error,
        stackTrace: stackTrace,
      );
    });

    // only add to the stats graph, if the transaction type is expense and income
    if (txnAdd.type == "expense" || txnAdd.type == "income") {
      // only add the statistics if the transaction being add is current month transaction
      // otherwise we can ignore, as we will not display the statistics on the home stats screen.
      if (txnAdd.date.year == DateTime.now().year &&
          txnAdd.date.month == DateTime.now().month) {
        String dateFrom = Globals.dfyyyyMMdd.format(
          DateTime(
            txnAdd.date.toLocal().year,
            txnAdd.date.toLocal().month,
            1
          )
        );

        String dateTo = Globals.dfyyyyMMdd.format(
          DateTime(
            txnAdd.date.toLocal().year,
            txnAdd.date.toLocal().month + 1,
            1
          ).subtract(const Duration(days: 1))
        );

        await TransactionSharedPreferences.addIncomeExpense(
          txnAdd.wallet.currencyId,
          dateFrom,
          dateTo,
          txnAdd
        ).then((incomeExpense) {
          if (mounted) {
            // set the provider for this statistics
            Provider.of<HomeProvider>(
              context,
              listen: false
            ).setIncomeExpense(
              ccyId: txnAdd.wallet.currencyId,
              data: incomeExpense
            );
          }
        }).onError((error, stackTrace) {
          Log.error(
            message: "Error when addIncomeExpense at <updateInformation>",
            error: error,
            stackTrace: stackTrace,
          );
        });
      }
    }

    // fetch wallets
    await Future.wait([
      futureWallets = _walletHttp.fetchWallets(
        showDisabled: true,
        force: true,
      ),
      futureBudgets = _budgetHttp.fetchBudgetDate(
        currencyID: txnAdd.wallet.currencyId,
        date: refreshDay
      ),
    ]).then((_) {
      // update the wallets
      futureWallets.then((wallets) {
        if (mounted) {
          Provider.of<HomeProvider>(
            context,
            listen: false
          ).setWalletList(wallets: wallets);
        }
      });

      // store the budgets list
      if (txnAdd.type == "expense" && isExists) {
        futureBudgets.then((value) {
          budgets = value;
          // now loops thru budget, and see if the current category fits or not?
          for (int i = 0; i < budgets.length; i++) {
            if (txnAdd.category!.id == budgets[i].category.id) {
              // as this is expense, add the total transaction and used for this
              BudgetModel newBudget = BudgetModel(
                  id: budgets[i].id,
                  category: budgets[i].category,
                  totalTransaction: (budgets[i].totalTransaction + 1),
                  amount: budgets[i].amount,
                  used: budgets[i].used + txnAdd.amount,
                  status: budgets[i].status,
                  currency: budgets[i].currency);
              budgets[i] = newBudget;
              // break from for loop
              break;
            }
          }
          // now we can set the shared preferences of budget
          BudgetSharedPreferences.setBudget(
            txnAdd.wallet.currencyId,
            refreshDay,
            budgets
          );

          // only update the provider if, the current home budget is ed
          // the same date as the refresh day
          String currentBudgetDate = BudgetSharedPreferences.getBudgetCurrent();
          if (refreshDay == currentBudgetDate && mounted) {
            Provider.of<HomeProvider>(
              context,
              listen: false
            ).setBudgetList(budgets: budgets);
          }
        });
      }

      // if this is income or expense then get the statistic
      if (txnAdd.type == 'income' || txnAdd.type == 'expense') {
        // check if transaction year and month is the same as today?
        // we will just assume that the stats is showed current month
        DateTime statFrom;
        DateTime statTo;

        (statFrom, statTo) = TransactionSharedPreferences.getStatDate();

        // check if txnAdd is within statFrom and statTo
        if (mounted) {
          if (txnAdd.date.isWithin(from: statFrom, to: statTo) &&
            (
              txnAdd.date.toLocal().month == DateTime.now().toLocal().month &&
              txnAdd.date.toLocal().year == DateTime.now().toLocal().year
            )
          ) {
            Provider.of<HomeProvider>(
              context,
              listen: false
            ).addTopTransaction(
              ccy: txnAdd.wallet.currencyId,
              type: txnAdd.type,
              transaction: txnAdd
            );
          }
        }
      }

      // lastly check whether the date being used on the transaction
      // is more or lesser than the max and min date?
      DateTime minDate = TransactionSharedPreferences.getTransactionMinDate();
      DateTime maxDate = TransactionSharedPreferences.getTransactionMaxDate();

      if (minDate.isAfter(txnAdd.date)) {
        // set txnAdd as current minDate, as minDate is bigger than current
        // transaction data date.
        TransactionSharedPreferences.setTransactionMinDate(txnAdd.date);
      } else if (maxDate.isBefore(txnAdd.date)) {
        // set txnAdd as current maxDate, as maxDate is lesser than current
        // transacion data date.
        TransactionSharedPreferences.setTransactionMaxDate(txnAdd.date);
      }
    }).onError((error, stackTrace) {
      Log.error(
        message: "Error on update information",
        error: error,
        stackTrace: stackTrace,
      );
      throw Exception(error.toString());
    });
  }
}
