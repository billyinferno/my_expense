import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/api/transaction_api.dart';
import 'package:my_expense/model/currency_model.dart';
import 'package:my_expense/model/income_expense_category_model.dart';
import 'package:my_expense/model/user_permission_model.dart';
import 'package:my_expense/model/users_me_model.dart';
import 'package:my_expense/model/wallet_model.dart';
import 'package:my_expense/model/wallet_type_model.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/themes/icon_list.dart';
import 'package:my_expense/utils/args/stats_detail_args.dart';
import 'package:my_expense/utils/misc/show_loader_dialog.dart';
import 'package:my_expense/utils/misc/snack_bar.dart';
import 'package:my_expense/utils/prefs/shared_transaction.dart';
import 'package:my_expense/utils/prefs/shared_user.dart';
import 'package:my_expense/utils/prefs/shared_wallet.dart';
import 'package:my_expense/widgets/input/type_slide.dart';
import 'package:my_expense/widgets/input/user_button.dart';
import 'package:my_expense/widgets/item/expand_animation.dart';

class StatsFilterPage extends StatefulWidget {
  const StatsFilterPage({ Key? key }) : super(key: key);

  @override
  _StatsFilterPageState createState() => _StatsFilterPageState();
}

class _StatsFilterPageState extends State<StatsFilterPage> {
  // animation variable
  // double _currentContainerPositioned = 0;

  DateTime _minDate = DateTime(DateTime.now().toLocal().year, DateTime.now().toLocal().month, 1);
  DateTime _maxDate = DateTime(DateTime.now().toLocal().year, DateTime.now().toLocal().month + 1, 1).subtract(Duration(days: 1));

  String _currentType = "month";
  DateTime _currentFromDate = DateTime(DateTime.now().toLocal().year, DateTime.now().toLocal().month, 1);
  DateTime _currentToDate = DateTime(DateTime.now().toLocal().year, DateTime.now().toLocal().month + 1, 1).subtract(Duration(days: 1));
  
  bool _showCalendar = false;
  late String _name;
  
  List<CurrencyModel> _currencies = [];
  List<WalletModel> _wallets = [];
  List<WalletModel> _currentWallets = [];

  late UsersMeModel _userMe;
  late CurrencyModel? _currentCurrencies;
  late WalletModel? _currentWallet;
  IncomeExpenseCategoryModel _currentIncomeExpenseCategory = IncomeExpenseCategoryModel(expense: [], income: []);
  // late PageController _monthController;
  final TextEditingController _nameController = TextEditingController();
  late ScrollController _scrollControllerCurrencies;
  late ScrollController _scrollControllerWallet;
  // late ScrollController _yearSelectorController;

  final TransactionHTTPService _transactionHttp = TransactionHTTPService();

  @override
  void initState() {
    super.initState();

    // default the name into "Any"
    _name = "Any";
    
    _userMe = UserSharedPreferences.getUserMe();

    _currencies = WalletSharedPreferences.getWalletUserCurrency();
    if(_userMe.defaultBudgetCurrency != null && _currencies.length > 0) {
      // defaulted to the first currency first
      _currentCurrencies = _currencies[0];

      // loop through all user wallet currencies and see which one is
      // actually being set as the default for user.
      for(int i=0; i<_currencies.length; i++) {
        if(_currencies[i].id == _userMe.defaultBudgetCurrency) {
          _currentCurrencies = _currencies[i];
        }
      }
    }
    else {
      // just initialize as an empty data
      _currentCurrencies = CurrencyModel(
        -1, "", "", ""
      );
    }

    // get all user wallet information (defaulted the 1st selected as all account)
    _wallets = [(WalletModel(-1, "All Account", 0.0, 0.0, true, true, WalletTypeModel(-1,""), CurrencyModel(-1, "", "", ""), UserPermissionModel(-1,"",""))), ...WalletSharedPreferences.getWallets(false)];
    _filterWalletList();

    // get the minimum and maximum date of the transaction we have
    _minDate = TransactionSharedPreferences.getTransactionMinDate();
    _maxDate = TransactionSharedPreferences.getTransactionMaxDate();

    // compare the max date with the DateTime.Now(), which one is lesser?
    // if _maxDate is lesser, then change the _maxDate with current date
    if(_maxDate.isBefore(DateTime.now().toLocal())) {
      // change the maxDate
      _maxDate = DateTime(DateTime.now().toLocal().year + 1, 1, 1).subtract(Duration(days: 1));
    }
    // set the minimum date as the 1 day of the minimum transaction date
    _minDate = DateTime(_minDate.year, 1, 1);

    _scrollControllerCurrencies = ScrollController();
    _scrollControllerWallet = ScrollController();
  }

