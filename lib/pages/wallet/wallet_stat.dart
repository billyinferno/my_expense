import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

class WalletStatPage extends StatefulWidget {
  final Object? wallet;
  const WalletStatPage({super.key, required this.wallet});

  @override
  State<WalletStatPage> createState() => _WalletStatPageState();
}

class _WalletStatPageState extends State<WalletStatPage> {
  final WalletHTTPService _walletHTTP = WalletHTTPService();
  bool _sortAscending = true;
  late WalletModel _wallet;
  late Future<bool> _getData;
  late List<WalletStatModel> _walletStat;
  late List<WalletStatModel> _origWalletStat;
  late List<Map<String, double>> _walletLineChartData;
  late DateTime _minDate;
  late DateTime _maxDate;
  late Map<DateTime, bool> _walletDateRange;
  late int _dateOffset;
  late double _maxAmount;
  late double _totalIncome;
  late int _countIncome;
  late double _totalExpense;
  late int _countExpense;

  @override
  void initState() {
    // get the wallet data
    _wallet = widget.wallet as WalletModel;

    // init the wallet list into empty list
    _walletStat = [];
    _origWalletStat = [];

    // set the wallet line data into empty array
    _walletLineChartData = [];
    _dateOffset = 0;

    // set the min and max date as 1 day before of max date which is today
    _walletDateRange = {};
    _minDate = DateTime.now().add(const Duration(days: -1));
    _maxDate = DateTime.now();
    _totalIncome = 0;
    _countIncome = 0;
    _totalExpense = 0;
    _countExpense = 0;

    // get the data from API
    _getData = _getWalletStatData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(_wallet.name)),
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
                    (_sortAscending ? Ionicons.arrow_up : Ionicons.arrow_down),
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
      body: _generateBody(),
    );
  }

  Widget _generateBody() {
    return FutureBuilder(
      future: _getData,
      builder: ((context, snapshot) {
        if (snapshot.hasError) {
          return const Column(
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
              SizedBox(height: 5,),
              Center(
                child: Text("Unable to load data from API"),
              )
            ],
          );
        }
        else if (snapshot.hasData) {
          return MySafeArea(
            child: _generateBarChart()
          );
        }
        else {
          return const Column(
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
          const SizedBox(height: 10,),
          MultiLineChart(
            data: _walletLineChartData,
            color: [accentColors[5], accentColors[0], accentColors[2]],
            legend: const ["Total", "Income", "Expense"],
            height: 200,
            dateOffset: _dateOffset,
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
          const SizedBox(height: 10,),
          Expanded(
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _walletStat.length,
              itemBuilder: ((context, index) {
                Color indicator = Colors.white;
                if (_walletStat[index].income! > _walletStat[index].expense!) {
                  indicator = accentColors[0];
                }
                else if (_walletStat[index].income! < _walletStat[index].expense!) {
                  indicator = accentColors[2];
                }

                return Container(
                  width: double.infinity,
                  height: 50,
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
                        height: 50,
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
                        color: secondaryBackground,
                        width: 70,
                        padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              Globals.dfyyyyMM.format(_walletStat[index].date.toLocal()),
                              style: const TextStyle(
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              formatCurrency(
                                (_walletStat[index].income ?? 0) - (_walletStat[index].expense ?? 0),
                                checkThousand: true,
                                showDecimal: true,
                                shorten: true,
                                decimalNum: 2,
                              ),
                              style: TextStyle(
                                color: indicator,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // bar chart
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Bar(
                              amount: _walletStat[index].income!,
                              maxAmount: _maxAmount,
                              text: Globals.fCCY.format(
                                _walletStat[index].income!
                              ),
                              color: accentColors[0]
                            ),
                            Bar(
                              amount: _walletStat[index].expense!,
                              maxAmount: _maxAmount,
                              text: Globals.fCCY.format(
                                _walletStat[index].expense!
                              ),
                              color: accentColors[2]
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

    double total = _wallet.startBalance;
    
    // loop thru _walletStat and get the maximum data
    _maxAmount = double.infinity * -1;

    _walletDateRange.forEach((key, value) {
      walletListIncome[Globals.dfMMyy.format(key)] = 0;
      walletListExpense[Globals.dfMMyy.format(key)] = 0;
      walletListTotal[Globals.dfMMyy.format(key)] = 0;
    });

    for (WalletStatModel data in _walletStat) {
      // generate the wallet list income, expense, and total
      walletListIncome[Globals.dfMMyy.format(data.date)] = (data.income ?? 0);
      walletListExpense[Globals.dfMMyy.format(data.date)] = (data.expense ?? 0);
      
      _totalIncome += data.income!;
      _totalExpense += data.expense!;

      if (data.income! > data.expense!) {
        _countIncome += 1;
      }
      else if (data.income! < data.expense!) {
        _countExpense += 1;
      }

      if (data.income! > _maxAmount) {
        _maxAmount = data.income!;
      }
      if (data.expense! > _maxAmount) {
        _maxAmount = data.expense!;
      }
    }

    // loop thru _walletDataRange again to calculate the total
    _walletDateRange.forEach((key, value) {
      total += walletListIncome[Globals.dfMMyy.format(key)]! - walletListExpense[Globals.dfMMyy.format(key)]!;
      walletListTotal[Globals.dfMMyy.format(key)] = total;
    });

    _dateOffset = walletListTotal.length ~/ 8;

    // set the wallet list data to the _walletList data
    _walletLineChartData.clear();
    _walletLineChartData.add(walletListTotal);
    _walletLineChartData.add(walletListIncome);
    _walletLineChartData.add(walletListExpense);
  }

  Future<bool> _getWalletStatData() async {
    try {
      // perform the get company detail information here
      await _walletHTTP.getStat(id: _wallet.id).then((resp) {
        // copy the response to company detail data
        _walletStat = resp;
        _origWalletStat.addAll(resp);

        // get the min date, where it should be the array 0 of the _origWalletStat
        if (_origWalletStat.isNotEmpty) {
          _minDate = DateTime(_origWalletStat[0].date.year, _origWalletStat[0].date.month, 1);
          _maxDate = DateTime(_origWalletStat[_origWalletStat.length - 1].date.year, _origWalletStat[_origWalletStat.length - 1].date.month, 1);

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
    }
    catch(error, stackTrace) {
      Log.error(
        message: "Error when try to get the data from server",
        error: error,
        stackTrace: stackTrace,
      );
      throw 'Error when try to get the data from server';
    }

    return true;
  }

  void _sortWalletStat() {
    setState(() 
    {
      _walletStat.clear();
      if (_sortAscending) {
        _walletStat.addAll(_origWalletStat.toList());
      }
      else {
        _walletStat.addAll(_origWalletStat.reversed.toList());
      }
    });
  }
}