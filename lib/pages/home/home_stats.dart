import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:my_expense/_index.g.dart';

class HomeStats extends StatefulWidget {
  const HomeStats({super.key});

  @override
  State<HomeStats> createState() => _HomeStatsState();
}

class _HomeStatsState extends State<HomeStats> {
  late List<CurrencyModel> _currencies;

  final WalletHTTPService _walletHttp = WalletHTTPService();
  final TransactionHTTPService _transactionHttp = TransactionHTTPService();

  late DateTime _from;
  late DateTime _to;
  late String _fromString;
  late String _toString;

  List<WorthModel> _worth = [];
  late WorthModel _currentWorth;
  late int _currentCurrencyId;
  late String _currentCurrencySymbol;
  late double _currentMaxAmount;

  final Map<int, IncomeExpenseModel> _incomeExpense = {};
  final Map<int, Map<String, List<TransactionTopModel>>> _transactionTop = {};
  final Map<int, double> _maxBudget = {};
  final ScrollController _scrollControllerChart = ScrollController();
  final ScrollController _scrollControllerExpense = ScrollController();
  final ScrollController _scrollControllerIncome = ScrollController();
  final ScrollController _scrollControllerCurrencies = ScrollController();
  late Future<bool> _getStat;
  late bool _clampToBudget;
  late UsersMeModel _userMe;

  late DateTime _minTxnDate;
  late DateTime _maxTxnDate;

  final Map<String, TypeSlideItem> _resultPageItem = {
    'chart': TypeSlideItem(
      color: accentColors[4],
      text: 'Chart',
      textColor: Colors.white.withValues(alpha: 0.7),
    ),
    'expense': TypeSlideItem(
      color: accentColors[2],
      text: 'Expense',
      textColor: Colors.white.withValues(alpha: 0.7),
    ),
    'income': TypeSlideItem(
      color: accentColors[6],
      text: 'Income',
      textColor: Colors.white.withValues(alpha: 0.7),
    ),
  };
  String _resultPageName = 'chart';

  @override
  void initState() {
    super.initState();

    // get the user information
    _userMe = UserSharedPreferences.getUserMe();

    // check if we got default currency id or not?
    _currentCurrencyId = (_userMe.defaultBudgetCurrency ?? -1);

    // initialize the from and to variable
    DateTime currentDate = DateTime.now().toLocal();
    _from = DateTime(currentDate.year, currentDate.month, 1).toLocal();
    _to = DateTime(currentDate.year, currentDate.month + 1, 1).subtract(const Duration(days: 1)).toLocal();
    _fromString = Globals.dfyyyyMMdd.formatLocal(_from);
    _toString = Globals.dfyyyyMMdd.formatLocal(_to);
    
    // get the currencies
    _currencies = WalletSharedPreferences.getWalletUserCurrency();
    // ensure that _currentCurrencyID is there, if not then default it to 0
    if (_currencies.isNotEmpty) {
      // loop thru currencies
      _currentCurrencySymbol = "";
      for(int i=0; i<_currencies.length; i++) {
        // check if _currentCurrencyID is the same or not?
        if (_currentCurrencyId == _currencies[i].id) {
          _currentCurrencySymbol = _currencies[i].symbol;
        }
      }

      // check if _currentCurrencySymbol is empty or not?
      if (_currentCurrencySymbol.isEmpty) {
        // means that default currency is wrong, reset it to 0
        _currentCurrencyId = _currencies[0].id;
        _currentCurrencySymbol = _currencies[0].symbol;
      }
    }

    // get the min and max transaction date
    _minTxnDate = TransactionSharedPreferences.getTransactionMinDate();
    _maxTxnDate = TransactionSharedPreferences.getTransactionMaxDate();

    // force the fetch data when the page is loaded, this is to ensure we
    // are getting the latest data from server.
    _getStat = _fetchData(isForce: true);

    // default clamp to budget to false, and max amount as 0
    _clampToBudget = false;
    _currentMaxAmount = 0;
  }