  @override
  void dispose() {
    super.dispose();
    
    // _monthController.dispose();
    _nameController.dispose();
    _scrollControllerCurrencies.dispose();
    _scrollControllerWallet.dispose();
    // _yearSelectorController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text("Filter Stats")),
        leading: IconButton(
          icon: Icon(Ionicons.close_outline, color: textColor),
          onPressed: (() {
            Navigator.pop(context);
          }),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: (() async {
              await _filterStats();
            }),
            icon: Icon(Ionicons.caret_forward_circle_outline, color: textColor),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              height: 50,
              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
              decoration: BoxDecoration(
                color: secondaryDark,
              ),
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: secondaryLight, width: 1.0)),
                ),
                child: Container(
                  color: Colors.transparent,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Ionicons.pencil,
                        color: accentColors[1],
                      ),
                      SizedBox(width: 10,),
                      Text(
                        "Name",
                        style: TextStyle(
                          color: textColor2,
                        ),
                      ),
                      const SizedBox(width: 10,),
                      InkWell(
                        onTap: (() {
                          showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
                            return Container(
                              height: 300,
                              color: secondaryDark,
                              child: Column(
                                children: <Widget>[
                                  _nameButton(value: "Any"),
                                  _nameButton(value: "Match"),
                                  _nameButton(value: "Exact"),
                                ],
                              ),
                            );
                          });
                        }),
                        child: Container(
                          height: 30,
                          width: 90,
                          padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                          decoration: BoxDecoration(
                            color: secondaryDark,
                            border: Border.all(
                              color: secondaryLight,
                              width: 1.0,
                              style: BorderStyle.solid
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Center(
                                  child: Text(
                                    _name,
                                    style: TextStyle(
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5,),
                              Icon(
                                Ionicons.chevron_down,
                                color: secondaryLight,
                                size: 15,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10,),
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          enabled: (_name.toLowerCase() == "any" ? false : true),
                          enableSuggestions: false,
                          keyboardType: TextInputType.name,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            hintText: "Transaction name",
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.zero,
                            isCollapsed: true,
                          ),
                          textInputAction: TextInputAction.done,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ),
            _generateCurrencySelector(),
            _generateCalendarDisplay(),
            _generateCalendar(),
            _generateAccountSelector(),
            Container(
              padding: EdgeInsets.all(10),
              child: MaterialButton(
                child: Center(child: Text("Filter Statistics"),),
                onPressed: (() async {
                  await _filterStats();
                }),
                color: accentColors[6],
                height: 50,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _generateCalendarDisplay() {
    return Container(
      height: 50,
      padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
      decoration: BoxDecoration(
        color: secondaryDark,
      ),
      child: UserButton(
        icon: Ionicons.calendar_outline,
        iconColor: accentColors[6],
        label: "Date",
        value: Align(
          alignment: Alignment.centerRight,
          child: Text(
            _getTitleText(),
            //textAlign: TextAlign.right,
            style: TextStyle(
              color: textColor,
            ),
          ),
        ),
        callback: (() {
          // showed the calendar
          setState(() {
            _showCalendar = !_showCalendar;
          });
        }),
      ),
    );
  }

  Widget _generateCalendar() {
    return AnimationExpand(
      expand: _showCalendar,
      child: Container(
        color: secondaryDark,
        height: (_currentType == "custom" ? 400 : 200),
        width: double.infinity,
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            TypeSlide(
              onChange: ((selected) {
                setState(() {
                  _currentType = selected;
                });
              }),
              items: <String, Color>{
                "Month": accentColors[6],
                "Year": accentColors[6],
                "Custom": accentColors[6],
              },
            ),
            SizedBox(height: 10,),
            Expanded(child:
              Container(
                color: Colors.transparent,
                child: _generateCalendarSelection()
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _generateCalendarSelection() {
    if(_currentType == "month") {
      // set the _currentToDate as the last day of the month
      _currentFromDate = DateTime(_currentToDate.toLocal().year, _currentToDate.toLocal().month, 1);
      _currentToDate = DateTime(_currentToDate.toLocal().year, _currentToDate.toLocal().month + 1, 1).subtract(Duration(days: 1));
      // debugPrint("Current From Date : " + _currentFromDate.toLocal().toString());
      // debugPrint("Current To Date : " + _currentToDate.toLocal().toString());
      return _generateMonthCalendar();
    }
    else if(_currentType == "year") {
      // set the _currentToDate as the last day of the year
      _currentFromDate = DateTime(_currentToDate.toLocal().year, 1, 1);
      _currentToDate = DateTime(_currentToDate.toLocal().year + 1, 1, 1).subtract(Duration(days: 1));
      // debugPrint("Current From Date : " + _currentFromDate.toLocal().toString());
      // debugPrint("Current To Date : " + _currentToDate.toLocal().toString());
      return _generateYearCalendar();
    }
    else {
      // check if the _currentTo < _currentFrom, if so, then set _currentTo equal to _currentFrom
      if(_currentToDate.toLocal().isBefore(_currentFromDate.toLocal())) {
        _currentToDate = DateTime(_currentFromDate.toLocal().year, _currentFromDate.toLocal().month + 1, 1).subtract(Duration(days: 1));
      }
      // debugPrint("Current From Date : " + _currentFromDate.toLocal().toString());
      // debugPrint("Current To Date : " + _currentToDate.toLocal().toString());
      return _generateCustomCalendar();
    }
  }

  Widget _generateMonthCalendar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Center(
            child: Container(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(initialItem: (_currentToDate.toLocal().month-1)),
                itemExtent: 25,
                onSelectedItemChanged: (int value) {
                  setState(() {
                     _currentFromDate = DateTime(_currentToDate.toLocal().year, value+1, 1);
                    _currentToDate = DateTime(_currentToDate.toLocal().year, value+2, 1).subtract(Duration(days: 1));
                    //debugPrint(_currentToDate.toString());
                  });
                },
                children: List.generate(12, ((index) {
                  return Text(
                    DateFormat("MMM").format(DateTime(_currentToDate.toLocal().year, index+1, 1)),
                    style: TextStyle(
                      color: textColor2,
                      fontSize: 20,
                      fontFamily: '--apple-system'
                    ),
                  );
                })),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Center(
            child: Container(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(initialItem: (_maxDate.toLocal().year - _currentToDate.toLocal().year)),
                itemExtent: 25,
                onSelectedItemChanged: (int value) {
                  setState(() {
                    _currentFromDate = DateTime((_maxDate.toLocal().year-value), _currentToDate.toLocal().month, 1);
                    _currentToDate = DateTime((_maxDate.toLocal().year-value), (_currentToDate.toLocal().month+1), 1).subtract(Duration(days: 1));
                    //debugPrint(_currentToDate.toString());
                  });
                },
                children: List.generate(((_maxDate.toLocal().year - _minDate.toLocal().year) + 1), ((index) {
                  return Text(
                    (_maxDate.year-index).toString(),
                    style: TextStyle(
                      color: textColor2,
                      fontSize: 20,
                      fontFamily: '--apple-system'
                    ),
                  );
                })),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _generateYearCalendar() {
    return Center(
      child: Container(
        child: CupertinoPicker(
          scrollController: FixedExtentScrollController(initialItem: (_maxDate.toLocal().year - _currentToDate.toLocal().year)),
          itemExtent: 25,
          onSelectedItemChanged: (int value) {
            setState(() {
              _currentFromDate = DateTime((_maxDate.toLocal().year-value), 1, 1);
              _currentToDate = DateTime((_maxDate.toLocal().year-value)+1, 1, 1).subtract(Duration(days: 1));
              //debugPrint(_currentToDate.toString());
            });
          },
          children: List.generate(((_maxDate.toLocal().year - _minDate.toLocal().year) + 1), ((index) {
            return Text(
              (_maxDate.year-index).toString(),
              style: TextStyle(
                color: textColor2,
                fontSize: 20,
                fontFamily: '--apple-system'
              ),
            );
          })),
        ),
      ),
    );
  }

  Widget _generateCustomCalendar() {
    // debugPrint("Max Date : " + _maxDate.toString());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          child: Text("From Date"),
        ),
        Expanded(
          child: Center(
            child: Container(
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: Brightness.dark,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(
                      color: textColor2,
                      fontSize: 20,
                      fontFamily: '--apple-system'
                    ),
                  ),
                ),
                child: CupertinoDatePicker(
                  onDateTimeChanged: (DateTime value) {
                    setState(() {
                      _currentFromDate = value;
                    });
                    //debugPrint(_currentToDate.toString());
                  },
                  initialDateTime: _currentFromDate.toLocal(),
                  maximumDate: _maxDate.toLocal(),
                  minimumDate: _minDate.toLocal(),
                  dateOrder: DatePickerDateOrder.dmy,
                  mode: CupertinoDatePickerMode.date,
                ),
              ),
            ),
          ),
        ),
        Divider(height: 10,),
        Container(
          child: Text("To Date"),
        ),
        Expanded(
          child: Center(
            child: Container(
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: Brightness.dark,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(
                      color: textColor2,
                      fontSize: 20,
                      fontFamily: '--apple-system'
                    ),
                  ),
                ),
                child: CupertinoDatePicker(
                  onDateTimeChanged: (DateTime value) {
                    setState(() {
                      _currentToDate = value;
                    });
                    //debugPrint(_currentToDate.toString());
                  },
                  initialDateTime: _currentToDate.toLocal(),
                  maximumDate: _maxDate.toLocal(),
                  minimumDate: _currentFromDate.toLocal(),
                  dateOrder: DatePickerDateOrder.dmy,
                  mode: CupertinoDatePickerMode.date,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCurrencySelection() async {
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
                      debugPrint("Refresh currency");
                    },
                    icon: Icon(
                      Ionicons.refresh,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollControllerCurrencies,
                itemCount: _currencies.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
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
                            _filterWalletList();
                            //debugPrint("Fetch the statistic for this");
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _showAccountSelection() async {
    // if showing calendar, then no need to showed up the modal bottom sheet
    // to select the account.
    if(_showCalendar) {
      return;
    }

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
                    child: Center(child: Text("Account")),
                  ),
                  IconButton(
                    onPressed: () {
                      debugPrint("Refresh wallet");
                    },
                    icon: Icon(
                      Ionicons.refresh,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollControllerWallet,
                itemCount: _currentWallets.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ListTile(
                        leading: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            color: IconList.getColor(_currentWallets[index].walletType.type.toLowerCase()),
                          ),
                          child: IconList.getIcon(_currentWallets[index].walletType.type.toLowerCase()),
                        ),
                        title: Text(_currentWallets[index].name),
                        trailing: Visibility(
                          visible: (_currentWallet!.id == _currentWallets[index].id),
                          child: Icon(
                            Ionicons.checkmark_circle,
                            size: 20,
                            color: accentColors[0],
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _currentWallet = _currentWallets[index];
                          });
                    
                          // fetch or filter the statistic data that we have
                          //debugPrint("fetch data");
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _generateAccountSelector() {
    return Container(
      height: 50,
      padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
      decoration: BoxDecoration(
        color: secondaryDark,
      ),
      child: UserButton(
        icon: Ionicons.wallet_outline,
        iconColor: accentColors[5],
        label: "Account",
        value: Align(
          alignment: Alignment.centerRight,
          child: Text(
            _currentWallet!.name,
            //textAlign: TextAlign.right,
            style: TextStyle(
              color: textColor,
            ),
          ),
        ),
        callback: (() {
          // showed the account
          _showAccountSelection();
        }),
      ),
    );
  }

  Widget _generateCurrencySelector() {
    return Container(
      height: 50,
      padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
      decoration: BoxDecoration(
        color: secondaryDark,
      ),
      child: UserButton(
        icon: Ionicons.cash_outline,
        iconColor: accentColors[9],
        label: "Currency",
        value: Align(
          alignment: Alignment.centerRight,
          child: Text(
            _currentCurrencies!.description,
            //textAlign: TextAlign.right,
            style: TextStyle(
              color: textColor,
            ),
          ),
        ),
        callback: (() {
          _showCurrencySelection();
        }),
      ),
    );
  }

  Widget _nameButton({required String value}) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
      ),
      child: InkWell(
        onTap: (() {
          // check if the value is any, then clear the _nameController
          if (value.toLowerCase() == "any") {
            _nameController.text = "";
          }

          // rebuild widget
          setState(() {
            _name = value;
          });

          // remove the popup modal dialog
          Navigator.pop(context);
        }),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(width: 20,),
              Expanded(
                child: Text(
                  value
                ),
              ),
              const SizedBox(width: 10,),
              Visibility(
                visible: (_name.toLowerCase() == value.toLowerCase()),
                child: Icon(
                  Ionicons.checkmark_circle,
                  size: 20,
                  color: accentColors[0],
                )
              ),
              const SizedBox(width: 20,),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitleText() {
    if(_currentType == "month") {
      return DateFormat("MMMM yyyy").format(_currentToDate.toLocal());
    }
    else if(_currentType == "year") {
      return DateFormat("yyyy").format(_currentToDate.toLocal());
    }
    else {
      return DateFormat("dd/MM/yyyy").format(_currentFromDate.toLocal()) + " - " + DateFormat("dd/MM/yyyy").format(_currentToDate.toLocal());
    }
  }

  void _filterWalletList() {
    // loop to get all the account that related with this currencies
    _currentWallets.clear();
    if(_currentCurrencies!.id > 0) {
      _wallets.forEach((wallet) {
        if(wallet.id == -1) {
          _currentWallets.add(wallet);
        }
        else {
          if(wallet.currency.id == _currentCurrencies!.id) {
            _currentWallets.add(wallet);
          }
        }
      });
    }
    else {
      _currentWallets = [_wallets[0]];
    }
    // defaulted current wallet to all accounts (-1)
    _currentWallet = _currentWallets[0];
  }

  Future<void> _filterStats() async {
    // fetch the transaction data for this
    if(_currentCurrencies!.id >= 0 && _currentWallet != null) {
      showLoaderDialog(context);

      await _fetchStats().then((_) {
        // pop the loader
        Navigator.pop(context);

        StatsDetailArgs args = StatsDetailArgs(
          type: _currentType,
          fromDate: _currentFromDate,
          toDate: _currentToDate,
          currency: _currentCurrencies!,
          wallet: _currentWallet!,
          incomeExpenseCategory: _currentIncomeExpenseCategory,
          name: (_nameController.text.isEmpty ? '*' : _nameController.text.trim()),
          search: _name,
        );

        // navigate to stats detail
        Navigator.pushNamed(context, '/stats/detail', arguments: args);
      }).onError((error, stackTrace) {
        // pop the loader
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          createSnackBar(
            message: error.toString(),
          )
        );
      });
    }
  }

  Future<void> _fetchStats() async {
    await _transactionHttp.fetchIncomeExpenseCategory(_nameController.text, _name, _currentCurrencies!.id, _currentWallet!.id, _currentFromDate, _currentToDate).then((incomeExpenseCategory) {
      // set current income expense category as this
      _currentIncomeExpenseCategory = incomeExpenseCategory;
    }).onError((error, stackTrace) {
      debugPrint("Error when <_fetchStats>");
      throw new Exception("Error when trying to fetch statistics");
    });
  }
}