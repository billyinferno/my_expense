import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/api/budget_api.dart';
import 'package:my_expense/model/budget_list_model.dart';
import 'package:my_expense/model/budget_model.dart';
import 'package:my_expense/model/category_model.dart';
import 'package:my_expense/model/currency_model.dart';
import 'package:my_expense/provider/home_provider.dart';
import 'package:my_expense/themes/category_icon_list.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/args/budget_detail_args.dart';
import 'package:my_expense/utils/misc/decimal_formatter.dart';
import 'package:my_expense/utils/misc/show_dialog.dart';
import 'package:my_expense/utils/misc/show_loader_dialog.dart';
import 'package:my_expense/utils/misc/snack_bar.dart';
import 'package:my_expense/utils/prefs/shared_box.dart';
import 'package:my_expense/utils/prefs/shared_budget.dart';
import 'package:my_expense/utils/prefs/shared_category.dart';
import 'package:my_expense/widgets/item/category_list_item.dart';
import 'package:my_expense/widgets/item/simple_item.dart';
import 'package:provider/provider.dart';

class BudgetListPage extends StatefulWidget {
  final Object? currencyId;
  const BudgetListPage({Key? key, required this.currencyId}) : super(key: key);

  @override
  _BudgetListPageState createState() => _BudgetListPageState();
}

class _BudgetListPageState extends State<BudgetListPage> {
  final BudgetHTTPService _budgetHttp = BudgetHTTPService();
  final TextEditingController _amountController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _scrollControllerAddCategory = ScrollController();
  final fCCY = new NumberFormat("#,##0.00", "en_US");

  late BudgetListModel? _budgetList;
  late double? _budgetAmount;

  int _currencyID = -1;
  double _totalAmount = 0.0;
  bool _isLoading = true;
  bool _isDataChanged = false;
  Map<int, CategoryModel> _expenseCategory = {};


