import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:my_expense/_index.g.dart';

class BudgetListPage extends StatefulWidget {
  final Object? currencyId;
  const BudgetListPage({super.key, required this.currencyId});

  @override
  State<BudgetListPage> createState() => _BudgetListPageState();
}

class _BudgetListPageState extends State<BudgetListPage> {
  final BudgetHTTPService _budgetHttp = BudgetHTTPService();
  final TextEditingController _amountController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _scrollControllerAddCategory = ScrollController();

  late BudgetListModel? _budgetList;
  late double? _budgetAmount;
  late Future<bool> _getData;

  int _currencyID = -1;
  double _totalAmount = 0.0;
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
    _getData = _fetchBudget(true);
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
        title: const Center(child: Text("Budget List")),
        leading: IconButton(
          icon: const Icon(Ionicons.close_outline, color: textColor),
          onPressed: (() {
            // check if got data changed already or not?
            if (_isDataChanged) {
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
                if (value == true && context.mounted) {
                  Navigator.pop(context);
                }
              });
            } else {
              Navigator.pop(context);
            }
          }),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () async {
              await _updateBudgetList().then((_) {
                if (context.mounted) {
                  // this is success, we can going back from this page
                  Navigator.pop(context);
                }
              }).onError((error, stackTrace) async {
                // print the error
                Log.error(
                  message: "Error while updating budget list",
                  error: error,
                  stackTrace: stackTrace,
                );

                if (context.mounted) {
                  // show dialog of error
                  await ShowMyDialog(
                    cancelEnabled: false,
                    confirmText: "OK",
                    dialogTitle: "Error Update Budget",
                    dialogText: "Error while updating budget list.")
                  .show(context);
                }
              });
            },
            icon: const Icon(
              Ionicons.save,
              color: textColor,
            ),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _getData,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error when get budget list"),);
          }
          else if (snapshot.hasData) {
            return MySafeArea(
              child: _budgetListView()
            );
          }
          else {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SpinKitFadingCube(
                  color: accentColors[6],
                  size: 25,
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  "loading...",
                  style: TextStyle(
                    color: textColor2,
                    fontSize: 10,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _budgetListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        budgetCurrencySelector(
          ccy: (_budgetList?.currency),
          totalAmount: _totalAmount,
        ),
        const SizedBox(
          height: 10,
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Consumer<HomeProvider>(
              builder: ((context, homeProvider, child) {
                return generateListItem(homeProvider.budgetAddList);
              }),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          child: MaterialButton(
            height: 40,
            minWidth: double.infinity,
            onPressed: (() {
              showModalBottomSheet<void>(
                context: context,
                builder: (BuildContext context) {
                  return MyBottomSheet(
                    context: context,
                    title: "Categories",
                    screenRatio: 0.75,
                    child: ListView.builder(
                      controller: _scrollControllerAddCategory,
                      itemCount: _expenseCategory.length,
                      itemBuilder: (BuildContext context, int index) {
                        int key = _expenseCategory.keys.elementAt(index);
                        return SimpleItem(
                          color: IconColorList.getExpenseColor(_expenseCategory[key]!.name),
                          title: _expenseCategory[key]!.name,
                          isSelected: (_checkIfCategorySelected(_expenseCategory[key]!.id)),
                          onTap: (() async {
                            // check if this is not already added as budget or not?
                            // if not yet then we can add this new budget to the budget list
                            if (!_checkIfCategorySelected(
                                _expenseCategory[key]!.id)) {
                              await _addBudget(
                                _expenseCategory[key]!.id,
                                _currencyID
                              ).then((_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    createSnackBar(
                                      message: "Success add new category",
                                      icon: Icon(
                                        Ionicons.checkmark_circle_outline,
                                        color: accentColors[6],
                                      ),
                                    ),
                                  );
                                }
                              }).onError((error, stackTrace) async {
                                // print the error
                                Log.error(
                                  message: "Error while add budget category",
                                  error: error,
                                  stackTrace: stackTrace,
                                );

                                if (context.mounted) {
                                  // show error dialog
                                  await ShowMyDialog(
                                    cancelEnabled: false,
                                    confirmText: "OK",
                                    dialogTitle: "Error Add Budget",
                                    dialogText: "Error while add budget category.")
                                  .show(context);
                                }
                              });
                            }
                            // remove the modal dialog
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          }),
                          icon: IconColorList.getExpenseIcon(_expenseCategory[key]!.name),
                        );
                      },
                    ),
                  );
                }
              );
            }),
            color: accentColors[5],
            child: const Text("Add New Category"),
          ),
        ),
      ],
    );

  }

  Widget generateListItem(List<BudgetModel> budgetList) {
    if (_budgetList == null) {
      return const Text("Loading Budget List");
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
              late Future<bool?> result = ShowMyDialog(
                dialogTitle: "Delete Budget",
                dialogText: "Do you want to delete ${budget.category.name}?",
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
            }),
            onTap: ((index) {
              // set the amount controller with the current budget
              _amountController.text = Globals.fCCY2.format(budgetArgs.budgetAmount);
              _budgetAmount = budgetArgs.budgetAmount;

              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return MyBottomSheet(
                    context: context,
                    title: "Edit ${budgetArgs.categoryName}".toUpperCase(),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      height: 300,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(height: 10,),
                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                const Text("Amount"),
                                const SizedBox(width: 10,),
                                Expanded(
                                  child: TextField(
                                    controller: _amountController,
                                    showCursor: true,
                                    textAlign: TextAlign.right,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      hintText: "0.00",
                                      hintStyle: TextStyle(
                                        color: primaryLight
                                      ),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: primaryLight,
                                          width: 1.0,
                                          style: BorderStyle.solid,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.zero,
                                      isCollapsed: true,
                                    ),
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
                                        _budgetAmount = (double.tryParse(value) ?? budgetArgs.budgetAmount);
                                      }
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30,),
                          SizedBox(
                            width: double.infinity,
                            child: Row(
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
                                      if (_budgetAmount != null) {
                                        _isDataChanged = true;
                                        List<BudgetModel> newBudgetList = [];
                                        for (int i = 0; i < _budgetList!.budgets.length; i++) {
                                          if (i == index) {
                                            // special treatment
                                            newBudgetList.add(BudgetModel(
                                              id: _budgetList!.budgets[i].id,
                                              category: _budgetList!.budgets[i].category,
                                              totalTransaction: _budgetList!.budgets[i].totalTransaction,
                                              amount: (_budgetAmount ?? budgetArgs.budgetAmount),
                                              used: _budgetList!.budgets[i].used,
                                              status: "in",
                                              currency: _budgetList!.budgets[i].currency,
                                            ));
                                          } else {
                                            newBudgetList.add(_budgetList!.budgets[i]);
                                          }
                                        }
                                  
                                        // create the new budget list model
                                        BudgetListModel newBudgetListModel =
                                          BudgetListModel(
                                            currency: _budgetList!.currency,
                                            budgets: newBudgetList
                                          );
                                  
                                        // set the new budget and announce
                                        _setBudgetList(newBudgetListModel);
                                        Provider.of<HomeProvider>(
                                          context,
                                          listen: false
                                        ).setBudgetAddList(newBudgetListModel.budgets);
                                  
                                        // remove the dialog
                                        Navigator.pop(context);
                                      }
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
                            ),
                          )
                        ],
                      ),
                    )
                  );
                },
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
        padding: const EdgeInsets.all(10),
        color: secondaryDark,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                color: accentColors[6],
              ),
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(ccy.symbol),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(child: Text(ccy.description)),
            const SizedBox(
              width: 10,
            ),
            Text("(${ccy.symbol} ${Globals.fCCY.format(totalAmount)})"),
          ],
        ),
      );
    } else {
      return const Text("Loading");
    }
  }

  void _setBudgetList(BudgetListModel budgetList) {
    setState(() {
      _budgetList = budgetList;

      _totalAmount = 0.0;
      if (_budgetList!.budgets.isNotEmpty) {
        for (BudgetModel budget in _budgetList!.budgets) {
          _totalAmount += budget.amount;
        }
      }
    });
  }

  Future<bool> _fetchBudget([bool? force]) async {
    bool isForce = (force ?? false);
    // fetch the budget from the web
    await _budgetHttp.fetchBudgetsList(_currencyID, isForce).then((result) {
      _setBudgetList(result);
      if (mounted) {
        Provider.of<HomeProvider>(
          context,
          listen: false
        ).setBudgetAddList(result.budgets);
      }
    }).onError((error, stackTrace) {
      // got error
      Log.error(
        message: "Error when <_fetchBudget> at BudgetList",
        error: error,
        stackTrace: stackTrace,
      );

      throw Exception('Error when retreiving budget list');
    });

    return true;
  }

  bool _checkIfCategorySelected(int id) {
    // loop throught the budget list budgets
    if (_budgetList != null) {
      if (_budgetList!.budgets.isNotEmpty) {
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
    // show the loading screen
    LoadingScreen.instance().show(context: context);

    await _budgetHttp.deleteBudgetList(
      currencyId: currencyId,
      budgetId: budgetId
    ).then((budget) {
      // we got the new budget, add this to the shared preferences and the
      // provider
      if (_budgetList!.budgets.isNotEmpty) {
        _budgetList!.budgets.removeWhere((element) =>
          element.id == budget.id &&
          element.currency.id == budget.currency.id
        );

        // create new budget list model with the new budget we added
        BudgetListModel newBudgetList = BudgetListModel(
          currency: _budgetList!.currency,
          budgets: _budgetList!.budgets
        );

        _setBudgetList(newBudgetList);
        if (mounted) {
          Provider.of<HomeProvider>(
            context,
            listen: false
          ).setBudgetAddList(newBudgetList.budgets);
        }

        // set the budget on the home screen, since the budget on the home screen
        // is based on date, first we need to get what is the curren date being displayed
        // on the home budget?
        String currentBudgetDate = BudgetSharedPreferences.getBudgetCurrent();
        List<BudgetModel>? homeBudgetList = BudgetSharedPreferences.getBudget(_currencyID, currentBudgetDate);
        if (homeBudgetList != null) {
          if (homeBudgetList.isNotEmpty) {
            homeBudgetList.removeWhere((element) =>
              element.id == budget.id &&
              element.currency.id == budget.currency.id
            );

            // store back the home budget list
            BudgetSharedPreferences.setBudget(
              _currencyID,
              currentBudgetDate,
              homeBudgetList
            );

            if (mounted) {
              // after that notify the budget list on the home
              Provider.of<HomeProvider>(
                context,
                listen: false
              ).setBudgetList(homeBudgetList);
            }
          }
        }
      }
    }).onError((error, stackTrace) {
      Log.error(
        message: "Error on <_deleteBudgetList> at BudgetList",
        error: error,
        stackTrace: stackTrace,
      );
    }).whenComplete(() {
      // remove the loading screen
      LoadingScreen.instance().hide();
    });
  }

  Future<void> _addBudget(int categoryId, int currencyId) async {
    // show the loading screen
    LoadingScreen.instance().show(context: context);

    await _budgetHttp.addBudgetList(
      currencyId: currencyId,
      categoryId: categoryId
    ).then((budget) {
      // we got the new budget, add this to the shared preferences and the
      // provider
      List<BudgetModel> newBudgets = [];
      if (_budgetList!.budgets.isNotEmpty) {
        newBudgets = _budgetList!.budgets;
      }
      newBudgets.add(budget);

      // create new budget list model with the new budget we added
      BudgetListModel newBudgetList = BudgetListModel(
        currency: _budgetList!.currency,
        budgets: newBudgets
      );
      _budgetList = newBudgetList;

      _setBudgetList(newBudgetList);
      if (mounted) {
        Provider.of<HomeProvider>(context, listen: false).setBudgetAddList(newBudgetList.budgets);
      }

      // set the budget on the home screen, since the budget on the home screen
      // is based on date, first we need to get what is the curren date being displayed
      // on the home budget?
      String currentBudgetDate = BudgetSharedPreferences.getBudgetCurrent();
      List<BudgetModel>? homeBudgetList = (
        BudgetSharedPreferences.getBudget(_currencyID, currentBudgetDate) ?? []
      );
      homeBudgetList.add(budget);
      // store back the home budget list
      BudgetSharedPreferences.setBudget(
          _currencyID, currentBudgetDate, homeBudgetList);
      if (mounted) {
        // after that notify the budget list on the home
        Provider.of<HomeProvider>(context, listen: false).setBudgetList(homeBudgetList);
      }
    }).onError((error, stackTrace) {
      Log.error(
        message: "Error on <_addBudget> at BudgetList",
        error: error,
        stackTrace: stackTrace,
      );
      throw Exception("Error when adding new budgets");
    }).whenComplete(() {
      // remove the loading screen
      LoadingScreen.instance().hide();
    });
  }

  Future<void> _updateBudgetList() async {
    // we will only save if the budget length more than 0, otherwise, no need to send any
    // data to backend
    if (_budgetList!.budgets.isNotEmpty) {
      // show the loading screen
      LoadingScreen.instance().show(context: context);

      await _budgetHttp.updateBudgetList(
        currencyId: _currencyID,
        budgetList: _budgetList!.budgets
      ).then((updatedBudgetList) {
        // store back the home budget list
        String currentBudgetDate = BudgetSharedPreferences.getBudgetCurrent();
        String budgetDate = "";
        List<BudgetModel> newHomeBudgetList = [];
        List<BudgetModel>? currentHomeBudgetList;

        // get the list of budget for this currency that we already load on the storage
        List<String> budgetKeys = MyBox.getKeys("budget_$_currencyID");
        for (String budgetKey in budgetKeys) {
          // get the current budget date
          budgetDate = budgetKey.replaceAll("budget_${_currencyID}_", "");

          // initialize all the variable needed
          newHomeBudgetList = [];
          currentHomeBudgetList = BudgetSharedPreferences.getBudget(_currencyID, budgetDate);

          // check if the current home budget list got data or not?
          // if got data then we can loop and add the new amount on the existing list
          if (currentHomeBudgetList != null) {
            // loop through the _currentHomeBudgetList and add on the _newHomeBudgetList
            for (BudgetModel element in updatedBudgetList) {
              // check if this element same to which id and store the amount
              double used = 0.0;
              for (int i = 0; i < currentHomeBudgetList.length; i++) {
                if (element.id == currentHomeBudgetList[i].id) {
                  used = currentHomeBudgetList[i].used;
                }
              }

              // add the new budget
              newHomeBudgetList.add(BudgetModel(
                id: element.id,
                category: element.category,
                totalTransaction: element.totalTransaction,
                amount: element.amount,
                used: used,
                status: "in",
                currency: element.currency)
              );
            }
          } else {
            // current home list is null?
            // just set the _newHomeBudget list with the _updatedBudgetList
            newHomeBudgetList = updatedBudgetList;
          }

          // set the new home list to the home list budget, so we can directly reflect the data
          BudgetSharedPreferences.setBudget(_currencyID, budgetDate, newHomeBudgetList);
          if (budgetDate == currentBudgetDate) {
            if (mounted) {
              // after that notify the budget list on the home if this is the same as the current budget
              Provider.of<HomeProvider>(context, listen: false).setBudgetList(newHomeBudgetList);
            }
          }
        }
      }).onError((error, stackTrace) {
        Log.error(
          message: "Error on <_addBudget> at BudgetList",
          error: error,
          stackTrace: stackTrace,
        );

        throw Exception("Cannot save budgets");
      }).whenComplete(() {
        // remove the loading screen
        LoadingScreen.instance().hide();
      });
    }
  }
}
