import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

class StatsAllPage extends StatefulWidget {
  final Object? ccy;
  const StatsAllPage({super.key, this.ccy});

  @override
  State<StatsAllPage> createState() => _StatsAllPageState();
}

class _StatsAllPageState extends State<StatsAllPage> {
  final WalletHTTPService _walletHTTP = WalletHTTPService();

  late Future<bool> _getData;
  late List<WalletStatAllModel> _walletStatAll;
  late List<WalletStatAllModel> _origWalletStatAll;
  late double _maxAmount;
  late double _totalIncome;
  late int _countIncome;
  late double _totalExpense;
  late int _countExpense;
  late int _ccy;

  // multiline chart data
  late List<Map<String, double>> _walletLineChartData;
  late int _dateOffset;
  late DateTime _minDate;
  late DateTime _maxDate;
  late Map<DateTime, bool> _walletDateRange;

  bool _sortAscending = true;

  @override
  void initState() {
    // get the current ccy
    _ccy = widget.ccy as int;

    // init the wallet list into empty list
    _walletStatAll = [];
    _origWalletStatAll = [];
    _walletLineChartData = [];
    _totalIncome = 0;
    _countIncome = 0;
    _totalExpense = 0;
    _countExpense = 0;
    _dateOffset = 0;

    // default the min and max date for the multiline chart data
    _walletDateRange = {};
    _minDate = DateTime.now().add(const Duration(days: -1));
    _maxDate = DateTime.now();

    // get the data from API
    _getData = _getWalletStatAllData();

    super.initState();
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
              title: Center(child: Text("Stat For ${_walletStatAll[0].ccy}")),
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
          return const Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: SizedBox(
                    child: Center(
                      child: Text("Load wallet data..."),
                    ),
                  ),
                )
              ],
            ),
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
          const SizedBox(
            height: 10,
          ),
          MultiLineChart(
            data: _walletLineChartData,
            color: [accentColors[5], accentColors[0], accentColors[2]],
            legend: const ["Total", "Income", "Expense"],
            height: 200,
            dateOffset: _dateOffset,
          ),
          const SizedBox(
            height: 10,
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
                const SizedBox(
                  width: 10,
                ),
                SummaryBox(
                    color: accentColors[2],
                    text: "Expense",
                    value: Globals.fCCY.format(_totalExpense),
                    count: _countExpense),
              ],
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Expanded(
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _walletStatAll[0].data.length,
              itemBuilder: ((context, index) {
                Color indicator = Colors.white;
                if (
                  _walletStatAll[0].data[index].income! >
                  _walletStatAll[0].data[index].expense!
                ) {
                  indicator = accentColors[0];
                } else if (
                  _walletStatAll[0].data[index].income! <
                  _walletStatAll[0].data[index].expense!
                ) {
                  indicator = accentColors[2];
                }

                return Container(
                  width: double.infinity,
                  height: 65,
                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                  decoration: BoxDecoration(
                    color: primaryLight,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      // indicator
                      Container(
                        width: 10,
                        height: 65,
                        decoration: BoxDecoration(
                          color: indicator,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(5),
                            bottomLeft: Radius.circular(5),
                          )
                        ),
                      ),
                      // date,
                      Container(
                        padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                        color: secondaryBackground,
                        height: 65,
                        width: 80,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            Globals.dfyyyyMM.format(_walletStatAll[0].data[index].date),
                          ),
                        ),
                      ),
                      // bar chart
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Bar(
                              amount: _walletStatAll[0].data[index].income!,
                              maxAmount: _maxAmount,
                              text: Globals.fCCY.format(
                                _walletStatAll[0].data[index].income!
                              ),
                              color: accentColors[0]
                            ),
                            Bar(
                              amount: _walletStatAll[0].data[index].expense!,
                              maxAmount: _maxAmount,
                              text: Globals.fCCY.format(
                                _walletStatAll[0].data[index].expense!
                              ),
                              color: accentColors[2]
                            ),
                            Bar(
                              amount: _walletStatAll[0].data[index].balance!,
                              maxAmount: _maxAmount,
                              text: Globals.fCCY.format(
                                _walletStatAll[0].data[index].balance!
                              ),
                              color: accentColors[4]
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5,),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _getStatData() {
    Map<String, double> walletListIncome = {};
    Map<String, double> walletListExpense = {};
    Map<String, double> walletListTotal = {};

    double total = 0;

    // loop thru _walletStat and get the maximum data
    _maxAmount = double.infinity * -1;

    // loop thru all the stat all date to add as key on the wallet list income
    // expense, and total
    _walletDateRange.forEach((key, value) {
      walletListIncome[Globals.dfMMyy.format(key)] = 0;
      walletListExpense[Globals.dfMMyy.format(key)] = 0;
      walletListTotal[Globals.dfMMyy.format(key)] = 0;
    });

    for (WalletStatAllModel ccy in _walletStatAll) {
      for (Datum data in ccy.data) {
        // generate the wallet list income, expense, and total
        walletListIncome[Globals.dfMMyy.format(data.date)] = (data.income ?? 0);
        walletListExpense[Globals.dfMMyy.format(data.date)] = (data.expense ?? 0);

        total += (data.diff ?? 0);
        walletListTotal[Globals.dfMMyy.format(data.date)] = total;

        _totalIncome += data.income!;
        _totalExpense += data.expense!;

        if (data.income! > data.expense!) {
          _countIncome += 1;
        } else if (data.income! < data.expense!) {
          _countExpense += 1;
        }

        if (data.income! > _maxAmount) {
          _maxAmount = data.income!;
        }
        if (data.expense! > _maxAmount) {
          _maxAmount = data.expense!;
        }
        if (data.balance! > _maxAmount) {
          _maxAmount = data.balance!;
        }
      }
    }

    _dateOffset = walletListTotal.length ~/ 8;

    // set the wallet list data to the _walletList data
    _walletLineChartData.clear();
    _walletLineChartData.add(walletListTotal);
    _walletLineChartData.add(walletListIncome);
    _walletLineChartData.add(walletListExpense);
  }

  Future<bool> _getWalletStatAllData() async {
    try {
      // perform the get company detail information here
      await _walletHTTP.getAllStat(_ccy).then((resp) {
        // copy the response to company detail data
        _walletStatAll = resp;
        _origWalletStatAll.addAll(resp);

        if (_origWalletStatAll[0].data.isNotEmpty) {
          _minDate = DateTime(
            _origWalletStatAll[0].data[0].date.year,
            _origWalletStatAll[0].data[0].date.month,
            1
          );
          
          _maxDate = DateTime(
            _origWalletStatAll[0].data[_origWalletStatAll[0].data.length - 1].date.year,
            _origWalletStatAll[0].data[_origWalletStatAll[0].data.length - 1].date.month,
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
      _walletStatAll.clear();
      if (_sortAscending) {
        _walletStatAll.addAll(_origWalletStatAll.toList());
      } else {
        _walletStatAll.addAll(_origWalletStatAll.reversed.toList());
      }
    });
  }
}
