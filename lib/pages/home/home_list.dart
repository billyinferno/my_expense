import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/api/budget_api.dart';
import 'package:my_expense/api/transaction_api.dart';
import 'package:my_expense/api/wallet_api.dart';
import 'package:my_expense/model/budget_model.dart';
import 'package:my_expense/model/income_expense_model.dart';
import 'package:my_expense/model/transaction_list_model.dart';
import 'package:my_expense/model/users_me_model.dart';
import 'package:my_expense/model/wallet_model.dart';
import 'package:my_expense/pages/home/home_appbar.dart';
import 'package:my_expense/provider/home_provider.dart';
import 'package:my_expense/utils/globals.dart';
import 'package:my_expense/utils/misc/my_callback.dart';
import 'package:my_expense/utils/misc/show_dialog.dart';
import 'package:my_expense/utils/misc/show_loader_dialog.dart';
import 'package:my_expense/utils/prefs/shared_budget.dart';
import 'package:my_expense/utils/prefs/shared_transaction.dart';
import 'package:my_expense/utils/prefs/shared_user.dart';
import 'package:my_expense/utils/prefs/shared_wallet.dart';
import 'package:my_expense/widgets/item/item_list.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:my_expense/themes/colors.dart';

class HomeList extends StatefulWidget {
  final VoidCallback userIconPress;
  final MyDateTimeCallback userDateSelect;

  HomeList(
      {required this.userIconPress,
      required this.userDateSelect});

  @override
  _HomeListState createState() => _HomeListState();
}

class _HomeListState extends State<HomeList> {
  bool _isLoading = false;

  DateTime _firstDay = DateTime(2010, 1, 1);
  DateTime _lastDay = DateTime(DateTime.now().year + 1, 12, 31);
  DateTime _currentFocusedDay = DateTime.now();

  String _appTitleMonth = "";
  String _appTitleYear = "";
  String _refreshDay = "";
  CalendarFormat _currentCalendarFormat = CalendarFormat.week;
  Icon _currentCalendarIcon = Icon(Ionicons.caret_down, size: 10);
  
  final TransactionHTTPService _transactionHttp = TransactionHTTPService();
  final WalletHTTPService _walletHTTP = WalletHTTPService();
  final BudgetHTTPService _budgetHTTP = BudgetHTTPService();

  late Future<List<BudgetModel>> _futureBudgets;
  late Future<List<WalletModel>> _futureWallets;
  late Future<IncomeExpenseModel> _futureIncomeExpense;
  late ScrollController _scrollController;

  List<TransactionListModel> _transactionData = [];
  List<BudgetModel> _budgets = [];
  late UsersMeModel _userMe;

  final fCCY = new NumberFormat("#,##0.00", "en_US");

