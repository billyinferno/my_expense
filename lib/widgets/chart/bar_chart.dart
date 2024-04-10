import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_expense/model/income_expense_model.dart';
import 'package:my_expense/themes/colors.dart';

class BarChart extends StatefulWidget {
  final DateTime from;
  final DateTime to;
  final IncomeExpenseModel data;
  final double? barWidth;
  final double? fontSize;
  
  const BarChart({ super.key, required this.from, required this.to, required this.data, this.barWidth, this.fontSize });

  @override
  State<BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<BarChart> {
  Map<DateTime, double> _expense = {};
  Map<DateTime, double> _income = {};
  double _maxExpense = 0.0;
  double _maxIncome = 0.0;
  double _barWidth = 6;
  bool _isShowed = false;

  final fCCY = NumberFormat("#,##0.00", "en_US");

  @override
  Widget build(BuildContext context) {
    _expense = widget.data.expense;
    _income = widget.data.income;
    _barWidth = (widget.barWidth ?? 6);
    _getMaxExpenseIncome();

    return GestureDetector(
      onTap: (() {
        setState(() {
          _isShowed = !_isShowed;
        });
      }),
      child: _generateBody(),
    );
  }

  Widget _generateBody() {
    // check if we got data or not?
    if(widget.data.expense.isEmpty && widget.data.income.isEmpty) {
      return Container(
        width: double.infinity,
        height: 35,
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xff232d37),
          borderRadius: BorderRadius.only(
            topLeft:Radius.circular(_barWidth),
            topRight: Radius.circular(_barWidth),
            bottomLeft: Radius.circular(_barWidth),
            bottomRight: Radius.circular(_barWidth),
          ),
        ),
        child: const Center(
          child: Text("No Data"),
        ),
      );
    }
    else {
      if(_isShowed) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xff232d37),
            borderRadius: BorderRadius.only(
              topLeft:Radius.circular(_barWidth),
              topRight: Radius.circular(_barWidth),
              bottomLeft: Radius.circular(_barWidth),
              bottomRight: Radius.circular(_barWidth),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              const Center(child: Text("Close Graph")),
              const SizedBox(height: 10,),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: _generateBarCharts(),
              )
            ],
          ),
        );
      }
      else {
        return Container(
          width: double.infinity,
          height: 40,
          margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xff232d37),
            borderRadius: BorderRadius.only(
              topLeft:Radius.circular(_barWidth),
              topRight: Radius.circular(_barWidth),
              bottomLeft: Radius.circular(_barWidth),
              bottomRight: Radius.circular(_barWidth),
            ),
          ),
          child: const Center(
            child: Text("Show Graph"),
          ),
        );
      }
    }
  }

  Widget _generateBar({required DateTime date, required double income, required double expense, required double maxIncome, required double maxExpense}) {
    String dateText = DateFormat('dd/MM').format(date.toLocal());

    // compute the income and expense length for the bar chart
    int incomeLength;
    int expenseLength;

    // check if the maxIncome or maxExpense is actually 0
    // if zero then cancelled the _incomeLength and _expenseLength as we should print
    // blank chart instead full one
    if(maxIncome <= 0) {
      incomeLength = 0;
    }
    else {
      incomeLength = (((income/maxIncome) * 1000) ~/ 4);
    }

    if(maxExpense <= 0) {
      expenseLength = 0;
    }
    else {
      expenseLength = (((expense/maxExpense) * 1000) ~/ 4);
    }

    // check if we got amount, but the income or expense length just too small
    // that make it 0
    if(income > 0 && incomeLength <= 0) {
      // defaulted it to at least 1 to tell that we have something here
      incomeLength = 1;
    }

    if(expense > 0 && expenseLength <= 0) {
      // defaulted it to at least 1 to tell that we have something here
      expenseLength = 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 45,
              child: Center(
                child: Text(
                  dateText,
                  style: const TextStyle(
                    color: textColor2,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5,),
            Expanded(
              child: Stack(
                children: <Widget>[
                  Container(
                    height: 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: primaryLight,
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        flex: (250 - incomeLength),
                        child: Container(
                          height: 20,
                          color: Colors.transparent,
                        ),
                      ),
                      Expanded(
                        flex: incomeLength,
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: accentColors[6],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              bottomLeft: Radius.circular(20)
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: expenseLength,
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: accentColors[2],
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(20),
                              bottomRight: Radius.circular(20)
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: (250 - expenseLength),
                        child: Container(
                          height: 20,
                          color: Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 2,
                    left: 5,
                    child: Text(
                      fCCY.format(income),
                      style: const TextStyle(
                        fontSize: 10,
                        color: textColor2,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 5,
                    child: Text(
                      fCCY.format(expense),
                      style: const TextStyle(
                        fontSize: 10,
                        color: textColor2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 5,),
      ],
    );
  }

  List<Widget> _generateBarCharts() {
    List<Widget> bars = [];
    DateTime currDate;
    double income = 0;
    double expense = 0;

    for(int index = 0; index <= widget.to.difference(widget.from).inDays; index++ ) {
      currDate = widget.from.add(Duration(days: index));
      income = (widget.data.income[currDate] ?? 0.0); 
      expense = (widget.data.expense[currDate] ?? 0.0);
      if(expense < 0) {
        expense *= (-1);
      }

      bars.add(
        _generateBar(
          date: currDate,
          income: income,
          expense: expense,
          maxIncome: _maxIncome,
          maxExpense: _maxExpense
        )
      );
    }
    return bars;
  }

  void _getMaxExpenseIncome() {
    _expense.forEach((key, value) {
      if(_maxExpense < (value * (-1))) {
        _maxExpense = (value * (-1));
      }
    });

    _income.forEach((key, value) {
      if(_maxIncome < value) {
        _maxIncome = value;
      }
    });
  }
}