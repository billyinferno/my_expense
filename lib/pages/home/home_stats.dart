import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/api/transaction_api.dart';
import 'package:my_expense/api/wallet_api.dart';
import 'package:my_expense/model/currency_model.dart';
import 'package:my_expense/model/income_expense_model.dart';
import 'package:my_expense/model/transaction_top_model.dart';
import 'package:my_expense/model/users_me_model.dart';
import 'package:my_expense/model/worth_model.dart';
import 'package:my_expense/provider/home_provider.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/prefs/shared_user.dart';
import 'package:my_expense/utils/prefs/shared_wallet.dart';
import 'package:my_expense/widgets/appbar/home_appbar.dart';
import 'package:my_expense/widgets/calendar/month_prev_next_calendar.dart';
import 'package:my_expense/widgets/chart/bar_chart.dart';
import 'package:my_expense/widgets/item/item_list.dart';
import 'package:my_expense/widgets/item/simple_item.dart';
import 'package:provider/provider.dart';

enum PageName {
  expense, income, chart
}

class HomeStats extends StatefulWidget {
  const HomeStats({super.key});

  @override
  State<HomeStats> createState() => _HomeStatsState();
}

class _HomeStatsState extends State<HomeStats> {
  late List<CurrencyModel> _currencies;

  final _fCCY = NumberFormat("#,##0.00", "en_US");
  final _df = DateFormat('yyyy-MM-dd');

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

  final Map<int, IncomeExpenseModel> _incomeExpense = {};
  final Map<int, Map<PageName, List<TransactionTopModel>>> _transactionTop = {};
  final ScrollController _scrollController = ScrollController();
  final ScrollController _scrollControllerCurrencies = ScrollController();
  late Future<bool> _getStat;
  late UsersMeModel _userMe;

  final Map<PageName, Color> _resultPageColor = {
    PageName.chart: accentColors[4],
    PageName.expense: accentColors[2],
    PageName.income: accentColors[6],
  };
  PageName _resultPageName = PageName.chart;

