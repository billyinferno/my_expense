import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_expense/_index.g.dart';

class BudgetBar extends StatelessWidget {
  final Icon? icon;
  final Color? iconColor;
  final String title;
  final String? subTitle;
  final String symbol;
  final double budgetUsed;
  final double budgetTotal;
  final bool? showLeftText;
  final Color? barColor;
  final String? type;

  BudgetBar(
      {super.key,
      this.icon,
      this.iconColor,
      this.showLeftText,
      this.barColor,
      required this.title,
      this.subTitle,
      required this.symbol,
      required this.budgetUsed,
      required this.budgetTotal,
      this.type});

  final _fCCY = NumberFormat("#,##0.00", "en_US");

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
                    visible: (showLeftText == null ? true : showLeftText!),
                    child: Text(
                      "$symbol ${_fCCY.format(budgetTotal - budgetUsed)}${budgetTotal >= budgetUsed ? " left" : " over"}",
                      textAlign: TextAlign.right,
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 2,
              ),
              SizedBox(
                height: 20,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: <Widget>[
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: secondaryBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                        clipBehavior: Clip.hardEdge,
                        borderRadius: BorderRadius.circular(20),
                        child: OverflowBox(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: ((budgetUsed / budgetTotal) <= 1 ? (budgetUsed / budgetTotal) : 1),
                            child: Container(
                              height: 20,
                              decoration: BoxDecoration(
                                color: (barColor ?? _getBarColor()),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 10),
                      child: Text(
                        "$symbol ${_fCCY.format(budgetUsed)} of $symbol ${_fCCY.format(budgetTotal)}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: textColor2,
                        ),
                      ),
                    ),
                  ],
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
