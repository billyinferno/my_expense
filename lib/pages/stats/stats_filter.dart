import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

class StatsFilterPage extends StatefulWidget {
  const StatsFilterPage({super.key});

  @override
  State<StatsFilterPage> createState() => _StatsFilterPageState();
}

class _StatsFilterPageState extends State<StatsFilterPage> {
  final TextEditingController _nameController = TextEditingController();
  final ScrollController _scrollControllerCurrencies = ScrollController();
  final ScrollController _scrollControllerWallet = ScrollController();
  final TransactionHTTPService _transactionHttp = TransactionHTTPService();
  final CalendarDatePicker2Config _calendarConfig = CalendarDatePicker2Config(
    calendarType: CalendarDatePicker2Type.range,
    selectedDayHighlightColor: primaryLight,
    weekdayLabelTextStyle: const TextStyle(
      color: textColor,
      fontWeight: FontWeight.bold,
    ),
    controlsTextStyle: const TextStyle(
      color: textColor,
      fontSize: 15,
      fontWeight: FontWeight.bold,
    ),
  );
  final Map<String, TypeSlideItem> _typeSlideItem = {
    "month": TypeSlideItem(
      color: accentColors[6],
      text: "Month",
      textColor: Colors.white.withValues(alpha: 0.7),
    ),
    "year": TypeSlideItem(
      color: accentColors[6],
      text: "Year",
      textColor: Colors.white.withValues(alpha: 0.7),
    ),
    "custom": TypeSlideItem(
      color: accentColors[6],
      text: "Custom",
      textColor: Colors.white.withValues(alpha: 0.7),
    ),
  };

  late DateTime _minDate;
  late DateTime _maxDate;
  late DateTime _currentFromDate;
  late DateTime _currentToDate;

  late String _currentType;
  late bool _showCalendar;
  late String _searchType;

  late List<CurrencyModel> _currencies;
  late List<WalletModel> _wallets;
  late List<WalletModel> _currentWallets;

  late UsersMeModel _userMe;
  late CurrencyModel? _currentCurrencies;
  late WalletModel? _currentWallet;
  late IncomeExpenseCategoryModel _currentIncomeExpenseCategory;
  late List<DateTime> _selectedDateTime;

