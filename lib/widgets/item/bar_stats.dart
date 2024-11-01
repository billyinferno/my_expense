import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_expense/_index.g.dart';

class BarStat extends StatelessWidget {
  final double? income;
  final double? expense;
  final double? balance;
  final double maxAmount;
  final DateTime date;
  final DateFormat? dateFormat;
  final bool showExpense;
  final bool showIncome;
  final bool showBalance;
  const BarStat({
    super.key,
    this.income,
    this.expense,
    this.balance,
    required this.maxAmount,
    required this.date,
    this.dateFormat,
    this.showExpense = true,
    this.showIncome = true,
    this.showBalance = true,
  });

  @override
  Widget build(BuildContext context) {
    Color indicator = Colors.white;
    if ((income ?? 0) > (expense ?? 0)) {
      indicator = accentColors[0];
    } else if ((income ?? 0) < (expense ?? 0)) {
      indicator = accentColors[2];
    }

    DateFormat df = (dateFormat ?? Globals.dfyyyyMM);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 5),
      decoration: BoxDecoration(
        color: primaryLight,
        borderRadius: BorderRadius.circular(5),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            // indicator
            Container(
              width: 10,
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
              width: 80,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  df.formatLocal(date),
                ),
              ),
            ),
            // bar chart
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Visibility(
                      visible: showIncome,
                      child: Bar(
                        amount: (income ?? 0),
                        maxAmount: maxAmount,
                        text: Globals.fCCY.format(income ?? 0),
                        color: accentColors[0]
                      ),
                    ),
                    Visibility(
                      visible: showExpense,
                      child: Bar(
                        amount: (expense ?? 0),
                        maxAmount: maxAmount,
                        text: Globals.fCCY.format(expense ?? 0),
                        color: accentColors[2]
                      ),
                    ),
                    Visibility(
                      visible: showBalance,
                      child: Bar(
                        amount: (balance ?? 0),
                        maxAmount: maxAmount,
                        text: Globals.fCCY.format(balance ?? 0),
                        color: accentColors[4]
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}