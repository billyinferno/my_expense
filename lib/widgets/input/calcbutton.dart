import 'package:flutter/material.dart';
import 'package:my_expense/themes/colors.dart';

class CalcButton extends StatelessWidget {
  final int? flex;
  final Color? color;
  final Color? borderColor;
  final double? borderWidth;
  final Widget child;
  final VoidCallback onTap;

  const CalcButton({ Key? key, this.flex, this.color, this.borderColor, this.borderWidth, required this.child, required this.onTap }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int _flex = (flex ?? 1);
    Color _color = (color ?? secondaryDark);
    Color _borderColor = (borderColor ?? secondaryLight);
    double _borderWidth = (borderWidth ?? 1.0);

    return Expanded(
      flex: _flex,
      child: InkWell(
        onTap: (() {
          onTap();
        }),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: _color,
            border: Border.all(color: _borderColor, width: _borderWidth),
          ),
          child: child,
        ),
      ),
    );
  }
}