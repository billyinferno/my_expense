import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

enum WalletDataType {
  monthly, yearly
}

class WalletStatPage extends StatefulWidget {
  final Object? wallet;
  const WalletStatPage({super.key, required this.wallet});

  @override
  State<WalletStatPage> createState() => _WalletStatPageState();
}

class _WalletStatPageState extends State<WalletStatPage> {
  final WalletHTTPService _walletHTTP = WalletHTTPService();
  final Map<WalletDataType, TypeSlideItem> _dataItems = {
    WalletDataType.monthly: TypeSlideItem(
      color: accentColors[2],
      text: "Monthly",
    ),
    WalletDataType.yearly: TypeSlideItem(
      color: accentColors[6],
      text: "Yearly",
    ),
  };

  final List<Color> _chartColors = [accentColors[5], accentColors[0], accentColors[2]];

  bool _sortAscending = true;
  late WalletModel _wallet;
  late Future<bool> _getData;
  late List<WalletStatModel> _walletStat;
  late List<WalletStatModel> _origWalletStatMonthly;
  late List<WalletStatModel> _origWalletStatYearly;

  late List<Map<String, double>> _walletLineChartData;
  late List<Map<String, double>> _walletLineChartDataMonthly;
  late List<Map<String, double>> _walletLineChartDataYearly;

  late DateTime _minDate;
  late DateTime _maxDate;
  late Map<DateTime, bool> _walletDateRange;
  late int _dateOffset;
  late double _maxAmount;
  late double _maxAmountMonthly;
  late double _maxAmountYearly;
  late double _totalIncome;
  late int _countIncome;
  late double _totalExpense;
  late int _countExpense;

  late WalletDataType _dataType;

