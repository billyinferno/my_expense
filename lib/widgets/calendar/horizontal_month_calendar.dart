import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/misc/my_callback.dart';

class HorizontalMonthCalendar extends StatefulWidget {
  final DateTime firstDay;
  final DateTime lastDay;
  final DateTime selectedDate;
  final MyDateTimeCallback? onDateSelected;

  HorizontalMonthCalendar({required this.firstDay, required this.lastDay, required this.selectedDate, this.onDateSelected});

  @override
  _HorizontalMonthCalendarState createState() => _HorizontalMonthCalendarState();
}

class _HorizontalMonthCalendarState extends State<HorizontalMonthCalendar> {
  late PageController _controller;
  int _initialPage = 0;
  int _totalPages = 0;
  int _diffMonths = 0;

  @override
  void initState() {
    _diffMonths = _computeTotalMonths(widget.firstDay, widget.lastDay);

    // now compute the page that we will need to be used
    _totalPages = _diffMonths ~/ 3;
    if(_totalPages * 3 < _diffMonths) {
      _totalPages += 1;
    }

    int _initialPages = _initialPage ~/ 3;
    _controller = PageController(initialPage: _initialPages);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _buildHorizontalCalendar();
  }

  int _computeTotalMonths(DateTime start, DateTime end) {
    DateTime _start = start;
    int total = 0;
    while(_start.year != end.year || _start.month != end.month) {
      _start = DateTime(start.year, start.month + total);
      //print(_start.toString() + " - " + end.toString());

      // check if this is the same as today year and month
      if(_start.year == DateTime.now().year && _start.month == DateTime.now().month) {
        _initialPage = total;
      }

      // add total
      total = total + 1;
    }

    return total;
  }

  bool _isSameDate(DateTime a, DateTime b) {
    if(a.year == b.year && a.month == b.month) {
      return true;
    }
    return false;
  }

  Widget _dateItem(DateTime dt) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if(widget.onDateSelected != null) {
            widget.onDateSelected!(dt);
          }
        },
        child: Container(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Center(
                child: Text(
                  DateFormat('MMM yyyy').format(dt.toLocal()),
                  style: TextStyle(
                    color: (_isSameDate(dt, DateTime.now()) ? (_isSameDate(dt, widget.selectedDate) ? textColor : accentColors[1]) : textColor),
                  ),
                ),
              ),
              SizedBox(height: 5,),
              Container(
                margin: EdgeInsets.only(left: 10, right: 10),
                height: 5,
                decoration: BoxDecoration(
                  color: (_isSameDate(dt, widget.selectedDate) ? selectedPrimary : Colors.transparent),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalCalendar() {
    return Container(
      height: 35,
      child: PageView.builder(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        itemCount: _totalPages,
        itemBuilder: ((BuildContext context, int index) {
          DateTime firstDate = DateTime(widget.firstDay.year, (widget.firstDay.month + ((index * 3) + 0)), widget.firstDay.day);
          DateTime secondDate = DateTime(widget.firstDay.year, (widget.firstDay.month + ((index * 3) + 1)), widget.firstDay.day);
          DateTime thirdDate = DateTime(widget.firstDay.year, (widget.firstDay.month + ((index * 3) + 2)), widget.firstDay.day);
          return Container(
            height: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _dateItem(firstDate),
                _dateItem(secondDate),
                _dateItem(thirdDate),
              ],
            ),
          );
        }),
      ),
    );
  }
}
