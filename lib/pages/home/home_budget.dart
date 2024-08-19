import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:my_expense/_index.g.dart';

class HomeBudget extends StatefulWidget {
  const HomeBudget({super.key});

  @override
  State<HomeBudget> createState() => _HomeBudgetState();
}

class _HomeBudgetState extends State<HomeBudget> {
  DateTime _firstDay = DateTime(2014, 1, 1); // just default to 2014/01/01
  DateTime _lastDay = DateTime(DateTime.now().year, DateTime.now().month + 1, 1);
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, 1);

  List<CurrencyModel> _currencies = []; // default to blank
  CurrencyModel? _currentCurrencies;
  late UsersMeModel _userMe;
  final ScrollController _scrollControllerCurrencies = ScrollController();
  final ScrollController _scrollControllerBudgetList = ScrollController();

  final BudgetHTTPService _budgetHTTP = BudgetHTTPService();

  bool _showNotInBudget = false;
  List<BudgetModel> _budgetList = [];
  late Future<bool> _getData;

  @override
  void initState() {
    // static prefs for each shared preferences is already initialize during
    // the application startup.
    _currencies = WalletSharedPreferences.getWalletUserCurrency();
    _userMe = UserSharedPreferences.getUserMe();

    // set the first and last day based on user min and max date we got from
    // transaction, so we knew exactly when is our first and last budget date.
    DateTime userMinDate = TransactionSharedPreferences.getTransactionMinDate();
    DateTime userMaxDate = TransactionSharedPreferences.getTransactionMaxDate();

    // convert the date to the first day of the min and max transaction date
    _firstDay = DateTime(userMinDate.year, userMinDate.month, 1);
    _lastDay = DateTime(userMaxDate.year, userMaxDate.month, 1);

    // now check which currencies is being used by the user
    if(_currencies.isNotEmpty) {
      // defaulted to first currency, in case user default currency is different
      // with the one that user has on their wallet
      _currentCurrencies = _currencies[0];

      // loop thru all user wallet currency, and check if the currency preferred
      // by the user is exists on the wallet (by right it should be).
      for(int idx=0; idx<_currencies.length; idx++) {
        if(_currencies[idx].id == _userMe.defaultBudgetCurrency) {
          _currentCurrencies = _currencies[idx];
          // exit from loop
          break;
        }
      }

      // now fetch budget based on the _currentCurrencies
      BudgetSharedPreferences.setBudgetCurrent(_selectedDate);
    }

    _getData = _fetchBudget();

    super.initState();
  }

  @override
  void dispose() {
    _scrollControllerCurrencies.dispose();
    _scrollControllerBudgetList.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(
        title: const Center(child: Text("Budget")),
        iconItem: const Icon(
          Ionicons.options_outline,
          size: 20,
        ),
        onUserPress: () {
          Navigator.pushNamed(context, '/user');
        },
        onActionPress: () {
          Navigator.pushNamed(context, '/budget/list', arguments: _currentCurrencies!.id);
        },
      ),
      body: FutureBuilder(
        future: _getData,
        builder: ((context, snapshot) {
          if (snapshot.hasError) {
            // got error when loading the budget data
            return const Center(child: Text("Error when loading budget"),);
          }
          else if (snapshot.hasData) {
            // build the budget page
            return _buildHomeBudgetPage();
          }
          else {
            // showed the loading
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitFadingCube(color: accentColors[6],),
                  const SizedBox(height: 20,),
                  const Text(
                    "Loading Budget",
                    style: TextStyle(
                      color: textColor2,
                      fontSize: 10,
                    ),
                  )
                ],
              )
            );
          }
        }),
      ),
    );
  }

  Widget _buildHomeBudgetPage() {
    if(_currencies.isEmpty) {
      // if currencies is null, means that user haven't setup anything?
      // just throw a container with center text, that there are nothing here
      // and ask user to setup wallet first
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: accentColors[4],
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Ionicons.file_tray_outline,
                color: textColor2,
              ),
            ),
            const SizedBox(height: 10,),
            const Text("Add wallet, and then refresh the budget page"),
          ],
        ),
      );
    }
    else {
      return Consumer<HomeProvider>(
        builder: (context, homeProvider, child) {
          _budgetList = homeProvider.budgetList;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                width: double.infinity,
                color: secondaryDark,
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(width: 1.0, color: secondaryBackground)),
                      ),
                      child: HorizontalMonthCalendar(
                        firstDay: _firstDay,
                        lastDay: _lastDay,
                        selectedDate: _selectedDate,
                        onDateSelected: ((value) {
                          setState(() {
                            _selectedDate = value;
                            BudgetSharedPreferences.setBudgetCurrent(value);
                            // in case we add transaction to other month, just refresh the budget forcefully.
                            _getData = _fetchBudget(true, true);
                          });
                        }),
                      ),
                    ),
                    const SizedBox(height: 15,),
                    Slidable(
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        extentRatio: 0.2,
                        children: <SlidableAction>[
                          SlidableAction(
                            label: 'Stat',
                            padding: const EdgeInsets.all(0),
                            foregroundColor: accentColors[3],
                            backgroundColor: Colors.transparent,
                            icon: Ionicons.bar_chart,
                            onPressed: ((_) {
                              // create budget transaction arguments that can be passed to other pages
                              BudgetTransactionArgs args = BudgetTransactionArgs(
                                categoryid: -1,
                                categoryName: _currentCurrencies!.description,
                                currencySymbol: _currentCurrencies!.symbol,
                                budgetAmount: -1,
                                budgetUsed: -1,
                                selectedDate: _selectedDate,
                                currencyId: _currentCurrencies!.id,
                              );

                              Navigator.pushNamed(context, '/budget/stat', arguments: args);
                            })
                          ),
                        ],
                      ),
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
                            return MyBottomSheet(
                              context: context,
                              title: "Currencies",
                              screenRatio: 0.35,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                controller: _scrollControllerCurrencies,
                                itemCount: _currencies.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return SimpleItem(
                                    color: accentColors[6],
                                    title: _currencies[index].description,
                                    isSelected: (_currentCurrencies!.id == _currencies[index].id),
                                    onTap: (() {
                                      setState(() {
                                        _currentCurrencies = _currencies[index];
                                        _fetchBudget(true);
                                      });
                                      Navigator.pop(context);
                                    }),
                                    icon: FittedBox(
                                      fit: BoxFit.contain,
                                      child: Text(_currencies[index].symbol.toUpperCase()),
                                    ),
                                  );
                                },
                              ),
                            );
                          });
                        },
                        child: Container(
                          height: 50,
                          color: Colors.transparent ,
                          child: Row(
                            children: [
                              Expanded(
                                child: BudgetBar(
                                  title: _currentCurrencies!.description,
                                  budgetTotal: _computeTotalAmount(_budgetList),
                                  budgetUsed: _computeTotalUsed(_budgetList),
                                  symbol: _currentCurrencies!.symbol,
                                ),
                              ),
                              const SizedBox(width: 10,),
                              const SizedBox(
                                height: 20,
                                child: Icon(
                                    Ionicons.chevron_down_circle
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10,),
                    GestureDetector(
                      onTap: (() {
                        setState(() {
                          _showNotInBudget = !_showNotInBudget;
                        });
                      }),
                      child: Container(
                        color: Colors.transparent,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(
                              height: 15,
                              width: 30,
                              child: Transform.scale(
                                scale: 0.6,
                                child: CupertinoSwitch(
                                  value: _showNotInBudget,
                                  onChanged: (value) {
                                    setState(() {
                                      _showNotInBudget = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 11,),
                            const Text(
                              "Not In Budget Expense",
                              style: TextStyle(
                                fontSize: 10,
                                color: textColor,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: accentColors[6],
                  onRefresh: () async {
                    await _fetchBudget(true, true);
                  },
                  child: ListView.builder(
                    controller: _scrollControllerBudgetList,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _budgetList.length + 1,
                    itemBuilder: ((BuildContext context, int index) {
                      if (index < _budgetList.length) {
                        // create budget transaction arguments that can be passed to other pages
                        BudgetTransactionArgs args = BudgetTransactionArgs(
                          categoryid: _budgetList[index].category.id,
                          categoryName: _budgetList[index].category.name,
                          currencySymbol: _budgetList[index].currency.symbol,
                          budgetAmount: _budgetList[index].amount,
                          budgetUsed: _budgetList[index].used,
                          selectedDate: _selectedDate,
                          currencyId: _currentCurrencies!.id,
                        );

                        // check whether we will show not in budget or not?
                        if (!_showNotInBudget) {
                          // check current budget, whether this is in or out
                          if (_budgetList[index].status.toLowerCase() != "in") {
                            // return empty widget
                            return const SizedBox();
                          }
                        }

                        return Slidable(
                          endActionPane: ActionPane(
                            motion: const DrawerMotion(),
                            extentRatio: 0.2,
                            children: <SlidableAction>[
                              SlidableAction(
                                label: 'Stat',
                                padding: const EdgeInsets.all(0),
                                foregroundColor: accentColors[3],
                                backgroundColor: primaryBackground,
                                icon: Ionicons.bar_chart,
                                onPressed: ((_) {
                                  Navigator.pushNamed(context, '/budget/stat', arguments: args);
                                })
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            onTap: (() {
                              Navigator.pushNamed(context, '/budget/transaction', arguments: args);
                            }),
                            child: Container(
                              color: Colors.transparent,
                              padding: const EdgeInsets.all(10),
                              child: BudgetBar(
                                icon: IconColorList.getExpenseIcon(_budgetList[index].category.name),
                                iconColor: IconColorList.getExpenseColor(_budgetList[index].category.name),
                                title: _budgetList[index].category.name,
                                subTitle: "${_budgetList[index].totalTransaction} transaction${_budgetList[index].totalTransaction > 1 ? 's' : ''}",
                                symbol: _budgetList[index].currency.symbol,
                                budgetUsed: _budgetList[index].used,
                                budgetTotal: _budgetList[index].amount,
                                type: _budgetList[index].status,
                              ),
                            ),
                          ),
                        );
                      }
                      else {
                        return const SizedBox(height: 30,);
                      }
                    }),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  double _computeTotalAmount(List<BudgetModel> budgets) {
    double amount = 0;
    for (BudgetModel budget in budgets) {
      if (_showNotInBudget) {
        amount += budget.amount;
      }
      else {
        if (budget.status.toLowerCase() == "in") {
          amount += budget.amount;
        }
      }
    }

    return amount;
  }

  double _computeTotalUsed(List<BudgetModel> budgets) {
    double used = 0;
    for (BudgetModel budget in budgets) {
      if (_showNotInBudget) {
        used += budget.used;
      }
      else {
        if (budget.status.toLowerCase() == "in") {
          used += budget.used;
        }
      }
    }

    return used;
  }

  void _streamBudgetList({required List<BudgetModel> data}) {
    Provider.of<HomeProvider>(context, listen: false).setBudgetList(data);
  }

  Future<bool> _fetchBudget([bool? showLoader, bool? force]) async {
    bool isShowLoader = (showLoader ?? false);
    bool isForce = (force ?? false);

    if(isShowLoader) {
      LoadingScreen.instance().show(context: context);
    }

    // fetch the budget, in case it null it will fetch the budget from the
    // backend instead.
    String budgetDate = DateFormat('yyyy-MM-dd').format(_selectedDate.toLocal());

    // show the debug print to know that we are refreshing/fetching budget
    Log.info(message: "📃 Refresh Budget at $budgetDate");

    // get the budget data
    await _budgetHTTP.fetchBudgetDate(_currentCurrencies!.id, budgetDate, isForce).then((value) {
      _streamBudgetList(data: value);
    }).whenComplete(() {
      if(isShowLoader) {
        LoadingScreen.instance().hide();
      }
    }).onError((error, stackTrace) {
      Log.error(
        message: "🚫 Error when fetching budget data",
        error: error,
        stackTrace: stackTrace,
      );
      throw Exception("Error when fetching budget data");
    },);

    // if all good return true
    return true;
  }
}
