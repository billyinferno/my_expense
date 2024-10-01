import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:my_expense/_index.g.dart';

class MonthPrevNextCalendar extends StatefulWidget {
  final Color background;
  final Color border;
  final DateTime initialDate;
  final DateTime minDate;
  final DateTime maxDate;
  final Widget? subChild;
  final Function(DateTime, DateTime) onDateChange;
  const MonthPrevNextCalendar({
    super.key,
    this.background = secondaryDark,
    this.border = primaryBackground,
    required this.maxDate,
    required this.minDate,
    required this.initialDate,
    required this.onDateChange,
    this.subChild,
  });

  @override
  State<MonthPrevNextCalendar> createState() => _MonthPrevNextCalendarState();
}

class _MonthPrevNextCalendarState extends State<MonthPrevNextCalendar> {
  late DateTime _currentDate;
  late DateTime _minDate;
  late DateTime _maxDate;

  @override
  void initState() {
    super.initState();

    // set current date same as initial date
    _currentDate = widget.initialDate;

    // check if _maxDate is less than today date?
    _maxDate = widget.maxDate;
    if (_maxDate.isBefore(DateTime.now())) {
      // change max date to today date
      _maxDate = DateTime.now().toLocal();
    }

    // check if min date is more than max date?
    _minDate = widget.minDate;
    if (_minDate.isAfter(_maxDate)) {
      // changemin date to max date
      _minDate = _maxDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (() async {
        // show the month dialog
        await showMonthPicker(
          context: context,
          initialDate: _currentDate,
          firstDate: _minDate,
          lastDate: _maxDate,
          monthPickerDialogSettings: MonthPickerDialogSettings(
            buttonsSettings: PickerButtonsSettings(
              unselectedMonthsTextColor: textColor2,
              selectedMonthTextColor: textColor,
              currentMonthTextColor: accentColors[0],
              unselectedYearsTextColor: textColor2,
              selectedYearTextColor: textColor,
              currentYearTextColor: accentColors[0],
            ),
          ),
          cancelWidget: Text(
            "Cancel",
            style: TextStyle(
              color: textColor2,
            ),
          ),
          confirmWidget: Text(
            "Confirm",
            style: TextStyle(
              color: accentColors[6],
            ),
          ),
        ).then((newDate) async {
          if (newDate != null) {
            setState(() {
              // set current date as new date
              _currentDate = newDate;

              // calculate the begining and end of the date
              DateTime from = DateTime(
                newDate.year,
                newDate.month,
                1
              ).toLocal();
              
              DateTime to = DateTime(
                newDate.year,
                newDate.month+1,
                1
              ).subtract(const Duration(days: 1)).toLocal();

              // call the onDateChange
              widget.onDateChange(from, to);
            });
          }
        });
      }),
      onDoubleTap: (() {
        setState(() {
          // set current date as todays date
          _currentDate = DateTime.now();

          // calculate from and to range for current date   
          DateTime from = DateTime(
            _currentDate.year,
            _currentDate.month,
            1
          ).toLocal();

          DateTime to = DateTime(
            _currentDate.year,
            _currentDate.month + 1,
            1
          ).subtract(const Duration(days: 1)).toLocal();

          // call onDateChange
          widget.onDateChange(from, to);
        });
      }),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: widget.background,
          border: Border(
            bottom: BorderSide(
              color: widget.border,
              width: 1.0,
              style: BorderStyle.solid,
            )
          )
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            GestureDetector(
              onTap: (() {
                _goPrevMonth();
              }),
              child: Container(
                padding: const EdgeInsets.all(5),
                width: 50,
                color: Colors.transparent,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: const Icon(
                    Ionicons.caret_back,
                    color: textColor,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all((widget.subChild != null ? 10 : 0)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      Globals.dfMMMMyyyy.formatLocal(_currentDate)
                    ),
                    _generateSubChild(),
                  ],
                ),
              )
            ),
            GestureDetector(
              onTap: (() {
                _goNextMonth();
              }),
              child: Container(
                padding: const EdgeInsets.all(5),
                width: 50,
                color: Colors.transparent,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: const Icon(
                    Ionicons.caret_forward,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goPrevMonth() {
    setState(() {
      // calculate the from and to date
      DateTime from = DateTime(
        _currentDate.year,
        _currentDate.month - 1,
        1
      ).toLocal();
      
      DateTime to = DateTime(
        _currentDate.year,
        _currentDate.month,
        1
      ).subtract(const Duration(days: 1)).toLocal();

      // change current date to be the same as from date
      _currentDate = from;

      // call on date change
      widget.onDateChange(from, to);
    });
  }

  void _goNextMonth() {
    setState(() {
      // calculate the from and to date
      DateTime from = DateTime(
        _currentDate.year,
        _currentDate.month+1,
        1
      ).toLocal();
      
      DateTime to = DateTime(
        _currentDate.year,
        _currentDate.month+2,
        1
      ).subtract(const Duration(days: 1)).toLocal();

      // change curent date to be the same as from date
      _currentDate = from;

      // call on date change
      widget.onDateChange(from, to);
    });
  }

  Widget _generateSubChild() {
    return (widget.subChild ?? const SizedBox.shrink());
  }
}