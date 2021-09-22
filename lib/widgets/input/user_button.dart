import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/themes/colors.dart';

class UserButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget value;
  final VoidCallback callback;

  UserButton({required this.icon, required this.iconColor, required this.label, required this.value, required this.callback});

  @override
  Widget build(BuildContext context) {
    double _sizedBoxMargin = (this.label.length > 0 ? 10 : 0);
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
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
              ),
              SizedBox(width: 10,),
              Text(
                label,
                style: TextStyle(
                  color: textColor2,
                ),
              ),
              SizedBox(width: _sizedBoxMargin,),
              Expanded(
                child: Container(
                  height: 50,
                  width: double.infinity,
                  color: Colors.transparent,
                  child: value,
                ),
              ),
              SizedBox(width: 10,),
              Icon(
                Ionicons.chevron_forward_outline,
                color: primaryLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