  @override
  void initState() {
    super.initState();
    
    // get the wallet data
    _wallet = widget.wallet as WalletModel;

    // init the wallet list into empty list
    _walletStat = [];
    _origWalletStatMonthly = [];
    _origWalletStatYearly = [];

    // set the wallet line data into empty array
    _walletLineChartData = [];
    _walletLineChartDataMonthly = [];
    _walletLineChartDataYearly = [];

    _dateOffset = 0;

    // set the min and max date as 1 day before of max date which is today
    _walletDateRange = {};
    _minDate = DateTime.now().add(const Duration(days: -1));
    _maxDate = DateTime.now();
    _totalIncome = 0;
    _countIncome = 0;
    _totalExpense = 0;
    _countExpense = 0;

    // init the graph type data
    _dataType = WalletDataType.monthly;

    // get the data from API
    _getData = _getWalletStatData();
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
          SortIcon(
            asc: _sortAscending,
            onPress: () {
              setState(() {                
                // set the sorting to inverse
                _sortAscending = !_sortAscending;
                _sortWalletStat();
              });
            },
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
          return CommonErrorPage(
            isNeedScaffold: false,
            errorText: "Unable to load data from API",
          );
        }
        else if (snapshot.hasData) {
          return MySafeArea(
            child: _generateBarChart()
          );
        }
        else {
          return CommonLoadingPage(
            isNeedScaffold: false,
            loadingText: "Load wallet data...",
          );
        }
      }),
    );
  }

  Widget _generateBarChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 10,),
        Center(
          child: SizedBox(
            width: (100 * _dataItems.length).toDouble(),
            child: TypeSlide<WalletDataType>(
              onValueChanged: (value) {
                setState(() {
                  _dataType = value;
                  _dataSelection();
                });
              },
              items: _dataItems,
              initialItem: WalletDataType.monthly,
            ),
          ),
        ),
        const SizedBox(height: 10,),
        MultiLineChart(
          data: _walletLineChartData,
          color: _chartColors,
          legend: const ["Net Worth", "Income", "Expense"],
          height: 200,
          dateOffset: _dateOffset,
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
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
              return Container(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: BarStat(
                  income: (_walletStat[index].income ?? 0),
                  expense: (_walletStat[index].expense ?? 0),
                  balance: 0,
                  maxAmount: _maxAmount,
                  date: _walletStat[index].date,
                  dateFormat: (
                    _dataType == WalletDataType.monthly ? Globals.dfyyyyMM : Globals.dfyyyy
                  ),
                  showBalance: false,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  void _getStatData() {
    Map<String, WalletStatModel> walletStatYearly = {};

    Map<String, double> walletListIncomeMonthly = {};
    Map<String, double> walletListExpenseMonthly = {};
    Map<String, double> walletListTotalMonthly = {};

    Map<String, double> walletListIncomeYearly = {};
    Map<String, double> walletListExpenseYearly = {};
    Map<String, double> walletListTotalYearly = {};

    double total = _wallet.startBalance;
    
    // loop thru _walletStat and get the maximum data
    _maxAmountMonthly = double.negativeInfinity;
    _maxAmountYearly = double.negativeInfinity;

    _walletDateRange.forEach((key, value) {
      // initialize monthly data
      walletListIncomeMonthly[Globals.dfMMyy.formatLocal(key)] = 0;
      walletListExpenseMonthly[Globals.dfMMyy.formatLocal(key)] = 0;
      walletListTotalMonthly[Globals.dfMMyy.formatLocal(key)] = 0;

      // initialize yearly data
      walletListIncomeYearly[Globals.dfyyyy.formatLocal(key)] = 0;
      walletListExpenseYearly[Globals.dfyyyy.formatLocal(key)] = 0;
      walletListTotalYearly[Globals.dfyyyy.formatLocal(key)] = 0;

      // initialize walletStatYearly
      walletStatYearly[Globals.dfyyyy.formatLocal(key)] = WalletStatModel(
        date: DateTime(key.year, 12, 31),
        expense: 0,
        income: 0,
      );
    });

    String key;
    WalletStatModel? prevWalletStat;
    for (WalletStatModel data in _walletStat) {
      // generate the wallet list income, expense, and total
      // monthly data
      key = Globals.dfMMyy.formatLocal(data.date);
      walletListIncomeMonthly[key] = (data.income ?? 0);
      walletListExpenseMonthly[key] = (data.expense ?? 0);

      total += (data.income ?? 0) - (data.expense ?? 0);
      walletListTotalMonthly[key] = total;

      // yearly data
      key = Globals.dfyyyy.formatLocal(data.date);
      walletListIncomeYearly[key] = (walletListIncomeYearly[key] ?? 0) + (data.income ?? 0);
      walletListExpenseYearly[key] = (walletListExpenseYearly[key] ?? 0) + (data.expense ?? 0);
      walletListTotalYearly[key] = total;

      // check for max amount yearly
      if ((walletListIncomeYearly[key] ?? 0) > _maxAmountYearly) {
        _maxAmountYearly = (walletListIncomeYearly[key] ?? 0);
      }
      if ((walletListExpenseYearly[key] ?? 0) > _maxAmountYearly) {
        _maxAmountYearly = (walletListExpenseYearly[key] ?? 0);
      }

      // generate yearly wallet stat model
      prevWalletStat = walletStatYearly[key];
      walletStatYearly[key] = WalletStatModel(
        date: prevWalletStat!.date,
        expense: (prevWalletStat.expense! + (data.expense ?? 0)),
        income: (prevWalletStat.income! + (data.income ?? 0)),
      );

      _totalIncome += data.income!;
      _totalExpense += data.expense!;

      if (data.income! > data.expense!) {
        _countIncome += 1;
      }
      else if (data.income! < data.expense!) {
        _countExpense += 1;
      }

      if (data.income! > _maxAmountMonthly) {
        _maxAmountMonthly = data.income!;
      }
      if (data.expense! > _maxAmountMonthly) {
        _maxAmountMonthly = data.expense!;
      }
    }

    // set the wallet list data to the _walletList data
    // monthly
    _walletLineChartDataMonthly.clear();
    _walletLineChartDataMonthly.add(walletListTotalMonthly);
    _walletLineChartDataMonthly.add(walletListIncomeMonthly);
    _walletLineChartDataMonthly.add(walletListExpenseMonthly);

    // yearly
    _walletLineChartDataYearly.clear();
    _walletLineChartDataYearly.add(walletListTotalYearly);
    _walletLineChartDataYearly.add(walletListIncomeYearly);
    _walletLineChartDataYearly.add(walletListExpenseYearly);

    // generate the wallet stat yearly
    _origWalletStatYearly.clear();
    walletStatYearly.forEach((key, value) {
      _origWalletStatYearly.add(value);
    },);

    // select the data we want to display
    _dataSelection();
  }

  void _dataSelection() {
    if (_dataType == WalletDataType.monthly) {
      _walletLineChartData = _walletLineChartDataMonthly;
      _maxAmount = _maxAmountMonthly;
    }
    else {
      _walletLineChartData = _walletLineChartDataYearly;
      _maxAmount = _maxAmountYearly;
    }

    // calculate date offset
    _dateOffset = 1;
    if (_walletLineChartData[0].isNotEmpty) {
      _dateOffset = _walletLineChartData[0].length ~/ 8;
    }
    if (_dateOffset <= 0) {
      _dateOffset = 1;
    }

    // get the wallet stat
    _sortWalletStat();
  }

  Future<bool> _getWalletStatData() async {
    try {
      // perform the get company detail information here
      await _walletHTTP.getStat(id: _wallet.id).then((resp) {
        // copy the response to company detail data
        _walletStat = resp;
        _origWalletStatMonthly = resp.toList();

        // get the min date, where it should be the array 0 of the _origWalletStat
        if (_origWalletStatMonthly.isNotEmpty) {
          _minDate = DateTime(_origWalletStatMonthly[0].date.year, _origWalletStatMonthly[0].date.month, 1);
          _maxDate = DateTime(_origWalletStatMonthly[_origWalletStatMonthly.length - 1].date.year, _origWalletStatMonthly[_origWalletStatMonthly.length - 1].date.month, 1);

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
    _walletStat.clear();
    if (_sortAscending) {
      if (_dataType == WalletDataType.monthly) {
        _walletStat.addAll(_origWalletStatMonthly.toList());
      }
      else {
        _walletStat.addAll(_origWalletStatYearly.toList());
      }
    }
    else {
      if (_dataType == WalletDataType.monthly) {
        _walletStat.addAll(_origWalletStatMonthly.reversed.toList());
      }
      else {
        _walletStat.addAll(_origWalletStatYearly.reversed.toList());
      }
    }
  }
}