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
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
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
                      ),
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
                          child: ClipRect(
                            clipBehavior: Clip.hardEdge,
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
    double _fraction;
    int _sR = 0;
    int _sG = 0;
    int _sB = 0;
    int _tR = 0;
    int _tG = 0;
    int _tB = 0;

    if (_totalUsed >= 0.80) {
      // red
      return accentColors[10];
    } else if (_totalUsed >= 0.60) {
      // blend between red and orange
      // fraction will be used by the secondary color
      _sR = accentColors[2].red - accentColors[1].red;
      _sG = accentColors[2].green - accentColors[1].green;
      _sB = accentColors[2].blue - accentColors[1].blue;

      _fraction = (0.80 - _totalUsed) * 100;
      _sR = _sR.toDouble() ~/ _fraction;
      _sG = _sG.toDouble() ~/ _fraction;
      _sB = _sB.toDouble() ~/ _fraction;
      //print(_totalUsed.toString() + " : " + _sR.toString() + "," + _sG.toString() + "," + _sB.toString());

      _tR = (accentColors[1].red + _sR);
      _tG = (accentColors[1].green + _sG);
      _tB = (accentColors[1].blue + _sB);

      return Color.fromARGB(0xFF, _tR, _tG, _tB);
    } else if (_totalUsed >= 0.40) {
      // orange
      return accentColors[1];
    } else if (_totalUsed >= 0.20) {
      // blend between orange and blue
      // fraction will be used by the secondary color
      _sR = accentColors[1].red - accentColors[4].red;
      _sG = accentColors[1].green - accentColors[4].green;
      _sB = accentColors[1].blue - accentColors[4].blue;

      _fraction = (0.40 - _totalUsed) * 100;
      _sR = _sR.toDouble() ~/ _fraction;
      _sG = _sG.toDouble() ~/ _fraction;
      _sB = _sB.toDouble() ~/ _fraction;
      //print(_totalUsed.toString() + " : " + _sR.toString() + "," + _sG.toString() + "," + _sB.toString());

      _tR = (accentColors[4].red + _sR);
      _tG = (accentColors[4].green + _sG);
      _tB = (accentColors[4].blue + _sB);

      return Color.fromARGB(0xFF, _tR, _tG, _tB);
    }
    return accentColors[4];
  }
}
