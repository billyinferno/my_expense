import 'package:flutter/material.dart';
import 'package:my_expense/_index.g.dart';

class ScrollDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? minDate;
  final DateTime? maxDate;
  final Function(DateTime)? onDateChange;
  const ScrollDatePicker({
    super.key,
    this.initialDate,
    this.minDate,
    this.maxDate,
    this.onDateChange,
  });

  @override
  State<ScrollDatePicker> createState() => _ScrollDatePickerState();
}

class _ScrollDatePickerState extends State<ScrollDatePicker> {
  late ScrollController _dayController;
  late ScrollController _monthController;
  late ScrollController _yearController;

  late DateTime _currentDate;
  late int _currentDay;
  late int _currentMonth;
  late int _currentYear;

  late DateTime _minDate;
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
    _minDate = (widget.minDate ?? DateTime(_currentDate.year - 5, 1, 1));
    _maxDate = (widget.maxDate ?? DateTime(_currentDate.year + 5, 12, 31));

    // calculate number of year
    _numOfYears = (_maxDate.year - _minDate.year) + 1;

    // get _numOfDays
    _calculateNumOfDays();

    // set the initial index for  day, month, and year
    _dayController = FixedExtentScrollController(
      initialItem: (_currentDate.day - 1),
    );

    _monthController = FixedExtentScrollController(
      initialItem: (_currentDate.month - 1),
    );

    _yearController = FixedExtentScrollController(
      initialItem: (_currentDate.year - _minDate.year),
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
        setState(() {
          _currentDate = DateTime.now();
        });

        //TODO: to move the controller to the correct position
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
                        color: Colors.blue,
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
                                  return Text("${index + 1}");
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
                                return Text(Globals.dfMMMM.format(DateTime(_currentDate.year, (index+1), 1)));
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
                                  color: primaryLight,
                                  style: BorderStyle.solid,
                                )
                              ),
                            ),
                            child: ListWheelScrollView.useDelegate(
                              controller: _yearController,
                              physics: FixedExtentScrollPhysics(),
                              onSelectedItemChanged: ((int index) {
                                _currentYear = (_minDate.year + index);
                                _setCurrentDate();
                              }),
                              itemExtent: 22.0,
                              childDelegate: ListWheelChildLoopingListDelegate(
                                children: List<Widget>.generate(_numOfYears, (int index) {
                                  return Text("${_minDate.year + index}");
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
    DateTime lastDate = DateTime(_currentDate.year, _currentDate.month + 1, 1).subtract(Duration(days: 1));

    // set the _numOfDays
    _numOfDays = lastDate.day;
  }

  void _setCurrentDate() {
    setState(() {
      _currentDate = DateTime(_currentYear, _currentMonth, _currentDay);
      if (widget.onDateChange != null) {
        widget.onDateChange!(_currentDate);
      }
    });
  }
}