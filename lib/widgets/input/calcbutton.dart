import 'package:flutter/material.dart';
import 'package:my_expense/themes/colors.dart';

class CalcButton extends StatelessWidget {
  final int? flex;
  final Color? color;
  final Color? borderColor;
  final double? borderWidth;
  final Widget child;
  final VoidCallback onTap;

  const CalcButton({ super.key, this.flex, this.color, this.borderColor, this.borderWidth, required this.child, required this.onTap });

  @override
  Widget build(BuildContext context) {
    int flexNum = (flex ?? 1);
    Color currentColor = (color ?? secondaryDark);
    Color currrentBorderColor = (borderColor ?? secondaryLight);
    double currentBorderWidth = (borderWidth ?? 1.0);

    return Expanded(
      flex: flexNum,
      child: TextFieldTapRegion(
        child: InkWell(
          onTap: (() {
            onTap();
          }),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: currentColor,
              border: Border.all(color: currrentBorderColor, width: currentBorderWidth),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}