import 'package:flutter/material.dart';
import 'package:my_expense/_index.g.dart';

class ScrollDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? minDate;
  final DateTime? maxDate;
  final Function(DateTime)? onDateChange;
  final Color barColor;
  final Color selectedColor;
  final Color borderColor;
  const ScrollDatePicker({
    super.key,
    this.initialDate,
    this.minDate,
    this.maxDate,
    this.onDateChange,
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
                  SizedBox(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
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
                        ),
                        Expanded(
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
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  width: 1.0,
                                  color: widget.borderColor,
                                  style: BorderStyle.solid,
                                )
                              ),
                            ),
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
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _calculateNumOfDays() {
    // get the last day of the _currentDate
    DateTime lastDate = DateTime(_currentYear, _currentMonth + 1, 1).subtract(Duration(days: 1));

    // set the _numOfDays
    _numOfDays = lastDate.day;
  }

  void _setCurrentDate() {
    setState(() {
      // calculate again the number of days
      _calculateNumOfDays();

      // get current selected item from day controller
      int selectedItem = _dayController.selectedItem;
      
      // loop while selected item is < 0
      while(selectedItem < 0) {
        selectedItem += _numOfDays;
      }

      // set current day based on the calculated selected item
      _currentDay = (selectedItem + 1);

      // set current date
      _currentDate = DateTime(_currentYear, _currentMonth, _currentDay);

      // call the on date change function if this is not null
      if (widget.onDateChange != null) {
        widget.onDateChange!(_currentDate);
      }
    });
  }
}