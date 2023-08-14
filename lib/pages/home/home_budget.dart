import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/api/budget_api.dart';
import 'package:my_expense/api/wallet_api.dart';
import 'package:my_expense/model/budget_model.dart';
import 'package:my_expense/model/currency_model.dart';
import 'package:my_expense/model/users_me_model.dart';
import 'package:my_expense/pages/home/home_appbar.dart';
import 'package:my_expense/provider/home_provider.dart';
import 'package:my_expense/themes/category_icon_list.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/args/budget_transaction_args.dart';
import 'package:my_expense/utils/misc/show_loader_dialog.dart';
import 'package:my_expense/utils/prefs/shared_budget.dart';
import 'package:my_expense/utils/prefs/shared_transaction.dart';
import 'package:my_expense/utils/prefs/shared_user.dart';
import 'package:my_expense/utils/prefs/shared_wallet.dart';
import 'package:my_expense/widgets/chart/budget_bar.dart';
import 'package:my_expense/widgets/calendar/horizontal_month_calendar.dart';
import 'package:provider/provider.dart';

class HomeBudget extends StatefulWidget {
  @override
  _HomeBudgetState createState() => _HomeBudgetState();
}

class _HomeBudgetState extends State<HomeBudget> {
  DateTime _firstDay = DateTime(2014, 1, 1); // just default to 2014/01/01
  DateTime _lastDay = DateTime(DateTime.now().year, DateTime.now().month + 1, 1);
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, 1);

  List<CurrencyModel> _currencies = []; // default to blank
  CurrencyModel? _currentCurrencies;
  late UsersMeModel _userMe;
  late ScrollController _scrollControllerCurrencies;
  late ScrollController _scrollControllerBudgetList;

  final WalletHTTPService _walletHTTP = WalletHTTPService();
  final BudgetHTTPService _budgetHTTP = BudgetHTTPService();

  bool _isFinished = false;
  bool _showNotInBudget = false;
  List<BudgetModel> _budgetList = [];

  @override
  void initState() {
    super.initState();
    initBudgetPage();
  }

  @override
  void dispose() {
    super.dispose();
    _scrollControllerCurrencies.dispose();
    _scrollControllerBudgetList.dispose();
  }

  void setFinished(bool isFinished) {
    setState(() {
      _isFinished = isFinished;
    });
  }

  Future<void> initBudgetPage() async {
    _scrollControllerCurrencies = ScrollController();
    _scrollControllerBudgetList = ScrollController();

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
    if(_currencies.length > 0) {
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
      _fetchBudget();
    }
    else {
      // nothing to fetch, set this into true
      setFinished(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(
        title: const Center(child: Text("Budget")),
        iconItem: Icon(
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
      body: _buildHomeBudgetPage(),
    );
  }

  Widget _buildHomeBudgetPage() {
    if(_currencies.length <= 0) {
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
              child: Icon(
                Ionicons.file_tray_outline,
                color: textColor2,
              ),
            ),
            SizedBox(height: 10,),
            Text("Add wallet, and then refresh the budget page"),
          ],
        ),
      );
    }
    else {
      if(!_isFinished) {
        // showed the loading
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(child: SpinKitFadingCube(color: accentColors[6],)),
              SizedBox(height: 20,),
              Text(
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
                  padding: EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        child: HorizontalMonthCalendar(
                          firstDay: _firstDay,
                          lastDay: _lastDay,
                          selectedDate: _selectedDate,
                          onDateSelected: ((value) {
                            setState(() {
                              _selectedDate = value;
                              BudgetSharedPreferences.setBudgetCurrent(value);
                              // in case we add transaction to other month, just refresh the budget forcefully.
                              _fetchBudget(true, true);
                            });
                          }),
                        ),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(width: 1.0, color: secondaryBackground)),
                        ),
                      ),
                      SizedBox(height: 15,),
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
                            return Container(
                              height: 300,
                              color: secondaryDark,
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Center(child: Text("Currencies")),
                                        ),
                                        IconButton(
                                          onPressed: () async {
                                            await _refreshUserCurrencies(true);
                                          },
                                          icon: Icon(
                                            Ionicons.refresh,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 10,),
                                  Expanded(
                                    child: ListView.builder(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      controller: _scrollControllerCurrencies,
                                      itemCount: _currencies.length,
                                      itemBuilder: (BuildContext context, int index) {
                                        return Container(
                                          height: 60,
                                          decoration: BoxDecoration(
                                            border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                                          ),
                                          child: ListTile(
                                            leading: Container(
                                              height: 40,
                                              width: 40,
                                              padding: EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(40),
                                                color: accentColors[6],
                                              ),
                                              child: FittedBox(
                                                child: Text(_currencies[index].symbol.toUpperCase()),
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                            title: Text(_currencies[index].description),
                                            trailing: Visibility(
                                              visible: (_currentCurrencies!.id == _currencies[index].id),
                                              child: Icon(
                                                Ionicons.checkmark_circle,
                                                size: 20,
                                                color: accentColors[0],
                                              ),
                                            ),
                                            onTap: () {
                                              setState(() {
                                                _currentCurrencies = _currencies[index];
                                                _fetchBudget(true);
                                              });
                                              Navigator.pop(context);
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          });
                        },
                        child: Container(
                          color: Colors.transparent ,
                          child: Row(
                            children: [
                              Expanded(
                                child: BudgetBar(
                                  title: _currentCurrencies!.description,
                                  budgetTotal: computeTotalAmount(_budgetList),
                                  budgetUsed: computeTotalUsed(_budgetList),
                                  symbol: _currentCurrencies!.symbol,
                                ),
                              ),
                              SizedBox(width: 10,),
                              Container(
                                height: 20,
                                child: Icon(
                                    Ionicons.chevron_down_circle
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10,),
                      Container(
                        width: double.infinity,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(
                              height: 15,
                              width: 30,
                              child: Transform.scale(
                                scale: 0.5,
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
                            Text(
                              "Showed Not In Budget Expense",
                              style: TextStyle(
                                fontSize: 10,
                                color: textColor,
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: accentColors[6],
                    onRefresh: () async {
                      //debugPrint("Refresh the budget forcefully");
                      _fetchBudget(true, true);
                    },
                    child: ListView.builder(
                      controller: _scrollControllerBudgetList,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _budgetList.length + 1,
                      itemBuilder: ((BuildContext context, int index) {
                        if (index < _budgetList.length) {
                          // check whether we will show not in budget or not?
                          if (!_showNotInBudget) {
                            // check current budget, whether this is in or out
                            if (_budgetList[index].status.toLowerCase() != "in") {
                              // return empty widget
                              return const SizedBox();
                            }
                          }

                          return GestureDetector(
                            onTap: (() {
                              //debugPrint("Showed the list of this transaction category " + _budgetList[index].category.id.toString() + " for this date " + selectedDate.toString());
                              BudgetTransactionArgs _args = BudgetTransactionArgs(
                                categoryid: _budgetList[index].category.id,
                                categoryName: _budgetList[index].category.name,
                                categorySymbol: _budgetList[index].currency.symbol,
                                budgetAmount: _budgetList[index].amount,
                                budgetUsed: _budgetList[index].used,
                                selectedDate: _selectedDate,
                                currencyId: _currentCurrencies!.id,
                              );
                              Navigator.pushNamed(context, '/budget/transaction', arguments: _args);
                            }),
                            child: Container(
                              color: Colors.transparent,
                              padding: EdgeInsets.all(10),
                              child: BudgetBar(
                                icon: IconColorList.getExpenseIcon(_budgetList[index].category.name),
                                iconColor: IconColorList.getExpenseColor(_budgetList[index].category.name),
                                title: _budgetList[index].category.name,
                                symbol: _budgetList[index].currency.symbol,
                                budgetUsed: _budgetList[index].used,
                                budgetTotal: _budgetList[index].amount,
                                type: _budgetList[index].status,
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
  }

  void setCurrencies(List<CurrencyModel> currencies) {
    setState(() {
      _currencies = currencies;
    });
  }

  Future<void> _refreshUserCurrencies(bool force) async {
    showLoaderDialog(context);
    await _walletHTTP.fetchWalletCurrencies(force).then((currencies) {
      setCurrencies(currencies);
      
      // set the home provider
      Provider.of<HomeProvider>(context, listen: false).setWalletCurrency(currencies);
      
      Navigator.pop(context);
    }).onError((error, stackTrace) {
      debugPrint("Error when <_refreshUserCurrencies>");
      debugPrint(error.toString());
      Navigator.pop(context);
    });
  }

  double computeTotalAmount(List<BudgetModel> budgets) {
    double _amount = 0;
    budgets.forEach((budget) {
      if (_showNotInBudget) {
        _amount += budget.amount;
      }
      else {
        if (budget.status.toLowerCase() == "in") {
          _amount += budget.amount;
        }
      }
    });

    return _amount;
  }

  double computeTotalUsed(List<BudgetModel> budgets) {
    double _used = 0;
    budgets.forEach((budget) {
      if (_showNotInBudget) {
        _used += budget.used;
      }
      else {
        if (budget.status.toLowerCase() == "in") {
          _used += budget.used;
        }
      }
    });

    return _used;
  }

  Future<void> _fetchBudget([bool? showLoader, bool? force]) async {
    bool _showLoader = (showLoader ?? false);
    bool _force = (force ?? false);

    if(_showLoader) {
      showLoaderDialog(context);
    }
    else {
      // always assume that we not yet finished
      setFinished(false);
    }

    // fetch the budget, in case it null it will fetch the budget from the
    // backend instead.
    String _budgetDate = DateFormat('yyyy-MM-dd').format(_selectedDate.toLocal());
    await _budgetHTTP.fetchBudgetDate(_currentCurrencies!.id, _budgetDate, _force).then((value) {
      // set the provider as we will use consumer to listen to the list
      Provider.of<HomeProvider>(context, listen: false).setBudgetList(value);
      // debugPrint("Set Budget List to Provider");
    }).then((_) {
      if(_showLoader) {
        Navigator.pop(context);
      }
      else {
        // set finished into true, as we finished already
        setFinished(true);
      }
    });
  }
}
