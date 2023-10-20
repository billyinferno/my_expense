import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/themes/colors.dart';

class SimpleItem extends StatelessWidget {
  final Color color;
  final Widget child;
  final String description;
  final bool? isSelected;
  final Color? checkmarkColor;
  final Function? onTap;
  const SimpleItem({
    Key? key,
    required this.color,
    required this.child,
    required this.description,
    this.isSelected,
    this.checkmarkColor,
    this.onTap
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ListTile(
          leading: Container(
            height: 40,
            width: 40,
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: color,
            ),
            child: child,
          ),
          title: Text(description),
          trailing: Visibility(
            visible: (isSelected ?? false),
            child: Icon(
              Ionicons.checkmark_circle,
              size: 20,
              color: (checkmarkColor ?? accentColors[0]),
            ),
          ),
          onTap: () {
            if (onTap != null) {
              onTap!();
            }
          },
        ),
      ),
    );
  }
}