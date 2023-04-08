import 'package:flutter/material.dart';
import 'package:my_expense/themes/colors.dart';

class Bar extends StatelessWidget {
  final double amount;
  final double maxAmount;
  final String text;
  final Color color;
  const Bar({Key? key, required this.amount, required this.maxAmount, required this.text, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Flexible(
            child: FractionallySizedBox(
              alignment: FractionalOffset.centerLeft,
              widthFactor: ((amount < 0 ? 0 : amount) / maxAmount),
              child: Container(
                height: 20,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 5,),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: textColor,
            ),
          )
        ],
      ),
    );
  }
}