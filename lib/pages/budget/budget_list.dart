import 'package:flutter/material.dart';
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
  final ScrollController _scrollController = ScrollController();
  final ScrollController _scrollControllerAddCategory = ScrollController();

  late BudgetListModel? _budgetList;
  late Map<int, BudgetModel> _budgetMap;
  late Map<int, CurrencyModel> _currencyMap;
  late Future<bool> _getData;

  int _currencyID = -1;
  double _totalAmount = 0.0;
  double _totalDailyUse = 0.0;
  bool _isDataChanged = false;
  Map<int, CategoryModel> _expenseCategory = {};
  List<CategoryModel> _expenseCategoryList = [];

  @override
  void initState() {
    super.initState();

    // initialize value
    _budgetList = null;
    _budgetMap = {};

    // get the currency ID being sent from the home budget page
    _currencyID = widget.currencyId as int;

    // get the expense category model
    _expenseCategory = CategorySharedPreferences.getCategory(type: "expense");
    _expenseCategoryList = _expenseCategory.values.toList();

    // get the currency map
    _currencyMap = WalletSharedPreferences.getMapWalletCurrencyID();

    // fetch the current budget
    _getData = _fetchBudget(true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollControllerAddCategory.dispose();

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
          const SizedBox(width: 10,),
        ],
      ),
      body: FutureBuilder(
        future: _getData,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return CommonErrorPage(
              errorText: "Error when get budget list",
              isNeedScaffold: false,
            );
          }
          else if (snapshot.hasData) {
            return MySafeArea(
              child: _budgetListView()
            );
          }
          else {
            return CommonLoadingPage(
              isNeedScaffold: false,
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
        _budgetCurrencySelector(
          ccy: (_budgetList?.currency),
          totalAmount: _totalAmount,
          totalDailyUse: _totalDailyUse,
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
          color: secondaryBackground,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accentColors[4],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 5,),
              Text(
                "Use for Daily",
                style: TextStyle(
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _generateListItem(),
        ),
      ],
    );

  }

  Widget _generateListItem() {
    if (_budgetList == null) {
      return const Text("Loading Budget List");
    } else {
      return ListView.builder(
        controller: _scrollController,
        itemCount: _expenseCategoryList.length,
        itemBuilder: (BuildContext ctx, int index) {
          // get the category ID and see if we have budget for this category
          // or not?
          int categoryId = _expenseCategoryList[index].id;

          BudgetModel budget;
          // check if we have budget for this category?
          if (_budgetMap.containsKey(categoryId)) {
            budget = _budgetMap[categoryId]!;
          }
          else {
            budget = BudgetModel(
              id: -1,
              category: _expenseCategoryList[index],
              totalTransaction: 0,
              amount: 0,
              used: 0,
              useForDaily: false,
              status: 'in',
              currency: _currencyMap[_currencyID]!,
            );
          }

          // generate budget detail arguments
          BudgetDetailArgs budgetArgs = BudgetDetailArgs(
            budgetId: budget.id,
            categoryId: budget.category.id,
            categoryIcon: IconColorList.getExpenseIcon(budget.category.name),
            categoryColor: IconColorList.getExpenseColor(budget.category.name),
            categoryName: budget.category.name,
            currencyId: budget.currency.id,
            currencySymbol: budget.currency.symbol,
            budgetAmount: budget.amount,
            useForDaily: budget.useForDaily,
          );

          return CategoryListItem(
            index: index,
            budget: budget,
            showFlagged: (budget.useForDaily),
            flagColor: (budget.useForDaily ? accentColors[4] : secondaryDark),
            isSelected: (budget.id != -1),
            onSelect: (index) async {
              // check the index if it's -1 means that this is not yet added
              if (budget.id == -1) {
                // add the budget
                try {
                  await _addBudget(categoryId, _currencyID);

                  if (mounted) {
                    // show snack bar
                    ScaffoldMessenger.of(context).showSnackBar(
                      createSnackBar(
                        icon: Icon(
                          Ionicons.checkmark_circle_outline,
                          color: accentColors[6],
                        ),
                        message: '${budget.category.name} added',
                      ),
                    );
                  }
                }
                catch(error, _) {
                  if (mounted) {
                    // show error dialog
                    await ShowMyDialog(
                      cancelEnabled: false,
                      confirmText: "OK",
                      dialogTitle: "Error Add Budget",
                      dialogText: "Error while add ${budget.category.name} to budget list.")
                    .show(context);
                  }
                }
              }
              else {
                // show the confirmation dialog
                await _showConfirmDialog(
                  name: budget.category.name,
                ).then((value) async {
                  if (value ?? false) {
                    // delete the budget instead
                    try {
                      await _deleteBudgetList(budget.id, budget.currency.id);
                      if (mounted) {
                        // show snack bar
                        ScaffoldMessenger.of(context).showSnackBar(
                          createSnackBar(message: 'Delete of ${budget.category.name} success'),
                        );
                      }
                    }
                    catch(error, _) {
                      if (mounted) {
                        // show error dialog
                        await ShowMyDialog(
                          cancelEnabled: false,
                          confirmText: "OK",
                          dialogTitle: "Error Delete Budget",
                          dialogText: "Error while deleting ${budget.category.name}.")
                        .show(context);
                      }
                    }
                  }
                });
              }
            },
            onEdit: ((index) async {
              // show edit budget form
              await Navigator.pushNamed<BudgetDetailArgs>(
                context,
                '/budget/list/edit',
                arguments: budgetArgs
              ).then((result) {
                if (result != null) {
                  // set the is data change into true
                  _isDataChanged = true;

                  // we got the budget, now we can change the budget
                  _changeBudget(
                    budgetArgs: result,
                    index: index
                  );
                }
              });
            }),
          );
        },
      );
    }
  }

  Widget _budgetCurrencySelector({
    required CurrencyModel? ccy,
    required double totalAmount,
    required double totalDailyUse,
  }) {
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  "(${ccy.symbol} ${Globals.fCCY.format(totalAmount)})",
                  style: TextStyle(
                    color: accentColors[2],
                  ),
                ),
                Text(
                  "(${ccy.symbol} ${Globals.fCCY.format(totalDailyUse)})",
                  style: TextStyle(
                    color: accentColors[4],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return const Text("Loading");
    }
  }

  void _calculateAndGenerateBudgetMap() {
    _totalAmount = 0.0;
    _totalDailyUse = 0.0;
    
    // clear the budget map
    _budgetMap.clear();

    // check if we have budget or not?
    if (_budgetList!.budgets.isNotEmpty) {
      // if have loop thru the budget
      for (BudgetModel budget in _budgetList!.budgets) {
        _totalAmount += budget.amount;
        if (budget.useForDaily) {
          _totalDailyUse += budget.amount;
        }

        // put the category ID into the budget map
        _budgetMap[budget.category.id] = budget;
      }
    }
  }

  void _setBudgetList(BudgetListModel budgetList) {
    setState(() {
      _budgetList = budgetList;
      _calculateAndGenerateBudgetMap();
    });
  }

  Future<bool> _fetchBudget([bool? force]) async {
    bool isForce = (force ?? false);
    // fetch the budget from the web
    await _budgetHttp.fetchBudgetsList(_currencyID, isForce).then((result) {
      _setBudgetList(result);
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

  Future<void> _deleteBudgetList(int budgetId, int currencyId) async {
    // show the loading screen
    LoadingScreen.instance().show(context: context);

    await _budgetHttp.deleteBudgetList(
      currencyId: currencyId,
      budgetId: budgetId
    ).then((budget) {
      // we got the new budget, add this to the shared preferences and the
      // provider
      setState(() {
        if (_budgetList!.budgets.isNotEmpty) {
          _budgetList!.budgets.removeWhere((element) =>
            element.id == budget.id &&
            element.currency.id == budget.currency.id
          );
        }

        // calculate the total amount and budget map, so we can map correctly
        _calculateAndGenerateBudgetMap();

        // store and update budget list so we can align the current budget list
        // with the one showed on the home budget page.
        _storeAndUpdateBudgetList(budget: budget, delete: true);
      });
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

  Future<void> _addBudget(
    int categoryId,
    int currencyId
  ) async {
    // show the loading screen
    LoadingScreen.instance().show(context: context);

    await _budgetHttp.addBudgetList(
      currencyId: currencyId,
      categoryId: categoryId
    ).then((budget) {
      // we got the new budget, add this to the shared preferences and the
      // provider
      setState(() {        
        if (_budgetList!.budgets.isNotEmpty) {
          _budgetList!.budgets.add(budget);

          // sort budget list
          List<BudgetModel> newBudget = _budgetList!.budgets.toList()..sort((a,b) => (a.category.id.compareTo(b.category.id)));
          _budgetList!.setBudgets(newBudget);

          // recalculate the total amount and budget map, so we can map correctly
          // on the home budget list page.
          _calculateAndGenerateBudgetMap();
        }
        
        // store and update budget list so we can align the current budget list
        // with the one showed on the home budget page.
        _storeAndUpdateBudgetList(budget: budget, delete: false);
      });
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
        String budgetDate = "";
        List<BudgetModel> newHomeBudgetList = [];
        List<BudgetModel>? currentHomeBudgetList;

        // get the list of budget for this currency that we already load on the storage
        List<String> budgetKeys = MyBox.getKeys(key: "budget_$_currencyID");
        for (String budgetKey in budgetKeys) {
          // get the current budget date
          budgetDate = budgetKey.replaceAll("budget_${_currencyID}_", "");

          // initialize all the variable needed
          newHomeBudgetList = [];
          currentHomeBudgetList = BudgetSharedPreferences.getBudget(
            ccyId: _currencyID,
            date: budgetDate,
          );

          // check if the current home budget list got data or not?
          // if got data then we can loop and add the new amount on the existing list
          if (currentHomeBudgetList != null) {
            // loop through the _currentHomeBudgetList and add on the _newHomeBudgetList
            for (BudgetModel budget in updatedBudgetList) {
              // check if this element same to which id and store the amount
              double used = 0.0;
              for (int i = 0; i < currentHomeBudgetList.length; i++) {
                if (budget.id == currentHomeBudgetList[i].id) {
                  used = currentHomeBudgetList[i].used;
                }
              }

              // add the new budget
              newHomeBudgetList.add(BudgetModel(
                id: budget.id,
                category: budget.category,
                totalTransaction: budget.totalTransaction,
                amount: budget.amount,
                used: used,
                useForDaily: budget.useForDaily,
                status: "in",
                currency: budget.currency)
              );
            }
          } else {
            // current home list is null?
            // just set the _newHomeBudget list with the _updatedBudgetList
            newHomeBudgetList = updatedBudgetList;
          }

          // set the new home list to the home list budget, so we can directly reflect the data
          BudgetSharedPreferences.setBudget(
            ccyId: _currencyID,
            date: budgetDate,
            budgets: newHomeBudgetList
          );
          
          // notify the budget list on the home so all page that use budget
          // will be update accordingly
          if (mounted) {
            Provider.of<HomeProvider>(
              context,
              listen: false
            ).setBudgetList(budgets: newHomeBudgetList);
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

  void _storeAndUpdateBudgetList({
    required BudgetModel budget,
    bool delete = false,
  }) {
    // set the budget on the home screen, since the budget on the home screen
    // is based on date, first we need to get what is the current date being displayed
    // on the home budget?
    String currentBudgetDate = BudgetSharedPreferences.getBudgetCurrent();

    // get the current budget
    List<BudgetModel> currentBudgetList = (BudgetSharedPreferences.getBudget(
      ccyId: _currencyID,
      date: currentBudgetDate
    ) ?? []);

    // check whether this is delete or add
    if (delete && currentBudgetList.isNotEmpty) {
      currentBudgetList.removeWhere(
        (data) => (
          data.category.id == budget.category.id &&
          data.currency.id == _currencyID
        ),
      );
    }
    else {
      // add the new budget
      currentBudgetList.add(budget);

      // once got then sort currentBudgetList
      currentBudgetList = currentBudgetList.toList()..sort((a, b) => (a.category.name.compareTo(b.category.name)));
    }

    // store the new budget list
    BudgetSharedPreferences.setBudget(
      ccyId: _currencyID,
      date: currentBudgetDate,
      budgets: currentBudgetList,
    );

    // check if mounted, then update the provider so we can show it on the
    // home budget screen.
    if (mounted) {
      // after that notify the budget list on the home
      Provider.of<HomeProvider>(
        context,
        listen: false
      ).setBudgetList(budgets: currentBudgetList);
    }
  }

  Future<bool?> _showConfirmDialog({
    required String name,
  }) {
    late Future<bool?> result = ShowMyDialog(
      dialogTitle: "Delete Budget",
      dialogText: "Do you want to delete $name?",
      confirmText: "Delete",
      confirmColor: accentColors[2],
      cancelText: "Cancel")
    .show(context);

    return (result);
  }

  void _changeBudget({
    required BudgetDetailArgs budgetArgs,
    required int index
  }) {
    List<BudgetModel> newBudgetList = [];
    for (int i = 0; i < _budgetList!.budgets.length; i++) {
      if (i == index) {
        // special treatment
        newBudgetList.add(BudgetModel(
          id: _budgetList!.budgets[i].id,
          category: _budgetList!.budgets[i].category,
          totalTransaction: _budgetList!.budgets[i].totalTransaction,
          amount: budgetArgs.budgetAmount,
          used: _budgetList!.budgets[i].used,
          status: "in",
          currency: _budgetList!.budgets[i].currency,
          useForDaily: budgetArgs.useForDaily,
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
  }
}
