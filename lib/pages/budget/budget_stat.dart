import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/api/transaction_api.dart';
import 'package:my_expense/model/budget_stat_model.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/args/budget_transaction_args.dart';
import 'package:my_expense/utils/misc/number_format.dart';
import 'package:my_expense/widgets/chart/multi_line_chart.dart';
import 'package:my_expense/widgets/input/type_slide.dart';

class BudgetStatPage extends StatefulWidget {
  final Object? arguments;
  const BudgetStatPage({Key? key, required this.arguments}) : super(key: key);

  @override
  State<BudgetStatPage> createState() => _BudgetStatPageState();
}

class _BudgetStatPageState extends State<BudgetStatPage> {
  final TransactionHTTPService _transactionHttp = TransactionHTTPService();
  final ScrollController _monthlyScroller = ScrollController();
  final ScrollController _yearlyScroller = ScrollController();
  final fCCY = NumberFormat("#,##0.00", "en_US");

  late BudgetTransactionArgs _budgetTransaction;
  late BudgetStatModel _budgetStat;
  late Map<String, double> _monthlyDateRange;
  late Map<String, double> _yearlyDateRange;
  late List<Map<String, double>> _monthlyData;
  late List<Map<String, double>> _yearlyData;
  late Future<bool> _getData;
  late String _currentType;
  late double _totalMonthlyAmount;
  late double _totalMonthlyDailyAmount;
  late double _averageMonthlyAmount;
  late double _averageMonthlyDailyAmount;
  late double _totalYearlyAmount;
  late double _totalYearlyDailyAmount;
  late double _averageYearlyAmount;
  late double _averageYearlyDailyAmount;
  
  int monthDateOffset = 12;
  int yearlyDateOffset = 12;

  @override
  void initState() {
    // convert arguments to Budget Transaction Arguments
    _budgetTransaction = widget.arguments as BudgetTransactionArgs;

    // initialize all variable
    _currentType = "monthly";
    _monthlyData = [];
    _yearlyData = [];
    _monthlyDateRange = {};
    _yearlyDateRange = {};
    _totalMonthlyAmount = 0;
    _totalMonthlyDailyAmount = 0;
    _totalYearlyAmount = 0;
    _totalYearlyDailyAmount = 0;
    _averageMonthlyAmount = 0;
    _averageMonthlyDailyAmount = 0;
    _averageYearlyAmount = 0;
    _averageYearlyDailyAmount = 0;

    // get the budget stat data from backend
    _getData = _getBudgetStatData();

    super.initState();
  }

