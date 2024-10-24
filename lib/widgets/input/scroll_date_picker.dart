import 'package:flutter/material.dart';
import 'package:my_expense/_index.g.dart';

enum ScrollDateType {
  fullDate,
  dayMonth,
  monthYear,
  yearOnly,
}

class ScrollDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? minDate;
  final DateTime? maxDate;
  final Function(DateTime)? onDateChange;
  final ScrollDateType type;
  final Color barColor;
  final Color selectedColor;
  final Color borderColor;
  const ScrollDatePicker({
    super.key,
    this.initialDate,
    this.minDate,
    this.maxDate,
    this.onDateChange,
    this.type = ScrollDateType.fullDate,
    this.barColor = Colors.blue,
    this.selectedColor = Colors.black,
    this.borderColor = primaryLight,
  });

  @override
  State<ScrollDatePicker> createState() => _ScrollDatePickerState();
}

class _ScrollDatePickerState extends State<ScrollDatePicker> {
  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  late DateTime _currentDate;
  late int _currentDay;
  late int _currentMonth;
  late int _currentYear;

  late DateTime _minDate;
  late int _minYear;

  late DateTime _maxDate;

  late int _numOfDays;
  late int _numOfYears;

  @override
  void initState() {
    super.initState();

    // initialize the _currentData
    _currentDate = (widget.initialDate ?? DateTime.now());
    _currentDay = _currentDate.day;
    _currentMonth = _currentDate.month;
    _currentYear = _currentDate.year;

    // initialize _min and _maxDate
    _minDate = (widget.minDate ?? DateTime(_currentYear - 5, 1, 1));
    _maxDate = (widget.maxDate ?? DateTime(_currentYear + 5, 12, 31));

    // get minimum date year
    _minYear = _minDate.year;

    // calculate number of year
    _numOfYears = (_maxDate.year - _minYear) + 1;

    // get _numOfDays
    _calculateNumOfDays();

    // set the initial index for  day, month, and year
    _dayController = FixedExtentScrollController(
      initialItem: (_currentDay - 1),
    );

    _monthController = FixedExtentScrollController(
      initialItem: (_currentMonth - 1),
    );

    _yearController = FixedExtentScrollController(
      initialItem: (_currentYear - _minYear),
    );
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: (() {
        // set the date back to current date
        _currentDate = DateTime.now();
        _currentDay = _currentDate.day;
        _currentMonth = _currentDate.month;
        _currentYear = _currentDate.year;

        if (widget.onDateChange != null) {
          widget.onDateChange!(_currentDate);
        }
        
        // move the controller to the correct position
        _dayController.animateToItem(
          _currentDay - 1,
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn
        );

        _monthController.animateToItem(
          _currentMonth - 1,
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn
        );

        _yearController.animateToItem(
          _currentYear - _minYear,
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn
        );
      }),
      child: Container(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: double.infinity,
                      height: 30,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: widget.barColor,
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      _dayPicker(),
                      _monthPicker(),
                      _yearPicker(),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _dayPicker() {
    if (
      widget.type == ScrollDateType.fullDate ||
      widget.type == ScrollDateType.dayMonth
    ) {
      return Expanded(
        flex: 2,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                width: 1.0,
                color: primaryLight,
                style: BorderStyle.solid,
              ),
            ),
          ),
          child: ListWheelScrollView.useDelegate(
            controller: _dayController,
            physics: FixedExtentScrollPhysics(),
            onSelectedItemChanged: ((int index) {
              _currentDay = (index + 1);
              _setCurrentDate();
            }),
            itemExtent: 22.0,
            childDelegate: ListWheelChildLoopingListDelegate(
              children: List<Widget>.generate(_numOfDays, (int index) {
                if ((index+1) == _currentDay) {
                  return Text(
                    "${index + 1}",
                    style: TextStyle(
                      color: widget.selectedColor
                    ),
                  );
                }
                else {
                  return Text("${index + 1}");
                }
              }),
            ),
          ),
        ),
      );
    }
    else {
      return const SizedBox.shrink();
    }
  }

  Widget _monthPicker() {
    if (
      widget.type == ScrollDateType.fullDate ||
      widget.type == ScrollDateType.dayMonth ||
      widget.type == ScrollDateType.monthYear
    ) {
      return Expanded(
        flex: 3,
        child: ListWheelScrollView.useDelegate(
          controller: _monthController,
          physics: FixedExtentScrollPhysics(),
          onSelectedItemChanged: ((int index) {
            _currentMonth = (index + 1);
            _setCurrentDate();
          }),
          itemExtent: 22.0,
          childDelegate: ListWheelChildLoopingListDelegate(
            children: List<Widget>.generate(12, (int index) {
              if ((index + 1) == _currentMonth) {
                return Text(
                  Globals.dfMMMM.format(DateTime(_currentDate.year, (index+1), 1)),
                  style: TextStyle(
                    color: widget.selectedColor
                  ),
                );
              }
              else {
                return Text(Globals.dfMMMM.format(DateTime(_currentDate.year, (index+1), 1)));
              }
            }),
          ),
        ),
      );
    }
    else {
      return const SizedBox.shrink();
    }
  }

  Widget _yearPicker() {
    if (
      widget.type == ScrollDateType.fullDate ||
      widget.type == ScrollDateType.monthYear ||
      widget.type == ScrollDateType.yearOnly
    ) {
      Decoration? decoration;
      if (
        widget.type == ScrollDateType.fullDate ||
        widget.type == ScrollDateType.monthYear
      ) {
        decoration = BoxDecoration(
          border: Border(
            left: BorderSide(
              width: (widget.type == ScrollDateType.yearOnly ? 0 : 1.0),
              color: widget.borderColor,
              style: BorderStyle.solid,
            )
          )
        );
      }

      return Expanded(
        flex: 2,
        child: Container(
          decoration: decoration,
          child: ListWheelScrollView.useDelegate(
            controller: _yearController,
            physics: FixedExtentScrollPhysics(),
            onSelectedItemChanged: ((int index) {
              _currentYear = (_minYear + index);
              _setCurrentDate();
            }),
            itemExtent: 22.0,
            childDelegate: ListWheelChildLoopingListDelegate(
              children: List<Widget>.generate(_numOfYears, (int index) {
                if ((_minYear + index) == _currentYear) {
                  return Text(
                    "${_minYear + index}",
                    style: TextStyle(
                      color: widget.selectedColor
                    ),
                  );
                }
                else {
                  return Text("${_minYear + index}");
                }
              }),
            ),
          ),
        ),
      );
    }
    else {
      return const SizedBox.shrink();
    }
  }

  void _calculateNumOfDays() {
    // get the last day of the _currentDate
    DateTime lastDate = DateTime(_currentYear, _currentMonth + 1, 1).subtract(Duration(days: 1));

    // set the _numOfDays
    _numOfDays = lastDate.day;
  }

  void _setCurrentDate() {
    setState(() {
      if (
        widget.type == ScrollDateType.fullDate ||
        widget.type == ScrollDateType.dayMonth
      ) {
        int prevNumDays = _numOfDays;

        // calculate again the number of days
        _calculateNumOfDays();

        // get current selected item from day controller
        int selectedItem = _dayController.selectedItem;
        int times = 0;

        // calculate the actual selected item to match with our current day
        // being selected.

        // if selected item less than 0, it means that user scroll to top
        if (selectedItem < 0) {
          while(selectedItem < 0) {
            selectedItem += prevNumDays;
            times -= 1;
          }
        }
        else if (selectedItem >= _numOfDays) {
          // for selected item 30, it means that this is 31 in date
          // so if num of days is 30 (which means we only have 30 day)
          // re-calculate the selectedItem
          while(selectedItem >= prevNumDays) {
            selectedItem -= prevNumDays;
            times += 1;
          }
        }

        // check if selected item is same or more than _numOfDays
        // re-calculate the selected item
        if (selectedItem >= _numOfDays) {
          if (prevNumDays > _numOfDays) {
            selectedItem = selectedItem - (prevNumDays - _numOfDays);
          }
          else if (_numOfDays > prevNumDays) {
            selectedItem = selectedItem + (_numOfDays - prevNumDays);
          }          
        }

        // calculate the current day based on the selectedabove
        _currentDay = (selectedItem + 1);
        while (_currentDay > _numOfDays) {
          _currentDay -= _numOfDays;
        }

        // revert back the selected item
        if (times < 0) {
          selectedItem = selectedItem + (_numOfDays * times);
        }
        else {
          selectedItem = selectedItem + (_numOfDays * times);
        }

        if (_dayController.selectedItem != selectedItem) {
          _dayController.animateToItem(
            selectedItem,
            duration: const Duration(milliseconds: 500),
            curve: Curves.fastOutSlowIn
          );
        }
      }
      else {
        // if there are no date, then just default the current day into 1
        _currentDay = 1;
      }

      // set current date
      _currentDate = DateTime(_currentYear, _currentMonth, _currentDay);

      // call the on date change function if this is not null
      if (widget.onDateChange != null) {
        widget.onDateChange!(_currentDate);
      }
    });
  }
}