  @override
  void dispose() {
    _scrollControllerChart.dispose();
    _scrollControllerExpense.dispose();
    _scrollControllerIncome.dispose();
    _scrollControllerCurrencies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(
        title: const Center(child: Text("Statistics")),
        onUserPress: () {
          Navigator.pushNamed(context, '/user');
        },
        iconItem: Icon(
          Ionicons.pie_chart,
          size: 20,
          color: (_currencies.isEmpty ? secondaryDark : textColor),
        ),
        onActionPress: () {
          if (_currencies.isNotEmpty) {
            // navigate to stats filter
            Navigator.pushNamed(context, '/stats/filter');
          }
        },
      ),
      body: FutureBuilder(
        future: _getStat,
        builder: ((context, snapshot) {
          if (snapshot.hasError) {
            return CommonErrorPage(
              isNeedScaffold: false,
              errorText: "Error when fetching statistic",
            );
          }
          else if (snapshot.hasData) {
            return _generateBody();
          }
          else {
            return CommonLoadingPage(
              isNeedScaffold: false,
            );
          }
        }),
      ),
    );
  }

  IncomeExpenseModel _getData(IncomeExpenseModel? data) {
    if(data == null) {
      return IncomeExpenseModel(expense: {}, income: {});
    }
    else {
      // check if we got data on income and expense?
      if(data.expense.isNotEmpty && data.income.isNotEmpty) {
        return data;
      }
      else {
        // check if expense got length?
        Map <DateTime, double> exp = {};
        Map <DateTime, double> inc = {};

        if(data.expense.isNotEmpty) {
          exp = data.expense;
        }
        if(data.income.isNotEmpty) {
          inc = data.income;
        }

        return IncomeExpenseModel(expense: exp, income: inc);
      }
    }
  }

  Widget _generateBody() {
    if (_worth.isNotEmpty) {
      return Consumer<HomeProvider>(
        builder: ((context, homeProvider, child) {
          // loop thru income expense in home provide to get the data
          _incomeExpense.clear();
          homeProvider.incomeExpense.forEach((ccy, data) {
            _incomeExpense[ccy] = data;
          });

          // put the top transaction
          _transactionTop.clear();
          homeProvider.topTransaction.forEach((ccy, data) {
            _transactionTop[ccy] = data;
          });

          // loop thru the 
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              MonthPrevNextCalendar(
                minDate: _minTxnDate,
                maxDate: _maxTxnDate,
                initialDate: _from,
                onDateChange: ((from, to) {
                  // set the new from and to date
                  _from = from;
                  _to = to;
          
                  // set the current from and to string
                  _fromString = Globals.dfyyyyMMdd.formatLocal(_from);
                  _toString = Globals.dfyyyyMMdd.formatLocal(_to);

                  // stored the from and to on the shared preferences
                  TransactionSharedPreferences.setStatDate(from: from, to: to);
          
                  // fetch the statistic data again once we change the _from and _to date
                  _getStat = _fetchData(showDialog: true);
                })
              ),
              Container(
                color: secondaryDark,
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Slidable(
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        extentRatio: 0.35,
                        children: <Widget>[
                          SlideButton(
                            icon: Ionicons.analytics,
                            iconColor: accentColors[3],
                            text: 'Stats',
                            textColor: accentColors[3],
                            textSize: 10,
                            onTap: () {
                              Navigator.pushNamed(context, '/stats/all', arguments: _currentCurrencyId);
                            },
                          ),
                          SlideButton(
                            icon: Ionicons.refresh,
                            iconColor: accentColors[6],
                            text: 'Refresh',
                            textColor: accentColors[6],
                            textSize: 10,
                            onTap: () {
                              _getStat = _fetchData(showDialog: true);
                            },
                          ),
                        ],
                      ),
                      child: _worthBar(),
                    ),
                    const SizedBox(height: 5,),
                    Visibility(
                      visible: ((_maxBudget[_currentCurrencyId] ?? 0) > 0),
                      child: GestureDetector(
                        onTap: (() {
                          setState(() {
                            _clampToBudget = !_clampToBudget;
                            if (_clampToBudget) {
                              _currentMaxAmount = (_maxBudget[_currentCurrencyId] ?? 0);
                            }
                            else {
                              _currentMaxAmount = 0;
                            }
                          });
                        }),
                        child: Container(
                          color: Colors.transparent,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(
                                height: 20,
                                width: 30,
                                child: Transform.scale(
                                  scale: 0.7,
                                  child: CupertinoSwitch(
                                    value: _clampToBudget,
                                    activeTrackColor: accentColors[0],
                                    onChanged: (value) {
                                      setState(() {
                                        _clampToBudget = value;
                                        if (_clampToBudget) {
                                          _currentMaxAmount = (_maxBudget[_currentCurrencyId] ?? 0);
                                        }
                                        else {
                                          _currentMaxAmount = 0;
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 11,),
                              Text(
                                "Clamp to avg daily budget ($_currentCurrencySymbol ${Globals.fCCY.format(_maxBudget[_currentCurrencyId] ?? 0)})",
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: textColor,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5,),
              Container(
                padding: const EdgeInsets.all(10),
                child: Center(
                  child: SizedBox(
                    width: (100 * _resultPageItem.length).toDouble(),
                    child: TypeSlide<String>(
                      onValueChanged: ((String value) {
                        setState(() {
                          _resultPageName = value;
                        });
                      }),
                      items: _resultPageItem,
                      initialItem: _resultPageName,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: (() async {
                    _getStat = _fetchData(showDialog: true);
                  }),
                  color: accentColors[0],
                  child: _generateSubPage(),
                ),
              ),
            ],
          );
        }),
      );
    } else {
      return const Center(
        child: Text("No data to be displayed"),
      );
    }
  }

  Widget _worthBar() {
    double amount = _currentWorth.walletsStartBalance + _currentWorth.walletsChangesAmount;
    double currentWorthIncome = (_incomeExpense[_currentWorth.currenciesId] != null ? _computeTotal((_incomeExpense[_currentWorth.currenciesId]!.income)) : 0.0);
    double currentWorthExpense = (_incomeExpense[_currentWorth.currenciesId] != null ? _computeTotal((_incomeExpense[_currentWorth.currenciesId]!.expense)) : 0.0);
    double currentWorthExpensePositive = currentWorthExpense.makePositive();
    double totalCurrentWorth = currentWorthIncome - currentWorthExpense;

    // calculate income and expense flex
    int incomeFlex = 0;
    int expenseFlex = 0;
    if (currentWorthIncome + currentWorthExpensePositive > 0) {
      incomeFlex = ((currentWorthIncome / (currentWorthIncome + currentWorthExpensePositive)) * 100).toInt();
      expenseFlex = ((currentWorthExpensePositive / (currentWorthIncome + currentWorthExpensePositive)) * 100).toInt();
    }

    return GestureDetector(
      onTap: (() {
        // check if user have more than 1 currencies?
        if (_currencies.length > 1) {
          // if so, then show the bottom sheet
          showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext context) {
              return MyBottomSheet(
                context: context,
                title: "Currencies",
                screenRatio: 0.35,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: _scrollControllerCurrencies,
                  itemCount: _currencies.length,
                  itemBuilder: (BuildContext context, int index) {
                    return SimpleItem(
                      color: accentColors[6],
                      title: _currencies[index].description,
                      isSelected: (_currentCurrencyId == _currencies[index].id),
                      onTap: (() {
                        setState(() {
                          _currentCurrencyId = _currencies[index].id;
                          _currentCurrencySymbol = _currencies[index].symbol;
                          if (_clampToBudget) {
                            _currentMaxAmount = (_maxBudget[_currencies[index].id] ?? 0);
                          }
                          else {
                            _currentMaxAmount = 0;
                          }
                          _changeCurrentWorth();
                        });
                        Navigator.pop(context);
                      }),
                      icon: FittedBox(
                        fit: BoxFit.contain,
                        child: Text(_currencies[index].symbol.toUpperCase()),
                      ),
                    );
                  },
                ),
              );
            }
          );
        }
      }),
      child: Container(
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                color: accentColors[6],
              ),
              child: FittedBox(child: Center(child: Text(_currentWorth.currenciesName))),
            ),
            const SizedBox(width: 10,),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text(_currentWorth.currenciesDescription),
                  Text(
                    "${_currentWorth.currenciesSymbol} ${Globals.fCCY.format(amount)}",
                    style: TextStyle(
                      color: (amount >= 0 ? accentColors[6] : accentColors[2]),
                      fontSize: 20,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  Text(
                    "(${Globals.fCCY.format(totalCurrentWorth)})",
                    style: TextStyle(
                      fontSize: 10,
                      color: (totalCurrentWorth < 0 ? accentColors[2] : accentColors[6]),
                    ),
                  ),
                  const SizedBox(height: 5,),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              "Income",
                              style: TextStyle(
                                fontSize: 10,
                                color: textColor,
                              ),
                            ),
                            Text(
                              "${_currentWorth.currenciesSymbol} ${Globals.fCCY.format(currentWorthIncome)}",
                              style: TextStyle(
                                color: accentColors[6],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              "Expense",
                              style: TextStyle(
                                fontSize: 10,
                                color: textColor,
                              ),
                            ),
                            Text(
                              "${_currentWorth.currenciesSymbol} ${Globals.fCCY.format(currentWorthExpense)}",
                              style: TextStyle(
                                color: accentColors[2],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5,),
                  Visibility(
                    visible: ((incomeFlex + expenseFlex) > 0),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: secondaryBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Visibility(
                            visible: (incomeFlex > 0),
                            child: Expanded(
                              flex: incomeFlex,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: accentColors[6],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: (expenseFlex > 0),
                            child: Expanded(
                              flex: expenseFlex,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: accentColors[2],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5,),
            const SizedBox(
              height: 20,
              child: Icon(
                  Ionicons.chevron_down_circle
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _generateSubPage() {
    switch(_resultPageName) {
      case 'expense':
      case 'income':
        // during refresh, the transaction top might be empty so return sized
        // box shrink first until we got the data.
        if (_transactionTop.isEmpty) {
          return const Center(child: Text("Fetching data"),);
        }
        else {
          // check if we got the currency id for this or not?
          if (_transactionTop.containsKey(_currentCurrencyId)) {
            // got key, now check if we got the result page name or not?
            if (_transactionTop[_currentCurrencyId]!.containsKey(_resultPageName)) {
              // got data, check if the data is empty or not?
              if (_transactionTop[_currentCurrencyId]![_resultPageName]!.isEmpty) {
                // data for this, return no data
                return const Center(child: Text("No data"),);
              }
            }
            else {
              // page name not yet generated, so return SizedBox
              return const Center(child: Text("Fetching data"),);
            }
          }
          else {
            // no key, just return as SizedBox
            return const Center(child: Text("Fetching data"),);
          }
        }

        String type = 'expense';
        if (_resultPageName == 'income') {
          type = 'income';
        }

        if (type == 'expense') {
          return SingleChildScrollView(
            controller: _scrollControllerExpense,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: List<Widget>.generate(
                    _transactionTop[_currentCurrencyId]![_resultPageName]!.length,
                    ((index) {
                      return MyItemList(
                        height: 70,
                        iconColor: IconColorList.getExpenseColor(_transactionTop[_currentCurrencyId]![_resultPageName]![index].transactionCategoryName),
                        icon: IconColorList.getExpenseIcon(_transactionTop[_currentCurrencyId]![_resultPageName]![index].transactionCategoryName),
                        type: type,
                        title: _transactionTop[_currentCurrencyId]![_resultPageName]![index].transactionName,
                        subTitle: "(${_transactionTop[_currentCurrencyId]![_resultPageName]![index].transactionWalletName}) ${_transactionTop[_currentCurrencyId]![_resultPageName]![index].transactionCategoryName}",
                        symbol: _currentCurrencySymbol,
                        amount: _transactionTop[_currentCurrencyId]![_resultPageName]![index].transactionAmount,
                        amountColor: accentColors[2],
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 30,),
              ],
            ),
          );
        }
        else {
          return SingleChildScrollView(
            controller: _scrollControllerIncome,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: List<Widget>.generate(
                    _transactionTop[_currentCurrencyId]![_resultPageName]!.length,
                    ((index) {
                      return MyItemList(
                        height: 70,
                        iconColor: IconColorList.getIncomeColor(_transactionTop[_currentCurrencyId]![_resultPageName]![index].transactionCategoryName),
                        icon: IconColorList.getIncomeIcon(_transactionTop[_currentCurrencyId]![_resultPageName]![index].transactionCategoryName),
                        type: type,
                        title: _transactionTop[_currentCurrencyId]![_resultPageName]![index].transactionName,
                        subTitle: "(${_transactionTop[_currentCurrencyId]![_resultPageName]![index].transactionWalletName}) ${_transactionTop[_currentCurrencyId]![_resultPageName]![index].transactionCategoryName}",
                        symbol: _currentCurrencySymbol,
                        amount: _transactionTop[_currentCurrencyId]![_resultPageName]![index].transactionAmount,
                        amountColor: accentColors[6],
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 30,),
              ],
            ),
          );
        }
      case 'chart':
        if (_incomeExpense[_currentCurrencyId] == null) {
          // no data for this, so return no data
          return const Center(child: Text("No data"),);
        }
        else {
          // check if we got data on the expense and income or not
          if (_incomeExpense[_currentCurrencyId]!.expense.isEmpty && _incomeExpense[_currentCurrencyId]!.income.isEmpty) {
            // no data for this, so return no data
            return const Center(child: Text("No data"),);
          }
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollControllerChart,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    BarChart(
                      from: _from.toLocal(),
                      to: _to.toLocal(),
                      data: (_getData(_incomeExpense[_currentCurrencyId])),
                      showed: true,
                      maxAmount: _currentMaxAmount,
                    ),
                    const SizedBox(height: 30,),
                  ],
                ),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  double _computeTotal(Map<DateTime, double> data) {
    double ret = 0.0;

    data.forEach((key, value) {
      ret = ret + value;
    });

    return ret;
  }

  void _setWorth(List<WorthModel> worth) {
    setState(() {
      _worth = worth;

      // default the current worth into index 0
      _currentWorth = _worth[0];
      _changeCurrentWorth();
    });
  }

  void _changeCurrentWorth() {
    // check if we have current currency or not?
    if (_currentCurrencyId != -1) {
      // loop thru the worth to see which one is have the same currency ID
      for(int i=0; i<_worth.length; i++) {
        if (_worth[i].currenciesId == _currentCurrencyId) {
          _currentWorth = _worth[i];
        }   
      }
    }
  }

  Future<bool> _fetchData({
    bool isForce = true,
    bool showDialog = false
  }) async {
    List<BudgetModel> currentBudget = [];
    double maxBudget = 0;
    String currentDateString = Globals.dfyyyyMMdd.formatLocal(
      DateTime(
        DateTime.now().year,
        DateTime.now().month,
        1
      )
    );

    // check if the currencies is not empty
    if (_currencies.isNotEmpty) {
      // check if we need to showed loading screen
      if (showDialog) {
        LoadingScreen.instance().show(context: context);
      }

      // show debug print to knew that we will fetch data
      Log.info(message: "📈 Refresh Statistic $_from to $_to");

      // clear the current transaction top map
      _transactionTop.clear();

      // if currency is not empty, it means that we can calculate the worth
      // by calling the API and fetch income expense for each currency.
      await _fetchWorth(_to, isForce).then((_) async {
        // loop thru all the currency in the currencies
        for(CurrencyModel ccy in _currencies) {
          // fetch the stats information
          await Future.wait([
            _fetchIncomeExpense(_from, _to, ccy, isForce),
            _fetchTopTransaction('expense', ccy.id, isForce),
            _fetchTopTransaction('income', ccy.id, isForce),
          ]).then((_) {
            // show success fetching
            Log.success(message: "📈 Refresh statisctic for CCY: ${ccy.name}");
            
            // try to get the budget data for this currencies
            // we can use the from to get the budget date
            currentBudget = (BudgetSharedPreferences.getBudget(
              ccyId: ccy.id,
              date: currentDateString
            ) ?? []);

            // default the max budget to 0 first
            maxBudget = 0;

            // check if currentBudget is not empty
            if (currentBudget.isNotEmpty) {
              // loop thru the current budget to get the budget
              for(BudgetModel budget in currentBudget) {
                if (budget.useForDaily) {
                  maxBudget += budget.amount;
                }
              }
            }

            // once finished add max budget to the max budget map divide by
            // as this is assume as monthly budget, we will times this 12 first
            // then divide by 365 to actually get the daily budget
            _maxBudget[ccy.id] = (maxBudget * 12) / 365;
          });
        }
      }).onError((error, stackTrace) {
        Log.error(
          message: "Error on _fetchData",
          error: error,
          stackTrace: stackTrace,
        );

        // check the loader dialog
        if (showDialog && mounted) {
          Navigator.pop(context);
        }
        throw Exception("Error when fetch statistic data");
      }).whenComplete(() {
        // remove the loading dialog if we showed it
        if (showDialog) {
          LoadingScreen.instance().hide();
        }
      },);
    }

    return true;
  }

  Future<void> _fetchWorth(DateTime to, [bool? force]) async {
    bool isForce = (force ?? false);

    // get the data
    await _walletHttp.fetchWalletsWorth(
      to: to,
      force: isForce
    ).then((worth) {
      Log.success(message: "💯 fetching wallet worth");
      // set this worth
      _setWorth(worth);

      if (mounted) {
        // set the provider for net worth
        Provider.of<HomeProvider>(context, listen: false).setNetWorth(worth: worth);
      }
    }).onError((error, stackTrace) {
      Log.error(
        message: "Error on <_fetchWorth>",
        error: error,
        stackTrace: stackTrace,
      );
      throw Exception("Error when fetching worth");
    },);
  }

  Future<void> _fetchIncomeExpense(DateTime from, DateTime to, CurrencyModel ccy, [bool? force]) async {
    bool isForce = (force ?? false);

    // get the data
    await _transactionHttp.fetchIncomeExpense(
      ccyId: ccy.id,
      from: from,
      to: to,
      force: isForce
    ).then((incomeExpense) {
      if (mounted) {
        // set the provider for income expense
        Provider.of<HomeProvider>(context, listen: false).setIncomeExpense(
          ccyId: ccy.id,
          data: incomeExpense
        );
      }
    }).onError((error, stackTrace) {
      Log.error(
        message: "Error on <_fetchIncomeExpense>",
        error: error,
        stackTrace: stackTrace,
      );
      throw Exception("Error when fetching income/expense");
    },);
  }

  Future<void> _fetchTopTransaction(String type, int ccy, [bool? force]) async {
    bool isForce = (force ?? false);
    await _transactionHttp.fetchTransactionTop(
      type: type,
      ccy: ccy,
      from: _fromString,
      to: _toString,
      force: isForce
    ).then((transactionTop) {
      if (mounted) {
        // set the provide for this
        Provider.of<HomeProvider>(
          context,
          listen: false
        ).setTopTransaction(
          ccy: ccy,
          type: type,
          data: transactionTop
        );
      }
    }).onError((error, stackTrace) {
      Log.error(
        message: "Error on <_fetchTopTransaction>",
        error: error,
        stackTrace: stackTrace,
      );
      throw Exception("Error when fetching top transaction");
    },);
  }
}
