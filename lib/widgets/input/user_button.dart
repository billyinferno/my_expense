import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

class UserButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final String label;
  final Widget? trailing;
  final bool showArrow;
  final Color arrowColor;
  final VoidCallback callback;

  const UserButton({
    super.key,
    required this.icon,
    this.iconSize = 20,
    required this.iconColor,
    required this.label,
    this.trailing,
    this.showArrow = true,
    this.arrowColor = primaryLight,
    required this.callback
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: secondaryLight, width: 1.0)),
      ),
      child: GestureDetector(
        onTap: callback,
        child: Container(
          color: Colors.transparent,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                color: iconColor,
                size: iconSize,
              ),
              const SizedBox(width: 10,),
              Text(
                label,
                style: const TextStyle(
                  color: textColor2,
                ),
              ),
              (label.isNotEmpty ? const SizedBox(width: 10,) : const SizedBox.shrink()),
              Expanded(
                child: SizedBox(
                  child: (trailing ?? const SizedBox.shrink()),
                ),
              ),
              const SizedBox(width: 10,),
              Visibility(
                visible: showArrow,
                child: Icon(
                  Ionicons.chevron_forward_outline,
                  color: arrowColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
