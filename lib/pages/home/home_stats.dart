import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/api/transaction_api.dart';
import 'package:my_expense/api/wallet_api.dart';
import 'package:my_expense/model/currency_model.dart';
import 'package:my_expense/model/income_expense_model.dart';
import 'package:my_expense/model/worth_model.dart';
import 'package:my_expense/provider/home_provider.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/prefs/shared_wallet.dart';
import 'package:my_expense/widgets/chart/bar_chart.dart';
import 'package:provider/provider.dart';
import '../../widgets/appbar/home_appbar.dart';

class HomeStats extends StatefulWidget {
  const HomeStats({super.key});

  @override
  State<HomeStats> createState() => _HomeStatsState();
}

class _HomeStatsState extends State<HomeStats> {
  late List<CurrencyModel> _currencies;

  final _fCCY = NumberFormat("#,##0.00", "en_US");

  final WalletHTTPService _walletHttp = WalletHTTPService();
  final TransactionHTTPService _transactionHttp = TransactionHTTPService();

  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1).toLocal();
  DateTime _to = DateTime(DateTime.now().year, DateTime.now().month + 1, 1).subtract(const Duration(days: 1)).toLocal();

  List<WorthModel> _worth = [];

  final Map<int, IncomeExpenseModel> _incomeExpense = {};
  final ScrollController _scrollController = ScrollController();
  late Future<bool> _getStat;

  @override
  void initState() {
    super.initState();

    // get the currencies
    _currencies = WalletSharedPreferences.getWalletUserCurrency();
    _getStat = _fetchData();
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
      body: Expanded(
        child: FutureBuilder(
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
          return GestureDetector(
            onHorizontalDragEnd: ((DragEndDetails details) {
              double velocity = (details.primaryVelocity ?? 0);
              if(velocity != 0) {
                if(velocity > 0) {
                  // go to the previous month
                  _goPrevMonth();
                }
                else if(velocity < 0) {
                  // go to the next month
                  _goNextMonth();
                }
              }
            }),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                  height: 35,
                  width: double.infinity,
                  color: secondaryDark,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      InkWell(
                        onTap: (() {
                          // change the date
                          _goPrevMonth();
                        }),
                        child: Container(
                          color: Colors.transparent,
                          width: 50,
                          height: 35,
                          child: const Icon(
                            Ionicons.arrow_back_circle,
                            size: 20,
                            color: textColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: Colors.transparent,
                          child: Center(child: Text(DateFormat("MMMM yyyy").format(_from)),),
                        ),
                      ),
                      InkWell(
                        onTap: (() {
                          _goNextMonth();
                        }),
                        child: Container(
                          color: Colors.transparent,
                          width: 50,
                          height: 35,
                          child: const Icon(
                            Ionicons.arrow_forward_circle,
                            size: 20,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: accentColors[6],
                    onRefresh: (() async {
                      _getStat = _fetchData();
                    }),
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: homeProvider.netWorth.length + 1,
                      itemBuilder: ((context, index) {
                        if (index < homeProvider.netWorth.length) {
                          return Slidable(
                            endActionPane: ActionPane(
                              motion: const DrawerMotion(),
                              extentRatio: 0.2,
                              children: <SlidableAction>[
                                SlidableAction(
                                  label: 'Stat',
                                  padding: const EdgeInsets.all(0),
                                  foregroundColor: accentColors[3],
                                  backgroundColor: primaryBackground,
                                  icon: Ionicons.bar_chart,
                                  onPressed: ((_) {
                                    Navigator.pushNamed(context, '/stats/all', arguments: homeProvider.netWorth[index].currenciesId);
                                  })
                                ),
                              ],
                            ),
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                              decoration: BoxDecoration(
                                color: secondaryDark,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  _generateNetWorth(homeProvider.netWorth[index]),
                                  BarChart(
                                    from: _from,
                                    to: _to,
                                    data: (_getData(homeProvider.incomeExpense[homeProvider.netWorth[index].currenciesId])),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        else {
                          // add padding on bottom
                          return const SizedBox(height: 30,);
                        }
                      }),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      );
    } else {
      return const Center(
        child: Text("No data to be displayed"),
      );
    }
  }

  void _goPrevMonth() {
    _from = DateTime(_from.year, _from.month-1, 1).toLocal();
    _to = DateTime(_to.year, _to.month, 1).subtract(const Duration(days: 1)).toLocal();
    
    // fetch the statistic data again once we change the _from and _to date
    _getStat = _fetchData();
  }

  void _goNextMonth() {
    _from = DateTime(_from.year, _from.month+1, 1);
    _to = DateTime(_to.year, _to.month+2, 1).subtract(const Duration(days: 1));

    // fetch the statistic data again once we change the _from and _to date
    _getStat = _fetchData();
  }

  double _computeTotal(Map<DateTime, double> data) {
    double ret = 0.0;

    data.forEach((key, value) {
      ret = ret + value;
    });

    return ret;
  }

  Widget _generateNetWorth(WorthModel worth) {
    double amount = worth.walletsStartBalance + worth.walletsChangesAmount;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: secondaryBackground, width: 1.0)),
      ),
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
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
                  child: FittedBox(child: Center(child: Text(worth.currenciesName))),
                ),
                const SizedBox(
                  width: 5,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(worth.currenciesDescription),
                      Text(
                        "${worth.currenciesSymbol} ${_fCCY.format(amount)}",
                        style: TextStyle(
                          color: (amount >= 0 ? accentColors[6] : accentColors[2]),
                          fontSize: 20,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10,),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: secondaryBackground, width: 1.0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: secondaryBackground, width: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "Income",
                          style: TextStyle(
                            color: accentColors[6],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${worth.currenciesSymbol} ${_fCCY.format(_incomeExpense[worth.currenciesId] != null ? _computeTotal((_incomeExpense[worth.currenciesId]!.income)) : 0.0)}",
                          style: TextStyle(
                            color: accentColors[6],
                          ),
                        ),
                      ],
                    ),
                  )
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: secondaryLight, width: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "Expense",
                          style: TextStyle(
                            color: accentColors[2],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${worth.currenciesSymbol} ${_fCCY.format(_incomeExpense[worth.currenciesId] != null ? _computeTotal((_incomeExpense[worth.currenciesId]!.expense)) : 0.0)}",
                          style: TextStyle(
                            color: accentColors[2],
                          ),
                        ),
                      ],
                    ),
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void setWorth(List<WorthModel> worth) {
    setState(() {
      _worth = worth;
    });
  }

  void setIncomeExpense(int ccyId, IncomeExpenseModel incomeExpense) {
    setState(() {
      _incomeExpense[ccyId] = incomeExpense;
    });
  }

  Future<bool> _fetchData([bool? isForce]) async {
    bool currentForce = (isForce ?? true);
    // check if the currencies is not empty
    if (_currencies.isNotEmpty) {
      // if currency is not empty, it means that we can calculate the worth
      // by calling the API and fetch income expense for each currency.
      await _fetchWorth(_to, true).then((_) async {
        for(CurrencyModel ccy in _currencies) {
          await _fetchIncomeExpense(_from, _to, ccy, currentForce);
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
    Future<List<WorthModel>> futureWorth;
    
    bool isForce = (force ?? false);

    // get the data
    Future.wait([
      futureWorth = _walletHttp.fetchWalletsWorth(to, isForce),
    ]).then((_) {
      futureWorth.then((worth) {
        // set this worth
        setWorth(worth);

        // set the provider for net worth
        Provider.of<HomeProvider>(context, listen: false).setNetWorth(worth);
      });
    }).onError((error, stackTrace) {
      debugPrint("Error on <_fetchWorth>");
      debugPrint(error.toString());
      throw Exception("Error when fetching worth");
    });
  }

  Future<void> _fetchIncomeExpense(DateTime from, DateTime to, CurrencyModel ccy, [bool? force]) async {
    Future<IncomeExpenseModel> futureIncomeExpense;
    
    bool isForce = (force ?? false);

    // get the data
    Future.wait([
      futureIncomeExpense = _transactionHttp.fetchIncomeExpense(ccy.id, from, to, isForce),
    ]).then((_) {
      futureIncomeExpense.then((incomeExpense) {
        setIncomeExpense(ccy.id, incomeExpense);

        // set the provider for income expense
        Provider.of<HomeProvider>(context, listen: false).setIncomeExpense(ccy.id, incomeExpense);
      });
    }).onError((error, stackTrace) {
      debugPrint("Error on <_fetchIncomeExpense>");
      debugPrint(error.toString());
      throw Exception("Error when fetching income/expense");
    });
  }
}
