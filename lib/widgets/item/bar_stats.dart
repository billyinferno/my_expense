import 'package:flutter/material.dart';
import 'package:my_expense/_index.g.dart';

class BarStat extends StatelessWidget {
  final double? income;
  final double? expense;
  final double? balance;
  final double maxAmount;
  final DateTime date;
  const BarStat({
    super.key,
    this.income,
    this.expense,
    this.balance,
    required this.maxAmount,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    Color indicator = Colors.white;
    if ((income ?? 0) > (expense ?? 0)) {
      indicator = accentColors[0];
    } else if ((income ?? 0) < (expense ?? 0)) {
      indicator = accentColors[2];
    }

    return Container(
      width: double.infinity,
      height: 45,
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 5),
      decoration: BoxDecoration(
        color: primaryLight,
        borderRadius: BorderRadius.circular(5),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            // indicator
            Container(
              width: 10,
              height: constraints.maxHeight,
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
              height: constraints.maxHeight,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  Globals.dfyyyyMM.formatLocal(date),
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
                    amount: income!,
                    maxAmount: maxAmount,
                    text: Globals.fCCY.format(income!),
                    color: accentColors[0]
                  ),
                  Bar(
                    amount: expense!,
                    maxAmount: maxAmount,
                    text: Globals.fCCY.format(expense!),
                    color: accentColors[2]
                  ),
                  Bar(
                    amount: balance!,
                    maxAmount: maxAmount,
                    text: Globals.fCCY.format(balance!),
                    color: accentColors[4]
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5,),
          ],
        );
      },),
    );
  }
}