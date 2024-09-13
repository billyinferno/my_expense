import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:my_expense/_index.g.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final CategoryHTTPService _categoryHTTP = CategoryHTTPService();
  final BudgetHTTPService _budgetHTTP = BudgetHTTPService();
  final WalletHTTPService _walletHTTP = WalletHTTPService();
  final TransactionHTTPService _transactionHTTP = TransactionHTTPService();
  final ScrollController _scrollControllerCurrency = ScrollController();
  final ScrollController _scrollControllerWallet = ScrollController();

  late UsersMeModel _userMe;
  late Map<int, CategoryModel> _expenseCategory;
  late Map<int, CategoryModel> _incomeCategory;
  late List<CurrencyModel> _currencies;
  late List<WalletModel> _wallets;

  late CategoryModel? _currentExpenseCategory;
  late CategoryModel? _currentIncomeCategory;
  late CurrencyModel? _currentCurrency;
  late WalletModel? _currentWallet;
  late String _runType;
  late Color _runTypeColor;
  
  late CategoryModel? _selectedExpenseCategory;
  late CategoryModel? _selectedIncomeCategory;
  late CurrencyModel? _selectedCurrency;
  late WalletModel? _selectedWallet;
  late PinModel? _pinUser;

  late Future<List<BudgetModel>> _futureBudgetList;
  bool _isPinEnabled = false;

  @override
  void initState() {
    // get the current user information
    _userMe = UserSharedPreferences.getUserMe();

    // get the expense and incomr category
    _expenseCategory = CategorySharedPreferences.getCategory(type: "expense");
    _incomeCategory = CategorySharedPreferences.getCategory(type: "income");
    
    // check what is the default category for expense
    if(_userMe.defaultCategoryExpense != null) {
      _currentExpenseCategory = _expenseCategory[_userMe.defaultCategoryExpense];
    }
    else {
      _currentExpenseCategory = CategoryModel(-1, "", "expense");
    }
    _selectedExpenseCategory = _currentExpenseCategory;

    // check what is the default category for income
    if(_userMe.defaultCategoryIncome != null) {
      _currentIncomeCategory = _incomeCategory[_userMe.defaultCategoryIncome];
    }
    else {
      _currentIncomeCategory = CategoryModel(-1, "", "income");
    }
    _selectedIncomeCategory = _currentIncomeCategory;

    // for user that don't have any wallet currencies it means that the
    // selectedCurrency will still be null, to avoid this we can just
    // initialize selectedCurrency with default data first instead before
    _selectedCurrency = CurrencyModel(-1, "", "", "");
    _currentCurrency = CurrencyModel(-1, "", "", "");

    // get user default currency
    _currencies = WalletSharedPreferences.getWalletUserCurrency();
    if(_currencies.isNotEmpty) {
      for (int i = 0; i < _currencies.length; i++) {
        if (_userMe.defaultBudgetCurrency == _currencies[i].id) {
          _currentCurrency = _currencies[i];
          _selectedCurrency = _currencies[i];
          break;
        }
      }
    }

    // initialize the user default wallet
    _currentWallet = WalletModel(
      -1,
      "",
      0.0,
      0.0,
      0.0,
      true,
      true,
      -1,
      WalletTypeModel(-1, ""),
      CurrencyModel(-1, "", "", ""),
      UserPermissionModel(-1, "", "")
    );
    _selectedWallet = _currentWallet;

    // get list of wallets from shared preferences
    _wallets = WalletSharedPreferences.getWallets(showDisabled: false);
    if(_userMe.defaultWallet != null && _wallets.isNotEmpty) {
      for (int i=0; i<_wallets.length; i++) {
        if(_userMe.defaultWallet == _wallets[i].id) {
          _currentWallet = _wallets[i];
          _selectedWallet = _wallets[i];
          break;
        }
      }
    }

    // check the pin for user
    _pinUser = PinSharedPreferences.getPin();
    if(_pinUser != null) {
      if(_pinUser!.hashKey != null && _pinUser!.hashPin != null) {
        _isPinEnabled = true;
      }
    }

    // get the type of application that we running
    var (type, color) = Globals.runAs();
    _runType = type;
    _runTypeColor = color;
    
    super.initState();
  }

  @override
  void dispose() {
    _scrollControllerCurrency.dispose();
    _scrollControllerWallet.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text("User")),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              _showLogoutDialog();
            },
            icon: Icon(
              Ionicons.log_out_outline,
              color: accentColors[2],
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(25),
            color: secondaryDark,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  "Hello,",
                  style: TextStyle(
                    color: textColor2,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  _userMe.username,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    UserButton(
                      icon: Ionicons.fast_food_outline,
                      iconColor: accentColors[2],
                      label: "Default Expense",
                      value: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _selectedExpenseCategory!.name.toString(),
                          //textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: textColor,
                          ),
                        ),
                      ),
                      callback: (() {
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return MyBottomSheet(
                              context: context,
                              title: "Expense Category",
                              screenRatio: 0.75,
                              child: GridView.count(
                                crossAxisCount: 4,
                                children: _generateExpenseCategory(),
                              ),
                            );
                          }
                        );
                      }),
                    ),
                    UserButton(
                      icon: Ionicons.cash_outline,
                      iconColor: accentColors[0],
                      label: "Default Income",
                      value: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _selectedIncomeCategory!.name.toString(),
                          style: const TextStyle(
                            color: textColor,
                          ),
                        ),
                      ),
                      callback: (() {
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return MyBottomSheet(
                              context: context,
                              title: "Income Category",
                              screenRatio: 0.75,
                              child: GridView.count(
                                crossAxisCount: 4,
                                children: _generateIncomeCategory(),
                              ),
                            );
                          });
                      }),
                    ),
                    UserButton(
                      icon: Ionicons.list,
                      iconColor: accentColors[9],
                      label: "Default Budget Currency",
                      value: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _selectedCurrency!.symbol.toString(),
                          //textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: textColor,
                          ),
                        ),
                      ),
                      callback: (() {
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return MyBottomSheet(
                              context: context,
                              title: "Currencies",
                              screenRatio: 0.35,
                              child: ListView.builder(
                                controller: _scrollControllerCurrency,
                                itemCount: _currencies.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return SimpleItem(
                                    color: accentColors[6],
                                    title: _currencies[index].description,
                                    isSelected: _selectedCurrency!.id == _currencies[index].id,
                                    onTap: (() {
                                      // get the selected currencies
                                      _selectedCurrency = _currencies[index];
                                      
                                      // check if currency the same or not?
                                      // if not the same then we can perform
                                      // update on the default budget currency.
                                      if (_selectedCurrency!.id != _currentCurrency!.id) {
                                        // need to update the currency
                                        setState(() {
                                          _updateBudgetCurrency(_currencies[index].id);
                                        });
                                      }
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
                      }),
                    ),
                    UserButton(
                      icon: Ionicons.wallet,
                      iconColor: accentColors[5],
                      label: "Default Wallet",
                      value: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _selectedWallet!.name.toString(),
                          style: const TextStyle(
                            color: textColor,
                          ),
                        ),
                      ),
                      callback: (() {
                        showModalBottomSheet<void>(
                          context: context,
                          builder: (BuildContext context) {
                            return MyBottomSheet(
                              context: context,
                              title: "Account",
                              screenRatio: 0.40,
                              child: ListView.builder(
                                controller: _scrollControllerWallet,
                                itemCount: _wallets.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return SimpleItem(
                                    color: IconList.getColor(_wallets[index].walletType.type.toLowerCase()),
                                    title: _wallets[index].name,
                                    isSelected: (_currentWallet!.id == _wallets[index].id),
                                    onTap: (() {
                                      // get current selected wallet
                                      _selectedWallet = _wallets[index];

                                      // check if currency the same or not?
                                      // if not the same then we can perform
                                      // update on the default budget currency.
                                      if (_selectedWallet!.id != _currentWallet!.id) {
                                        // need to update the currency
                                        setState(() {
                                          _updateDefaultWallet(_wallets[index].id);
                                        });
                                      }
                                    }),
                                    icon: IconList.getIcon(_wallets[index].walletType.type.toLowerCase()),
                                  );
                                },
                              ),
                            );
                          }
                        );
                      }),
                    ),
                    UserButton(
                      icon: Ionicons.pricetag_outline,
                      iconColor: accentColors[4],
                      label: "",
                      value: const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Refresh Transaction Tags",
                          //textAlign: TextAlign.right,
                          style: TextStyle(
                            color: textColor,
                          ),
                        ),
                      ),
                      callback: (() {
                        LoadingScreen.instance().show(context: context);
                        _refreshTransactionTag().whenComplete(() {
                          LoadingScreen.instance().hide();
                        });
                      }),
                    ),
                    UserButton(
                      icon: Ionicons.lock_closed_outline,
                      iconColor: accentColors[1],
                      label: "",
                      value: const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Change Password",
                          //textAlign: TextAlign.right,
                          style: TextStyle(
                            color: textColor,
                          ),
                        ),
                      ),
                      callback: (() {
                        Navigator.pushNamed(context, '/user/password');
                      }),
                    ),
                    UserButton(
                      icon: Ionicons.keypad_outline,
                      iconColor: accentColors[3],
                      label: "Setup PIN",
                      value: Align(
                        alignment: Alignment.centerRight,
                        child: MySwitch(enabled: _isPinEnabled,),
                      ),
                      callback: (() {
                        if(_isPinEnabled) {
                          // ask user if they really want to disable the pin?
                          // if yes, then show the PinPad screen and if correct then remove the pin
                          _showRemovePinDialog();
                        }
                        else {
                          // setup the pin
                          _showSetupPin();
                        }
                      }),
                    ),
                    UserButton(
                      icon: Ionicons.information,
                      iconColor: accentColors[7],
                      label: "Version",
                      value: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          Globals.appVersion,
                          style: const TextStyle(
                            color: textColor,
                          ),
                        ),
                      ),
                      callback: (() {
                        // do nothing
                      }),
                    ),
                    UserButton(
                      icon: Ionicons.rocket,
                      iconColor: accentColors[9],
                      label: "Run As",
                      value: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _runType,
                          style: TextStyle(
                            color: _runTypeColor,
                          ),
                        ),
                      ),
                      callback: (() {
                        // do nothing
                      }),
                    ),
                    UserButton(
                      icon: Ionicons.cog,
                      iconColor: accentColors[9],
                      label: "Flutter SDK",
                      value: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          Globals.flutterVersion,
                          style: const TextStyle(
                            color: textColor,
                          ),
                        ),
                      ),
                      callback: (() {
                        // do nothing
                      }),
                    ),
                    UserButton(
                      icon: Ionicons.log_out_outline,
                      iconColor: accentColors[2],
                      label: "",
                      value: const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Logout",
                          //textAlign: TextAlign.right,
                          style: TextStyle(
                            color: textColor,
                          ),
                        ),
                      ),
                      callback: (() {
                        _showLogoutDialog();
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30,),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    late Future<bool?> result = ShowMyDialog(
      dialogTitle: "Logout",
      dialogText: "Do you want to logout?",
      confirmText: "Logout",
      confirmColor: accentColors[2],
      cancelText: "Cancel")
    .show(context);

    // check the result of the dialog box
    result.then((value) async {
      if (value == true) {
        Log.info(message: "logout user");
        await _logout();
      }
    });
  }

  Future<void> _logout() async {
    await Future.wait([
      // clear the box
      MyBox.clear(),
    ]).then((_) {
      // clear the JWT token
      NetUtils.clearJWT();
      if (mounted) {
        // clear provider
        Provider.of<HomeProvider>(context, listen: false).clearProvider();
        // navigate to the login screen
        Navigator.pushNamedAndRemoveUntil(
            context, '/login', (Route<dynamic> route) => false);
      }
    });
  }

  Widget _iconCategory(CategoryModel category) {
    // check if this is expense or income
    Color iconColor;
    Icon icon;

    if (category.type.toLowerCase() == "expense") {
      iconColor = IconColorList.getExpenseColor(category.name.toLowerCase());
      icon = IconColorList.getExpenseIcon(category.name.toLowerCase());
    } else {
      iconColor = IconColorList.getIncomeColor(category.name.toLowerCase());
      icon = IconColorList.getIncomeIcon(category.name.toLowerCase());
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (category.type.toLowerCase() == "expense") {
            _selectedExpenseCategory = category;
          } else {
            _selectedIncomeCategory = category;
          }
        });
        Navigator.pop(context);
        // check if this is the same or not?
        // if not same then save this to server by sending the update request
        if (category.type.toLowerCase() == "expense") {
          if (!_compareCategory(
              _currentExpenseCategory!, _selectedExpenseCategory!)) {
            // update expense category
            _updateDefaultCategory(category.type.toLowerCase(), category.id);
          }
        } else {
          if (!_compareCategory(
              _currentIncomeCategory!, _selectedIncomeCategory!)) {
            // update income category
            _updateDefaultCategory(category.type.toLowerCase(), category.id);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Center(
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: iconColor,
                ),
                child: icon,
              ),
            ),
            Center(
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 10,
                  color: textColor,
                ),
                softWrap: true,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _generateExpenseCategory() {
    List<Widget> ret = [];

    // loop thru all the _currentCategoryList, and generate the category icon
    _expenseCategory.forEach((key, value) {
      ret.add(_iconCategory(value));
    });

    return ret;
  }

  List<Widget> _generateIncomeCategory() {
    List<Widget> ret = [];

    // loop thru all the _currentCategoryList, and generate the category icon
    _incomeCategory.forEach((key, value) {
      ret.add(_iconCategory(value));
    });

    return ret;
  }

  bool _compareCategory(CategoryModel cat1, CategoryModel cat2) {
    if (cat1.name == cat2.name &&
        cat1.id == cat2.id &&
        cat1.type == cat2.type) {
      return true;
    }
    return false;
  }

  void _refreshUserMe() {
    setState(() {
      _userMe = UserSharedPreferences.getUserMe();
    });
  }

  void _setIsPinEnabled(bool enabled) {
    setState(() {
      _isPinEnabled = enabled;
    });
  }

  Future<void> _updateDefaultCategory(String type, int categoryID) async {
    // show loading screen
    LoadingScreen.instance().show(context: context);

    await _categoryHTTP.updateDefaultCategory(
      type: type,
      categoryID: categoryID
    ).then((_) {
      String newCategoryName = '';

      // refresh the user me, as we already stored the updated user me
      // in the shared preferences
      _refreshUserMe();

      if (type == "expense") {
        _currentExpenseCategory = _selectedExpenseCategory;
        newCategoryName = _currentExpenseCategory!.name;
      } else {
        _currentIncomeCategory = _selectedIncomeCategory;
        newCategoryName = _currentIncomeCategory!.name;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          createSnackBar(
            message: "Default $type updated to $newCategoryName",
            icon: Icon(
              Ionicons.checkmark_circle_outline,
              color: accentColors[6],
            )
          )
        );
      }
    }).onError((error, stackTrace) {
      Log.error(
        message: "Got error when update default $type category!",
        error: error,
        stackTrace: stackTrace,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          createSnackBar(
            message: "Unable to update default $type",
          )
        );
      }
    }).whenComplete(() {
      // remove the loading screen
      LoadingScreen.instance().hide();
    },);
  }

  Future<void> _updateBudgetCurrency(int currencyID) async {
    // show the loading screen
    LoadingScreen.instance().show(context: context);

    // get the current date of the budget that we need to load
    String currentBudgetDate = BudgetSharedPreferences.getBudgetCurrent();

    await Future.wait([
      _budgetHTTP.updateBudgetCurrency(currencyID: currencyID),
      _futureBudgetList = _budgetHTTP.fetchBudgetDate(
        currencyID: currencyID,
        date: currentBudgetDate
      ),
    ]).then((_) {
      _refreshUserMe();
      _currentCurrency = _selectedCurrency!;

      // update the budget provider and budget shared preferences
      // now we can set the shared preferences of budget
      _futureBudgetList.then((value) {
        BudgetSharedPreferences.setBudget(
          ccyId: currencyID,
          date: currentBudgetDate,
          budgets: value
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          createSnackBar(
            message: "Default budget currency updated",
            icon: Icon(
              Ionicons.checkmark_circle_outline,
              color: accentColors[6],
            )
          )
        );
      }
    }).onError((error, stackTrace) {
      Log.error(
        message: "Got error when update default budget currency!",
        error: error,
        stackTrace: stackTrace,
      );

      _selectedCurrency = _currentCurrency;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          createSnackBar(
            message: "Unable to update default budget currency",
          )
        );
      }
    }).whenComplete(() {
      // remove the loading screen
      LoadingScreen.instance().hide();
    },);
  }

  Future<void> _updateDefaultWallet(int walletId) async {
    // show the loading screen
    LoadingScreen.instance().show(context: context);

    await _walletHTTP.updateDefaultWallet(walletId: walletId).then((_) {
      _refreshUserMe();
      _currentWallet = _selectedWallet!;

      if (mounted) {
        // show it success
        ScaffoldMessenger.of(context).showSnackBar(
          createSnackBar(
            message: "Default wallet updated",
            icon: Icon(
              Ionicons.checkmark_circle_outline,
              color: accentColors[6],
            )
          )
        );
      }
    }).onError((error, stackTrace) {
      Log.error(
        message: "Got error when update default wallet!",
        error: error,
        stackTrace: stackTrace,
      );

      _selectedWallet = _currentWallet;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          createSnackBar(
            message: "Error when updating default wallet",
          )
        );
      }
    }).whenComplete(() {
      // remove the loading screen
      LoadingScreen.instance().hide();
    },);

    // remove the bottom sheet
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _refreshTransactionTag() async {
    // show loading screen
    LoadingScreen.instance().show(context: context);

    await Future.wait([
      _transactionHTTP.fetchLastTransaction(type: "income", force: true),
      _transactionHTTP.fetchLastTransaction(type: "expense", force: true),
    ]).then((_) {
      if (mounted) {
        // finished fetch the last transaction income and expense
        // showed a message on the scaffold telling that the refresh is finished
        ScaffoldMessenger.of(context).showSnackBar(
          createSnackBar(
            message: "Fetching Transaction Tag Complete",
            icon: Icon(
              Ionicons.checkmark_circle_outline,
              color: accentColors[6],
            )
          )
        );
      }
    }).onError((error, stackTrace) {
      Log.error(
        message: "Got error when refresh transaction tag",
        error: error,
        stackTrace: stackTrace,
      );
    }).whenComplete(() {
      // remove the loading screen
      LoadingScreen.instance().hide();
    },);
  }

  void _showRemovePinDialog() {
    late Future<bool?> result = ShowMyDialog(
            dialogTitle: "Remove Pin",
            dialogText: "Do you want to remove PIN?",
            confirmText: "Remove",
            confirmColor: accentColors[0],
            cancelText: "Cancel")
        .show(context);

    // check the result of the dialog box
    result.then((value) async {
      if (value == true && mounted) {
        // navigate to the remove pin screen.
        final result = await Navigator.push(
          context,
          createAnimationRoute(
            page: const PinRemovePage()
          )
        );
        if(result) {
          // set the pin as disabled
          _setIsPinEnabled(false);
          // refresh the pin model value
          _pinUser = PinSharedPreferences.getPin();

          if (mounted) {
            await ShowMyDialog(
              dialogTitle: "PIN Removed",
              dialogText: "Successfully remove PIN",
              confirmText: "OK",
              confirmColor: accentColors[0],
              cancelEnabled: false,
            ).show(context);
          }
        }
      }
    });
  }

  void _showSetupPin() async {
    // navigate to the remove pin screen.
    final result = await Navigator.push(
      context,
      createAnimationRoute(
        page: const PinSetupPage()
      )
    );
    
    if(result) {
      // set the pin as disabled
      _setIsPinEnabled(true);
      // refresh the pin model value
      _pinUser = PinSharedPreferences.getPin();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          createSnackBar(
            message: "PIN is set",
            icon: Icon(
              Ionicons.checkmark_circle_outline,
              color: accentColors[6],
            )
          )
        );
      }
    }
  }
}