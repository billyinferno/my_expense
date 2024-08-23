import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:my_expense/_index.g.dart';

class HomeList extends StatefulWidget {
  final VoidCallback userIconPress;
  final MyDateTimeCallback userDateSelect;

  const HomeList({
    super.key,
    required this.userIconPress,
    required this.userDateSelect}
  );

  @override
  State<HomeList> createState() => _HomeListState();
}

class _HomeListState extends State<HomeList> {
  final DateTime _firstDay = DateTime(2010, 1, 1);
  final DateTime _lastDay = DateTime(DateTime.now().year + 1, 12, 31);
  DateTime _currentFocusedDay = DateTime.now();

  String _appTitleMonth = "";
  String _appTitleYear = "";
  String _refreshDay = "";
  CalendarFormat _currentCalendarFormat = CalendarFormat.week;
  Icon _currentCalendarIcon = const Icon(Ionicons.caret_down, size: 10);

  final TransactionHTTPService _transactionHttp = TransactionHTTPService();
  final WalletHTTPService _walletHTTP = WalletHTTPService();
  final BudgetHTTPService _budgetHTTP = BudgetHTTPService();

  late Future<List<BudgetModel>> _futureBudgets;
  late Future<List<WalletModel>> _futureWallets;
  final ScrollController _scrollController = ScrollController();

  List<TransactionListModel> _transactionData = [];
  List<BudgetModel> _budgets = [];
  late UsersMeModel _userMe;
  late Future<bool> _getData;

  final fCCY = NumberFormat("#,##0.00", "en_US");

