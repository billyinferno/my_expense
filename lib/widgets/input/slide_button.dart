import 'package:flutter/material.dart';

class SlideButton extends StatelessWidget {
  final IconData icon;
  final double? iconSize;
  final Color iconColor;
  final String? text;
  final Color? textColor;
  final double? textSize;
  final Color? bgColor;
  final BoxBorder? border;
  final Function? onTap;
  const SlideButton({
    super.key,
    required this.icon,
    this.iconSize,
    required this.iconColor,
    this.text,
    this.textColor,
    this.textSize,
    this.bgColor,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    
    return Expanded(
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: (bgColor ?? Colors.transparent),
            border: border,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: (iconSize ?? 20),
                color: iconColor,
              ),
              _textWidget(
                text: text,
                textColor: textColor,
                textSize: textSize,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textWidget({
    String? text,
    Color? textColor,
    double? textSize,
  }) {
    if (text == null) {
      return const SizedBox.shrink();
    }
    else {
      // check if got text color and textSize
      if (textColor != null && textSize != null) {
        return Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: textSize,
          ),
        );
      }
      else {
        if (textColor != null) {
          return Text(
            text,
            style: TextStyle(
              color: textColor,
            ),
          );
        }
        else if (textSize != null) {
          return Text(
            text,
            style: TextStyle(
              fontSize: textSize,
            ),
          );
        }
        else {
          return Text(text);
        }
      }
    }
  }
}