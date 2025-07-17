import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
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
  final DateTime _firstDay = DateTime(2010, 1, 1).toLocal();
  final DateTime _lastDay = DateTime(DateTime.now().year + 1, 12, 31).toLocal();
  DateTime _currentFocusedDay = DateTime.now().toLocal();

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

  List<BudgetModel> _budgets = [];
  late UsersMeModel _userMe;
  late Future<bool> _getData;

  @override
  void initState() {
    super.initState();

    _userMe = UserSharedPreferences.getUserMe();

    _appTitleMonth = Globals.dfMMMM.formatLocal(_currentFocusedDay);
    _appTitleYear = Globals.dfyyyy.formatLocal(_currentFocusedDay);

    _getData = _refreshTransaction(
      refreshDay: _currentFocusedDay,
      force: true
    );
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
              DateTime.now().day).toLocal()
            );

            // get the data
            _getData = _refreshTransaction(
              refreshDay: _currentFocusedDay,
              showLoading: true,
            );
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
      body: Consumer<HomeProvider>(builder: (context, homeProvider, child) {

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
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
                    _getData = _refreshTransaction(
                      refreshDay: focusedDay,
                      showLoading: true,
                    );
                  },
                  selectedDayPredicate: (day) {
                    return day.isSameDate(date: _currentFocusedDay);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    if (!(selectedDay.isSameDate(date: _currentFocusedDay))) {
                      _setFocusedDay(selectedDay);
                      _getData = _refreshTransaction(
                        refreshDay: selectedDay,
                        showLoading: true,
                      );
                    }
                  },
                  headerVisible: false,
                  calendarBuilders: CalendarBuilders(
                    todayBuilder: (context, day, focusedDay) {
                      return Container(
                        color: Colors.transparent,
                        alignment: Alignment.center,
                        child: Text(
                          Globals.dfd.formatLocal(day),
                          style: TextStyle(
                            color: accentColors[1],
                          ),
                        ),
                      );
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      if (focusedDay.isSameDate(date: DateTime.now())) {
                        return Container(
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: accentColors[1],
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            Globals.dfd.formatLocal(day),
                            style: TextStyle(
                              color: textColor,
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                  calendarStyle: CalendarStyle(
                    weekendTextStyle: TextStyle(color: accentColors[2]),
                  ),
                ),
              ),
            ),
            InkWell(
              splashColor: secondaryDark,
              onTap: () {
                setState(() {
                  if (_currentCalendarFormat == CalendarFormat.week) {
                    _currentCalendarFormat = CalendarFormat.month;
                    _currentCalendarIcon = const Icon(
                      Ionicons.caret_up,
                      size: 10
                    );
                  } else {
                    _currentCalendarFormat = CalendarFormat.week;
                    _currentCalendarIcon = const Icon(
                      Ionicons.caret_down,
                      size: 10
                    );
                  }
                });
              },
              child: Ink(
                width: double.infinity,
                height: 15,
                decoration: const BoxDecoration(
                  color: secondaryDark,
                ),
                child: Center(
                  child: _currentCalendarIcon,
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      (
                        _currentFocusedDay.isSameDate(date: DateTime.now()) ?
                        "Today" :
                        Globals.dfddMMMMyyyy.formatLocal(_currentFocusedDay)
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    _getTotalIncomeExpense(
                      transactionData: homeProvider.transactionList
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
                    return CommonErrorPage(
                      isNeedScaffold: false,
                      errorText: "Error when get transaction list",
                    );
                  } else if (snapshot.hasData) {
                    return _generateView(
                      transactions: homeProvider.transactionList
                    );
                  } else {
                    // show loading
                    return CommonLoadingPage(
                      isNeedScaffold: false,
                    );
                  }
                }),
              ),
            ),
          ],
        );
      },),
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
            dialogTheme: DialogThemeData(
              backgroundColor: secondaryBackground,
            ),
          ),
          child: child!,
        );
      }),
    ).then((newDate) {
      if (newDate != null) {
        _setFocusedDay(
          DateTime(
            newDate.toLocal().year,
            newDate.toLocal().month,
            newDate.toLocal().day,
          )..toLocal()
        );
        _getData = _refreshTransaction(
          refreshDay: _currentFocusedDay,
          showLoading: true,
        );
      }
    });
  }

  Widget _generateView({required List<TransactionListModel> transactions}) {
    return GestureDetector(
      onHorizontalDragEnd: ((DragEndDetails details) {
        double velocity = (details.primaryVelocity ?? 0);
        if (velocity != 0) {
          if (velocity > 0) {
            // go to the previous day
            _setFocusedDay(_currentFocusedDay.subtract(
              const Duration(days: 1))
            );
            _getData = _refreshTransaction(
              refreshDay: _currentFocusedDay,
              showLoading: true
            );
          } else if (velocity < 0) {
            // go to the next day
            _setFocusedDay(_currentFocusedDay.add(const Duration(days: 1)));
            _getData = _refreshTransaction(
              refreshDay: _currentFocusedDay,
              showLoading: true,
            );
          }
        }
      }),
      child: (Container(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
        child: RefreshIndicator(
          color: accentColors[6],
          onRefresh: () async {
            _getData = _refreshTransaction(
              refreshDay: _currentFocusedDay,
              force: true,
              showLoading: true,
            );
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: _scrollController,
            itemCount: transactions.length + 1,
            itemBuilder: (BuildContext ctx, int index) {
              if (index < transactions.length) {
                TransactionListModel txn = transactions[index];
                return _generateListItem(
                  index: index,
                  txn: txn,
                  context: context
                );
              } else {
                return const SizedBox(height: 30,);
              }
            },
          ),
        ),
      )),
    );
  }

  void _setFocusedDay(DateTime focusedDay) {
    setState(() {
      _currentFocusedDay = focusedDay;
      _appTitleMonth = Globals.dfMMMM.formatLocal(_currentFocusedDay);
      _appTitleYear = Globals.dfyyyy.formatLocal(_currentFocusedDay);

      // return back the selected date to the router
      widget.userDateSelect(_currentFocusedDay.toLocal());
    });
  }

  Widget _generateListItem({
    required int index,
    required TransactionListModel txn,
    required BuildContext context
  }) {
    return Slidable(
      key: Key("${txn.id}_${txn.wallet.id}_${txn.type}"),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.40,
        dismissible: DismissiblePane(
          onDismissed: () async {
            // if dismissed then delete the transaction
            await _deleteTransaction(txnDeleted: txn);
          },
          confirmDismiss: () async {
            return await ShowMyDialog(
              dialogTitle: "Delete Item",
              dialogText: "Do you want to delete ${txn.name}?",
              confirmText: "Delete",
              confirmColor: accentColors[2],
              cancelText: "Cancel")
            .show(context) ?? false;
          },
        ),
        children: <Widget>[
          SlideButton(
            icon: Ionicons.copy,
            iconColor: textColor,
            bgColor: accentColors[3],
            text: 'Duplicate',
            onTap: () {
              Navigator.pushNamed(
                context, '/transaction/add',
                arguments: TransactionAddArgs(
                  date: (TransactionSharedPreferences.getTransactionListCurrentDate() ?? DateTime.now()).toLocal(),
                  transaction: txn,
                ),
              );
            },
          ),
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
                  await _deleteTransaction(txnDeleted: txn);
                }
              });
            },
          ),
        ],
      ),
      child: _generateItem(txn),
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
          onTap: () {
            Navigator.pushNamed(context, '/transaction/edit', arguments: txn);
          },
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
          onTap: () {
            Navigator.pushNamed(context, '/transaction/edit', arguments: txn);
          },
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
          onTap: () {
            Navigator.pushNamed(context, '/transaction/edit', arguments: txn);
          },
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
          onTap: () {
            Navigator.pushNamed(context, '/transaction/edit', arguments: txn);
          },
        );
    }
  }

  Future<bool> _refreshTransaction({
    required DateTime refreshDay,
    bool force = false,
    bool showLoading = false,
  }) async {
    // check if we need to show the loading screen or not?
    if (showLoading) {
      LoadingScreen.instance().show(context: context);
    }

    // store current transaction list date on shared preferences.
    // we can use this date when we perform edit, and if the date is not the same
    // as the current transaction list date, we don't need to refresh the provider.
    await TransactionSharedPreferences.setTransactionListCurrentDate(
      date: refreshDay.toLocal()
    );

    String strRefreshDay = Globals.dfyyyyMMdd.formatLocal(refreshDay);

    if (force) {
      Log.info(message: "🧺 Refresh Transaction $strRefreshDay (force)");
    }

    await _transactionHttp.fetchTransaction(
      date: strRefreshDay,
      force: force,
    ).then((value) {
      // ensure that the selectedDate and the refreshDay is the same
      if (_currentFocusedDay.isSameDate(date: refreshDay) && mounted) {
        Provider.of<HomeProvider>(
          context,
          listen: false
        ).setTransactionList(transactions: value);
      }
    }).onError((error, stackTrace) {
      Log.error(
        message: "Error when refresh transaction",
        error: error,
        stackTrace: stackTrace,
      );
      throw Exception("Error when refresh transaction");
    }).whenComplete(() {
      LoadingScreen.instance().hide();
    },);

    return true;
  }

  Future<void> _deleteTransaction({
    required TransactionListModel txnDeleted
  }) async {
    // show the loading screen
    LoadingScreen.instance().show(context: context);

    await _transactionHttp.deleteTransaction(txn: txnDeleted).then((_) async {
      if (mounted) {
        // pop the transaction from the provider
        Provider.of<HomeProvider>(
          context,
          listen: false
        ).popTransactionList(transaction: txnDeleted);

        // get the current transaction on the provider
        List<TransactionListModel> txnListModel = Provider.of<HomeProvider>(
          context,
          listen: false
        ).transactionList;

        // save the current transaction on the provider to the shared preferences
        String date = Globals.dfyyyyMMdd.formatLocal(txnDeleted.date);
        TransactionSharedPreferences.setTransaction(
          date: date,
          txn: txnListModel
        );
      }

      // update information for txn delete
      await _updateInformation(txnInfo: txnDeleted);
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

  Future<void> _updateInformation({
    required TransactionListModel txnInfo
  }) async {
    _refreshDay = Globals.dfyyyyMMdd.formatLocal(
      DateTime(
        txnInfo.date.toLocal().year,
        txnInfo.date.toLocal().month,
        1
      ).toLocal()
    );

    DateTime from;
    DateTime to;
    String fromString;
    String toString;

    // get the stat date
    (from, to) = TransactionSharedPreferences.getStatDate();

    // format the from and to string
    fromString = Globals.dfyyyyMMdd.formatLocal(from);
    toString = Globals.dfyyyyMMdd.formatLocal(to);

    // delete the transaction from wallet transaction
    await TransactionSharedPreferences.deleteTransactionWallet(
      walletId: txnInfo.wallet.id,
      date: _refreshDay,
      txn: txnInfo
    );

    if (txnInfo.walletTo != null) {
      await TransactionSharedPreferences.deleteTransactionWallet(
        walletId: txnInfo.walletTo!.id,
        date: _refreshDay,
        txn: txnInfo
      );
    }

    // delete the transaction from budget
    await WalletSharedPreferences.deleteWalletWorth(txn: txnInfo);

    await Future.wait([
      _futureWallets = _walletHTTP.fetchWallets(
        showDisabled: true,
        force: true,
      ),
      _futureBudgets = _budgetHTTP.fetchBudgetDate(
        currencyID: txnInfo.wallet.currencyId,
        date: _refreshDay
      ),
    ]).then((_) {
      // update the wallets
      _futureWallets.then((wallets) {
        if (mounted) {
          Provider.of<HomeProvider>(
            context,
            listen: false
          ).setWalletList(wallets: wallets);
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
                useForDaily: _budgets[i].useForDaily,
                status: _budgets[i].status,
                currency: _budgets[i].currency,
              );

              _budgets[i] = newBudget;
              // break from for loop
              break;
            }
          }
          // now we can set the shared preferences of budget
          BudgetSharedPreferences.setBudget(
            ccyId: txnInfo.wallet.currencyId,
            date: _refreshDay,
            budgets: _budgets
          );

          // only set the provider if only the current budget date is the same as the refresh day
          String currentBudgetDate = BudgetSharedPreferences.getBudgetCurrent();
          if (currentBudgetDate == _refreshDay && mounted) {
            Provider.of<HomeProvider>(
              context,
              listen: false
            ).setBudgetList(budgets: _budgets);
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
    if (
      txnInfo.date.isWithin(from: from, to: to) &&
      (txnInfo.type == "expense" || txnInfo.type == "income")
    ) {
      // fetch the income expense
      await _transactionHttp.fetchIncomeExpense(
        ccyId: txnInfo.wallet.currencyId,
        from: from,
        to: to,
        force: true,
      ).then((result) {
        if (mounted) {
          // put on the provider and notify the listener
          Provider.of<HomeProvider>(
            context,
            listen: false
          ).setIncomeExpense(
            ccyId: txnInfo.wallet.currencyId,
            data: result
          );
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
      await _transactionHttp.fetchTransactionTop(
        type: txnInfo.type,
        ccy: txnInfo.wallet.currencyId,
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
            ccy: txnInfo.wallet.currencyId,
            type: txnInfo.type,
            data: transactionTop
          );
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

  Widget _getTotalIncomeExpense({
    required List<TransactionListModel> transactionData
  }) {
    List<Widget> children = [];
    final SplayTreeMap <int, Tuple<String, double>> totalAmount = SplayTreeMap<int, Tuple<String, double>>();
    Tuple<String, double> currentData;
    double currentAmount;

    // loop thru transaction data to calculate each income expense amount
    if (transactionData.isNotEmpty) {
      // compute the total amount
      for (TransactionListModel txn in transactionData) {
        // ensure we only process expense and income transaction only
        if (txn.type == 'expense' || txn.type == 'income') {
          // get current amount from the total amount map
          currentData = (totalAmount[txn.wallet.currencyId] ?? Tuple<String, double>(item1: txn.wallet.symbol, item2: 0));
          currentAmount = currentData.item2;

          // check the transaction type
          if (txn.type == "expense") {
            currentAmount -= txn.amount;
          } else if (txn.type == "income") {
            currentAmount += txn.amount;
          }

          // stored the current amount to total amount map
          totalAmount[txn.wallet.currencyId] = Tuple<String, double>(
            item1: txn.wallet.symbol,
            item2: currentAmount,
          );
        }
      }

      // ensure total amount is not empty before we processing to create the
      // widget for flip flap text
      if (totalAmount.isNotEmpty) {
        // check if we got default budget currency or not?
        if (_userMe.defaultBudgetCurrency != null) {
          // if got then we put this as the first widget list
          if (totalAmount.containsKey(_userMe.defaultBudgetCurrency)) {
            // get the data
            currentData = totalAmount[_userMe.defaultBudgetCurrency]!;
            
            // generate the widget here
            children.add(_incomeExpenseText(
              currency: currentData.item1,
              amount: currentData.item2,
            ));

            // remove the data from total amount map
            totalAmount.remove(_userMe.defaultBudgetCurrency);
          }
        }

        // loop thru the total amount map
        totalAmount.forEach((key, data) {
          // generate the widget here
          children.add(_incomeExpenseText(
            currency: data.item1,
            amount: data.item2,
          ));
        },);
      }
    }

    return FlipFlapText(
      children: children,
    );
  }

  Widget _incomeExpenseText({
    required String currency,
    required double amount
  }) {
    Color color = textColor;
    String text = "$currency ${Globals.fCCY.format(amount)}";

    // get the color
    if (amount < 0) {
      color = accentColors[2];
    } else if (amount > 0) {
      color = accentColors[6];
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: color,
      )
    );
  }
}