  @override
  void initState() {
    _userMe = UserSharedPreferences.getUserMe();

    _appTitleMonth = Globals.dfMMMM.format(_currentFocusedDay.toLocal());
    _appTitleYear = Globals.dfyyyy.format(_currentFocusedDay.toLocal());

    _getData = _refreshTransaction(_currentFocusedDay, true);

    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(
        title: InkWell(
          onTap: (() {
            // show the month selector
            _showCalendarPicker();
          }),
          onDoubleTap: (() {
            // go to the current date
            _setFocusedDay(
              DateTime(DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day)
            );

            // get the data
            _getData = _refreshTransaction(_currentFocusedDay);
          }),
          child: Container(
            width: double.infinity,
            color: Colors.transparent,
            child: Center(
              child: Container(
                color: Colors.transparent,
                child: Text(
                  "$_appTitleMonth $_appTitleYear",
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ),
        ),
        iconItem: const Icon(
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
            child: Container(
              decoration: const BoxDecoration(
                color: primaryDark,
              ),
              child: TableCalendar(
                focusedDay: _currentFocusedDay,
                firstDay: _firstDay,
                lastDay: _lastDay,
                calendarFormat: _currentCalendarFormat,
                onPageChanged: (focusedDay) {
                  _setFocusedDay(focusedDay);
                  _getData = _refreshTransaction(focusedDay);
                },
                selectedDayPredicate: (day) {
                  return isSameDate(day, _currentFocusedDay);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  if (!(isSameDate(selectedDay, _currentFocusedDay))) {
                    _setFocusedDay(selectedDay);
                    _getData = _refreshTransaction(selectedDay);
                  }
                },
                headerVisible: false,
                calendarBuilders: CalendarBuilders(
                  todayBuilder: (context, day, focusedDay) {
                    return Container(
                      alignment: Alignment.center,
                      child: Text(
                        Globals.dfd.format(day.toLocal()),
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
                  _currentCalendarIcon =
                      const Icon(Ionicons.caret_up, size: 10);
                } else {
                  _currentCalendarFormat = CalendarFormat.week;
                  _currentCalendarIcon =
                      const Icon(Ionicons.caret_down, size: 10);
                }
              });
            },
            child: Container(
              width: double.infinity,
              height: 15,
              decoration: const BoxDecoration(
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
            decoration: const BoxDecoration(
                border: Border(
              bottom: BorderSide(width: 1.0, color: primaryLight),
            )),
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text(
                    (isSameDate(_currentFocusedDay, DateTime.now())
                      ? "Today"
                      : Globals.dfddMMMMyyyy.format(_currentFocusedDay.toLocal())
                    ),
                    style: const TextStyle(
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
                          return _getTotalIncomeExpense(
                              homeProvider.transactionList);
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: _getData,
              builder: ((context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text("Error when get transaction list"),
                  );
                } else if (snapshot.hasData) {
                  return _generateView();
                } else {
                  // show loading
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SpinKitFadingCube(
                        color: accentColors[6],
                        size: 25,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const Text(
                        "loading...",
                        style: TextStyle(
                          color: textColor2,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  );
                }
              }),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCalendarPicker() async {
    await showDatePicker(
      context: context,
      initialDate: _currentFocusedDay,
      firstDate: _firstDay,
      lastDate: _lastDay,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: ((BuildContext context, Widget? child) {
        return Theme(
          data: Globals.themeData.copyWith(
            textTheme: const TextTheme(
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
            dialogBackgroundColor: secondaryBackground,
          ),
          child: child!,
        );
      }),
    ).then((newDate) {
      if (newDate != null) {
        _setFocusedDay(DateTime(newDate.toLocal().year, newDate.toLocal().month,
            newDate.toLocal().day));
        _getData = _refreshTransaction(_currentFocusedDay);
      }
    });
  }

  Widget _generateView() {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        _transactionData = homeProvider.transactionList;
        return GestureDetector(
          onHorizontalDragEnd: ((DragEndDetails details) {
            double velocity = (details.primaryVelocity ?? 0);
            if (velocity != 0) {
              if (velocity > 0) {
                // go to the previous day
                _setFocusedDay(
                    _currentFocusedDay.subtract(const Duration(days: 1)));
                _getData = _refreshTransaction(_currentFocusedDay);
              } else if (velocity < 0) {
                // go to the next day
                _setFocusedDay(_currentFocusedDay.add(const Duration(days: 1)));
                _getData = _refreshTransaction(_currentFocusedDay);
              }
            }
          }),
          child: (Container(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
            child: RefreshIndicator(
              color: accentColors[6],
              onRefresh: () async {
                _getData = _refreshTransaction(_currentFocusedDay, true);
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _scrollController,
                itemCount: _transactionData.length + 1,
                itemBuilder: (BuildContext ctx, int index) {
                  if (index < _transactionData.length) {
                    TransactionListModel txn = _transactionData[index];
                    return _generateListItem(index, txn, context);
                  } else {
                    return const SizedBox(
                      height: 30,
                    );
                  }
                },
              ),
            ),
          )),
        );
      },
    );
  }

  void _setFocusedDay(DateTime focusedDay) {
    setState(() {
      _currentFocusedDay = focusedDay;
      _appTitleMonth = Globals.dfMMMM.format(_currentFocusedDay.toLocal());
      _appTitleYear = Globals.dfyyyy.format(_currentFocusedDay.toLocal());

      // return back the selected date to the router
      widget.userDateSelect(_currentFocusedDay.toLocal());
    });
  }

  Widget _generateListItem(
      int index, TransactionListModel txn, BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.20,
        children: <Widget>[
          SlideButton(
            icon: Ionicons.trash,
            iconColor: textColor,
            bgColor: accentColors[2],
            text: 'Delete',
            onTap: () {
              late Future<bool?> result = ShowMyDialog(
                dialogTitle: "Delete Item",
                dialogText: "Do you want to delete ${txn.name}?",
                confirmText: "Delete",
                confirmColor: accentColors[2],
                cancelText: "Cancel")
              .show(context);

              // check the result of the dialog box
              result.then((value) async {
                if (value == true) {
                  await _deleteTransaction(txn);
                }
              });
            },
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/transaction/edit', arguments: txn);
        },
        child: _generateItem(txn),
      ),
    );
  }

  Widget _generateItem(TransactionListModel txn) {
    switch (txn.type.toLowerCase()) {
      case "expense":
        return MyItemList(
          height: 70,
          iconColor: IconColorList.getExpenseColor(txn.category!.name),
          icon: IconColorList.getExpenseIcon((txn.category!.name)),
          type: txn.type.toLowerCase(),
          title: txn.name,
          subTitle: "(${txn.wallet.name}) ${(txn.category!.name)}",
          symbol: txn.wallet.symbol,
          amount: txn.amount,
          amountColor: accentColors[2],
        );
      case "income":
        return MyItemList(
          height: 70,
          iconColor: IconColorList.getIncomeColor(txn.category!.name),
          icon: IconColorList.getIncomeIcon((txn.category!.name)),
          type: txn.type.toLowerCase(),
          title: txn.name,
          subTitle: "(${txn.wallet.name}) ${(txn.category!.name)}",
          symbol: txn.wallet.symbol,
          amount: txn.amount,
          amountColor: accentColors[6],
        );
      case "transfer":
        return MyItemList(
          height: 70,
          iconColor: accentColors[4],
          icon: const Icon(
            Ionicons.repeat,
            color: textColor,
          ),
          type: txn.type.toLowerCase(),
          title: '-',
          subTitle: "${txn.wallet.name} > ${txn.walletTo!.name}",
          symbol: txn.wallet.symbol,
          amount: txn.amount,
          amountColor: accentColors[4],
          symbolTo: txn.walletTo!.symbol,
          amountTo: (txn.amount * txn.exchangeRate),
        );
      default:
        return MyItemList(
          height: 70,
          iconColor: IconColorList.getExpenseColor(txn.category!.name),
          icon: IconColorList.getExpenseIcon((txn.category!.name)),
          type: txn.type.toLowerCase(),
          title: txn.name,
          subTitle: "(${txn.wallet.name}) ${(txn.category!.name)}",
          symbol: txn.wallet.symbol,
          amount: txn.amount,
          amountColor: accentColors[2],
        );
    }
  }

  Future<bool> _refreshTransaction(DateTime refreshDay, [bool? force]) async {
    bool isForce = (force ?? false);

    // store current transaction list date on shared preferences.
    // we can use this date when we perform edit, and if the date is not the same
    // as the current transaction list date, we don't need to refresh the provider.
    await TransactionSharedPreferences.setTransactionListCurrentDate(
        refreshDay.toLocal());

    String strRefreshDay =
        Globals.dfyyyyMMdd.format(refreshDay.toLocal());

    if (force ?? false) {
      Log.info(message: "🧺 Refresh Transaction $strRefreshDay (force)");
    }

    await _transactionHttp
        .fetchTransaction(strRefreshDay, isForce)
        .then((value) {
      // ensure that the selectedDate and the refreshDay is the same
      if (isSameDate(_currentFocusedDay, refreshDay) && mounted) {
        Provider.of<HomeProvider>(context, listen: false)
            .setTransactionList(value);
      }
    }).onError((error, stackTrace) {
      Log.error(
        message: "Error when refresh transaction",
        error: error,
        stackTrace: stackTrace,
      );
      throw Exception("Error when refresh transaction");
    });

    return true;
  }

  Future<void> _deleteTransaction(TransactionListModel txnDeleted) async {
    // show the loading screen
    LoadingScreen.instance().show(context: context);

    await _transactionHttp
        .deleteTransaction(context, txnDeleted)
        .then((_) async {
      if (mounted) {
        // pop the transaction from the provider
        Provider.of<HomeProvider>(context, listen: false)
            .popTransactionList(txnDeleted);

        // get the current transaction on the provider
        List<TransactionListModel> txnListModel =
            Provider.of<HomeProvider>(context, listen: false).transactionList;

        // save the current transaction on the provider to the shared preferences
        String date =
            Globals.dfyyyyMMdd.format(txnDeleted.date.toLocal());
        TransactionSharedPreferences.setTransaction(date, txnListModel);
      }

      // update information for txn delete
      await _updateInformation(txnDeleted);
    }).onError((error, stackTrace) {
      Log.error(
        message: "Error when delete",
        error: error,
        stackTrace: stackTrace,
      );
    }).whenComplete(() {
      // remove the loading screen
      LoadingScreen.instance().hide();
    });
  }

  Future<void> _updateInformation(TransactionListModel txnInfo) async {
    _refreshDay = Globals.dfyyyyMMdd.format(
        DateTime(txnInfo.date.toLocal().year, txnInfo.date.toLocal().month, 1));
    DateTime from;
    DateTime to;
    String fromString;
    String toString;

    // get the stat date
    (from, to) = TransactionSharedPreferences.getStatDate();

    // format the from and to string
    fromString = Globals.dfyyyyMMdd.format(from);
    toString = Globals.dfyyyyMMdd.format(to);

    // delete the transaction from wallet transaction
    await TransactionSharedPreferences.deleteTransactionWallet(
        txnInfo.wallet.id, _refreshDay, txnInfo);
    if (txnInfo.walletTo != null) {
      await TransactionSharedPreferences.deleteTransactionWallet(
          txnInfo.walletTo!.id, _refreshDay, txnInfo);
    }

    // delete the transaction from budget
    await WalletSharedPreferences.deleteWalletWorth(txnInfo);

    await Future.wait([
      _futureWallets = _walletHTTP.fetchWallets(true, true),
      _futureBudgets =
          _budgetHTTP.fetchBudgetDate(txnInfo.wallet.currencyId, _refreshDay),
    ]).then((_) {
      // update the wallets
      _futureWallets.then((wallets) {
        if (mounted) {
          Provider.of<HomeProvider>(context, listen: false)
              .setWalletList(wallets);
        }
      });

      // store the budgets list
      if (txnInfo.type == "expense") {
        _futureBudgets.then((value) {
          _budgets = value;
          // now loops thru budget, and see if the current category fits or not?
          for (int i = 0; i < _budgets.length; i++) {
            if (txnInfo.category!.id == _budgets[i].category.id) {
              // as this is expense, subtract total transaction and the amount
              BudgetModel newBudget = BudgetModel(
                  id: _budgets[i].id,
                  category: _budgets[i].category,
                  totalTransaction: (_budgets[i].totalTransaction - 1),
                  amount: _budgets[i].amount,
                  used: _budgets[i].used - txnInfo.amount,
                  status: _budgets[i].status,
                  currency: _budgets[i].currency);
              _budgets[i] = newBudget;
              // break from for loop
              break;
            }
          }
          // now we can set the shared preferences of budget
          BudgetSharedPreferences.setBudget(
              txnInfo.wallet.currencyId, _refreshDay, _budgets);

          // only set the provider if only the current budget date is the same as the refresh day
          String currentBudgetDate = BudgetSharedPreferences.getBudgetCurrent();
          if (currentBudgetDate == _refreshDay && mounted) {
            Provider.of<HomeProvider>(context, listen: false)
                .setBudgetList(_budgets);
          }
        });
      }
    }).onError((error, stackTrace) {
      Log.error(
        message: "Error on update information",
        error: error,
        stackTrace: stackTrace,
      );
      throw Exception(error.toString());
    });

    // check if the txn date is within the from and to of the stat date
    if (isWithin(txnInfo.date, from, to) &&
        (txnInfo.type == "expense" || txnInfo.type == "income")) {
      // fetch the income expense
      await _transactionHttp
          .fetchIncomeExpense(txnInfo.wallet.currencyId, from, to, true)
          .then((result) {
        if (mounted) {
          // put on the provider and notify the listener
          Provider.of<HomeProvider>(context, listen: false)
              .setIncomeExpense(txnInfo.wallet.currencyId, result);
        }
      }).onError((error, stackTrace) {
        Log.error(
          message: "Error on fetch income expense",
          error: error,
          stackTrace: stackTrace,
        );
        throw Exception(error.toString());
      });

      // fetch the top transaction
      await _transactionHttp
          .fetchTransactionTop(txnInfo.type, txnInfo.wallet.currencyId,
              fromString, toString, true)
          .then((transactionTop) {
        if (mounted) {
          // set the provide for this
          Provider.of<HomeProvider>(context, listen: false).setTopTransaction(
              txnInfo.wallet.currencyId, txnInfo.type, transactionTop);
        }
      }).onError(
        (error, stackTrace) {
          Log.error(
            message: "Error on fetch top transaction",
            error: error,
            stackTrace: stackTrace,
          );
          throw Exception(error.toString());
        },
      );
    }
  }

  Widget _getTotalIncomeExpense(List<TransactionListModel> transactionData) {
    String totalIncomeExpense = "";
    String currencySymbol = "";
    double totalAmount = 0;
    Color textColor = textColor2;

    if (_userMe.defaultBudgetCurrency != null) {
      if (transactionData.isNotEmpty) {
        // compute the total amount
        for (TransactionListModel txn in transactionData) {
          // if current wallet currency same as the default budget currectr
          if (txn.wallet.currencyId == _userMe.defaultBudgetCurrency) {
            // check the transaction type
            if (txn.type == "expense") {
              totalAmount -= txn.amount;
            } else if (txn.type == "income") {
              totalAmount += txn.amount;
            }

            // set the current currency symbol
            currencySymbol = txn.wallet.symbol;
          }
        }

        // format the amount
        totalIncomeExpense = "$currencySymbol ${fCCY.format(totalAmount)}";

        // get the color
        if (totalAmount < 0) {
          textColor = accentColors[2];
        } else if (totalAmount > 0) {
          textColor = accentColors[6];
        }
      }
    }

    return Text(totalIncomeExpense,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
        ));
  }
}
