import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

class SimpleItem extends StatelessWidget {
  final Color color;
  final Widget icon;
  final String title;
  final bool isSelected;
  final IconData checkmarkIcon;
  final Color? checkmarkColor;
  final Function? onTap;
  final bool isDisabled;
  const SimpleItem({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    this.isSelected = false,
    this.checkmarkIcon = Ionicons.checkmark_circle,
    this.checkmarkColor,
    this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ListTile(
          leading: Container(
            height: 40,
            width: 40,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: color,
            ),
            child: icon,
          ),
          title: Text(title),
          trailing: Visibility(
            visible: isSelected,
            child: Icon(
              checkmarkIcon,
              size: 20,
              color: (checkmarkColor ?? accentColors[0]),
            ),
          ),
          onTap: () {
            // check if disabled or not?
            if (!isDisabled) {
              if (onTap != null) {
                onTap!();
              }
            }
          },
        ),
      ),
    );
  }
}