  @override
  void initState() {
    super.initState();

    // default the name into "Any"
    _searchType = "Any";
    _currentType = "month";
    _showCalendar = false;

    _userMe = UserSharedPreferences.getUserMe();

    // default current income expense category into empty array
    _currentIncomeExpenseCategory = IncomeExpenseCategoryModel(
      expense: [],
      income: []
    );

    _currencies = WalletSharedPreferences.getWalletUserCurrency();
    if (_userMe.defaultBudgetCurrency != null && _currencies.isNotEmpty) {
      // defaulted to the first currency first
      _currentCurrencies = _currencies[0];

      // loop through all user wallet currencies and see which one is
      // actually being set as the default for user.
      for (int i = 0; i < _currencies.length; i++) {
        if (_currencies[i].id == _userMe.defaultBudgetCurrency) {
          _currentCurrencies = _currencies[i];
        }
      }
    } else {
      // just initialize as an empty data
      _currentCurrencies = CurrencyModel(-1, "", "", "");
    }

    // get all user wallet information (defaulted the 1st selected as all account)
    _wallets = [
      // mock result for all account
      (WalletModel(
        -1,
        "All Account",
        0.0,
        0.0,
        0.0,
        true,
        true,
        -1,
        WalletTypeModel(-1, ""),
        CurrencyModel(-1, "", "", ""),
        UserPermissionModel(-1, "", ""))
      ),
      ...WalletSharedPreferences.getWallets(showDisabled: false)
    ];

    // default current wallets to empty array and filter wallet list
    _currentWallets = [];
    _filterWalletList();

    // get the minimum and maximum date of the transaction we have
    _minDate = TransactionSharedPreferences.getTransactionMinDate();
    _maxDate = TransactionSharedPreferences.getTransactionMaxDate();

    // set the minimum date as the 1 day of the minimum transaction date
    _minDate = DateTime(_minDate.year, 1, 1);

    // compare the max date with the DateTime.Now(), which one is lesser?
    // if _maxDate is lesser, then change the _maxDate with current date
    if (_maxDate.isBefore(DateTime.now().toLocal())) {
      // change the maxDate
      _maxDate = DateTime(
        DateTime.now().toLocal().year + 1, 1, 1
      ).subtract(const Duration(days: 1));
    }

    _currentFromDate = DateTime(
      DateTime.now().toLocal().year,
      DateTime.now().toLocal().month,
      1
    );
    _currentToDate = DateTime(
      DateTime.now().toLocal().year,
      DateTime.now().toLocal().month + 1,
      1
    ).subtract(const Duration(days: 1));

    _selectedDateTime = [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scrollControllerCurrencies.dispose();
    _scrollControllerWallet.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text("Filter Stats")),
        leading: IconButton(
          icon: const Icon(Ionicons.close_outline, color: textColor),
          onPressed: (() {
            Navigator.pop(context);
          }),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: (() async {
              await _filterStats();
            }),
            icon: const Icon(
              Ionicons.caret_forward_circle_outline,
              color: textColor
            ),
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
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                decoration: const BoxDecoration(
                  color: secondaryDark,
                ),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: secondaryLight,
                        width: 1.0
                      )
                    ),
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
                        const SizedBox(width: 10,),
                        const Text(
                          "Name",
                          style: TextStyle(
                            color: textColor2,
                          ),
                        ),
                        const SizedBox(width: 10,),
                        InkWell(
                          onTap: (() {
                            showModalBottomSheet<void>(
                              context: context,
                              builder: (BuildContext context) {
                                return MyBottomSheet(
                                  context: context,
                                  title: 'Search Type',
                                  screenRatio: 0.35,
                                  child:  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      _nameButton(value: "Any"),
                                      _nameButton(value: "Match"),
                                      _nameButton(value: "Exact"),
                                    ],
                                  )
                                );
                              }
                            );
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
                                      _searchType,
                                      style: const TextStyle(
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                const Icon(
                                  Ionicons.chevron_down,
                                  color: secondaryLight,
                                  size: 15,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Visibility(
                          visible: (_searchType.toLowerCase() != 'any'),
                          child: Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              enabled: (_searchType.toLowerCase() == "any" ? false : true),
                              enableSuggestions: false,
                              keyboardType: TextInputType.name,
                              textAlign: TextAlign.right,
                              cursorColor: primaryLight,
                              decoration: const InputDecoration(
                                hintText: "Transaction name",
                                hintStyle: TextStyle(
                                  color: primaryLight,
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.zero,
                                isCollapsed: true,
                              ),
                              textInputAction: TextInputAction.done,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
            _generateCurrencySelector(),
            _generateCalendarDisplay(),
            _generateCalendar(),
            _generateAccountSelector(),
            Container(
              padding: const EdgeInsets.all(10),
              child: MaterialButton(
                onPressed: (() async {
                  await _filterStats();
                }),
                color: accentColors[6],
                focusColor: accentColors[6],
                highlightColor: accentColors[0],
                height: 50,
                child: const Center(
                  child: Text("Filter Statistics"),
                ),
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
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      decoration: const BoxDecoration(
        color: secondaryDark,
      ),
      child: UserButton(
        icon: Ionicons.calendar_outline,
        iconColor: accentColors[6],
        label: "Date",
        trailing: Align(
          alignment: Alignment.centerRight,
          child: Text(
            _getTitleText(),
            //textAlign: TextAlign.right,
            style: const TextStyle(
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
        padding: const EdgeInsets.all(10),
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
              initialItem: 'month',
              items: _typeSlideItem,
            ),
            const SizedBox(height: 10,),
            Expanded(
              child: Container(
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
    if (_currentType == "month") {
      // set the _currentToDate as the last day of the month
      _currentFromDate = DateTime(
        _currentToDate.toLocal().year, _currentToDate.toLocal().month, 1
      );
      _currentToDate = DateTime(
        _currentToDate.toLocal().year,_currentToDate.toLocal().month + 1, 1
      ).subtract(const Duration(days: 1));
      
      return _generateMonthCalendar();
    } else if (_currentType == "year") {
      // set the _currentToDate as the last day of the year
      _currentFromDate = DateTime(_currentToDate.toLocal().year, 1, 1);
      _currentToDate = DateTime(
        _currentToDate.toLocal().year + 1, 1, 1
      ).subtract(const Duration(days: 1));
      
      return _generateYearCalendar();
    } else {
      // check if the _currentTo < _currentFrom, if so, then set _currentTo equal to _currentFrom
      if (_currentToDate.toLocal().isBefore(_currentFromDate.toLocal())) {
        _currentToDate = DateTime(
          _currentFromDate.toLocal().year,
          _currentFromDate.toLocal().month + 1,
          1
        ).subtract(const Duration(days: 1));
      }

      // ensure _currentToDate also not more than _maxDate
      if (_currentToDate.toLocal().isAfter(_maxDate.toLocal())) {
        _currentToDate = _maxDate;
      }

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
            child: CupertinoPicker(
              scrollController: FixedExtentScrollController(
                initialItem: (_currentToDate.toLocal().month - 1)
              ),
              itemExtent: 25,
              onSelectedItemChanged: (int value) {
                setState(() {
                  _currentFromDate = DateTime(
                    _currentToDate.toLocal().year, value + 1, 1
                  );
                  _currentToDate = DateTime(
                    _currentToDate.toLocal().year, value + 2, 1
                  ).subtract(const Duration(days: 1));
                });
              },
              children: List.generate(12, ((index) {
                return Text(
                  Globals.dfMMM.format(DateTime(_currentToDate.toLocal().year, index + 1, 1)),
                  style: const TextStyle(
                    color: textColor2,
                    fontSize: 20,
                    fontFamily: '--apple-system'
                  ),
                );
              })),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Center(
            child: CupertinoPicker(
              scrollController: FixedExtentScrollController(
                initialItem: (_maxDate.toLocal().year - _currentToDate.toLocal().year)
              ),
              itemExtent: 25,
              onSelectedItemChanged: (int value) {
                setState(() {
                  _currentFromDate = DateTime(
                    (_maxDate.toLocal().year - value),
                    _currentToDate.toLocal().month,
                    1
                  );
                  
                  _currentToDate = DateTime(
                    (_maxDate.toLocal().year - value),
                    (_currentToDate.toLocal().month + 1),
                    1
                  ).subtract(const Duration(days: 1));
                });
              },
              children: List.generate(
                ((_maxDate.toLocal().year - _minDate.toLocal().year) + 1),
                ((index) {
                  return Text(
                    (_maxDate.year - index).toString(),
                    style: const TextStyle(
                        color: textColor2,
                        fontSize: 20,
                        fontFamily: '--apple-system'),
                  );
                })
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _generateYearCalendar() {
    return Center(
      child: CupertinoPicker(
        scrollController: FixedExtentScrollController(
          initialItem: (_maxDate.toLocal().year - _currentToDate.toLocal().year)
        ),
        itemExtent: 25,
        onSelectedItemChanged: (int value) {
          setState(() {
            _currentFromDate = DateTime(
              (_maxDate.toLocal().year - value), 1, 1
            );
            _currentToDate = DateTime(
              (_maxDate.toLocal().year - value) + 1, 1, 1
            ).subtract(const Duration(days: 1));
          });
        },
        children: List.generate(
          (
            (_maxDate.toLocal().year - _minDate.toLocal().year) + 1
          ),
          ((index) {
            return Text(
              (_maxDate.year - index).toString(),
              style: const TextStyle(
                color: textColor2,
                fontSize: 20,
                fontFamily: '--apple-system'
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _generateCustomCalendar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: CalendarDatePicker2(
            config: _calendarConfig.copyWith(
              firstDate: _minDate,
              lastDate: _maxDate,
            ),
            value: _selectedDateTime,
            onValueChanged: ((newDate) {
              if (newDate.length == 2) {
                setState(() {
                  _currentFromDate = newDate[0];
                  _currentToDate = newDate[1];

                  _selectedDateTime = [_currentFromDate, _currentToDate];
                });
              }
            }),
          ),
        ),
      ],
    );
  }

  Future<void> _showCurrencySelection() async {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return MyBottomSheet(
          context: context,
          title: "Currencies",
          screenRatio: 0.35,
          child: ListView.builder(
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
                    _filterWalletList();
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
      }
    );
  }

  Future<void> _showAccountSelection() async {
    // if showing calendar, then no need to showed up the modal bottom sheet
    // to select the account.
    if (_showCalendar) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return MyBottomSheet(
          context: context,
          title: "Account",
          screenRatio: 0.45,
          child: ListView.builder(
            controller: _scrollControllerWallet,
            itemCount: _currentWallets.length,
            itemBuilder: (BuildContext context, int index) {
              return SimpleItem(
                color: IconList.getColor(
                  _currentWallets[index].walletType.type.toLowerCase()
                ),
                title: _currentWallets[index].name,
                isSelected: (_currentWallet!.id == _currentWallets[index].id),
                onTap: (() {
                  setState(() {
                    _currentWallet = _currentWallets[index];
                  });
                  Navigator.pop(context);
                }),
                icon: IconList.getIcon(
                  _currentWallets[index].walletType.type.toLowerCase()
                ),
              );
            },
          ),
        );
      }
    );
  }

  Widget _generateAccountSelector() {
    return Container(
      height: 50,
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      decoration: const BoxDecoration(
        color: secondaryDark,
      ),
      child: UserButton(
        icon: Ionicons.wallet_outline,
        iconColor: accentColors[5],
        label: "Account",
        trailing: Align(
          alignment: Alignment.centerRight,
          child: Text(
            _currentWallet!.name,
            //textAlign: TextAlign.right,
            style: const TextStyle(
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
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      decoration: const BoxDecoration(
        color: secondaryDark,
      ),
      child: UserButton(
        icon: Ionicons.cash_outline,
        iconColor: accentColors[9],
        label: "Currency",
        trailing: Align(
          alignment: Alignment.centerRight,
          child: Text(
            _currentCurrencies!.description,
            //textAlign: TextAlign.right,
            style: const TextStyle(
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      height: 60,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: primaryLight,
            width: 1.0
          )
        ),
      ),
      child: InkWell(
        onTap: (() {
          // check if the value is any, then clear the _nameController
          if (value.toLowerCase() == "any") {
            _nameController.text = "";
          }

          // rebuild widget
          setState(() {
            _searchType = value;
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
              Expanded(
                child: Text(value),
              ),
              const SizedBox(width: 10,),
              Visibility(
                visible: (_searchType.toLowerCase() == value.toLowerCase()),
                child: Icon(
                  Ionicons.checkmark_circle,
                  size: 20,
                  color: accentColors[0],
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitleText() {
    if (_currentType == "month") {
      return Globals.dfMMMMyyyy.formatLocal(_currentToDate);
    } else if (_currentType == "year") {
      return Globals.dfyyyy.formatLocal(_currentToDate);
    } else {
      return "${Globals.dfddMMyyyy.formatLocal(_currentFromDate)} - ${Globals.dfddMMyyyy.formatLocal(_currentToDate)}";
    }
  }

  void _filterWalletList() {
    // loop to get all the account that related with this currencies
    _currentWallets.clear();
    if (_currentCurrencies!.id > 0) {
      for (WalletModel wallet in _wallets) {
        if (wallet.id == -1) {
          _currentWallets.add(wallet);
        } else {
          if (wallet.currency.id == _currentCurrencies!.id) {
            _currentWallets.add(wallet);
          }
        }
      }
    } else {
      _currentWallets = [_wallets[0]];
    }
    // defaulted current wallet to all accounts (-1)
    _currentWallet = _currentWallets[0];
  }

  Future<void> _filterStats() async {
    // fetch the transaction data for this
    if (_currentCurrencies!.id >= 0 && _currentWallet != null) {
      await _fetchStats().then((_) {
        StatsDetailArgs args = StatsDetailArgs(
          type: _currentType,
          fromDate: _currentFromDate,
          toDate: _currentToDate,
          currency: _currentCurrencies!,
          wallet: _currentWallet!,
          incomeExpenseCategory: _currentIncomeExpenseCategory,
          name: (_nameController.text.isEmpty ? '*' : _nameController.text.trim()),
          search: _searchType,
        );

        if (mounted) {
          // navigate to stats detail
          Navigator.pushNamed(context, '/stats/detail', arguments: args);
        }
      }).onError((error, stackTrace) async {
        // print the error
        Log.error(
          message: "Error while fetching stats information",
          error: error,
          stackTrace: stackTrace,
        );

        if (mounted) {
          // show the error dialog
          await ShowMyDialog(
            cancelEnabled: false,
            confirmText: "OK",
            dialogTitle: "Error Fetch",
            dialogText: "Error while fetching stats information from server.")
          .show(context);
        }
      });
    }
  }

  Future<void> _fetchStats() async {
    String name = _nameController.text.trim();

    // show the loading screen
    LoadingScreen.instance().show(context: context);

    await _transactionHttp.fetchIncomeExpenseCategory(
      name: name,
      search: _searchType,
      ccyId: _currentCurrencies!.id,
      walletId: _currentWallet!.id,
      from: _currentFromDate,
      to: _currentToDate
    ).then((incomeExpenseCategory) {
      // set current income expense category as this
      _currentIncomeExpenseCategory = incomeExpenseCategory;
    }).onError((error, stackTrace) {
      Log.error(
        message: "Error when <_fetchStats>",
        error: error,
        stackTrace: stackTrace,
      );
      throw Exception("Error when trying to fetch statistics");
    }).whenComplete(() {
      // remove the loading screen
      LoadingScreen.instance().hide();
    },);
  }
}
