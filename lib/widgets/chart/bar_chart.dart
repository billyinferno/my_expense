import 'dart:math';

import 'package:flutter/material.dart';
import 'package:my_expense/_index.g.dart';

class BarChart extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  final IncomeExpenseModel data;
  final double? barWidth;
  final double? fontSize;
  final bool? showed;
  final double? maxAmount;
  const BarChart({
    super.key,
    required this.from,
    required this.to,
    required this.data,
    this.barWidth,
    this.fontSize,
    this.showed,
    this.maxAmount
  });

  @override
  Widget build(BuildContext context) {
    // check if data is empty or not?
    if (data.expense.isEmpty && data.income.isEmpty) {
      return const SizedBox(
        width: double.infinity,
        child: Center(
          child: Text("No data"),
        ),
      );
    }
    else {
      return _buildBarChart();
    }
  }

  Widget _buildBarChart()  {
    bool isShowed = (showed ?? false);
    
    // check if showed or not?
    if (!isShowed) {
      // return the button text instead the bar chart
      return Container(
        width: double.infinity,
        height: 40,
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: secondaryDark,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: const Center(
          child: Text("Show Graph"),
        ),
      );
    }

    // generate the bar chart
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: _generateBarCharts(),
          )
        ],
      ),
    );
  }

  List<Widget> _generateBarCharts() {
    final List<Widget> bars = [];
    DateTime currDate;
    double income = 0;
    double expense = 0;
    double maxExpense = _getMaxAmount(data: data.expense, clamp: maxAmount);
    double maxIncome = _getMaxAmount(data: data.income, clamp: maxAmount);

    for(int index = 0; index <= to.difference(from).inDays; index++ ) {
      currDate = from.add(Duration(days: index));
      income = (data.income[currDate] ?? 0.0); 
      expense = (data.expense[currDate] ?? 0.0);
      if(expense < 0) {
        expense *= (-1);
      }

      bars.add(
        _generateBar(
          date: currDate,
          income: income,
          expense: expense,
          maxIncome: maxIncome,
          maxExpense: maxExpense,
        )
      );
    }
    return bars;
  }

  Widget _generateBar({
    required DateTime date,
    required double income,
    required double expense,
    required double maxIncome,
    required double maxExpense,
  }) {
    String dateText = Globals.dfddMM.formatLocal(date);

    // compute the income and expense length for the bar chart
    int incomeLength;
    int expenseLength;
    bool isIncomeExceeded;
    bool isExpenseExceeded;

    // check if the maxIncome or maxExpense is actually 0
    // if zero then cancelled the _incomeLength and _expenseLength as we should print
    // blank chart instead full one
    if(maxIncome <= 0) {
      incomeLength = 0;
    }
    else {
      incomeLength = ((income/maxIncome) * 100).toInt();
    }

    if(maxExpense <= 0) {
      expenseLength = 0;
    }
    else {
      expenseLength = ((expense/maxExpense) * 100).toInt();
    }

    // check if we got amount, but the income or expense length just too small
    // that make it 0
    if(income > 0 && incomeLength <= 0) {
      // defaulted it to at least 1 to tell that we have something here
      incomeLength = 1;
    }
    
    // clamp income length to 250 if it's exceeded
    isIncomeExceeded = false;
    if (incomeLength > 100) {
      incomeLength = 100;
      isIncomeExceeded = true;
    }

    if(expense > 0 && expenseLength <= 0) {
      // defaulted it to at least 1 to tell that we have something here
      expenseLength = 1;
    }

    // clamp expense length to 250 if it's exceeded
    isExpenseExceeded = false;
    if (expenseLength > 100) {
      expenseLength = 100;
      isExpenseExceeded = true;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 5),
      child: Row(
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
            child: Container(
              decoration: BoxDecoration(
                color: primaryLight,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        flex: (100 - incomeLength),
                        child: SizedBox(),
                      ),
                      Expanded(
                        flex: incomeLength,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                (isIncomeExceeded ? darkAccentColors[6] : accentColors[6]),
                                accentColors[6],
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              bottomLeft: Radius.circular(20)
                            ),
                          ),
                          child: Text(
                            "",
                            style: const TextStyle(
                              fontSize: 10,
                              color: textColor2,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: expenseLength,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentColors[2],
                                (isExpenseExceeded ? darkAccentColors[2] : accentColors[2])
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(20),
                              bottomRight: Radius.circular(20)
                            ),
                          ),
                          child: Text(
                            "",
                            style: const TextStyle(
                              fontSize: 10,
                              color: textColor2,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: (100 - expenseLength),
                        child: SizedBox(),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(
                      10,
                      0,
                      10,
                      0
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          Globals.fCCY.format(income),
                          style: const TextStyle(
                            fontSize: 10,
                            color: textColor2,
                          ),
                        ),
                        Text(
                          Globals.fCCY.format(expense),
                          style: const TextStyle(
                            fontSize: 10,
                            color: textColor2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxAmount({required Map<DateTime, double> data, double? clamp}) {
    // check clamp
    if (clamp != null) {
      if (clamp > 0) {
        return clamp;
      }
    }

    double maxAmount = 0;

    // loop thru data
    data.forEach((key, value) {
      if (value < 0) {
        maxAmount = max(maxAmount, (value * -1));
      }
      else {
        maxAmount = max(maxAmount, value);
      }
    });

    // return max amount
    return maxAmount;
  }
}