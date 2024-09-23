import 'package:flutter/material.dart';
import 'package:my_expense/_index.g.dart';

class MySwitch extends StatelessWidget {
  final bool enabled;
  final double width;
  final Color? activeColor;
  final Color disabledColor;
  final Color borderColor;
  final Color toggleColor;

  const MySwitch({
    super.key,
    required this.enabled,
    this.width = 40,
    this.activeColor,
    this.disabledColor = secondaryDark,
    this.borderColor = secondaryLight,
    this.toggleColor = textColor2
  });

  @override
  Widget build(BuildContext context) {
    Color currentActiveColor = (activeColor ?? accentColors[0]);

    return SizedBox(
      height: 25,
      width: width,
      child: Stack(
        children: <Widget>[
          Container(
            height: 25,
            width: width,
            decoration: BoxDecoration(
              color: (enabled ? currentActiveColor : disabledColor),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: borderColor,
                width: 1.0,
                style: BorderStyle.solid,
              ),
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
                border: Border.all(
                  color: borderColor,
                  width: 1.0,
                  style: BorderStyle.solid,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}