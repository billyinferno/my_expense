import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

class BudgetInput extends StatefulWidget {
  final Object? budget;
  const BudgetInput({
    super.key,
    required this.budget,
  });

  @override
  State<BudgetInput> createState() => _BudgetInputState();
}

class _BudgetInputState extends State<BudgetInput> {
  final TextEditingController _amountController = TextEditingController();

  late BudgetDetailArgs _budget;
  late double _budgetAmount;
  late bool _budgetUseForDaily;

  @override
  void initState() {
    super.initState();

    // set the current budget with the budget data coming from args
    _budget = widget.budget as BudgetDetailArgs;

    // set the budget amount
    _budgetAmount = _budget.budgetAmount;

    // set the use for daily
    _budgetUseForDaily = _budget.useForDaily;
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            _budget.categoryName
          ),
        ),
        leading: IconButton(
          onPressed: () {
            // return back the budget if got changes
            if (
              _budget.budgetAmount != _budgetAmount ||
              _budget.useForDaily != _budgetUseForDaily
            ) {
              BudgetDetailArgs newBudget = BudgetDetailArgs(
                budgetId: _budget.budgetId,
                categoryId: _budget.categoryId,
                categoryIcon: _budget.categoryIcon,
                categoryColor: _budget.categoryColor,
                categoryName: _budget.categoryName,
                currencyId: _budget.currencyId,
                currencySymbol: _budget.currencySymbol,
                budgetAmount: _budgetAmount,
                useForDaily: _budgetUseForDaily,
              );

              Navigator.pop(context, newBudget);
            }
            else {
              Navigator.pop(context);
            }
          },
          icon: Icon(
            Ionicons.arrow_back
          ),
        ),
        actions: <Widget>[
          const SizedBox(width: 25,),
        ],
      ),
      body: MySafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(
                "Amount",
              ),
              const SizedBox(height: 5,),
              TextField(
                controller: _amountController,
                showCursor: true,
                textAlign: TextAlign.right,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: _budget.budgetAmount.formatCurrency(shorten: false, decimalNum: 2),
                  hintStyle: TextStyle(
                    color: primaryLight
                  ),
                  contentPadding: EdgeInsets.zero,
                  isCollapsed: true,
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: primaryLight,
                      width: 1.0,
                      style: BorderStyle.solid,
                    )
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: textColor,
                      width: 1.0,
                      style: BorderStyle.solid,
                    )
                  ),
                ),
                cursorColor: primaryLight,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(12),
                  DecimalTextInputFormatter(
                    decimalRange: 3
                  ),
                ],
                onChanged: ((value) {
                  if (value.isNotEmpty) {
                    _budgetAmount = (double.tryParse(value) ?? _budget.budgetAmount);
                  }
                }),
              ),
              const SizedBox(height: 5,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      "Use for daily average",
                    ),
                  ),
                  const SizedBox(width: 10,),
                  CupertinoSwitch(
                    value: _budgetUseForDaily,
                    onChanged: (value) {
                      setState(() {                      
                        _budgetUseForDaily = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: GestureDetector(
                      onTap: (() {
                        // don't care with data changes, if user press
                        // cancel then just pop.
                        Navigator.pop(context);
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Icon(
                              Ionicons.close,
                              size: 15,
                            ),
                            SizedBox(width: 10,),
                            Expanded(
                              child: Center(
                                child: Text("Cancel")
                              )
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20,),
                  Expanded(
                    child: GestureDetector(
                      onTap: (() {
                        BudgetDetailArgs newBudget = BudgetDetailArgs(
                          budgetId: _budget.budgetId,
                          categoryId: _budget.categoryId,
                          categoryIcon: _budget.categoryIcon,
                          categoryColor: _budget.categoryColor,
                          categoryName: _budget.categoryName,
                          currencyId: _budget.currencyId,
                          currencySymbol: _budget.currencySymbol,
                          budgetAmount: _budgetAmount,
                          useForDaily: _budgetUseForDaily,
                        );

                        Navigator.pop(context, newBudget);
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Icon(
                              Ionicons.checkbox,
                              size: 15,
                            ),
                            SizedBox(width: 10,),
                            Expanded(
                              child: Center(
                                child: Text("Save")
                              )
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}