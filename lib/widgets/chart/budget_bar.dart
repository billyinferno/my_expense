import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_expense/themes/colors.dart';

class BudgetBar extends StatelessWidget {
  final Icon? icon;
  final Color? iconColor;
  final String title;
  final String symbol;
  final double budgetUsed;
  final double budgetTotal;
  final bool? showLeftText;
  final Color? barColor;

  BudgetBar(
      {Key? key,
      this.icon,
      this.iconColor,
      this.showLeftText,
      this.barColor,
      required this.title,
      required this.symbol,
      required this.budgetUsed,
      required this.budgetTotal})
      : super(key: key);

  final _fCCY = new NumberFormat("#,##0.00", "en_US");

  @override
  Widget build(BuildContext context) {
    return _buildBudgetBarChart();
  }

  Widget _buildBudgetBarChart() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Visibility(
            visible: (icon == null ? false : true),
            child: Container(
              height: 40,
              width: 40,
              margin: EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                color: iconColor,
              ),
              child: icon,
            ),
          ),
          Expanded(
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SizedBox(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        child: Visibility(
                          visible: (showLeftText == null ? true : showLeftText!),
                          child: Text(
                            symbol +
                                " " +
                                _fCCY.format(budgetTotal - budgetUsed) +
                                " left",
                            textAlign: TextAlign.right,
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Container(
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
                                child: Container(
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: (barColor == null ? _getBarColor() : barColor),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                widthFactor: ((budgetUsed / budgetTotal) <= 1 ? (budgetUsed / budgetTotal) : 1),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 10),
                          child: Text(
                            symbol +
                                " " +
                                _fCCY.format(budgetUsed) +
                                " of " +
                                symbol +
                                " " +
                                _fCCY.format(budgetTotal),
                            style: TextStyle(
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
          ),
        ],
      ),
    );
  }

  Color _getBarColor() {
    // check the budget being used
    double _totalUsed = budgetUsed / budgetTotal;
    // double _fraction;
    int _sR = 0;
    int _sG = 0;
    int _sB = 0;
    int _tR = 0;
    int _tG = 0;
    int _tB = 0;
    int _count;

    // get the current
    _count = ((_totalUsed - 0.01) * 100).toInt();

    if (_count >= 100) {
      return accentColors[10];
    }

    // between 1%-50% put gradient between green orange
    if (_count <= 50) {
      _sR = ((1 - (_count/99)) * accentColors[0].red).toInt();
      _sG = ((1 - (_count/99)) * accentColors[0].green).toInt();
      _sB = ((1 - (_count/99)) * accentColors[0].blue).toInt();

      _tR = ((_count/99) * accentColors[1].red).toInt();
      _tG = ((_count/99) * accentColors[1].green).toInt();
      _tB = ((_count/99) * accentColors[1].blue).toInt();

      return Color.fromARGB(0xFF, (_sR + _tR), (_sG + _tG), (_sB + _tB));      
    }

    // other than that put orange to red
    _sR = ((1 - (_count/50)) * accentColors[1].red).toInt();
    _sG = ((1 - (_count/50)) * accentColors[1].green).toInt();
    _sB = ((1 - (_count/50)) * accentColors[1].blue).toInt();

    _tR = ((_count/50) * accentColors[10].red).toInt();
    _tG = ((_count/50) * accentColors[10].green).toInt();
    _tB = ((_count/50) * accentColors[10].blue).toInt();

    return Color.fromARGB(0xFF, (_sR + _tR), (_sG + _tG), (_sB + _tB));
  }
}
