import 'package:flutter/material.dart';
import 'package:my_expense/themes/colors.dart';

class MySwitch extends StatelessWidget {
  final bool enabled;
  final double? width;
  final Color? activeColor;
  final Color? disabledColor;
  final Color? borderColor;
  final Color? toggleColor;

  const MySwitch({ super.key, required this.enabled, this.width, this.activeColor, this.disabledColor, this.borderColor, this.toggleColor});

  @override
  Widget build(BuildContext context) {
    double currentWidth = (width ?? 40);
    Color currentActiveColor = (activeColor ?? accentColors[6]);
    Color currentDisabledColor = (disabledColor ?? secondaryDark);
    Color currentBorderColor = (borderColor ?? secondaryLight);

    return SizedBox(
      height: 25,
      width: currentWidth,
      child: Stack(
        children: <Widget>[
          Container(
            height: 25,
            width: currentWidth,
            decoration: BoxDecoration(
              color: (enabled ? currentActiveColor : currentDisabledColor),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: currentBorderColor, width: 1.0),
            ),
          ),
          Positioned(
            left: (enabled ? null : 0),
            right: (enabled ? 0 : null),
            child: Container(
              height: 25,
              width: 25,
              decoration: BoxDecoration(
                color: textColor2,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: currentBorderColor, width: 1.0),
              ),
            ),
          )
        ],
      ),
    );
  }
}