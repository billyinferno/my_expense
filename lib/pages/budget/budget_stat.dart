import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

class BudgetStatPage extends StatefulWidget {
  final Object? arguments;
  const BudgetStatPage({super.key, required this.arguments});

  @override
  State<BudgetStatPage> createState() => _BudgetStatPageState();
}

class _BudgetStatPageState extends State<BudgetStatPage> {
  final TransactionHTTPService _transactionHttp = TransactionHTTPService();
  final ScrollController _monthlyScroller = ScrollController();
  final ScrollController _yearlyScroller = ScrollController();

  late BudgetTransactionArgs _budgetTransaction;
  late BudgetStatModel _budgetStat;
  late List<BudgetStatDetail> _budgetMonthly;
  late List<BudgetStatDetail> _budgetYearly;
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
  late bool _sortAscending;

  int monthDateOffset = 12;
  int yearlyDateOffset = 12;

  @override
  void initState() {
    super.initState();

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
    _sortAscending = true;

    // get the budget stat data from backend
    _getData = _getBudgetStatData();
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
          icon: const Icon(Ionicons.close_outline, color: textColor),
          onPressed: (() {
            // back to previous page
            Navigator.pop(context);
          }),
        ),
        actions: <Widget>[
          InkWell(
            onTap: (() async {
              // reversed the monthly and yearly ydata
              setState(() {
                _budgetMonthly = _budgetMonthly.reversed.toList();
                _budgetYearly = _budgetYearly.reversed.toList();
                _sortAscending = !_sortAscending;
              });
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
          const SizedBox(
            width: 5,
          ),
        ],
      ),
      body: FutureBuilder(
        future: _getData,
        builder: ((context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("Error when get budget stat data"),
            );
          } else if (snapshot.hasData) {
            return MySafeArea(
              child: _generatePage()
            );
          } else {
            return const Center(
              child: Text("Loading budget stat data"),
            );
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
        const SizedBox(
          height: 10,
        ),
        TypeSlide(
          initialItem: _currentType,
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
        const SizedBox(
          height: 5,
        ),
        Expanded(child: _generateSubPage()),
      ],
    );
  }

  Widget _generateSubPage() {
    if (_currentType.toLowerCase() == "monthly") {
      return _generateMonthlyPage();
    } else {
      return _generateYearlyPage();
    }
  }

  Widget _generateMonthlyPage() {
    if (_monthlyData.isEmpty) {
      return const Center(
        child: Text("No monthly data"),
      );
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
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      "Total Monthly",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      "${_budgetTransaction.currencySymbol} ${_totalMonthlyAmount.formatCurrency(
                        checkThousand: false,
                        showDecimal: true,
                        shorten: true,
                        decimalNum: 2
                      )}"
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 5,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      "Avg Monthly",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                        "${_budgetTransaction.currencySymbol} ${_averageMonthlyAmount.formatCurrency(
                          checkThousand: false,
                          showDecimal: true,
                          shorten: true,
                          decimalNum: 2,
                        )}"),
                  ],
                ),
              ),
              const SizedBox(
                width: 5,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      "Avg Daily",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                        "${_budgetTransaction.currencySymbol} ${_averageMonthlyDailyAmount.formatCurrency(
                          checkThousand: false,
                          showDecimal: true,
                          shorten: true,
                          decimalNum: 2
                        )}"),
                  ],
                ),
              ),
              const SizedBox(
                width: 10,
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                // header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      height: 35,
                      width: 80,
                      decoration: BoxDecoration(
                          color: secondaryDark,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                          ),
                          border: Border.all(
                              color: secondaryBackground,
                              width: 1.0,
                              style: BorderStyle.solid)),
                      child: const Center(
                        child: Text("Date"),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 35,
                        decoration: const BoxDecoration(
                            color: secondaryDark,
                            border: Border(
                              top: BorderSide(
                                  color: secondaryBackground,
                                  width: 1.0,
                                  style: BorderStyle.solid),
                              bottom: BorderSide(
                                  color: secondaryBackground,
                                  width: 1.0,
                                  style: BorderStyle.solid),
                            )),
                        child: const Center(
                          child: Text("Monthly Amount"),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 35,
                        decoration: BoxDecoration(
                            color: secondaryDark,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(10),
                            ),
                            border: Border.all(
                                color: secondaryBackground,
                                width: 1.0,
                                style: BorderStyle.solid)),
                        child: const Center(
                          child: Text("Average Daily"),
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 5,
                  decoration: const BoxDecoration(
                      border: Border(
                    left: BorderSide(
                      color: secondaryBackground,
                      width: 1.0,
                      style: BorderStyle.solid,
                    ),
                    right: BorderSide(
                      color: secondaryBackground,
                      width: 1.0,
                      style: BorderStyle.solid,
                    ),
                  )),
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                          left: BorderSide(
                            color: secondaryBackground,
                            width: 1.0,
                            style: BorderStyle.solid,
                          ),
                          right: BorderSide(
                            color: secondaryBackground,
                            width: 1.0,
                            style: BorderStyle.solid,
                          )),
                    ),
                    child: ListView.builder(
                        controller: _monthlyScroller,
                        itemCount: _budgetMonthly.length,
                        itemBuilder: ((context, index) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(
                                width: 80,
                                child: Center(
                                    child: Text(_budgetMonthly[index].date)),
                              ),
                              Expanded(
                                child: Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 10, 0),
                                  child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                          "${_budgetTransaction.currencySymbol} ${_budgetMonthly[index].totalAmount.formatCurrency(
                                            checkThousand: false,
                                            showDecimal: true,
                                            shorten: true,
                                            decimalNum: 2,
                                          )}")),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 10, 0),
                                  child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                          "${_budgetTransaction.currencySymbol} ${_budgetMonthly[index].averageAmount.formatCurrency(
                                            checkThousand: false,
                                            showDecimal: true,
                                            shorten: true,
                                            decimalNum: 2,
                                          )}")),
                                ),
                              ),
                            ],
                          );
                        })),
                  ),
                ),
                Container(
                  height: 10,
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(
                            10,
                          )),
                      border: Border(
                        left: BorderSide(
                          color: secondaryBackground,
                          width: 1.0,
                          style: BorderStyle.solid,
                        ),
                        bottom: BorderSide(
                          color: secondaryBackground,
                          width: 1.0,
                          style: BorderStyle.solid,
                        ),
                        right: BorderSide(
                          color: secondaryBackground,
                          width: 1.0,
                          style: BorderStyle.solid,
                        ),
                      )),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _generateYearlyPage() {
    if (_yearlyData.isEmpty) {
      return const Center(
        child: Text("No yearly data"),
      );
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
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      "Total Yearly",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                        "${_budgetTransaction.currencySymbol} ${_totalYearlyAmount.formatCurrency(
                          checkThousand: false,
                          showDecimal: true,
                          shorten: true,
                          decimalNum: 2,
                        )}"),
                  ],
                ),
              ),
              const SizedBox(
                width: 5,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      "Avg Yearly",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                        "${_budgetTransaction.currencySymbol} ${_averageYearlyAmount.formatCurrency(
                          checkThousand: false,
                          showDecimal: true,
                          shorten: true,
                          decimalNum: 2,
                        )}"),
                  ],
                ),
              ),
              const SizedBox(
                width: 5,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      "Avg Daily",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                        "${_budgetTransaction.currencySymbol} ${_averageYearlyDailyAmount.formatCurrency(
                          checkThousand: false,
                          showDecimal: true,
                          shorten: true,
                          decimalNum: 2,
                        )}"),
                  ],
                ),
              ),
              const SizedBox(
                width: 10,
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                // header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      height: 35,
                      width: 80,
                      decoration: BoxDecoration(
                          color: secondaryDark,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                          ),
                          border: Border.all(
                              color: secondaryBackground,
                              width: 1.0,
                              style: BorderStyle.solid)),
                      child: const Center(
                        child: Text("Date"),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 35,
                        decoration: const BoxDecoration(
                            color: secondaryDark,
                            border: Border(
                              top: BorderSide(
                                  color: secondaryBackground,
                                  width: 1.0,
                                  style: BorderStyle.solid),
                              bottom: BorderSide(
                                  color: secondaryBackground,
                                  width: 1.0,
                                  style: BorderStyle.solid),
                            )),
                        child: const Center(
                          child: Text("Yearly Amount"),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 35,
                        decoration: BoxDecoration(
                            color: secondaryDark,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(10),
                            ),
                            border: Border.all(
                                color: secondaryBackground,
                                width: 1.0,
                                style: BorderStyle.solid)),
                        child: const Center(
                          child: Text("Average Daily"),
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 5,
                  decoration: const BoxDecoration(
                      border: Border(
                    left: BorderSide(
                      color: secondaryBackground,
                      width: 1.0,
                      style: BorderStyle.solid,
                    ),
                    right: BorderSide(
                      color: secondaryBackground,
                      width: 1.0,
                      style: BorderStyle.solid,
                    ),
                  )),
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                          left: BorderSide(
                            color: secondaryBackground,
                            width: 1.0,
                            style: BorderStyle.solid,
                          ),
                          right: BorderSide(
                            color: secondaryBackground,
                            width: 1.0,
                            style: BorderStyle.solid,
                          )),
                    ),
                    child: ListView.builder(
                        controller: _yearlyScroller,
                        itemCount: _budgetYearly.length,
                        itemBuilder: ((context, index) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(
                                width: 80,
                                child: Center(
                                    child: Text(_budgetYearly[index].date)),
                              ),
                              Expanded(
                                child: Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 10, 0),
                                  child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                          "${_budgetTransaction.currencySymbol} ${_budgetYearly[index].totalAmount.formatCurrency(
                                            checkThousand: false,
                                            showDecimal: true,
                                            shorten: true,
                                            decimalNum: 2,
                                          )}")),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 10, 0),
                                  child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                          "${_budgetTransaction.currencySymbol} ${_budgetYearly[index].averageAmount.formatCurrency(
                                            checkThousand: false,
                                            showDecimal: true,
                                            shorten: true,
                                            decimalNum: 2,
                                          )}")),
                                ),
                              ),
                            ],
                          );
                        })),
                  ),
                ),
                Container(
                  height: 10,
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(
                            10,
                          )),
                      border: Border(
                        left: BorderSide(
                          color: secondaryBackground,
                          width: 1.0,
                          style: BorderStyle.solid,
                        ),
                        bottom: BorderSide(
                          color: secondaryBackground,
                          width: 1.0,
                          style: BorderStyle.solid,
                        ),
                        right: BorderSide(
                          color: secondaryBackground,
                          width: 1.0,
                          style: BorderStyle.solid,
                        ),
                      )),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<bool> _getBudgetStatData() async {
    try {
      // check if this is to get all data or specificy category
      if (_budgetTransaction.categoryid < 0) {
        // this is get all the data
        _budgetStat = await _transactionHttp
            .fetchTransactionBudgetStatSummary(_budgetTransaction.currencyId);
      } else {
        // this will get specific category
        _budgetStat = await _transactionHttp.fetchTransactionBudgetStat(
          categoryId: _budgetTransaction.categoryid,
          currencyId: _budgetTransaction.currencyId
        );
      }

      // generate the monthly and yearly data
      // as API will not return all the date range, we will need to fill the void
      // of the date range here.

      // first let's generate a date range based on current data until the
      // last date of the data

      // first generate the monthly date range
      DateTime nextDate = DateTime(
        DateTime.now().year,
        DateTime.now().month + 1,
        1
      );
      
      DateTime lastDate = DateTime.parse(
        "${_budgetStat.monthly[_budgetStat.monthly.length - 1].date}-01"
      );
      
      _monthlyDateRange.clear();
      
      while (lastDate.isBefore(nextDate)) {
        _monthlyDateRange[Globals.dfyyyyMM.formatLocal(lastDate)] = 0;
        lastDate = DateTime(lastDate.year, lastDate.month + 1, 1);
      }

      if (_monthlyDateRange.length > 12) {
        monthDateOffset = _monthlyDateRange.length ~/ 7;
      } else {
        monthDateOffset = 1;
      }

      nextDate = DateTime(
        DateTime.now().year + 1,
        12,
        1
      );
      
      lastDate = DateTime.parse(
        "${_budgetStat.yearly[_budgetStat.yearly.length - 1].date}-12-01"
      );

      _yearlyDateRange.clear();
      while (lastDate.isBefore(nextDate)) {
        _yearlyDateRange[Globals.dfyyyy.formatLocal(lastDate)] = 0;
        lastDate = DateTime(lastDate.year + 1, 12, 1);
      }
      
      if (_yearlyDateRange.length > 12) {
        yearlyDateOffset = _yearlyDateRange.length ~/ 7;
      } else {
        yearlyDateOffset = 1;
      }

      _monthlyData.clear();
      _totalMonthlyAmount = 0;
      _totalMonthlyDailyAmount = 0;

      for (BudgetStatDetail data in _budgetStat.monthly.reversed) {
        _monthlyDateRange[data.date] = data.totalAmount;
        _totalMonthlyAmount += data.totalAmount;
        _totalMonthlyDailyAmount += data.averageAmount;
      }
      
      _averageMonthlyAmount = _totalMonthlyAmount / _monthlyDateRange.length;
      _averageMonthlyDailyAmount = _totalMonthlyDailyAmount / _monthlyDateRange.length;
      _monthlyData.add(_monthlyDateRange);

      _yearlyData.clear();
      _totalYearlyAmount = 0;

      for (BudgetStatDetail data in _budgetStat.yearly.reversed) {
        _yearlyDateRange[data.date] = data.totalAmount;
        _totalYearlyAmount += data.totalAmount;
        _totalYearlyDailyAmount += data.averageAmount;
      }
      
      _averageYearlyAmount = _totalYearlyAmount / _yearlyDateRange.length;
      _averageYearlyDailyAmount = _totalYearlyDailyAmount / _yearlyDateRange.length;
      _yearlyData.add(_yearlyDateRange);

      // put on different list so we can manipulate it as this is not final one
      _budgetMonthly = _budgetStat.monthly.toList();
      _budgetYearly = _budgetStat.yearly.toList();

      return true;
    } catch (error, stackTrace) {
      Log.error(
        message: "Error when get statistic data from server",
        error: error,
        stackTrace: stackTrace,
      );
      throw 'Error when try to get the stock collection data from server';
    }
  }
}
