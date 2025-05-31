import 'package:flutter/material.dart';
import 'package:my_expense/_index.g.dart';

class HorizontalMonthCalendar extends StatefulWidget {
  final DateTime firstDay;
  final DateTime lastDay;
  final DateTime selectedDate;
  final DateTime? currentDate;
  final MyDateTimeCallback? onDateSelected;

  const HorizontalMonthCalendar({
    super.key,
    required this.firstDay,
    required this.lastDay,
    required this.selectedDate,
    this.currentDate,
    this.onDateSelected
  });

  @override
  State<HorizontalMonthCalendar> createState() => _HorizontalMonthCalendarState();
}

class _HorizontalMonthCalendarState extends State<HorizontalMonthCalendar> {
  late PageController _controller;
  late int _initialPage;
  late int _totalPages;
  late int _diffMonths;
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();

    // default value
    _initialPage = 0;
    _totalPages = 0;
    _diffMonths = 0;
    _currentDate = (widget.currentDate ?? DateTime.now());

    // calculate total month we have
    _diffMonths = _computeTotalMonths(widget.firstDay, widget.lastDay);

    // check if this is the same month, then we can just showed 1 page
    if (_diffMonths <= 0) {
      _totalPages = 1;
    }
    else {
      // now compute the page that we will need to be used
      _totalPages = _diffMonths ~/ 3;
      if(_totalPages * 3 < _diffMonths) {
        _totalPages += 1;
      }
    }

    int initialPages = _initialPage ~/ 3;
    _controller = PageController(initialPage: initialPages);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35,
      child: PageView.builder(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        itemCount: _totalPages,
        itemBuilder: ((BuildContext context, int index) {
          DateTime firstDate = DateTime(widget.firstDay.year, (widget.firstDay.month + ((index * 3) + 0)), widget.firstDay.day);
          DateTime secondDate = DateTime(widget.firstDay.year, (widget.firstDay.month + ((index * 3) + 1)), widget.firstDay.day);
          DateTime thirdDate = DateTime(widget.firstDay.year, (widget.firstDay.month + ((index * 3) + 2)), widget.firstDay.day);
          return SizedBox(
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

  int _computeTotalMonths(DateTime start, DateTime end) {
    // ensure the start and end date is correct
    assert(start.year <= end.year);
    if (start.year == end.year) {
      assert(start.month <= end.month);
    }
    
    DateTime startDate = start;
    DateTime endDate = end;
    
    // check if endDate is before today date
    if (endDate.isBefore(DateTime.now())) {
      // if so then change the endDate into today date instead
      endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 1).subtract(Duration(days: 1));
    }

    int total = 0;

    while(startDate.year != endDate.year || startDate.month != endDate.month) {
      startDate = DateTime(start.year, start.month + total);

      // check if this is the same as today year and month
      if(startDate.year == DateTime.now().year && startDate.month == DateTime.now().month) {
        _initialPage = total;
      }

      // add total
      total = total + 1;
    }

    return total;
  }

  Widget _dateItem(DateTime dt) {
    Color currentTextColor = textColor;
    // check whether this is current date or not?
    if (dt.sameMonthAndYear(date: _currentDate)) {
      if (!dt.sameMonthAndYear(date: widget.selectedDate)) {
        currentTextColor = accentColors[1];
      }
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {            
            if(widget.onDateSelected != null) {
              widget.onDateSelected!(dt);
            }
          });
        },
        child: Container(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Center(
                child: Text(
                  Globals.dfMMMyyyy.formatLocal(dt),
                  style: TextStyle(
                    color: currentTextColor,
                  ),
                ),
              ),
              const SizedBox(height: 5,),
              Container(
                margin: const EdgeInsets.only(left: 10, right: 10),
                height: 5,
                decoration: BoxDecoration(
                  color: (dt.isSameDate(date: widget.selectedDate) ? selectedPrimary : Colors.transparent),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