  @override
  void initState() {
    super.initState();

    // initialize value
    _budgetList = null;
    _budgetAmount = 0;

    // get the currency ID being sent from the home budget page
    _currencyID = widget.currencyId as int;

    // get the expense category model
    _expenseCategory = CategorySharedPreferences.getCategory("expense");

    // fetch the current budget
    _fetchBudget(true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollControllerAddCategory.dispose();
    _amountController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text("Budget List")),
        leading: IconButton(
          icon: Icon(Ionicons.close_outline, color: textColor),
          onPressed: (() {
            // check if got data changed already or not?
            if(_isDataChanged) {
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
                  Navigator.pop(context);
                }
              });
            }
            else {
              Navigator.pop(context);
            }
          }),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () async {
              await _updateBudgetList().then((_) {
                // this is success, we can going back from this page
                Navigator.pop(context);
              }).onError((error, stackTrace) {
                // show the snack bar
                ScaffoldMessenger.of(context).showSnackBar(
                  createSnackBar(
                    message: error.toString(),
                  )
                );
              });
            },
            icon: Icon(
              Ionicons.save,
              color: textColor,
            ),
          ),
        ],
      ),
      body: Container(
        child: budgetListView(),
      ),
    );
  }

  Widget budgetListView() {
    if (_isLoading) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitFadingCube(
              color: accentColors[6],
              size: 25,
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              "loading...",
              style: TextStyle(
                color: textColor2,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          budgetCurrencySelector(
            ccy: (_budgetList == null ? null : _budgetList!.currency),
            totalAmount: _totalAmount,
          ),
          SizedBox(
            height: 10,
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Consumer<HomeProvider>(
                builder: ((context, homeProvider, child) {
                  return generateListItem(homeProvider.budgetAddList);
                }),
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Container(
            padding: EdgeInsets.all(10),
            margin: EdgeInsets.fromLTRB(0, 0, 0, 25),
            child: MaterialButton(
              height: 40,
              minWidth: double.infinity,
              onPressed: (() {
                showModalBottomSheet<void>(
                  context: context,
                  builder: (BuildContext context) {
                    return Container(
                      height: 300,
                      color: secondaryDark,
                      child: Column(
                        children: <Widget>[
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: primaryLight, width: 1.0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Center(child: Text("Categories")),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollControllerAddCategory,
                              itemCount: _expenseCategory.length,
                              itemBuilder: (BuildContext context, int index) {
                                int _key = _expenseCategory.keys.elementAt(index);
                                return SimpleItem(
                                  color: IconColorList.getExpenseColor(_expenseCategory[_key]!.name),
                                  child: IconColorList.getExpenseIcon(_expenseCategory[_key]!.name),
                                  description: _expenseCategory[_key]!.name,
                                  isSelected: (_checkIfCategorySelected(_expenseCategory[_key]!.id)),
                                  onTap: (() async {
                                    // check if this is not already added as budget or not?
                                    // if not yet then we can add this new budget to the budget list
                                    if (!_checkIfCategorySelected(_expenseCategory[_key]!.id)) {
                                      await _addBudget(_expenseCategory[_key]!.id,_currencyID).then((_) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          createSnackBar(
                                            message: "Success add new category",
                                            icon: Icon(
                                              Ionicons.checkmark_circle_outline,
                                              color: accentColors[6],
                                            ),
                                          )
                                        );
                                      }).onError((error, stackTrace) {
                                        // show the snack bar of error
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          createSnackBar(
                                            message: error.toString(),
                                          )
                                        );
                                      });
                                    }
                                    // remove the modal dialog
                                    Navigator.pop(context);
                                  }),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20,),
                        ],
                      ),
                    );
                  }
                );
              }),
              child: Text("Add New Category"),
              color: accentColors[5],
            ),
          ),
        ],
      );
    }
  }

  Widget generateListItem(List<BudgetModel> budgetList) {
    if (_budgetList == null) {
      return Text("Loading Budget List");
    } else {
      return ListView.builder(
        controller: _scrollController,
        itemCount: budgetList.length,
        itemBuilder: (BuildContext ctx, int index) {
          BudgetModel budget = budgetList[index];

          // generate budget detail arguments
          BudgetDetailArgs budgetArgs = BudgetDetailArgs(
            budgetId: budget.id,
            categoryId: budget.category.id,
            categoryIcon: IconColorList.getExpenseIcon(budget.category.name),
            categoryColor: IconColorList.getExpenseColor(budget.category.name),
            categoryName: budget.category.name,
            currencyId: budget.currency.id,
            currencySymbol: budget.currency.symbol,
            budgetAmount: budget.amount
          );
          
          return CategoryListItem(
            index: index,
            budgetId: budget.id,
            categoryId: budget.category.id,
            categoryIcon: IconColorList.getExpenseIcon(budget.category.name),
            categoryColor: IconColorList.getExpenseColor(budget.category.name),
            categoryName: budget.category.name,
            currencyId: budget.currency.id,
            currencySymbol: budget.currency.symbol,
            budgetAmount: budget.amount,
            onDelete: (() {
              if (!_isLoading) {
                late Future<bool?> result = ShowMyDialog(
                        dialogTitle: "Delete Budget",
                        dialogText: "Do you want to delete " + budget.category.name + "?",
                        confirmText: "Delete",
                        confirmColor: accentColors[2],
                        cancelText: "Cancel")
                    .show(context);

                // check the result of the dialog box
                result.then((value) {
                  if (value == true) {
                    _deleteBudgetList(budget.id, budget.currency.id);
                  }
                });
              }
            }),
            onTap: ((index) {
              showDialog(
                context: context,
                builder: ((context) {
                  // set the amount controller with the current budget
                  _amountController.text = fCCY.format(budgetArgs.budgetAmount);
                  _budgetAmount= budgetArgs.budgetAmount;

                  return AlertDialog(
                    content: Container(
                      width: 300,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: budgetArgs.categoryColor,
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: budgetArgs.categoryIcon,
                          ),
                          const SizedBox(width: 10,),
                          Expanded(
                            child: Container(
                              height: 60,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Text("Edit ${budgetArgs.categoryName}"),
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
                                      if (value.isNotEmpty) {
                                        try {
                                          _budgetAmount = double.tryParse(value);
                                          if (_budgetAmount == null) {
                                            // wrong amount set budget amount as
                                            // budget args
                                            _budgetAmount = budgetArgs.budgetAmount;
                                          }
                                        }
                                        catch(ex) {
                                          // defaulted to budget amount from parent
                                          _budgetAmount = budgetArgs.budgetAmount;
                                        }
                                      }
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          GestureDetector(
                            onTap: (() {
                              // don't care with data changes, if user press
                              // cancel then just pop.
                              Navigator.pop(context);
                            }),
                            child: Container(
                              width: 100,
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10)
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Icon(
                                    Ionicons.close,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 10,),
                                  Expanded(child: Center(child: Text("Cancel"))),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10,),
                          GestureDetector(
                            onTap: (() {
                              if (_budgetAmount != null) {
                                _isDataChanged = true;
                                List<BudgetModel> _newBudgetList = [];
                                for(int i=0; i<_budgetList!.budgets.length; i++) {
                                  if(i == index) {
                                    // special treatment
                                    _newBudgetList.add(new BudgetModel(
                                        id: _budgetList!.budgets[i].id,
                                        category: _budgetList!.budgets[i].category,
                                        totalTransaction: _budgetList!.budgets[i].totalTransaction,
                                        amount: (_budgetAmount ?? budgetArgs.budgetAmount),
                                        used: _budgetList!.budgets[i].used,
                                        status: "in",
                                        currency: _budgetList!.budgets[i].currency,
                                      )
                                    );
                                  }
                                  else {
                                    _newBudgetList.add(_budgetList!.budgets[i]);
                                  }
                                }

                                // create the new budget list model
                                BudgetListModel _newBudgetListModel = BudgetListModel(currency: _budgetList!.currency, budgets: _newBudgetList);

                                // set the new budget and announce
                                setBudgetList(_newBudgetListModel);
                                Provider.of<HomeProvider>(context, listen: false).setBudgetAddList(_newBudgetListModel.budgets);

                                // remove the dialog
                                Navigator.pop(context);
                              }
                            }),
                            child: Container(
                              width: 100,
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10)
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Icon(
                                    Ionicons.checkbox,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 10,),
                                  Expanded(child: Center(child: Text("Save"))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  );
                })
              );
            }),
          );
        },
      );
    }
  }

  Widget budgetCurrencySelector(
      {required CurrencyModel? ccy, required double totalAmount}) {
    if (ccy != null) {
      return Container(
        padding: EdgeInsets.all(10),
        color: secondaryDark,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                color: accentColors[6],
              ),
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(ccy.symbol),
              ),
            ),
            SizedBox(
              width: 10,
            ),
            Expanded(child: Text(ccy.description)),
            SizedBox(
              width: 10,
            ),
            Text("(" + ccy.symbol + " " + fCCY.format(totalAmount) + ")"),
          ],
        ),
      );
    } else {
      return Text("Loading");
    }
  }

  void setBudgetList(BudgetListModel budgetList) {
    setState(() {
      _budgetList = budgetList;

      _totalAmount = 0.0;
      if (_budgetList!.budgets.length > 0) {
        _budgetList!.budgets.forEach((budget) {
          _totalAmount += budget.amount;
        });
      }
    });
  }

  void setLoading(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  Future<void> _fetchBudget([bool? force]) async {
    bool _force = (force ?? false);
    // fetch the budget from the web
    await _budgetHttp.fetchBudgetsList(_currencyID, _force).then((result) {
      setBudgetList(result);
      Provider.of<HomeProvider>(context, listen: false).setBudgetAddList(result.budgets);
      setLoading(false);
    }).onError((error, stackTrace) {
      // got error
      debugPrint("Error when <_fetchBudget> at BudgetList");
      debugPrint(error.toString());
      setLoading(false);
    });
  }

  bool _checkIfCategorySelected(int id) {
    // loop throught the budget list budgets
    if (_budgetList != null) {
      if (_budgetList!.budgets.length > 0) {
        for (int i = 0; i < _budgetList!.budgets.length; i++) {
          // this budget is selected already
          if (_budgetList!.budgets[i].category.id == id) {
            return true;
          }
        }
      }
    }
    // defualted to return false.
    return false;
  }

  Future<void> _deleteBudgetList(int budgetId, int currencyId) async {
    // show the loader dialog
    showLoaderDialog(context);

    await _budgetHttp.deleteBudgetList(currencyId, budgetId).then((budget) {
      // we got the new budget, add this to the shared preferences and the
      // provider
      if (_budgetList!.budgets.length > 0) {
        _budgetList!.budgets.removeWhere((element) => element.id == budget.id && element.currency.id == budget.currency.id);

        // create new budget list model with the new budget we added
        BudgetListModel _newBudgetList = BudgetListModel(
            currency: _budgetList!.currency,
            budgets: _budgetList!.budgets
        );

        setBudgetList(_newBudgetList);
        Provider.of<HomeProvider>(context, listen: false).setBudgetAddList(_newBudgetList.budgets);

        // set the budget on the home screen, since the budget on the home screen
        // is based on date, first we need to get what is the curren date being displayed
        // on the home budget?
        String _currentBudgetDate = BudgetSharedPreferences.getBudgetCurrent();
        List<BudgetModel>? _homeBudgetList = BudgetSharedPreferences.getBudget(_currencyID, _currentBudgetDate);
        if(_homeBudgetList != null) {
          if(_homeBudgetList.length > 0) {
            _homeBudgetList.removeWhere((element) => element.id == budget.id && element.currency.id == budget.currency.id);

            // store back the home budget list
            BudgetSharedPreferences.setBudget(_currencyID, _currentBudgetDate, _homeBudgetList);
            // after that notify the budget list on the home
            Provider.of<HomeProvider>(context, listen: false).setBudgetList(_homeBudgetList);
          }
        }
      }

      // pop out the loader
      Navigator.pop(context);
    }).onError((error, stackTrace) {
      debugPrint("Error oon <_deleteBudgetList> at BudgetList");
      debugPrint(error.toString());

      // pop out the loader
      Navigator.pop(context);
    });
  }

  Future<void> _addBudget(int categoryId, int currencyId) async {
    // show the loader dialog
    showLoaderDialog(context);

    await _budgetHttp.addBudgetList(currencyId, categoryId).then((budget) {
      // we got the new budget, add this to the shared preferences and the
      // provider
      List<BudgetModel> _newBudgets = [];
      if (_budgetList!.budgets.length > 0) {
        _newBudgets = _budgetList!.budgets;
      }
      _newBudgets.add(budget);

      // create new budget list model with the new budget we added
      BudgetListModel _newBudgetList = BudgetListModel(
          currency: _budgetList!.currency,
          budgets: _newBudgets
      );
      _budgetList = _newBudgetList;

      setBudgetList(_newBudgetList);
      Provider.of<HomeProvider>(context, listen: false).setBudgetAddList(_newBudgetList.budgets);

      // set the budget on the home screen, since the budget on the home screen
      // is based on date, first we need to get what is the curren date being displayed
      // on the home budget?
      String _currentBudgetDate = BudgetSharedPreferences.getBudgetCurrent();
      List<BudgetModel>? _homeBudgetList = BudgetSharedPreferences.getBudget(_currencyID, _currentBudgetDate);
      if(_homeBudgetList == null) {
        _homeBudgetList = [];
      }
      _homeBudgetList.add(budget);
      // store back the home budget list
      BudgetSharedPreferences.setBudget(_currencyID, _currentBudgetDate, _homeBudgetList);
      // after that notify the budget list on the home
      Provider.of<HomeProvider>(context, listen: false).setBudgetList(_homeBudgetList);

      // pop out the loader
      Navigator.pop(context);
    }).onError((error, stackTrace) {
      debugPrint("Error oon <_addBudget> at BudgetList");
      debugPrint(error.toString());

      // pop out the loader
      Navigator.pop(context);
      throw new Exception("Error when adding new budgets");
    });
  }

  Future <void> _updateBudgetList() async {
    // we will only save if the budget length more than 0, otherwise, no need to send any
    // data to backend
    if(_budgetList!.budgets.length > 0) {
      // show the loader dialog
      showLoaderDialog(context);

      await _budgetHttp.updateBudgetList(_currencyID, _budgetList!.budgets).then((_updatedBudgetList) {
        // store back the home budget list
        String _currentBudgetDate = BudgetSharedPreferences.getBudgetCurrent();
        String _budgetDate = "";
        List<BudgetModel> _newHomeBudgetList = [];
        List<BudgetModel>? _currentHomeBudgetList;

        // get the list of budget for this currency that we already load on the storage
        List<String> _budgetKeys = MyBox.getKeys("budget_" + _currencyID.toString());
        _budgetKeys.forEach((_budgetKey) {
          // get the current budget date
          _budgetDate = _budgetKey.replaceAll("budget_" + _currencyID.toString() + "_", "");

          // initialize all the variable needed
          _newHomeBudgetList = [];
          _currentHomeBudgetList = BudgetSharedPreferences.getBudget(_currencyID, _budgetDate);

          // check if the current home budget list got data or not?
          // if got data then we can loop and add the new amount on the existing list
          if(_currentHomeBudgetList != null) {
            // loop through the _currentHomeBudgetList and add on the _newHomeBudgetList
            _updatedBudgetList.forEach((element) {
              // check if this element same to which id and store the amount
              double _used = 0.0;
              for(int i=0; i<_currentHomeBudgetList!.length; i++) {
                if(element.id == _currentHomeBudgetList![i].id) {
                  _used = _currentHomeBudgetList![i].used;
                }
              }

              // add the new budget
              _newHomeBudgetList.add(
                BudgetModel(
                  id: element.id,
                  category: element.category,
                  totalTransaction: element.totalTransaction,
                  amount: element.amount,
                  used: _used,
                  status: "in",
                  currency: element.currency
                )
              );
            });
          }
          else {
            // current home list is null?
            // just set the _newHomeBudget list with the _updatedBudgetList
            _newHomeBudgetList = _updatedBudgetList;
          }

          // set the new home list to the home list budget, so we can directly reflect the data
          BudgetSharedPreferences.setBudget(_currencyID, _budgetDate, _newHomeBudgetList);
          if(_budgetDate == _currentBudgetDate) {
            // after that notify the budget list on the home if this is the same as the current budget
            Provider.of<HomeProvider>(context, listen: false).setBudgetList(_newHomeBudgetList);
          }
        });

        // pop out the loader
        Navigator.pop(context);
      }).onError((error, stackTrace) {
        debugPrint("Error oon <_addBudget> at BudgetList");
        debugPrint(error.toString());

        // pop out the loader
        Navigator.pop(context);
        throw new Exception("Cannot save budgets");
      });
    }
  }
}
