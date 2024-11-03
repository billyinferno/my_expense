import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class SortIcon extends StatelessWidget {
  final bool asc;
  final Function()? onPress;
  const SortIcon({
    super.key,
    required this.asc,
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: (() {
        if (onPress != null) {
          onPress!();
        }
      }),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              (asc ? Ionicons.arrow_up : Ionicons.arrow_down),
              size: 15,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
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
      ),
    );
  }
}