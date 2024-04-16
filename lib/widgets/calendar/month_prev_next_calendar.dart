import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/themes/colors.dart';

class MonthPrevNextCalendar extends StatelessWidget {
  final Color? background;
  final Color? border;
  final DateTime initialDate;
  final Function(DateTime, DateTime) onPress;
  const MonthPrevNextCalendar({
    this.background,
    this.border,
    required this.initialDate,
    required this.onPress,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    final DateFormat df = DateFormat("MMMM yyyy");

    return Container(
      height: 35,
      width: double.infinity,
      decoration: BoxDecoration(
        color: (background ?? secondaryDark),
        border: Border(
          bottom: BorderSide(
            color: (border ?? primaryBackground),
            width: 1.0,
            style: BorderStyle.solid
          )
        )
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          InkWell(
            onTap: (() {
              // change the date
              _goPrevMonth();
            }),
            child: Container(
              color: Colors.transparent,
              width: 50,
              height: 35,
              child: const Icon(
                Ionicons.arrow_back_circle,
                size: 20,
                color: textColor,
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.transparent,
              child: Center(child: Text(df.format(initialDate)),),
            ),
          ),
          InkWell(
            onTap: (() {
              _goNextMonth();
            }),
            child: Container(
              color: Colors.transparent,
              width: 50,
              height: 35,
              child: const Icon(
                Ionicons.arrow_forward_circle,
                size: 20,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goPrevMonth() {
    DateTime from = DateTime(initialDate.year, initialDate.month-1, 1).toLocal();
    DateTime to = DateTime(initialDate.year, initialDate.month, 1).subtract(const Duration(days: 1)).toLocal();
    
    onPress(from, to);
  }

  void _goNextMonth() {
    DateTime from = DateTime(initialDate.year, initialDate.month+1, 1);
    DateTime to = DateTime(initialDate.year, initialDate.month+2, 1).subtract(const Duration(days: 1));

    onPress(from, to);
  }
}