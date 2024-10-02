import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class SortIcon extends StatelessWidget {
  final bool asc;
  const SortIcon({
    super.key,
    required this.asc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            (asc ? Ionicons.arrow_down : Ionicons.arrow_up),
            size: 15,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(
                (asc ? "A" : "Z"),
                style: TextStyle(
                  fontSize: 10,
                ),
              ),
              Text(
                (asc ? "Z" : "A"),
                style: TextStyle(
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