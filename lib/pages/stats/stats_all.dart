import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';
import 'package:my_expense/widgets/page/common_loading_page.dart';

class StatsAllPage extends StatefulWidget {
  final Object? ccy;
  const StatsAllPage({super.key, this.ccy});

  @override
  State<StatsAllPage> createState() => _StatsAllPageState();
}

class _StatsAllPageState extends State<StatsAllPage> {
  final WalletHTTPService _walletHTTP = WalletHTTPService();
  final Map<String, TypeSlideItem> _typeSlideItem = {
    "m": TypeSlideItem(color: accentColors[2], text: "Monthly"),
    "y": TypeSlideItem(color: accentColors[0], text: "Yearly"),
  };

  final Map<String, double> _walletListIncomeMonthly = {};
  final Map<String, double> _walletListExpenseMonthly = {};
  final Map<String, double> _walletListTotalMonthly = {};
  final Map<String, double> _walletListIncomeYearly = {};
  final Map<String, double> _walletListExpenseYearly = {};
  final Map<String, double> _walletListTotalYearly = {};
  late String _graphType;

  late Future<bool> _getData;
  late WalletStatAllModel _walletStatAll;
  late WalletStatAllModel _origWalletStatAllMonthly;
  late WalletStatAllModel _origWalletStatAllReverseMonthly;
  late WalletStatAllModel _origWalletStatAllYearly;
  late WalletStatAllModel _origWalletStatAllReverseYearly;
  late double _maxAmount;
  late double _maxAmountMonthly;
  late double _maxAmountYearly;
  late double _totalIncome;
  late int _countIncome;
  late double _totalExpense;
  late int _countExpense;
  late int _ccy;

  // multiline chart data
  late List<Map<String, double>> _walletLineChartData;
  late List<Color> _walletLineChartColors;
  late int _dateOffset;
  late DateTime _minDate;
  late DateTime _maxDate;
  late Map<DateTime, bool> _walletDateRange;

  late bool _sortAscending;
  late bool _showTotal;
  late bool _showIncome;
  late bool _showExpense;

  @override
  void initState() {
    super.initState();

    // get the current ccy
    _ccy = widget.ccy as int;

    // init the wallet list into empty list
    _walletLineChartData = [];
    _walletLineChartColors = [accentColors[5], accentColors[0], accentColors[2]];
    _totalIncome = 0;
    _countIncome = 0;
    _totalExpense = 0;
    _countExpense = 0;
    _dateOffset = 0;
    _maxAmount = 0;
    _maxAmountMonthly = 0;
    _maxAmountYearly = 0;

    // default the min and max date for the multiline chart data
    _walletDateRange = {};
    _minDate = DateTime.now().add(const Duration(days: -1));
    _maxDate = DateTime.now();

    // default sort into descending, so we can get the latest data on the top
    // of the list view
    _sortAscending = false;

    // default show total, income, and expense into true
    _showTotal = true;
    _showIncome = true;
    _showExpense = true;

    // default graph type to monthly
    _graphType = "m";

    // get the data from API
    _getData = _getWalletStatAllData();
  }

  @override
  Widget build(BuildContext context) {
    return _generateBody();
  }

