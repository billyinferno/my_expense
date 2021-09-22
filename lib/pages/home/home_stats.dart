import 'package:flutter/material.dart';
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
import 'home_appbar.dart';

class HomeStats extends StatefulWidget {
  const HomeStats({Key? key}) : super(key: key);

  @override
  _HomeStatsState createState() => _HomeStatsState();
}

class _HomeStatsState extends State<HomeStats> {
  late List<CurrencyModel> _currencies;

  final fCCY = new NumberFormat("#,##0.00", "en_US");

  final WalletHTTPService walletHttp = WalletHTTPService();
  final TransactionHTTPService transactionHttp = TransactionHTTPService();

  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to = DateTime(DateTime.now().year, DateTime.now().month + 1, 1).subtract(Duration(days: 1));

  bool _isLoading = true;
  List<WorthModel> _worth = [];

  Map<int, IncomeExpenseModel> _incomeExpense = {};

  @override
  void initState() {
    super.initState();

    // get the currencies
    _currencies = WalletSharedPreferences.getWalletUserCurrency();
    if (_currencies.length > 0) {
      // only if we have currencies, then we will have wallet worth, otherwise
      // it's pointless to call the function.
      setLoading(true);
      _fetchWorth(_to, true).then((_) async {
        _currencies.forEach((ccy) async {
          await _fetchIncomeExpense(_from, _to, ccy, true);
        });
        setLoading(false);
      }).onError((error, stackTrace) {
        setLoading(false);
      });
    } else {
      // since no data, it means the _worth variable will be still empty
      // so just set the _isLoading is false.
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(
        title: Center(child: Text("Statistics")),
        onUserPress: () {
          Navigator.pushNamed(context, '/user');
        },
        iconItem: Icon(
          Ionicons.pie_chart,
          size: 20,
          color: (_currencies.length <= 0 ? secondaryDark : textColor),
        ),
        onActionPress: () {
          //debugPrint("Go to filter stats");
          if (_currencies.length > 0) {
            // navigate to stats filter
            Navigator.pushNamed(context, '/stats/filter');
          }
        },
      ),
      body: _generateBody(),
    );
  }

  IncomeExpenseModel _getData(IncomeExpenseModel? data) {
    if(data == null) {
      return IncomeExpenseModel(expense: {}, income: {});
    }
    else {
      // check if we got data on income and expense?
      if(data.expense.length > 0 && data.income.length > 0) {
        return data;
      }
      else {
        // check if expense got length?
        Map <DateTime, double> _exp = {};
        Map <DateTime, double> _inc = {};

        if(data.expense.length > 0) {
          _exp = data.expense;
        }
        if(data.income.length > 0) {
          _inc = data.income;
        }

        return IncomeExpenseModel(expense: _exp, income: _inc);
      }
    }
  }

