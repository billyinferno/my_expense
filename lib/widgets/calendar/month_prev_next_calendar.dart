import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:my_expense/_index.g.dart';

class MonthPrevNextCalendar extends StatelessWidget {
  final Color? background;
  final Color? border;
  final DateTime initialDate;
  final DateTime minDate;
  final DateTime maxDate;
  final Function(DateTime, DateTime) onPress;
  const MonthPrevNextCalendar({
    this.background,
    this.border,
    required this.maxDate,
    required this.minDate,
    required this.initialDate,
    required this.onPress,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: (() async {
        // show the month dialog
        await showMonthPicker(
          context: context,
          initialDate: initialDate,
          firstDate: minDate,
          lastDate: maxDate,
        ).then((newDate) async {
          if (newDate != null) {
            DateTime from = DateTime(newDate.year, newDate.month, 1).toLocal();
            DateTime to = DateTime(newDate.year, newDate.month+1, 1).subtract(const Duration(days: 1)).toLocal();

            onPress(from, to);
          }
        });
      }),
      onDoubleTap: (() {
        DateTime from = DateTime(DateTime.now().year, DateTime.now().month, 1).toLocal();
        DateTime to = DateTime(DateTime.now().year, DateTime.now().month + 1, 1).subtract(const Duration(days: 1)).toLocal();
    
        onPress(from, to);
      }),
      child: Container(
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
                child: Center(child: Text(Globals.dfMMMMyyyy.format(initialDate)),),
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
      ),
    );
  }

  void _goPrevMonth() {
    DateTime from = DateTime(initialDate.year, initialDate.month-1, 1).toLocal();
    DateTime to = DateTime(initialDate.year, initialDate.month, 1).subtract(const Duration(days: 1)).toLocal();
    
    onPress(from, to);
  }

  void _goNextMonth() {
    DateTime from = DateTime(initialDate.year, initialDate.month+1, 1).toLocal();
    DateTime to = DateTime(initialDate.year, initialDate.month+2, 1).subtract(const Duration(days: 1)).toLocal();

    onPress(from, to);
  }
}