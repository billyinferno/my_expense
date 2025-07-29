import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

class MonthCalendarDialog extends StatefulWidget {
  final DateTime? minDate;
  final DateTime? maxDate;
  final DateTime? initialDate;
  final Function(DateTime) onDateChange;
  final Color headerTextColor;
  final Color headerBackgroundColor;
  final Color bodyBackgroundColor;
  final Color? barColor;
  const MonthCalendarDialog({
    super.key,
    this.minDate,
    this.maxDate,
    this.initialDate,
    required this.onDateChange,
    this.headerTextColor = textColor,
    this.headerBackgroundColor = secondaryBackground,
    this.bodyBackgroundColor = primaryBackground,
    this.barColor,
  });

  @override
  State<MonthCalendarDialog> createState() => _MonthCalendarDialogState();
}

class _MonthCalendarDialogState extends State<MonthCalendarDialog> {
  late DateTime _minDate;
  late DateTime _maxDate;
  late DateTime _currentDate;
  late DateTime _initialDate;

  @override
  void initState() {
    // set current date
    _currentDate = DateTime.now().toLocal();

    // now get the value for the min, max and initial date
    _minDate = widget.minDate ?? DateTime(2000, 1, 1);
    _maxDate = widget.maxDate ?? DateTime.now().toLocal();
    _initialDate = widget.initialDate ?? DateTime.now().toLocal();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      color: Colors.black.withAlpha(128),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
              decoration: BoxDecoration(
                color: secondaryBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: Icon(
                      Ionicons.close,
                      size: 20,
                      color: widget.headerTextColor,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      Globals.dfMMMMyyyy.format(_currentDate),
                      style: TextStyle(
                        color: widget.headerTextColor,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      widget.onDateChange(_currentDate);
                      Navigator.of(context).pop(_currentDate);
                    },
                    icon: Icon(
                      Ionicons.checkmark,
                      size: 20,
                      color: widget.headerTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: widget.bodyBackgroundColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    height: 250,
                    child: ScrollDatePicker(
                      initialDate: _initialDate,
                      minDate: _minDate,
                      maxDate: _maxDate,
                      type: ScrollDateType.monthYear,
                      borderColor: widget.headerBackgroundColor,
                      barColor: (widget.barColor ?? accentColors[0]),
                      onDateChange: (date) {
                        setState(() {
                          _currentDate = date;
                        });
                      },              
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}