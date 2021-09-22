import 'package:flutter/material.dart';
import 'package:my_expense/themes/colors.dart';

class MySwitch extends StatelessWidget {
  final bool enabled;
  final double? width;
  final Color? activeColor;
  final Color? disabledColor;
  final Color? borderColor;
  final Color? toggleColor;

  const MySwitch({ Key? key, required this.enabled, this.width, this.activeColor, this.disabledColor, this.borderColor, this.toggleColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double _width = (width ?? 40);
    Color _activeColor = (activeColor ?? accentColors[6]);
    Color _disabledColor = (disabledColor ?? secondaryDark);
    Color _borderColor = (borderColor ?? secondaryLight);

    return SizedBox(
      height: 25,
      width: _width,
      child: Stack(
        children: <Widget>[
          Container(
            height: 25,
            width: _width,
            decoration: BoxDecoration(
              color: (enabled ? _activeColor : _disabledColor),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: _borderColor, width: 1.0),
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
                border: Border.all(color: _borderColor, width: 1.0),
              ),
            ),
          )
        ],
      ),
    );
  }
}