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
  
  const BarChart({ Key? key, required this.from, required this.to, required this.data, this.barWidth, this.fontSize }) : super(key: key);

  @override
  _BarChartState createState() => _BarChartState();
}

class _BarChartState extends State<BarChart> {
  Map<DateTime, double> _expense = {};
  Map<DateTime, double> _income = {};
  double _maxExpense = 0.0;
  double _maxIncome = 0.0;
  double _barWidth = 6;
  bool _isShowed = false;

  final fCCY = new NumberFormat("#,##0.00", "en_US");

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
    if(widget.data.expense.length <= 0 && widget.data.income.length <= 0) {
      return Container(
        width: double.infinity,
        height: 35,
        margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Color(0xff232d37),
          borderRadius: BorderRadius.only(
            topLeft:Radius.circular(_barWidth),
            topRight: Radius.circular(_barWidth),
            bottomLeft: Radius.circular(_barWidth),
            bottomRight: Radius.circular(_barWidth),
          ),
        ),
        child: Center(
          child: Text("No Data"),
        ),
      );
    }
    else {
      if(_isShowed) {
        return Container(
          width: double.infinity,
          margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Color(0xff232d37),
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
              Center(child: Text("Close Graph")),
              SizedBox(height: 10,),
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
          height: 35,
          margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Color(0xff232d37),
            borderRadius: BorderRadius.only(
              topLeft:Radius.circular(_barWidth),
              topRight: Radius.circular(_barWidth),
              bottomLeft: Radius.circular(_barWidth),
              bottomRight: Radius.circular(_barWidth),
            ),
          ),
          child: Center(
            child: Text("Show Graph"),
          ),
        );
      }
    }
  }

  Widget _generateBar({required DateTime date, required double income, required double expense, required double maxIncome, required double maxExpense}) {
    String _dateText = DateFormat('dd/MM').format(date.toLocal());

    // compute the income and expense length for the bar chart
    int _incomeLength;
    int _expenseLength;

    // check if the maxIncome or maxExpense is actually 0
    // if zero then cancelled the _incomeLength and _expenseLength as we should print
    // blank chart instead full one
    if(maxIncome <= 0) {
      _incomeLength = 0;
    }
    else {
      _incomeLength = (((income/maxIncome) * 1000) ~/ 4);
    }

    if(maxExpense <= 0) {
      _expenseLength = 0;
    }
    else {
      _expenseLength = (((expense/maxExpense) * 1000) ~/ 4);
    }

    // check if we got amount, but the income or expense length just too small
    // that make it 0
    if(income > 0 && _incomeLength <= 0) {
      // defaulted it to at least 1 to tell that we have something here
      _incomeLength = 1;
    }

    if(expense > 0 && _expenseLength <= 0) {
      // defaulted it to at least 1 to tell that we have something here
      _expenseLength = 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 45,
              child: Center(
                child: Text(
                  _dateText,
                  style: TextStyle(
                    color: textColor2,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            SizedBox(width: 5,),
            Expanded(
              child: Stack(
                children: <Widget>[
                  Container(
                    height: 15,
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
                        flex: (250 - _incomeLength),
                        child: Container(
                          height: 15,
                          color: Colors.transparent,
                        ),
                      ),
                      Expanded(
                        flex: _incomeLength,
                        child: Container(
                          height: 15,
                          decoration: BoxDecoration(
                            color: accentColors[6],
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: _expenseLength,
                        child: Container(
                          height: 15,
                          decoration: BoxDecoration(
                            color: accentColors[2],
                            borderRadius: BorderRadius.only(topRight: Radius.circular(15), bottomRight: Radius.circular(15)),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: (250 - _expenseLength),
                        child: Container(
                          height: 15,
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
                      style: TextStyle(
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
                      style: TextStyle(
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
        SizedBox(height: 5,),
      ],
    );
  }

  List<Widget> _generateBarCharts() {
    List<Widget> _bars = [];
    DateTime _currDate;
    double _income = 0;
    double _expense = 0;

    for(int index = 0; index <= widget.to.difference(widget.from).inDays; index++ ) {
      _currDate = widget.from.add(Duration(days: index));
      _income = (widget.data.income[_currDate] ?? 0.0); 
      _expense = (widget.data.expense[_currDate] ?? 0.0);
      if(_expense < 0) {
        _expense *= (-1);
      }

      _bars.add(
        _generateBar(
          date: _currDate,
          income: _income,
          expense: _expense,
          maxIncome: _maxIncome,
          maxExpense: _maxExpense
        )
      );
    }
    return _bars;
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