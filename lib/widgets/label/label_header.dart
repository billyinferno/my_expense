import 'package:flutter/material.dart';
import 'package:my_expense/_index.g.dart';

class LabelHeader extends StatelessWidget {
  final String data;
  final Color color;
  final double size;
  final bool bold;

  const LabelHeader(
    this.data, {
      super.key,
      this.color = secondaryLight,
      this.size = 22,
      this.bold = true,
    }
  );

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: (bold ? FontWeight.bold : FontWeight.normal),
      ),
    );
  }
}