  @override
  void dispose() {
    _monthlyScroller.dispose();
    _yearlyScroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text("${_budgetTransaction.categoryName} Stat")),
        leading: IconButton(
          icon: Icon(Ionicons.close_outline, color: textColor),
          onPressed: (() {
            // back to previous page
            Navigator.pop(context);
          }),
        ),
      ),
      body: FutureBuilder(
        future: _getData,
        builder: ((context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error when get budget stat data"),);
          }
          else if (snapshot.hasData) {
            return _generatePage();
          }
          else {
            return Center(child: Text("Loading budget stat data"),);
          }
        }),
      ),
    );
  }

  Widget _generatePage() {
    // generate the page for the budget stat
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 10,),
        TypeSlide(
          type: _currentType,
          onChange: ((selected) {
            setState(() {
              _currentType = selected.toLowerCase();
            });
          }),
          items: <String, Color>{
            "Monthly": accentColors[2],
            "Yearly": accentColors[0],
          },
        ),
        const SizedBox(height: 5,),
        Expanded(child: _generateSubPage()),
        const SizedBox(height: 35,),
      ],
    );
  }

  Widget _generateSubPage() {
    if (_currentType.toLowerCase() == "monthly") {
      return _generateMonthlyPage();
    }
    else {
      return _generateYearlyPage();
    }
  }

  Widget _generateMonthlyPage() {
    if (_monthlyData.length <= 0) {
      return Center(child: Text("No monthly data"),);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        MultiLineChart(
          data: _monthlyData,
          color: [accentColors[2]],
          dateOffset: monthDateOffset,
          min: 0,
          addBottomPadd: false,
        ),
        SizedBox(
          width: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              const SizedBox(width: 10,),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "Total Monthly",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2,),
                    Text("${_budgetTransaction.currencySymbol} ${formatCurrency(_totalMonthlyAmount, false, true, true, 2)}"),
                  ],
                ),
              ),
              const SizedBox(width: 5,),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "Avg Monthly",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2,),
                    Text("${_budgetTransaction.currencySymbol} ${formatCurrency(_averageMonthlyAmount, false, true, true, 2)}"),
                  ],
                ),
              ),
              const SizedBox(width: 5,),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "Avg Daily",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2,),
                    Text("${_budgetTransaction.currencySymbol} ${formatCurrency(_averageMonthlyDailyAmount, false, true, true, 2)}"),
                  ],
                ),
              ),
              const SizedBox(width: 10,),
            ],
          ),
        ),
        const SizedBox(height: 10,),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              // header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                decoration: BoxDecoration(
                  color: secondaryDark,
                  border: Border(
                    bottom: BorderSide(
                      color: secondaryBackground,
                      width: 1.0,
                      style: BorderStyle.solid,
                    )
                  )
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 80,
                      child: Center(child: Text("Date")),
                    ),
                    Expanded(
                      child: SizedBox(
                        child: Center(child: Text("Monthly Amount")),
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                        child: Center(child: Text("Average Daily")),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _monthlyScroller,
                  itemCount: _budgetStat.monthly.length,
                  itemBuilder: ((context, index) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            width: 80,
                            child: Center(child: Text(_budgetStat.monthly[index].date)),
                          ),
                          Expanded(
                            child: SizedBox(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  "${_budgetTransaction.currencySymbol} ${formatCurrency(_budgetStat.monthly[index].totalAmount, false, true, true, 2)}"
                                )
                              ),
                            ),
                          ),
                          Expanded(
                            child: SizedBox(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  "${_budgetTransaction.currencySymbol} ${formatCurrency(_budgetStat.monthly[index].averageAmount, false, true, true, 2)}"
                                )
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _generateYearlyPage() {
    if (_yearlyData.length <= 0) {
      return Center(child: Text("No yearly data"),);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        MultiLineChart(
          data: _yearlyData,
          color: [accentColors[2]],
          dateOffset: yearlyDateOffset,
          min: 0,
          addBottomPadd: false,
        ),
        SizedBox(
          width: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              const SizedBox(width: 10,),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "Total Yearly",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2,),
                    Text("${_budgetTransaction.currencySymbol} ${formatCurrency(_totalYearlyAmount, false, true, true, 2)}"),
                  ],
                ),
              ),
              const SizedBox(width: 5,),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "Avg Yearly",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2,),
                    Text("${_budgetTransaction.currencySymbol} ${formatCurrency(_averageYearlyAmount, false, true, true, 2)}"),
                  ],
                ),
              ),
              const SizedBox(width: 5,),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "Avg Daily",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2,),
                    Text("${_budgetTransaction.currencySymbol} ${formatCurrency(_averageYearlyDailyAmount, false, true, true, 2)}"),
                  ],
                ),
              ),
              const SizedBox(width: 10,),
            ],
          ),
        ),
        const SizedBox(height: 10,),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              // header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                decoration: BoxDecoration(
                  color: secondaryDark,
                  border: Border(
                    bottom: BorderSide(
                      color: secondaryBackground,
                      width: 1.0,
                      style: BorderStyle.solid,
                    )
                  )
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 80,
                      child: Center(child: Text("Date")),
                    ),
                    Expanded(
                      child: SizedBox(
                        child: Center(child: Text("Yearly Amount")),
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                        child: Center(child: Text("Average Daily")),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _yearlyScroller,
                  itemCount: _budgetStat.yearly.length,
                  itemBuilder: ((context, index) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            width: 80,
                            child: Center(child: Text(_budgetStat.yearly[index].date)),
                          ),
                          Expanded(
                            child: SizedBox(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  "${_budgetTransaction.currencySymbol} ${formatCurrency(_budgetStat.yearly[index].totalAmount, false, true, true, 2)}"
                                )
                              ),
                            ),
                          ),
                          Expanded(
                            child: SizedBox(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  "${_budgetTransaction.currencySymbol} ${formatCurrency(_budgetStat.yearly[index].averageAmount, false, true, true, 2)}"
                                )
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<bool> _getBudgetStatData() async {
    try {
      _budgetStat = await _transactionHttp.fetchTransactionBudgetStat(_budgetTransaction.categoryid, _budgetTransaction.currencyId);

      // generate the monthly and yearly data
      // as API will not return all the date range, we will need to fill the void
      // of the date range here.

      // first let's generate a date range based on current data until the
      // last date of the data

      // first generate the monthly date range
      DateTime _nextDate = DateTime.parse("${DateTime.now().year}-${DateTime.now().month + 1}-01");
      DateTime _lastDate = DateTime.parse("${_budgetStat.monthly[_budgetStat.monthly.length-1].date}-01");
      _monthlyDateRange.clear();
      while (_lastDate.isBefore(_nextDate)) {
        _monthlyDateRange[DateFormat("yyyy-MM").format(_lastDate)] = 0;
        _lastDate = DateTime(_lastDate.year, _lastDate.month + 1, 1);
      }
      if (_monthlyDateRange.length > 12) {
        monthDateOffset = _monthlyDateRange.length ~/ 7;
      }
      else {
        monthDateOffset = 1;
      }

      _nextDate = DateTime.parse("${DateTime.now().year + 1}-12-01");
      _lastDate = DateTime.parse("${_budgetStat.yearly[_budgetStat.yearly.length-1].date}-12-01");
      _yearlyDateRange.clear();
      while (_lastDate.isBefore(_nextDate)) {
        _yearlyDateRange[DateFormat("yyyy").format(_lastDate)] = 0;
        _lastDate = DateTime(_lastDate.year + 1, 12, 1);
      }
      if (_yearlyDateRange.length > 12) {
        yearlyDateOffset = _yearlyDateRange.length ~/ 7;
      }
      else {
        yearlyDateOffset = 1;
      }
      
      _monthlyData.clear();
      _totalMonthlyAmount = 0;
      _totalMonthlyDailyAmount = 0;
      _budgetStat.monthly.reversed.forEach((data) {
        _monthlyDateRange[data.date] = data.totalAmount;
        _totalMonthlyAmount += data.totalAmount;
        _totalMonthlyDailyAmount += data.averageAmount;
      });
      _averageMonthlyAmount = _totalMonthlyAmount / _monthlyDateRange.length;
      _averageMonthlyDailyAmount = _totalMonthlyDailyAmount / _monthlyDateRange.length;
      // _monthlyDateRange = Map.fromEntries(_yearlyDateRange.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
      _monthlyData.add(_monthlyDateRange);

      _yearlyData.clear();
      _totalYearlyAmount = 0;
      _budgetStat.yearly.reversed.forEach((data) {
        _yearlyDateRange[data.date] = data.totalAmount;
        _totalYearlyAmount += data.totalAmount;
        _totalYearlyDailyAmount += data.averageAmount;
      });
      // _yearlyDateRange = Map.fromEntries(_yearlyDateRange.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
      _averageYearlyAmount = _totalYearlyAmount / _yearlyDateRange.length;
      _averageYearlyDailyAmount = _totalYearlyDailyAmount / _yearlyDateRange.length;
      _yearlyData.add(_yearlyDateRange);

      return true;
    }
    catch (error) {
      debugPrint(error.toString());
      throw 'Error when try to get the stock collection data from server';
    }
  }
}