  Widget _generateBody() {
    if (_isLoading) {
      // return the circle spinning as usual
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              child: SpinKitFadingCube(
            color: accentColors[6],
          )),
          SizedBox(
            height: 20,
          ),
          Text(
            "Loading Stats",
            style: TextStyle(
              color: textColor2,
              fontSize: 10,
            ),
          )
        ],
      ));
    } else {
      if (_worth.length > 0) {
        return Consumer<HomeProvider>(
          builder: ((context, homeProvider, child) {
            return GestureDetector(
              onHorizontalDragEnd: ((DragEndDetails details) {
                double _velocity = (details.primaryVelocity ?? 0);
                if(_velocity != 0) {
                  if(_velocity > 0) {
                    // go to the previous month
                    _goPrevMonth();
                  }
                  else if(_velocity < 0) {
                    // go to the next month
                    _goNextMonth();
                  }
                }
              }),
              child: Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
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
                              child: Icon(
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
                              child: Icon(
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
                          setLoading(true);
                          await _fetchWorth(_to, true).then((_) async {
                            _currencies.forEach((ccy) async {
                              await _fetchIncomeExpense(_from, _to, ccy, true);
                            });
                            setLoading(false);
                          }).onError((error, stackTrace) {
                            setLoading(false);
                          });
                        }),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: homeProvider.netWorth.length,
                          itemBuilder: ((context, index) {
                            return Container(
                              margin: EdgeInsets.fromLTRB(10, 0, 10, 10),
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
                            );
                          }),
                        ),
                      ),
                    ),
                    SizedBox(height: 25,),
                  ],
                ),
              ),
            );
          }),
        );
      } else {
        return Center(
          child: Text("No data to be displayed"),
        );
      }
    }
  }

  void _goPrevMonth() {
    _from = DateTime(_from.year, _from.month-1, 1);
    _to = DateTime(_to.year, _to.month, 1).subtract(Duration(days: 1));
    // debugPrint("BBBB : " + _from.toString());
    // debugPrint("BBBB : " + _to.toString());
    setLoading(true);
    if (_currencies.length > 0) {
      // only if we have currencies, then we will have wallet worth, otherwise
      // it's pointless to call the function.
      _fetchWorth(_to, true).then((_) async {
        _currencies.forEach((ccy) async {
          await _fetchIncomeExpense(_from, _to, ccy, true);
        });
        setLoading(false);
      }).onError((error, stackTrace) {
        setLoading(false);
      });
    }
    else {
      setLoading(false);
    }
  }

  void _goNextMonth() {
    // debugPrint("AAAA : " + _from.toString());
    // debugPrint("AAAA : " + (_to.month+1).toString());
    _from = DateTime(_from.year, _from.month+1, 1);
    _to = DateTime(_to.year, _to.month+2, 1).subtract(Duration(days: 1));
    // debugPrint("BBBB : " + _from.toString());
    // debugPrint("BBBB : " + _to.toString());
    setLoading(true);
    if (_currencies.length > 0) {
      // only if we have currencies, then we will have wallet worth, otherwise
      // it's pointless to call the function.
      _fetchWorth(_to, true).then((_) async {
        _currencies.forEach((ccy) async {
          await _fetchIncomeExpense(_from, _to, ccy, true);
        });
        setLoading(false);
      }).onError((error, stackTrace) {
        setLoading(false);
      });
    }
    else {
      setLoading(false);
    }
  }

  double _computeTotal(Map<DateTime, double> data) {
    double _ret = 0.0;

    data.forEach((key, value) {
      _ret = _ret + value;
    });

    return _ret;
  }

  double _computeAverage(Map<DateTime, double> data) {
    // check if we got data or not?
    if(data.length <= 0) {
      return 0;
    }

    double _ret = 0.0;
    double _num = 0;

    data.forEach((key, value) {
      _ret = _ret + value;
      _num = _num + 1;
    });

    return _ret/_num;
  }

  Widget _generateNetWorth(WorthModel worth) {
    double _amount = worth.walletsStartBalance + worth.walletsChangesAmount;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: secondaryBackground, width: 1.0)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: accentColors[6],
                ),
                child: FittedBox(child: Center(child: Text(worth.currenciesName))),
              ),
              SizedBox(
                width: 5,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(worth.currenciesDescription),
                    SizedBox(
                      height: 5,
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        worth.currenciesSymbol + " " + fCCY.format(_amount),
                        style: TextStyle(
                          color: (_amount >= 0 ? accentColors[6] : accentColors[2]),
                          fontSize: 20,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10,),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: secondaryLight, width: 1.0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: secondaryLight, width: 0.5)),
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
                          worth.currenciesSymbol + " " + fCCY.format(_incomeExpense[worth.currenciesId] != null ? _computeTotal((_incomeExpense[worth.currenciesId]!.income)) : 0.0),
                          style: TextStyle(
                            color: accentColors[6],
                          ),
                        ),
                        Text(
                          worth.currenciesSymbol + " " + fCCY.format(_incomeExpense[worth.currenciesId] != null ? _computeAverage((_incomeExpense[worth.currenciesId]!.income)) : 0.0),
                          style: TextStyle(
                            color: accentColors[6],
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
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
                          worth.currenciesSymbol + " " + fCCY.format(_incomeExpense[worth.currenciesId] != null ? _computeTotal((_incomeExpense[worth.currenciesId]!.expense)) : 0.0),
                          style: TextStyle(
                            color: accentColors[2],
                          ),
                        ),
                        Text(
                          worth.currenciesSymbol + " " + fCCY.format(_incomeExpense[worth.currenciesId] != null ? _computeAverage((_incomeExpense[worth.currenciesId]!.expense)) : 0.0),
                          style: TextStyle(
                            color: accentColors[2],
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
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
    //debugPrint("Set for currency : " + ccyId.toString() + " with expsne length : " + incomeExpense.expense.length.toString() + " and income length : " + incomeExpense.income.length.toString());
    setState(() {
      _incomeExpense[ccyId] = incomeExpense;
    });
  }

  void setLoading(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  Future<void> _fetchWorth(DateTime to, [bool? force]) async {
    Future<List<WorthModel>> _futureWorth;
    
    bool _force = (force ?? false);

    // get the data
    Future.wait([
      _futureWorth = walletHttp.fetchWalletsWorth(to, _force),
    ]).then((_) {
      _futureWorth.then((worth) {
        // set this worth
        setWorth(worth);

        // set the provider for net worth
        Provider.of<HomeProvider>(context, listen: false).setNetWorth(worth);
      });

      setLoading(false);
    }).onError((error, stackTrace) {
      debugPrint("Error on <_fetchWorth>");
      debugPrint(error.toString());
      setLoading(false);
    });
  }

  Future<void> _fetchIncomeExpense(DateTime from, DateTime to, CurrencyModel ccy, [bool? force]) async {
    Future<IncomeExpenseModel> _futureIncomeExpense;
    
    bool _force = (force ?? false);

    // get the data
    Future.wait([
      _futureIncomeExpense = transactionHttp.fetchIncomeExpense(ccy.id, from, to, _force),
    ]).then((_) {
      _futureIncomeExpense.then((incomeExpense) {
        setIncomeExpense(ccy.id, incomeExpense);

        // set the provider for income expense
        Provider.of<HomeProvider>(context, listen: false).setIncomeExpense(ccy.id, incomeExpense);
      });

      setLoading(false);
    }).onError((error, stackTrace) {
      debugPrint("Error on <_fetchIncomeExpense>");
      debugPrint(error.toString());
      setLoading(false);
    });
  }
}
