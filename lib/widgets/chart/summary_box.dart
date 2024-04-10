import 'package:flutter/material.dart';

class SummaryBox extends StatelessWidget {
  final Color color;
  final String text;
  final String value;
  final int count;
  const SummaryBox({super.key, required this.color, required this.text, required this.value, required this.count});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 25,
            height: 50,
            color: color,
          ),
          const SizedBox(width: 5,),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(
                text,
                style: const TextStyle(
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold
                ),
              ),
              Text(
                "Total $count",
                style: const TextStyle(
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}