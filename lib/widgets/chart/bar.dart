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
      child: Stack(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Flexible(
                child: FractionallySizedBox(
                  alignment: FractionalOffset.centerLeft,
                  widthFactor: ((amount < 0 ? 0 : amount) / maxAmount),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(100),
                        bottomRight: Radius.circular(100),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          color,
                          color.darken(amount: darkenValue),
                        ]
                      ),
                    ),
                    child: Text(
                      " ",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.transparent
                      ),
                    ),
                  ),
                ),
              ),
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
    );
  }
}