  Widget _generateBody() {
    return FutureBuilder(
      future: _getData,
      builder: ((context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Center(
                  child: Icon(
                    Ionicons.warning,
                    color: Colors.red,
                    size: 25,
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                Center(
                  child: Text("Unable to load data from API"),
                )
              ],
            ),
          );
        } else if (snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: Center(child: Text("Stat For ${_walletStatAll.ccy}")),
              leading: IconButton(
                icon: const Icon(Ionicons.close_outline, color: textColor),
                onPressed: (() {
                  Navigator.pop(context);
                }),
              ),
              actions: <Widget>[
                InkWell(
                  onTap: (() {
                    // set the sorting to inverse
                    _sortAscending = !_sortAscending;
                    _sortWalletStat();
                  }),
                  child: SizedBox(
                    width: 50,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          (_sortAscending
                              ? Ionicons.arrow_up
                              : Ionicons.arrow_down),
                          color: textColor,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              (_sortAscending ? "A" : "Z"),
                              style: const TextStyle(
                                fontSize: 12,
                                color: textColor,
                              ),
                            ),
                            Text(
                              (_sortAscending ? "Z" : "A"),
                              style: const TextStyle(
                                fontSize: 12,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            body: MySafeArea(
              child: _generateBarChart()
            ),
          );
        } else {
          return CommonLoadingPage(
            isNeedScaffold: true,
            loadingText: 'Loading stats data...',
          );
        }
      }),
    );
  }

  Widget _generateBarChart() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 5),
            child: TypeSlide<String>(
              onValueChanged: (value) {
                setState(() {
                  _graphType = value;
                  _setGraphData();
                });
              },
              items: _typeSlideItem,
              initialItem: _graphType,
            ),
          ),
          MultiLineChart(
            data: _walletLineChartData,
            color: _walletLineChartColors,
            height: 200,
            dateOffset: _dateOffset,
            addBottomPadd: false,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Transform.scale(
                    scale: 0.7,
                    child: CupertinoSwitch(
                      value: _showTotal,
                      activeTrackColor: accentColors[5],
                      onChanged: ((value) {
                        setState(() {
                          _showTotal = value;
                          _setGraphData();
                        });
                      }),
                    ),
                  ),
                  Text(
                    "Net Worth",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                    ),
                  )
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Transform.scale(
                    scale: 0.7,
                    child: CupertinoSwitch(
                      value: _showIncome,
                      activeTrackColor: accentColors[0],
                      onChanged: ((value) {
                        setState(() {
                          _showIncome = value;
                          _setGraphData();
                        });
                      }),
                    ),
                  ),
                  Text(
                    "Income",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                    ),
                  )
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Transform.scale(
                    scale: 0.7,
                    child: CupertinoSwitch(
                      value: _showExpense,
                      activeTrackColor: accentColors[2],
                      onChanged: ((value) {
                        setState(() {
                          _showExpense = value;
                          _setGraphData();
                        });
                      }),
                    ),
                  ),
                  Text(
                    "Expense",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                    ),
                  )
                ],
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                SummaryBox(
                  color: accentColors[0],
                  text: "Income",
                  value: Globals.fCCY.format(_totalIncome),
                  count: _countIncome,
                ),
                const SizedBox(width: 10,),
                SummaryBox(
                  color: accentColors[2],
                  text: "Expense",
                  value: Globals.fCCY.format(_totalExpense),
                  count: _countExpense
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Expanded(
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _walletStatAll.data.length,
              itemBuilder: ((context, index) {
                return BarStat(
                  income: _walletStatAll.data[index].income,
                  expense: _walletStatAll.data[index].expense,
                  balance: _walletStatAll.data[index].balance,
                  maxAmount: _maxAmount,
                  date: _walletStatAll.data[index].date,
                  dateFormat: (
                    _graphType == "m" ? Globals.dfyyyyMM : Globals.dfyyyy
                  ),
                  showIncome: _showIncome,
                  showExpense: _showExpense,
                  showBalance: _showTotal,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _getStatData() {
    double total = 0;

    // clear all wallet list map
    _walletListIncomeMonthly.clear();
    _walletListExpenseMonthly.clear();
    _walletListTotalMonthly.clear();

    _walletListIncomeYearly.clear();
    _walletListExpenseYearly.clear();
    _walletListTotalYearly.clear();

    // loop thru _walletStat and get the maximum data
    _maxAmountMonthly = double.infinity * -1;

    // loop thru all the stat all date to add as key on the wallet list income
    // expense, and total
    _walletDateRange.forEach((key, value) {
      // create date range for monthly data
      _walletListIncomeMonthly[Globals.dfMMyy.formatLocal(key)] = 0;
      _walletListExpenseMonthly[Globals.dfMMyy.formatLocal(key)] = 0;
      _walletListTotalMonthly[Globals.dfMMyy.formatLocal(key)] = 0;

      // create date range for yearly data
      _walletListIncomeYearly[Globals.dfyyyy.formatLocal(key)] = 0;
      _walletListExpenseYearly[Globals.dfyyyy.formatLocal(key)] = 0;
      _walletListTotalYearly[Globals.dfyyyy.formatLocal(key)] = 0;
    });

    String yearlyKey = "";
    double yearlyAmount = 0;
    for (Datum data in _origWalletStatAllMonthly.data) {
      // generate the wallet list income, expense, and total monthly
      _walletListIncomeMonthly[Globals.dfMMyy.formatLocal(data.date)] = (data.income ?? 0);
      _walletListExpenseMonthly[Globals.dfMMyy.formatLocal(data.date)] = (data.expense ?? 0);

      total += (data.diff ?? 0);
      _walletListTotalMonthly[Globals.dfMMyy.formatLocal(data.date)] = total;

      _totalIncome += data.income!;
      _totalExpense += data.expense!;

      if (data.income! > data.expense!) {
        _countIncome += 1;
      } else if (data.income! < data.expense!) {
        _countExpense += 1;
      }

      if (data.income! > _maxAmountMonthly) {
        _maxAmountMonthly = data.income!;
      }
      if (data.expense! > _maxAmountMonthly) {
        _maxAmountMonthly = data.expense!;
      }
      if (data.balance! > _maxAmountMonthly) {
        _maxAmountMonthly = data.balance!;
      }

      // generate the wallet list income, expense, and total yearly
      yearlyKey = Globals.dfyyyy.formatLocal(data.date);
      // income yearly
      yearlyAmount = (_walletListIncomeYearly[yearlyKey] ?? 0);
      yearlyAmount += (data.income ?? 0);
      _walletListIncomeYearly[yearlyKey] = yearlyAmount;

      // expense yearly
      yearlyAmount = (_walletListExpenseYearly[yearlyKey] ?? 0);
      yearlyAmount += (data.expense ?? 0);
      _walletListExpenseYearly[yearlyKey] = yearlyAmount;

      // total yearly
      _walletListTotalYearly[yearlyKey] = total;
    }

    // now create the max amount yearly based on the wallet list income and
    // expense yearly.
    _maxAmountYearly = double.infinity * -1;
    _walletListIncomeYearly.forEach((key, value) {
      if (_maxAmountYearly < value) {
        _maxAmountYearly = value;
      }
    },);
    _walletListExpenseYearly.forEach((key, value) {
      if (_maxAmountYearly < value) {
        _maxAmountYearly = value;
      }
    },);

    // set graph data based on selection
    _setGraphData();
  }

  void _setGraphData() {
    // clear current chart data
    _walletLineChartData.clear();
    _walletLineChartColors.clear();

    // select the graph type
    if (_graphType == "m") {
      // set the wallet list data to the _walletList data
      if (_showTotal) {
        _walletLineChartData.add(_walletListTotalMonthly);
        _walletLineChartColors.add(accentColors[5]);
      }

      if (_showIncome) {
        _walletLineChartData.add(_walletListIncomeMonthly);
        _walletLineChartColors.add(accentColors[0]);
      }

      if (_showExpense) {
        _walletLineChartData.add(_walletListExpenseMonthly);
        _walletLineChartColors.add(accentColors[2]);
      }

      _dateOffset = _walletListTotalMonthly.length ~/ 8;

      // check whether this is ascending or descending
      if (_sortAscending) {
        _walletStatAll = _origWalletStatAllMonthly;
      }
      else {
        _walletStatAll = _origWalletStatAllReverseMonthly;
      }

      _maxAmount = _maxAmountMonthly;
    }
    else {
      if (_showTotal) {
        _walletLineChartData.add(_walletListTotalYearly);
        _walletLineChartColors.add(accentColors[5]);
      }

      if (_showIncome) {
        _walletLineChartData.add(_walletListIncomeYearly);
        _walletLineChartColors.add(accentColors[0]);
      }

      if (_showExpense) {
        _walletLineChartData.add(_walletListExpenseYearly);
        _walletLineChartColors.add(accentColors[2]);
      }

      _dateOffset = _walletListTotalYearly.length ~/ 8;

      // check whether this is ascending or descending
      if (_sortAscending) {
        _walletStatAll = _origWalletStatAllYearly;
      }
      else {
        _walletStatAll = _origWalletStatAllReverseYearly;
      }

      _maxAmount = _maxAmountYearly;
    }
  }

  Future<bool> _getWalletStatAllData() async {
    try {
      // perform the get company detail information here
      await _walletHTTP.getAllStat(ccy: _ccy).then((resp) {
        // copy the response to company detail data
        _origWalletStatAllMonthly = resp[0];
        _origWalletStatAllReverseMonthly = WalletStatAllModel(
          ccy: resp[0].ccy,
          symbol: resp[0].symbol,
          data: resp[0].data.reversed.toList(),
        );

        // generate the yearly data, we can do this by loop thru the data
        // and create new Datum list
        Datum? newData;
        Map<String, Datum> yearlyData = {};
        String key;
        for(Datum data in _origWalletStatAllMonthly.data) {
          key = Globals.dfyyyy.formatLocal(data.date);
          // check if key exists in yearly data or not?
          if (yearlyData.containsKey(key)) {
            newData = yearlyData[key];
            newData = Datum(
              date: data.date,
              balance: (data.balance ?? 0),
              diff: (data.diff ?? 0),
              expense: (newData?.expense ?? 0) + (data.expense ?? 0),
              income: (newData?.income ?? 0) + (data.income ?? 0),
            );
          }
          else {
            newData = data;
          }

          // put newData to the map
          yearlyData[key] = newData;
        }

        // once map is generated, we can convert the map and put it to list
        // of Datum
        List<Datum> yearlyList = [];
        yearlyData.forEach((key, value) {
          yearlyList.add(value);
        },);

        // once that finished, we can create the _origWalletStatYearly data
        _origWalletStatAllYearly = WalletStatAllModel(
          ccy: resp[0].ccy,
          symbol: resp[0].symbol,
          data: yearlyList,
        );

        _origWalletStatAllReverseYearly = WalletStatAllModel(
          ccy: resp[0].ccy,
          symbol: resp[0].symbol,
          data: yearlyList.reversed.toList(),
        );

        if (_origWalletStatAllMonthly.data.isNotEmpty) {
          _minDate = DateTime(
            _origWalletStatAllMonthly.data[0].date.year,
            _origWalletStatAllMonthly.data[0].date.month,
            1
          );
          
          _maxDate = DateTime(
            _origWalletStatAllMonthly.data[_origWalletStatAllMonthly.data.length - 1].date.year,
            _origWalletStatAllMonthly.data[_origWalletStatAllMonthly.data.length - 1].date.month,
            1
          );

          // generate the list of date beased on _min and _max date
          DateTime startDate = _minDate;
          while (startDate.isBefore(_maxDate)) {
            // add the start date in the wallet date range
            _walletDateRange[startDate] = true;

            // add next month
            startDate = DateTime(startDate.year, startDate.month + 1, 1);
          }

          // add the _maxDate here as _maxDate will be skipped above
          _walletDateRange[_maxDate] = true;
        }

        // get the statistic data
        _getStatData();
      });
    } catch (error, stackTrace) {
      Log.error(
        message: "Error when get wallet stat data",
        error: error,
        stackTrace: stackTrace,
      );
      throw 'Error when try to get the data from server';
    }

    return true;
  }

  void _sortWalletStat() {
    setState(() {
      if (_sortAscending) {
        _walletStatAll = _origWalletStatAllMonthly;
      } else {
        _walletStatAll = _origWalletStatAllReverseMonthly;
      }
    });
  }
}
