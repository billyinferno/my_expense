import 'package:flutter/material.dart';
import 'package:flutter_keyboard_size/flutter_keyboard_size.dart';
import 'package:intl/intl.dart';
import 'package:my_expense/api/budget_api.dart';
import 'package:my_expense/api/category_api.dart';
import 'package:my_expense/api/transaction_api.dart';
import 'package:my_expense/api/wallet_api.dart';
import 'package:my_expense/model/budget_model.dart';
import 'package:my_expense/model/last_transaction_model.dart';
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

class TransactionAddPage extends StatefulWidget {
  final Object? params;

  TransactionAddPage(this.params);

  @override
  _TransactionAddPageState createState() => _TransactionAddPageState();
}

class _TransactionAddPageState extends State<TransactionAddPage> with TickerProviderStateMixin {
  DateTime selectedDate = DateTime.now();

  final WalletHTTPService _walletHttp = WalletHTTPService();
  final CategoryHTTPService _categoryHttp = CategoryHTTPService();
  final TransactionHTTPService _transactionHttp = TransactionHTTPService();
  final BudgetHTTPService _budgetHttp = BudgetHTTPService();

  List<WorthModel> _worth = [];

  @override
  void initState() {
    DateTime? prefCurrentTime;

    selectedDate = widget.params as DateTime;
    
    // check on the shared preferences if the transaction list current time is already set or not?
    // if not then use params.
    prefCurrentTime = TransactionSharedPreferences.getTransactionListCurrentDate();
    if (prefCurrentTime != null) {
      selectedDate = prefCurrentTime;
    }

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //print("Adding transaction for " + selectedDate.toString());
    return KeyboardSizeProvider(
      child: TransactionInput(
        title: "Add Transaction",
        refreshCategory: refreshCategory,
        refreshWallet: refreshWallet,
        saveTransaction: (value) {
          saveTransaction(value);
        },
        selectedDate: selectedDate,
      ),
    );
  }

  Future<void> refreshWallet() async {
    print("Refresh the account");

    // fetch again the wallet
    await _walletHttp.fetchWallets(false).then((wallets) {
      if (wallets.length > 0) {
        Provider.of<HomeProvider>(context, listen: false)
            .setWalletList(wallets);
      }

      // remove the loader dialog
      Navigator.pop(context);
    }).onError((error, stackTrace) {
      print("Error when fetching wallet");
      print(error.toString());
      // remove the loader dialog
      Navigator.pop(context);
    });
  }

  Future<void> refreshCategory() async {
    print("Refresh the category");

    // fetch again the wallet
    await _categoryHttp.fetchCategory(true).then((value) {
      // remove the loader dialog
      Navigator.pop(context);
    }).onError((error, stackTrace) {
      print("Error when refresh category");
      print(error.toString());
      // remove the loader dialog
      Navigator.pop(context);
    });
  }

  void saveTransaction(TransactionModel? txn) async {
    // now we can try to send updated data to the backend
    TransactionModel _txn = txn!;
    await _transactionHttp.addTransaction(context, _txn, selectedDate).then((value) {
      // update necessary information after we add the transaction
      updateInformation(value).then((_) {
        // finished update information
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
          message: "Error when add transaction",
        )
      );
    });
  }

