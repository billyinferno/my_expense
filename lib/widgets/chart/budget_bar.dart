import 'package:flutter/material.dart';
import 'package:my_expense/_index.g.dart';

class BudgetBar extends StatelessWidget {
  final Icon? icon;
  final Color? iconColor;
  final String title;
  final String? subTitle;
  final String symbol;
  final double budgetUsed;
  final double budgetTotal;
  final bool showLeftText;
  final Color? barColor;
  final String? type;

  const BudgetBar({
    super.key,
    this.icon,
    this.iconColor,
    this.showLeftText = true,
    this.barColor,
    required this.title,
    this.subTitle,
    required this.symbol,
    required this.budgetUsed,
    required this.budgetTotal,
    this.type
  });

  @override
  Widget build(BuildContext context) {
    return _buildBudgetBarChart();
  }

  Widget _buildBudgetBarChart() {
    String currentType = (type ?? 'in');
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Visibility(
          visible: (icon == null ? false : true),
          child: Container(
            height: 40,
            width: 40,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: (currentType.toLowerCase() == 'in' ? iconColor : Colors.orange[900]!),
              border: Border.all(
                color: (currentType.toLowerCase() == 'in' ? Colors.transparent : Colors.red[900]!),
                style: BorderStyle.solid,
                width: 2.0,
              )
            ),
            child: icon,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Visibility(
                          visible: (subTitle != null),
                          child: Text(
                            (subTitle ?? ''),
                            style: const TextStyle(
                              fontSize: 10,
                              color: textColor2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: showLeftText,
                    child: Text(
                      "$symbol ${Globals.fCCY.format((budgetTotal - budgetUsed).makePositive())}${budgetTotal >= budgetUsed ? " left" : " over"}",
                      textAlign: TextAlign.right,
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 2,
              ),
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: secondaryBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  clipBehavior: Clip.hardEdge,
                  borderRadius: BorderRadius.circular(20),
                  child: Bar(
                    amount: budgetUsed,
                    maxAmount: budgetTotal,
                    color: (barColor ?? _getBarColor()),
                    darken: false,
                    shadingAlpha: 25,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                      child: Text(
                        "$symbol ${Globals.fCCY.format(budgetUsed)} of $symbol ${Globals.fCCY.format(budgetTotal)}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: textColor2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getBarColor() {
    // check if this already over budger or not?
    if (budgetUsed > budgetTotal || budgetTotal <= 0) {
      return Colors.red[900]!;
    }
    else {
      // calculate how many budget is being used
      double totalUsed = (budgetUsed / budgetTotal) * 100;

      // now based on 10% step
      if (totalUsed <= 10) {
        return Colors.green[900]!;
      }
      else if (totalUsed <= 20) {
        return Colors.green[800]!;
      }
      else if (totalUsed <= 30) {
        return Colors.green[700]!;
      }
      else if (totalUsed <= 40) {
        return Colors.green[600]!;
      }
      else if (totalUsed <= 50) {
        return Colors.orange[700]!;
      }
      else if (totalUsed <= 60) {
        return Colors.orange[800]!;
      }
      else if (totalUsed <= 70) {
        return Colors.orange[900]!;
      }
      else if (totalUsed <= 80) {
        return Colors.red[700]!;
      }
      else if (totalUsed <= 90) {
        return Colors.red[800]!;
      }
      // else
      return Colors.red[900]!;
    }
  }
}
