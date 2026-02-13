import 'package:flutter/material.dart';
import 'package:flutter_simple_calculator/flutter_simple_calculator.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/globals.dart';
import 'package:my_expense/widgets/page/my_safe_area.dart';

class TransactionCalculatorArgs {
  final bool isCurrentAmount;
  final double currentAmount;
  final double conversionAmount;
  final String currentType;
  final bool? isDoubleTap;

  TransactionCalculatorArgs({
    required this.isCurrentAmount,
    required this.currentAmount,
    required this.conversionAmount,
    required this.currentType,
    this.isDoubleTap,
  });
}

class TransactionCalculator extends StatefulWidget {
  final Object? args;
  const TransactionCalculator({
    super.key,
    required this.args,
  });

  @override
  State<TransactionCalculator> createState() => _TransactionCalculatorState();
}

class _TransactionCalculatorState extends State<TransactionCalculator> {
  final CalcController _controller = CalcController();
  late TransactionCalculatorArgs _args;
  late double _currentAmount;
  late double _conversionAmount;

  @override
  void initState() {
    super.initState();

    // convert current amount that being passed
    _args = widget.args as TransactionCalculatorArgs;

    // get current and conversion amount
    _currentAmount = _args.currentAmount;
    _conversionAmount = _args.conversionAmount;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MySafeArea(
        bottomPadding: 80,
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                width: double.infinity,
                color: secondaryDark,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {
                        // just pop from calculator
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 10, 50, 10),
                        color: Colors.transparent,
                        child: Icon(
                          Ionicons.close,
                          size: 24,
                          color: accentColors[2],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: (() {
                        // create a new TransactionCalculatorArgs as the result
                        TransactionCalculatorArgs result = TransactionCalculatorArgs(
                          isCurrentAmount: _args.isCurrentAmount,
                          currentAmount: _currentAmount,
                          conversionAmount: _conversionAmount,
                          currentType: _args.currentType,
                        );

                        // pop from calculator
                        Navigator.pop(context, result);
                      }),
                      onDoubleTap: (() async {
                        // create a new TransactionCalculatorArgs as the result
                        TransactionCalculatorArgs result = TransactionCalculatorArgs(
                          isCurrentAmount: _args.isCurrentAmount,
                          currentAmount: _currentAmount,
                          conversionAmount: _conversionAmount,
                          currentType: _args.currentType,
                          isDoubleTap: true,
                        );

                        // pop from calculator
                        Navigator.pop(context, result);
                      }),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(50, 10, 10, 10),
                        color: Colors.transparent,
                        child: Icon(
                          Ionicons.checkmark,
                          size: 24,
                          color: accentColors[0],
                        ),
                      )
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: secondaryDark,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: secondaryBackground,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      border: Border.all(
                        color: secondaryLight,
                        width: 1.0,
                        style: BorderStyle.solid,
                      )
                    ),
                    child: SimpleCalculator(
                      controller: _controller,
                      value: (_args.isCurrentAmount ? _currentAmount : _conversionAmount),
                      hideExpression: false,
                      hideSurroundingBorder: true,
                      autofocus: true,
                      theme: CalculatorThemeData(
                        operatorColor: Colors.orange[600],
                        equalColor: Colors.orange[800],
                      ),
                      maximumDigits: 14,
                      numberFormat: Globals.fCCYnf,
                      onChanged: (key, value, expression) {
                        if (_args.isCurrentAmount) {
                          // set the current amount as previous current amount if value is null
                          _currentAmount = (value ?? _currentAmount);
                        }
                        else {
                          // it means that this is for the conversion amount
                          _conversionAmount = (value ?? _conversionAmount);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}