  @override
  void initState() {
    // get the user information
    _userMe = UserSharedPreferences.getUserMe();

    // check if we got default currency id or not?
    _currentCurrencyId = (_userMe.defaultBudgetCurrency ?? -1);

    // initialize the from and to variable
    _from = DateTime(DateTime.now().year, DateTime.now().month, 1).toLocal();
    _to = DateTime(DateTime.now().year, DateTime.now().month + 1, 1).subtract(const Duration(days: 1)).toLocal();
    _fromString = _df.format(_from.toLocal());
    _toString = _df.format(_to.toLocal());
    
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
    _getStat = _fetchData();

    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
            return const Center(child: Text("Error when fetching statistic"),);
          }
          else if (snapshot.hasData) {
            return _generateBody();
          }
          else {
            return Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SpinKitFadingCube(
                  color: accentColors[6],
                ),
                const SizedBox(
                  height: 20,
                ),
                const Text(
                  "Loading Stats",
                  style: TextStyle(
                    color: textColor2,
                    fontSize: 10,
                  ),
                )
              ],
            ));
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              MonthPrevNextCalendar(
                initialDate: _from,
                onPress: ((from, to) {
                  // set the new from and to date
                  _from = from;
                  _to = to;

                  // set the current from and to string
                  _fromString = _df.format(_from.toLocal());
                  _toString = _df.format(_to.toLocal());

                  // fetch the statistic data again once we change the _from and _to date
                  _getStat = _fetchData();
                })
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Slidable(
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        extentRatio: 0.2,
                        children: <SlidableAction>[
                          SlidableAction(
                            label: 'Stat',
                            padding: const EdgeInsets.all(0),
                            foregroundColor: accentColors[3],
                            backgroundColor: secondaryDark,
                            icon: Ionicons.bar_chart,
                            onPressed: ((_) {
                              Navigator.pushNamed(context, '/stats/all', arguments: _currentCurrencyId);
                            })
                          ),
                        ],
                      ),
                      child: _worthBar(),
                    ),
                    const SizedBox(height: 10,),
                    Container(
                      padding: const EdgeInsets.all(10),
                      child: Center(
                        child: CupertinoSegmentedControl<PageName>(
                          selectedColor: (_resultPageColor[_resultPageName] ?? accentColors[9]),
                          // Provide horizontal padding around the children.
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          // This represents a currently selected segmented control.
                          groupValue: _resultPageName,
                          // Callback that sets the selected segmented control.
                          onValueChanged: (PageName value) {
                            setState(() {
                              _resultPageName = value;
                            });
                          },
                          children: const <PageName, Widget>{
                            PageName.chart: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Text('Chart'),
                            ),
                            PageName.expense: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Text('Expense'),
                            ),
                            PageName.income: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Text('Income'),
                            ),
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            _generateSubPage(),
                            const SizedBox(height: 30,),
                          ],
                        ),
                      ),
                    ),
                  ],
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

    return GestureDetector(
      onTap: (() {
        showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
          return Container(
            height: 300,
            color: secondaryDark,
            child: Column(
              children: <Widget>[
                Container(
                  height: 40,
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                  ),
                  child: const Expanded(
                    child: Center(child: Text("Currencies")),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: _scrollControllerCurrencies,
                    itemCount: _currencies.length,
                    itemBuilder: (BuildContext context, int index) {
                      return SimpleItem(
                        color: accentColors[6],
                        description: _currencies[index].description,
                        isSelected: (_currentCurrencyId == _currencies[index].id),
                        onTap: (() {
                          setState(() {
                            _currentCurrencyId = _currencies[index].id;
                            _currentCurrencySymbol = _currencies[index].symbol;
                            _changeCurrentWorth();
                          });
                          Navigator.pop(context);
                        }),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Text(_currencies[index].symbol.toUpperCase()),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20,),
              ],
            ),
          );
        });
      }),
      child: Container(
        color: secondaryDark,
        padding: const EdgeInsets.all(10),
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
                    "${_currentWorth.currenciesSymbol} ${_fCCY.format(amount)}",
                    style: TextStyle(
                      color: (amount >= 0 ? accentColors[6] : accentColors[2]),
                      fontSize: 20,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  Text(
                    "(${_fCCY.format(currentWorthIncome - currentWorthExpense)})",
                    style: TextStyle(
                      fontSize: 10,
                      color: (currentWorthIncome + currentWorthExpense < 0 ? accentColors[2] : accentColors[6]),
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
                              "${_currentWorth.currenciesSymbol} ${_fCCY.format(currentWorthIncome)}",
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
                              "${_currentWorth.currenciesSymbol} ${_fCCY.format(currentWorthExpense)}",
                              style: TextStyle(
                                color: accentColors[2],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
      case PageName.expense:
      case PageName.income:
        // during refresh, the transaction top might be empty so return sized
        // box shrink first until we got the data.
        if (_transactionTop.isEmpty) {
          return const SizedBox.shrink();
        }
        else {
          // check if we got the currency id for this or not?
          if (_transactionTop.containsKey(_currentCurrencyId)) {
            // got key, now check if we got the result page name or not?
            if (_transactionTop[_currentCurrencyId]!.containsKey(_resultPageName)) {
              // got data, let it flow!
            }
            else {
              // page name not yet generated, so return SizedBox
              return const SizedBox.shrink();
            }
          }
          else {
            // no key, just return as SizedBox
            return const SizedBox.shrink();
          }
        }

        ItemType type = ItemType.expense;
        if (_resultPageName == PageName.income) {
          type = ItemType.income;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: List<Widget>.generate(
            _transactionTop[_currentCurrencyId]![_resultPageName]!.length,
            ((index) {
              return ItemList(
                type: type,
                name: _transactionTop[_currentCurrencyId]![_resultPageName]![index].transactionName,
                walletName: _transactionTop[_currentCurrencyId]![_resultPageName]![index].transactionWalletName,
                walletSymbol: _currentCurrencySymbol,
                categoryName: _transactionTop[_currentCurrencyId]![_resultPageName]![index].transactionCategoryName,
                amount: _transactionTop[_currentCurrencyId]![_resultPageName]![index].transactionAmount
              );
            }),
          ),
        );
      case PageName.chart:
        return BarChart(
          from: _from,
          to: _to,
          data: (_getData(_incomeExpense[_currentCurrencyId])),
          needColapse: true,
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

  Future<bool> _fetchData([bool? isForce]) async {
    bool currentForce = (isForce ?? true);
    // check if the currencies is not empty
    if (_currencies.isNotEmpty) {
      // show debug print to knew that we will fetch data
      debugPrint("📈 Refresh Statistic $_from to $_to");

      // clear the current transaction top map
      _transactionTop.clear();

      // if currency is not empty, it means that we can calculate the worth
      // by calling the API and fetch income expense for each currency.
      await _fetchWorth(_to, currentForce).then((_) async {
        for(CurrencyModel ccy in _currencies) {
          await _fetchIncomeExpense(_from, _to, ccy, currentForce);
          await _fetchTopTransaction('expense', ccy.id, currentForce);
          await _fetchTopTransaction('income', ccy.id, currentForce);
        }
      }).onError((error, stackTrace) {
        debugPrint("Error on _fetchData");
        debugPrint(error.toString());
        debugPrintStack(stackTrace: stackTrace);
        throw Exception("Error when fetch statistic data");
      });
    }

    return true;
  }

  Future<void> _fetchWorth(DateTime to, [bool? force]) async {
    bool isForce = (force ?? false);

    // get the data
    await _walletHttp.fetchWalletsWorth(to, isForce).then((worth) {
      // set this worth
      _setWorth(worth);

      // set the provider for net worth
      Provider.of<HomeProvider>(context, listen: false).setNetWorth(worth);
    }).onError((error, stackTrace) {
      debugPrint("Error on <_fetchWorth>");
      debugPrint(error.toString());
      debugPrintStack(stackTrace: stackTrace);
      throw Exception("Error when fetching worth");
    },);
  }

  Future<void> _fetchIncomeExpense(DateTime from, DateTime to, CurrencyModel ccy, [bool? force]) async {
    bool isForce = (force ?? false);

    // get the data
    await _transactionHttp.fetchIncomeExpense(ccy.id, from, to, isForce).then((incomeExpense) {
      _incomeExpense[ccy.id] = incomeExpense;

      // set the provider for income expense
      Provider.of<HomeProvider>(context, listen: false).setIncomeExpense(ccy.id, incomeExpense);
    }).onError((error, stackTrace) {
      debugPrint("Error on <_fetchIncomeExpense>");
      debugPrint(error.toString());
      throw Exception("Error when fetching income/expense");
    },);
  }

  Future<void> _fetchTopTransaction(String type, int ccy, [bool? force]) async {
    bool isForce = (force ?? false);
    Map<PageName, List<TransactionTopModel>> currentTransactionTop = {};
    PageName pageName = PageName.expense;
    switch(type) {
      case "expense":
        pageName = PageName.expense;
        break;
      case "income":
        pageName = PageName.income;
        break; 
    }

    await _transactionHttp.fetchTransactionTop(type, ccy, _fromString, _toString, isForce).then((transactionTop) {
      // set the transaction top for this currency
      
      // check if currency already exists or not?
      if(_transactionTop.containsKey(ccy)) {
        // already there so we can just get this data first to check if we have
        // the page name or not?
        currentTransactionTop = _transactionTop[ccy]!;

        // regardless, just change the page name on the current transaction top
        // with the one we got from API.
        currentTransactionTop[pageName] = transactionTop;
      }
      else {
        // it means that ccy is not exists just add this data
        // first we create the currentTransactionTop
        currentTransactionTop[pageName] = transactionTop;

        // then add currentTransactionTop to _transactionTop
        _transactionTop[ccy] = currentTransactionTop;
      }
    }).onError((error, stackTrace) {
      debugPrint("Error on <_fetchTopTransaction>");
      debugPrint(error.toString());
      debugPrintStack(stackTrace: stackTrace);
      throw Exception("Error when fetching top transaction");
    },);
  }
}
