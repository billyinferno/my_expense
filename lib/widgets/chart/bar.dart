import 'package:flutter/material.dart';
import 'package:my_expense/_index.g.dart';

class Bar extends StatelessWidget {
  final double amount;
  final double maxAmount;
  final String text;
  final Color color;
  const Bar({
    super.key,
    required this.amount,
    required this.maxAmount,
    required this.text,
    required this.color
  });

  @override
  Widget build(BuildContext context) {
    double darkenValue = (amount/maxAmount) - 0.7;
    if (darkenValue < 0) {
      darkenValue = 0;
    }
    if (darkenValue > 0.7) {
      darkenValue = 0.7;
    }

    return SizedBox(
      width: double.infinity,
      child: IntrinsicHeight(
        child: Stack(
          children: <Widget>[
            Row(
              children: <Widget>[
                Flexible(
                  child: FractionallySizedBox(
                    alignment: FractionalOffset.centerLeft,
                    widthFactor: 0.8,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 2),
                      decoration: BoxDecoration(
                        color: color.darken(amount: 0.5),
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
                                      margin: const EdgeInsets.fromLTRB(4, 2, 4, 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(50),
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
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 10,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // child: Stack(
      //   children: <Widget>[
      //     Row(
      //       crossAxisAlignment: CrossAxisAlignment.center,
      //       mainAxisAlignment: MainAxisAlignment.start,
      //       children: <Widget>[
      //         Flexible(
      //           child: FractionallySizedBox(
      //             alignment: FractionalOffset.centerLeft,
      //             widthFactor: ((amount < 0 ? 0 : amount) / maxAmount),
      //             child: Container(
      //               decoration: BoxDecoration(
      //                 borderRadius: const BorderRadius.only(
      //                   topRight: Radius.circular(100),
      //                   bottomRight: Radius.circular(100),
      //                 ),
      //                 gradient: LinearGradient(
      //                   colors: [
      //                     color,
      //                     color.darken(amount: darkenValue),
      //                   ]
      //                 ),
      //               ),
      //               child: Text(
      //                 " ",
      //                 style: TextStyle(
      //                   fontSize: 10,
      //                   color: Colors.transparent
      //                 ),
      //               ),
      //             ),
      //           ),
      //         ),
      //       ],
      //     ),
      //     Align(
      //       alignment: Alignment.centerRight,
      //       child: Container(
      //         padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
      //         child: Text(
      //           text,
      //           style: const TextStyle(
      //             fontSize: 10,
      //             color: textColor,
      //           ),
      //         ),
      //       ),
      //     ),
      //   ],
      // ),
    );
  }
}