  Future<void> updateInformation(TransactionListModel txnAdd) async {
    Future<List<BudgetModel>> _futureBudgets;
    Future<List<WalletModel>> _futureWallets;
    List<BudgetModel> _budgets = [];
    String _refreshDay = DateFormat('yyyy-MM-dd')
        .format(DateTime(txnAdd.date.toLocal().year, txnAdd.date.toLocal().month, 1));
    bool _isExists = false;

    // try to get the transaction date data from the storage, and see whether we got null or not?
    List<BudgetModel>? _budgetPref = BudgetSharedPreferences.getBudget(
        txnAdd.wallet.currencyId, _refreshDay);
    if (_budgetPref != null) {
      // if this is set into true, it means that we need to calculate the budget manually
      // as we already have data from shared preferences.
      _isExists = true;
    }

    // check for the last transaction list, and add the last transaction if the transaction is not
    // on the last transaction list?
    if (txnAdd.type == "expense" || txnAdd.type == "income") {
      List<LastTransactionModel>? _lastTransaction = TransactionSharedPreferences.getLastTransaction(txnAdd.type);
      LastTransactionModel _lastTxn = LastTransactionModel(
        name: txnAdd.name,
        category: CategoryLastTransaction(
          id: txnAdd.category!.id,
          name: txnAdd.category!.name
        ),
      );
      int _lastLoc = -1;

      if (_lastTransaction != null) {
        // already got list, check if this _lastTxn already in the list or not?
        // if not, then just add this transaction to the list
        bool _lastTxnExist = false;
        for (int i = 0; i < _lastTransaction.length; i++) {
          if (_lastTransaction[i].name == _lastTxn.name &&
              _lastTransaction[i].category.name == _lastTxn.category.name) {
            _lastTxnExist = true;
            _lastLoc = i;
            break;
          }
        }

        // check the _lastTxnExists
        if (!_lastTxnExist) {
          _lastTransaction.add(_lastTxn);

          // then save the _lastTransaction to shared preferences
          TransactionSharedPreferences.setLastTransaction(txnAdd.type, _lastTransaction);
        }
        else {
          // last transaction already exists, bump this to first list of the _lastTransaction
          _lastTransaction.removeAt(_lastLoc);
          List<LastTransactionModel> _newLastTransaction = [_lastTxn,..._lastTransaction];

          // then save the _newLastTransaction to shared preferences
          TransactionSharedPreferences.setLastTransaction(txnAdd.type, _newLastTransaction);
        }
      } else {
        // means this is the first one?
        _lastTransaction = [];
        _lastTransaction.add(_lastTxn);

        // then save the _lastTransaction to shared preferences
        TransactionSharedPreferences.setLastTransaction(txnAdd.type, _lastTransaction);
      }
    }

    // add the new transaction to the wallet transaction
    await TransactionSharedPreferences.addTransactionWallet(txnAdd.wallet.id, _refreshDay, txnAdd);
    if (txnAdd.walletTo != null) {
      await TransactionSharedPreferences.addTransactionWallet(txnAdd.walletTo!.id, _refreshDay, txnAdd);
    }

    // add the transaction to the statisctics
    await WalletSharedPreferences.addWalletWorth(txnAdd).then((_) {
      String _dateTo = DateFormat("yyyy-MM-dd").format(DateTime(txnAdd.date.toLocal().year, txnAdd.date.toLocal().month+1, 1).subtract(Duration(days: 1)));

      _worth = WalletSharedPreferences.getWalletWorth(_dateTo);
      Provider.of<HomeProvider>(context, listen: false).setNetWorth(_worth);
    }).onError((error, stackTrace) {
      // why got error here?
      debugPrint("Error when addWalletWorth at <updateInformation>");
      debugPrint(error.toString());
    });

    // only add to the stats graph, if the transaction type is expense and income
    if(txnAdd.type == "expense" || txnAdd.type == "income") {
      // only add the statistics if the transaction being add is current month transaction
      // otherwise we can ignore, as we will not display the statistics on the home stats screen.
      if(txnAdd.date.year == DateTime.now().year && txnAdd.date.month == DateTime.now().month) {
        String _dateFrom = DateFormat("yyyy-MM-dd").format(DateTime(txnAdd.date.toLocal().year, txnAdd.date.toLocal().month, 1));
        String _dateTo = DateFormat("yyyy-MM-dd").format(DateTime(txnAdd.date.toLocal().year, txnAdd.date.toLocal().month+1, 1).subtract(Duration(days: 1)));
        await TransactionSharedPreferences.addIncomeExpense(txnAdd.wallet.currencyId, _dateFrom, _dateTo, txnAdd).then((incomeExpense) {
          // set the provider for this statistics
          Provider.of<HomeProvider>(context, listen: false).setIncomeExpense(txnAdd.wallet.currencyId, incomeExpense);
        }).onError((error, stackTrace) {
          debugPrint("Error when addIncomeExpense at <updateInformation>");
          debugPrint(error.toString());
        });
      }
    }

    // fetch wallets
    await Future.wait([
      _futureWallets = _walletHttp.fetchWallets(true, true),
      _futureBudgets = _budgetHttp.fetchBudgetDate(txnAdd.wallet.currencyId, _refreshDay),
      // update the wallet transaction list
    ]).then((_) {
      // update the wallets
      _futureWallets.then((wallets) {
        Provider.of<HomeProvider>(context, listen: false).setWalletList(wallets);
      });

      // store the budgets list
      if (txnAdd.type == "expense" && _isExists) {
        _futureBudgets.then((value) {
          _budgets = value;
          // now loops thru budget, and see if the current category fits or not?
          for (int i = 0; i < _budgets.length; i++) {
            if (txnAdd.category!.id == _budgets[i].category.id) {
              // as this is expense, add the used for this budget
              BudgetModel _newBudget = BudgetModel(
                  id: _budgets[i].id,
                  category: _budgets[i].category,
                  amount: _budgets[i].amount,
                  used: _budgets[i].used + txnAdd.amount,
                  currency: _budgets[i].currency);
              _budgets[i] = _newBudget;
              // break from for loop
              break;
            }
          }
          // now we can set the shared preferences of budget
          BudgetSharedPreferences.setBudget(txnAdd.wallet.currencyId, _refreshDay, _budgets);

          // only update the provider if, the current home budget is showed
          // the same date as the refresh day
          String _currentBudgetDate = BudgetSharedPreferences.getBudgetCurrent();
          if (_refreshDay == _currentBudgetDate) {
            Provider.of<HomeProvider>(context, listen: false).setBudgetList(_budgets);
          }
        });
      }
      

      // lastly check whether the date being used on the transaction
      // is more or lesser than the max and min date?
      DateTime _minDate = TransactionSharedPreferences.getTransactionMinDate();
      DateTime _maxDate = TransactionSharedPreferences.getTransactionMaxDate();

      if (_minDate.isAfter(txnAdd.date)) {
        // set txnAdd as current minDate, as minDate is bigger than current
        // transaction data date.
        TransactionSharedPreferences.setTransactionMinDate(txnAdd.date);
      } else if (_maxDate.isBefore(txnAdd.date)) {
        // set txnAdd as current maxDate, as maxDate is lesser than current
        // transacion data date.
        TransactionSharedPreferences.setTransactionMaxDate(txnAdd.date);
      }

      // this is success, so we can pop the loader
      Navigator.pop(context);

      // since we already finished, we can pop again to return back to the
      // previous page
      Navigator.pop(context);
    }).onError((error, stackTrace) {
      print("Error on update information");
      throw new Exception(error.toString());
    });
  }
}
