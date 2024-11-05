import 'package:flutter/material.dart';
import 'package:my_expense/_index.g.dart';

class Bar extends StatelessWidget {
  final double amount;
  final double maxAmount;
  final Widget child;
  final Color color;
  final bool darken;
  final int shadingAlpha;
  const Bar({
    super.key,
    required this.amount,
    required this.maxAmount,
    required this.child,
    required this.color,
    this.darken = true,
    this.shadingAlpha = 45,
  });

  @override
  Widget build(BuildContext context) {
    double darkenValue = (amount/maxAmount) - 0.7;
    if (darken) {
      if (darkenValue < 0) {
        darkenValue = 0;
      }
      if (darkenValue > 0.5) {
        darkenValue = 0.5;
      }
    }
    else {
      // if no need darken then default the darken value into 0
      darkenValue = 0;
    }
    
    double widthFactor = ((amount < 0 ? 0 : amount) / maxAmount);
    if (widthFactor > 1) {
      widthFactor = 1;
    }

    return SizedBox(
      width: double.infinity,
      child: IntrinsicHeight(
        child: Stack(
          alignment: Alignment.centerLeft,
          children: <Widget>[
            Row(
              children: <Widget>[
                Flexible(
                  child: FractionallySizedBox(
                    alignment: FractionalOffset.centerLeft,
                    widthFactor: widthFactor,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.darken(amount: 0.15),
                            color.darken(amount: darkenValue + 0.15),
                          ]
                        ),
                        borderRadius: BorderRadius.circular(100)
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    color,
                                    color.darken(amount: darkenValue),
                                  ]
                                ),
                                borderRadius: BorderRadius.circular(100)
                              ),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.fromLTRB(4, 2, 4, 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(shadingAlpha),
                                        borderRadius: BorderRadius.circular(100)
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}