  @override
  void initState() {
    super.initState();

    _userMe = UserSharedPreferences.getUserMe();
    
    setState(() {
      _appTitleMonth = DateFormat('MMMM').format(_currentFocusedDay.toLocal());
      _appTitleYear = DateFormat('yyyy').format(_currentFocusedDay.toLocal());
    });

    getInitialTransactionList();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  void getInitialTransactionList() async {
    Future.wait([
      _refreshTransaction(_currentFocusedDay, true),
    ]).then((_) {
      debugPrint("💯 Initialized Home List Finished");
    }).onError((error, stackTrace) {
      print("Error when perform <fetchTransaction>");
      print(error.toString());
    });
  }

  Future<void> _showCalendarPicker() async {
    Future<DateTime?> _date = showDatePicker(
      context: context,
      initialDate: _currentFocusedDay,
      firstDate: _firstDay,
      lastDate: _lastDay,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: ((BuildContext context, Widget? child) {
        return Theme(
          data: Globals.themeData.copyWith(
            textTheme: TextTheme(
              headlineMedium: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              headlineSmall: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            colorScheme: ColorScheme.dark(
              primary: accentColors[6],
              onPrimary: textColor,
              surface: secondaryDark,
              onSurface: textColor2,
            ),
            dialogBackgroundColor:secondaryBackground,
          ),
          child: child!,
        );
      }),
    );

    _date.then((_newDate) {
      if(_newDate != null) {
        //debugPrint(_newDate.toString());
        setFocusedDay(DateTime(_newDate.toLocal().year, _newDate.toLocal().month, _newDate.toLocal().day));
        _refreshTransaction(_currentFocusedDay);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(
        title: Center(
          child: InkWell(
            onTap: (() {
              // show the month selector
              _showCalendarPicker();
            }),
            onDoubleTap: (() {
              // go to the current date
              setFocusedDay(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
              _refreshTransaction(_currentFocusedDay);
            }),
            child: Container(
              color: Colors.transparent,
              child: Text(
                _appTitleMonth + " " + _appTitleYear,
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ),
        iconItem: Icon(
          Ionicons.search,
          size: 20,
        ),
        onUserPress: widget.userIconPress,
        onActionPress: () {
          Navigator.pushNamed(context, "/transaction/search");
        },
      ),
      body: Column(
        children: [
          GestureDetector(
            onVerticalDragEnd: ((DragEndDetails details) {
              double _velocity = (details.primaryVelocity ?? 0);
              debugPrint(_velocity.toString());
              if(_velocity != 0) {
                if(_velocity > 0) {
                  debugPrint("Up");
                }
                else if(_velocity < 0) {
                  debugPrint("Down");
                }
              }
            }),
            child: Container(
              decoration: BoxDecoration(
                color: primaryDark,
              ),
              child: TableCalendar(
                focusedDay: _currentFocusedDay,
                firstDay: _firstDay,
                lastDay: _lastDay,
                calendarFormat: _currentCalendarFormat,
                onPageChanged: (_focusedDay) {
                  setFocusedDay(_focusedDay);
                  _refreshTransaction(_focusedDay);
                },
                selectedDayPredicate: (day) {
                  return isSameDay(day, _currentFocusedDay);
                },
                onDaySelected: (_selectedDay, _focusedDay) {
                  if (!(isSameDay(_selectedDay, _currentFocusedDay))) {
                    setFocusedDay(_selectedDay);
                    _refreshTransaction(_selectedDay);
                  }
                },
                headerVisible: false,
                calendarBuilders: CalendarBuilders(
                  todayBuilder: (context, day, focusedDay) {
                    return Container(
                      alignment: Alignment.center,
                      child: Text(
                        DateFormat('d').format(day.toLocal()),
                        style: TextStyle(
                          color: accentColors[1],
                        ),
                      ),
                    );
                  },
                ),
                calendarStyle: CalendarStyle(
                  weekendTextStyle: TextStyle(color: accentColors[2]),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                if (_currentCalendarFormat == CalendarFormat.week) {
                  _currentCalendarFormat = CalendarFormat.month;
                  _currentCalendarIcon = Icon(Ionicons.caret_up, size: 10);
                } else {
                  _currentCalendarFormat = CalendarFormat.week;
                  _currentCalendarIcon = Icon(Ionicons.caret_down, size: 10);
                }
              });
            },
            child: Container(
              width: double.infinity,
              height: 15,
              decoration: BoxDecoration(
                color: secondaryDark,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _currentCalendarIcon,
                ],
              ),
            ),
          ),
          Container(
            height: 36,
            width: double.infinity,
            decoration: BoxDecoration(
                border: Border(
              bottom: BorderSide(width: 1.0, color: primaryLight),
            )),
            child: Container(
              padding: EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text(
                    (isSameDay(_currentFocusedDay, DateTime.now())
                        ? "Today"
                        : DateFormat('dd MMMM yyyy').format(_currentFocusedDay.toLocal())),
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: Colors.transparent,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Consumer<HomeProvider>(
                          builder: (context, homeProvider, child) {
                            return _getTotalIncomeExpense(homeProvider.transactionList);
                          }
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: generateView(),
          ),
        ],
      ),
    );
  }

  Widget generateView() {
    if (_isLoading) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitFadingCube(
              color: accentColors[6],
              size: 25,
            ),
            SizedBox(height: 10,),
            Text(
              "loading...",
              style: TextStyle(
                color: textColor2,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    } else {
      return Consumer<HomeProvider>(
        builder: (context, homeProvider, child) {
          _transactionData = homeProvider.transactionList;
          return GestureDetector(
            onHorizontalDragEnd: ((DragEndDetails details) {
              double _velocity = (details.primaryVelocity ?? 0);
              if(_velocity != 0) {
                if(_velocity > 0) {
                  // go to the previous day
                  setFocusedDay(_currentFocusedDay.subtract(Duration(days: 1)));
                  _refreshTransaction(_currentFocusedDay);
                }
                else if(_velocity < 0) {
                  // go to the next day
                  setFocusedDay(_currentFocusedDay.add(Duration(days: 1)));
                  _refreshTransaction(_currentFocusedDay);
                }
              }
            }),
            child: (Container(
              padding: EdgeInsets.all(10),
              child: RefreshIndicator(
                color: accentColors[6],
                onRefresh: () async {
                  await _refreshTransaction(_currentFocusedDay, true);
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: _scrollController,
                  itemCount: _transactionData.length + 1,
                  itemBuilder: (BuildContext ctx, int index) {
                    if (index < _transactionData.length) {
                      TransactionListModel txn = _transactionData[index];
                      return generateListItem(index, txn, context);
                    }
                    else {
                      return const SizedBox(height: 30,);
                    }
                  },
                ),
              ),
            )),
          );
        },
      );
    }
  }

  void setFocusedDay(DateTime _focusedDay) {
    setState(() {
      _currentFocusedDay = _focusedDay;
      _appTitleMonth = DateFormat('MMMM').format(_currentFocusedDay.toLocal());
      _appTitleYear = DateFormat('yyyy').format(_currentFocusedDay.toLocal());

      // return back the selected date to the router
      widget.userDateSelect(_currentFocusedDay.toLocal());
    });
  }

  Widget generateListItem(int index, TransactionListModel txn, BuildContext context) {
    // debugPrint("Txn " + txn.date.toLocal().toString());
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.20,
        children: <SlidableAction>[
          SlidableAction(
            label: 'Delete',
            foregroundColor: textColor,
            backgroundColor: accentColors[2],
            icon: Ionicons.trash,
            onPressed: ((_) {
              if (!_isLoading) {
                late Future<bool?> result = ShowMyDialog(
                        dialogTitle: "Delete Item",
                        dialogText: "Do you want to delete " + txn.name + "?",
                        confirmText: "Delete",
                        cancelText: "Cancel")
                    .show(context);

                // check the result of the dialog box
                result.then((value) {
                  if (value == true) {
                    _deleteTransaction(txn);
                  }
                });
              }
            })
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/transaction/edit', arguments: txn);
        },
        child: generateItem(txn),
      ),
    );
  }

  Widget generateItem(TransactionListModel txn) {
    switch (txn.type.toLowerCase()) {
      case "expense":
        return ItemList(
          type: ItemType.expense,
          name: txn.name,
          walletName: txn.wallet.name,
          walletSymbol: txn.wallet.symbol,
          categoryName: txn.category!.name,
          amount: txn.amount
        );
      case "income":
        return ItemList(
          type: ItemType.income,
          name: txn.name,
          walletName: txn.wallet.name,
          walletSymbol: txn.wallet.symbol,
          categoryName: txn.category!.name,
          amount: txn.amount
        );
      case "transfer":
        return ItemList(
          type: ItemType.transfer,
          walletName: txn.wallet.name,
          walletSymbol: txn.wallet.symbol,
          walletToName: txn.walletTo!.name,
          walletToSymbol: txn.walletTo!.symbol,
          amount: txn.amount,
          exchangeRate: txn.exchangeRate,
        );
      default:
        return ItemList(
          type: ItemType.expense,
          name: txn.name,
          walletName: txn.wallet.name,
          walletSymbol: txn.wallet.symbol,
          categoryName: txn.category!.name,
          amount: txn.amount
        );
    }
  }

  void setLoading(bool _loading) {
    setState(() {
      _isLoading = _loading;
    });
  }

  Future<void> _refreshTransaction(DateTime refreshDay, [bool? force]) async {
    bool _force = (force ?? false);

    // fetch the new wallet data from API
    setLoading(true);

    // store current transaction list date on shared preferences.
    // we can use this date when we perform edit, and if the date is not the same
    // as the current transaction list date, we don't need to refresh the provider.
    await TransactionSharedPreferences.setTransactionListCurrentDate(refreshDay.toLocal());

    String _refreshDay = DateFormat('yyyy-MM-dd').format(refreshDay.toLocal());
    await _transactionHttp.fetchTransaction(_refreshDay, _force).then((value) {
      // ensure that the selectedDate and the refreshDay is the same
      if(isSameDay(_currentFocusedDay, refreshDay)) {
        Provider.of<HomeProvider>(context, listen: false).setTransactionList(value);
        //debugPrint("Now provider length is : " + Provider.of<HomeProvider>(context, listen: false).transactionList.length.toString());
      }
      setLoading(false);
    }).onError((error, stackTrace) {
      setLoading(false);
      print(error.toString());
      print(stackTrace.toString());
      throw new Exception("Error when refresh transaction");
    });
  }

  Future<void> _deleteTransaction(TransactionListModel txnDeleted) async {
    showLoaderDialog(context);

    await _transactionHttp.deleteTransaction(context, txnDeleted).then((_) {
      //debugPrint(txnDeleted.toJson().toString());
      updateInformation(txnDeleted);
    }).onError((error, stackTrace) {
      debugPrint("Error when delete");
      debugPrint(error.toString());
      // since got error we need to pop from the loader
      Navigator.pop(context);
    });
  }

  Future<void> updateInformation(TransactionListModel txnInfo) async {
    //debugPrint("Updating Information");

    _refreshDay = DateFormat('yyyy-MM-dd').format(DateTime(txnInfo.date.toLocal().year, txnInfo.date.toLocal().month, 1));
    DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
    DateTime _to = DateTime(DateTime.now().year, DateTime.now().month + 1, 1).subtract(Duration(days: 1));

    // delete the transaction from wallet transaction
    await TransactionSharedPreferences.deleteTransactionWallet(txnInfo.wallet.id, _refreshDay, txnInfo);
    if (txnInfo.walletTo != null) {
      await TransactionSharedPreferences.deleteTransactionWallet(txnInfo.walletTo!.id, _refreshDay, txnInfo);
    }

    // delete the transaction from budget
    await WalletSharedPreferences.deleteWalletWorth(txnInfo);

    await Future.wait([
      _futureWallets = _walletHTTP.fetchWallets(true, true),
      _futureBudgets = _budgetHTTP.fetchBudgetDate(txnInfo.wallet.currencyId, _refreshDay),
      _futureIncomeExpense = _transactionHttp.fetchIncomeExpense(txnInfo.wallet.currencyId, _from, _to, true),
    ]).then((_) {
      // update the wallets
      _futureWallets.then((wallets) {
        Provider.of<HomeProvider>(context, listen: false).setWalletList(wallets);
      });

      // store the budgets list
      if(txnInfo.type == "expense") {
        _futureBudgets.then((value) {
          _budgets = value;
          // now loops thru budget, and see if the current category fits or not?
          for (int i = 0; i < _budgets.length; i++) {
            if (txnInfo.category!.id == _budgets[i].category.id) {
              // as this is expense, add the used for this budget
              BudgetModel _newBudget = BudgetModel(
                  id: _budgets[i].id,
                  category: _budgets[i].category,
                  amount: _budgets[i].amount,
                  used: _budgets[i].used - txnInfo.amount,
                  status: _budgets[i].status,
                  currency: _budgets[i].currency);
              _budgets[i] = _newBudget;
              // break from for loop
              break;
            }
          }
          // now we can set the shared preferences of budget
          BudgetSharedPreferences.setBudget(txnInfo.wallet.currencyId, _refreshDay, _budgets);

          // only set the provider if only the current budget date is the same as the refresh day
          String _currentBudgetDate = BudgetSharedPreferences.getBudgetCurrent();
          if(_currentBudgetDate == _refreshDay) {
            Provider.of<HomeProvider>(context, listen: false).setBudgetList(_budgets);
          }
        });
      }

      if(txnInfo.type == "expense" || txnInfo.type == "income") {
        _futureIncomeExpense.then((incomeExpense) {
          Provider.of<HomeProvider>(context, listen: false).setIncomeExpense(txnInfo.wallet.currencyId, incomeExpense);
        });
      }

      // remove the loader
      Navigator.pop(context);
    }).onError((error, stackTrace) {
      // remove the loader
      Navigator.pop(context);

      debugPrint("Error on update information");
      throw new Exception(error.toString());
    });
  }

  Widget _getTotalIncomeExpense(List<TransactionListModel> _transactionData) {
    String _totalIncomeExpense = "";
    String _currencySymbol = "";
    double _totalAmount = 0;
    Color _textColor = textColor2;

    if(_userMe.defaultBudgetCurrency != null) {
      if(_transactionData.length > 0) {
        // compute the total amount
        // debugPrint(_transactionData.length.toString());
        //debugPrint("user me : " + _userMe.defaultBudgetCurrency.toString());
        _transactionData.forEach((_txn) {
          //debugPrint("Current Currency : " + _txn.wallet.currency + ", " + _txn.wallet.currencyId.toString());
          if(_txn.wallet.currencyId == _userMe.defaultBudgetCurrency) {
            //debugPrint("CCCC");
            if(_txn.type == "expense") {
              _totalAmount -= _txn.amount;
            }
            else if(_txn.type == "income") {
              _totalAmount += _txn.amount;
            }

            _currencySymbol = _txn.wallet.symbol;
          }
        });

        // format the amount
        _totalIncomeExpense = _currencySymbol + " " + fCCY.format(_totalAmount);

        // get the color
        if(_totalAmount < 0) {
          _textColor = accentColors[2];
        }
        else if (_totalAmount > 0) {
          _textColor = accentColors[6];
        }
      }
    }

    return Text(
      _totalIncomeExpense,
      style: TextStyle(
        fontSize: 12,
        color: _textColor,
      )
    );
  }
}
