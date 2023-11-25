import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/args/budget_detail_args.dart';
import 'package:my_expense/utils/misc/decimal_formatter.dart';
import 'package:my_expense/utils/misc/show_dialog.dart';

class BudgetEditPage extends StatefulWidget {
  final Object? args;
  const BudgetEditPage({Key? key, required this.args}) : super(key: key);

  @override
  State<BudgetEditPage> createState() => _BudgetEditPageState();
}

class _BudgetEditPageState extends State<BudgetEditPage> {
  final fCCY = new NumberFormat("0.00", "en_US");
  final TextEditingController _amountController = TextEditingController();
  late BudgetDetailArgs _budgetDetail;
  late double _budgetAmount;

  @override
  void initState() {
    // convert args to budget detail args, so we can use it on the page
    _budgetDetail = widget.args as BudgetDetailArgs;
    
    // initialize all variable
    _budgetAmount = _budgetDetail.budgetAmount;

    // set the amount controller initial value as budget amount
    _amountController.text = fCCY.format(_budgetAmount);

    super.initState();
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
        title: Center(child: Text("Edit ${_budgetDetail.categoryName}")),
        leading: IconButton(
          icon: Icon(Ionicons.close_outline, color: textColor),
          onPressed: (() {
            // check if got data changed already or not?
            if(_budgetAmount != _budgetDetail.budgetAmount) {
              // show a modal dialog telling that you already change data
              // and not yet save the budget list
              late Future<bool?> result = ShowMyDialog(
                  dialogTitle: "Discard Data",
                  dialogText: "Do you want to discard budget changes?",
                  confirmText: "Discard",
                  confirmColor: accentColors[2],
                  cancelText: "Cancel")
                .show(context);

                // check the result of the dialog box
                result.then((value) {
                  if (value == true) {
                    Navigator.pop(context, null);
                  }
                }
              );
            }
            else {
              Navigator.pop(context, null);
            }
          }),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: (() {
              // save the budget
              if (_budgetAmount != _budgetDetail.budgetAmount) {
                Navigator.pop(context, _budgetAmount);
              }
              else {
                Navigator.pop(context, null);
              }
            }),
            icon: Icon(Ionicons.checkmark)
          ),
        ],
      ),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              width: double.infinity,
              color: secondaryDark,
              padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _budgetDetail.categoryColor,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: _budgetDetail.categoryIcon,
                  ),
                  const SizedBox(width: 10,),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text(_budgetDetail.categoryName),
                        const SizedBox(height: 5,),
                        TextField(
                          controller: _amountController,
                          showCursor: true,
                          textAlign: TextAlign.right,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: "0.00",
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.zero,
                            isCollapsed: true,
                          ),
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(12),
                            DecimalTextInputFormatter(decimalRange: 3),
                          ],
                          onChanged: ((value) {
                            if (value.length > 0) {
                              try {
                                _budgetAmount = double.parse(value);
                              }
                              catch(ex) {
                                // defaulted to budget amount from parent
                                _budgetAmount = _budgetDetail.budgetAmount;
                              }
                            }
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10,),
          ],
        ),
      ),
    );
  }
}