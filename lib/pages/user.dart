import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/api/budget_api.dart';
import 'package:my_expense/api/category_api.dart';
import 'package:my_expense/api/transaction_api.dart';
import 'package:my_expense/api/wallet_api.dart';
import 'package:my_expense/model/budget_model.dart';
import 'package:my_expense/model/category_model.dart';
import 'package:my_expense/model/currency_model.dart';
import 'package:my_expense/model/pin_model.dart';
import 'package:my_expense/model/user_permission_model.dart';
import 'package:my_expense/model/users_me_model.dart';
import 'package:my_expense/model/wallet_model.dart';
import 'package:my_expense/model/wallet_type_model.dart';
import 'package:my_expense/pages/user/user_pin_remove.dart';
import 'package:my_expense/pages/user/user_pin_setup.dart';
import 'package:my_expense/provider/home_provider.dart';
import 'package:my_expense/themes/category_icon_list.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/themes/icon_list.dart';
import 'package:my_expense/utils/anim/page_transition.dart';
import 'package:my_expense/utils/globals.dart';
import 'package:my_expense/utils/misc/show_dialog.dart';
import 'package:my_expense/utils/misc/show_loader_dialog.dart';
import 'package:my_expense/utils/misc/snack_bar.dart';
import 'package:my_expense/utils/prefs/shared_box.dart';
import 'package:my_expense/utils/prefs/shared_budget.dart';
import 'package:my_expense/utils/prefs/shared_category.dart';
import 'package:my_expense/utils/prefs/shared_pin.dart';
import 'package:my_expense/utils/prefs/shared_user.dart';
import 'package:my_expense/utils/prefs/shared_wallet.dart';
import 'package:my_expense/widgets/input/switch.dart';
import 'package:my_expense/widgets/input/user_button.dart';
import 'package:provider/provider.dart';

class UserPage extends StatefulWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final CategoryHTTPService categoryHTTP = CategoryHTTPService();
  final BudgetHTTPService budgetHTTP = BudgetHTTPService();
  final WalletHTTPService walletHTTP = WalletHTTPService();
  final TransactionHTTPService transactionHTTP = TransactionHTTPService();

  late UsersMeModel userMe;
  late Map<int, CategoryModel> expenseCategory;
  late Map<int, CategoryModel> incomeCategory;
  late List<CurrencyModel> currencies;
  late List<WalletModel> wallets;

  late CategoryModel? currentExpenseCategory;
  late CategoryModel? currentIncomeCategory;
  late CurrencyModel? currentCurrency;
  late WalletModel? currentWallet;
  
  late CategoryModel? selectedExpenseCategory;
  late CategoryModel? selectedIncomeCategory;
  late CurrencyModel? selectedCurrency;
  late WalletModel? selectedWallet;
  late PinModel? pinUser;

  late Future<List<BudgetModel>> futureBudgetList;
  bool _isPinEnabled = false;

  @override
  void initState() {
    // get the current user information
    userMe = UserSharedPreferences.getUserMe();

    // get the expense and incomr category
    expenseCategory = CategorySharedPreferences.getCategory("expense");
    incomeCategory = CategorySharedPreferences.getCategory("income");
    
    // check what is the default category for expense
    if(userMe.defaultCategoryExpense != null) {
      currentExpenseCategory = expenseCategory[userMe.defaultCategoryExpense];
    }
    else {
      currentExpenseCategory = CategoryModel(-1, "", "expense");
    }
    selectedExpenseCategory = currentExpenseCategory;

    // check what is the default category for income
    if(userMe.defaultCategoryIncome != null) {
      currentIncomeCategory = incomeCategory[userMe.defaultCategoryIncome];
    }
    else {
      currentIncomeCategory = CategoryModel(-1, "", "income");
    }
    selectedIncomeCategory = currentIncomeCategory;

    // for user that don't have any wallet currencies it means that the
    // selectedCurrency will still be null, to avoid this we can just
    // initialize selectedCurrency with default data first instead before
    selectedCurrency = CurrencyModel(-1, "", "", "");
    currentCurrency = CurrencyModel(-1, "", "", "");

    // get user default currency
    currencies = WalletSharedPreferences.getWalletUserCurrency();
    if(currencies.length > 0) {
      for (int i = 0; i < currencies.length; i++) {
        if (userMe.defaultBudgetCurrency == currencies[i].id) {
          currentCurrency = currencies[i];
          selectedCurrency = currencies[i];
          break;
        }
      }
    }

    // initialize the user default wallet
    currentWallet = WalletModel(-1, "", 0.0, 0.0, true, true, WalletTypeModel(-1, ""), CurrencyModel(-1, "", "", ""), UserPermissionModel(-1, "", ""));
    selectedWallet = currentWallet;

    // get list of wallets from shared preferences
    wallets = WalletSharedPreferences.getWallets(false);
    if(userMe.defaultWallet != null && wallets.length > 0) {
      for (int i=0; i<wallets.length; i++) {
        if(userMe.defaultWallet == wallets[i].id) {
          currentWallet = wallets[i];
          selectedWallet = wallets[i];
          break;
        }
      }
    }

    // check the pin for user
    pinUser = PinSharedPreferences.getPin();
    if(pinUser != null) {
      if(pinUser!.hashKey != null && pinUser!.hashPin != null) {
        _isPinEnabled = true;
      }
    }
    
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text("User")),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              showLogoutDialog();
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
            padding: EdgeInsets.all(25),
            color: secondaryDark,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Hello,",
                  style: TextStyle(
                    color: textColor2,
                    fontSize: 15,
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                Text(
                  userMe.username,
                  style: TextStyle(
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
                padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
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
                          selectedExpenseCategory!.name.toString(),
                          //textAlign: TextAlign.right,
                          style: TextStyle(
                            color: textColor,
                          ),
                        ),
                      ),
                      callback: (() {
                        showModalBottomSheet(
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
                                          color: primaryLight,
                                          width: 1.0
                                        )
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Center(
                                            child: Text("Expense Category"),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Expanded(
                                    child: GridView.count(
                                      crossAxisCount: 4,
                                      children: generateExpenseCategory(),
                                    ),
                                  ),
                                ],
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
                          selectedIncomeCategory!.name.toString(),
                          //textAlign: TextAlign.right,
                          style: TextStyle(
                            color: textColor,
                          ),
                        ),
                      ),
                      callback: (() {
                        showModalBottomSheet(
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Center(
                                              child: Text("Income Category")),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            //refreshCategory();
                                          },
                                          icon: Icon(
                                            Ionicons.refresh,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Expanded(
                                    child: GridView.count(
                                      crossAxisCount: 4,
                                      children: generateIncomeCategory(),
                                    ),
                                  ),
                                ],
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
                          selectedCurrency!.symbol.toString(),
                          //textAlign: TextAlign.right,
                          style: TextStyle(
                            color: textColor,
                          ),
                        ),
                      ),
                      callback: (() {
                        showModalBottomSheet(
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
                                    child: Center(child: Text("Currencies")),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: currencies.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        return Container(
                                          height: 60,
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: primaryLight,
                                                width: 1.0
                                              )
                                            ),
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
                                                child: Text(currencies[index].symbol.toUpperCase()),
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                            title: Text(currencies[index].description),
                                            trailing: Visibility(
                                              visible: (selectedCurrency!.id == currencies[index].id),
                                              child: Icon(
                                                Ionicons.checkmark_circle,
                                                size: 20,
                                                color: accentColors[0],
                                              ),
                                            ),
                                            onTap: () {
                                              // print("Selected currencies");
                                              setState(() {
                                                selectedCurrency = currencies[index];
                                              });
                                              // check if currency the same or not?
                                              // if not the same then we can perform
                                              // update on the default budget currency.
                                              if (selectedCurrency!.id != currentCurrency!.id) {
                                                // need to update the currency
                                                updateBudgetCurrency(currencies[index].id);
                                              }
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
                          selectedWallet!.name.toString(),
                          //textAlign: TextAlign.right,
                          style: TextStyle(
                            color: textColor,
                          ),
                        ),
                      ),
                      callback: (() {
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
                                    ],
                                  ),
                                ),
                                SizedBox(height: 10,),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: wallets.length,
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
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(40),
                                              color: IconList.getColor(wallets[index].walletType.type.toLowerCase()),
                                            ),
                                            child: IconList.getIcon(wallets[index].walletType.type.toLowerCase()),
                                          ),
                                          title: Text(wallets[index].name),
                                          trailing: Visibility(
                                            visible: (currentWallet!.id == wallets[index].id),
                                            child: Icon(
                                              Ionicons.checkmark_circle,
                                              size: 20,
                                              color: accentColors[0],
                                            ),
                                          ),
                                          onTap: () {
                                            // print("Selected wallet");
                                            setState(() {
                                              selectedWallet = wallets[index];
                                            });
                                            // check if currency the same or not?
                                            // if not the same then we can perform
                                            // update on the default budget currency.
                                            if (selectedWallet!.id != currentWallet!.id) {
                                              // need to update the currency
                                              updateDefaultWallet(wallets[index].id);
                                            }
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
                      }),
                    ),
                    UserButton(
                      icon: Ionicons.pricetag_outline,
                      iconColor: accentColors[4],
                      label: "",
                      value: Align(
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
                        showLoaderDialog(context);
                        refreshTransactionTag().then((_) {
                          // remove the loader dialog
                          Navigator.pop(context);
                        });
                      }),
                    ),
                    UserButton(
                      icon: Ionicons.lock_closed_outline,
                      iconColor: accentColors[1],
                      label: "",
                      value: Align(
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
                          showRemovePinDialog();
                        }
                        else {
                          // setup the pin
                          showSetupPin();
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
                          //textAlign: TextAlign.right,
                          style: TextStyle(
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
                      value: Align(
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
                        showLogoutDialog();
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

  Future<void> showLogoutDialog() async {
    late Future<bool?> result = ShowMyDialog(
            dialogTitle: "Logout",
            dialogText: "Do you want to logout?",
            confirmText: "Logout",
            cancelText: "Cancel")
        .show(context);

    // check the result of the dialog box
    result.then((value) async {
      if (value == true) {
        print("logout user");
        await logout();
      }
    });
  }

  Future<void> logout() async {
    Future.wait([
      MyBox.clear(),
    ]).then((_) {
      // clear provider
      Provider.of<HomeProvider>(context, listen: false).clearProvider();
      // navigate to the login screen
      Navigator.pushNamedAndRemoveUntil(
          context, '/login', (Route<dynamic> route) => false);
    });
  }

  Widget iconCategory(CategoryModel category) {
    // check if this is expense or income
    Color _iconColor;
    Icon _icon;

    if (category.type.toLowerCase() == "expense") {
      _iconColor = IconColorList.getExpenseColor(category.name.toLowerCase());
      _icon = IconColorList.getExpenseIcon(category.name.toLowerCase());
    } else {
      _iconColor = IconColorList.getIncomeColor(category.name.toLowerCase());
      _icon = IconColorList.getIncomeIcon(category.name.toLowerCase());
    }

    return GestureDetector(
      onTap: () {
        // print("Select category");
        setState(() {
          if (category.type.toLowerCase() == "expense") {
            selectedExpenseCategory = category;
          } else {
            selectedIncomeCategory = category;
          }
        });
        Navigator.pop(context);
        // check if this is the same or not?
        // if not same then save this to server by sending the update request
        if (category.type.toLowerCase() == "expense") {
          if (!compareCategory(
              currentExpenseCategory!, selectedExpenseCategory!)) {
            // update expense category
            updateDefaultCategory(category.type.toLowerCase(), category.id);
          }
        } else {
          if (!compareCategory(
              currentIncomeCategory!, selectedIncomeCategory!)) {
            // update income category
            updateDefaultCategory(category.type.toLowerCase(), category.id);
          }
        }
      },
      child: Container(
        padding: EdgeInsets.all(5),
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
                  color: _iconColor,
                ),
                child: _icon,
              ),
            ),
            Center(
              child: Text(
                category.name,
                style: TextStyle(
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

  List<Widget> generateExpenseCategory() {
    List<Widget> _ret = [];

    // loop thru all the _currentCategoryList, and generate the category icon
    expenseCategory.forEach((key, value) {
      _ret.add(iconCategory(value));
    });

    return _ret;
  }

  List<Widget> generateIncomeCategory() {
    List<Widget> _ret = [];

    // loop thru all the _currentCategoryList, and generate the category icon
    incomeCategory.forEach((key, value) {
      _ret.add(iconCategory(value));
    });

    return _ret;
  }

  bool compareCategory(CategoryModel cat1, CategoryModel cat2) {
    if (cat1.name == cat2.name &&
        cat1.id == cat2.id &&
        cat1.type == cat2.type) {
      return true;
    }
    return false;
  }

  void refreshUserMe() {
    setState(() {
      userMe = UserSharedPreferences.getUserMe();
    });
  }

  void setIsPinEnabled(bool enabled) {
    setState(() {
      _isPinEnabled = enabled;
    });
  }

  Future<void> updateDefaultCategory(String type, int categoryID) async {
    // show the loader dialog
    showLoaderDialog(context);

    await categoryHTTP.updateDefaultCategory(type, categoryID).then((_) {
      // refresh the user me, as we already stored the updated user me
      // in the shared preferences
      refreshUserMe();

      if (type == "expense") {
        currentExpenseCategory = selectedExpenseCategory;
      } else {
        currentIncomeCategory = selectedIncomeCategory;
      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        createSnackBar(
          message: "Default category updated",
          icon: Icon(
            Ionicons.checkmark_circle_outline,
            color: accentColors[6],
          )
        )
      );
    }).onError((error, stackTrace) {
      print("Got error when update default category!");
      print(error.toString());

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        createSnackBar(
          message: "Unable to update default category",
        )
      );
    });
  }

  Future<void> updateBudgetCurrency(int currencyID) async {
    // show the loader dialog
    showLoaderDialog(context);

    // get the current date of the budget that we need to load
    String _currentBudgetDate = BudgetSharedPreferences.getBudgetCurrent();

    Future.wait([
      budgetHTTP.updateBudgetCurrency(currencyID),
      futureBudgetList = budgetHTTP.fetchBudgetDate(currencyID, _currentBudgetDate),
    ]).then((_) {
      refreshUserMe();
      currentCurrency = selectedCurrency!;

      // update the budget provider and budget shared preferences
      // now we can set the shared preferences of budget
      futureBudgetList.then((value) {
        BudgetSharedPreferences.setBudget(currencyID, _currentBudgetDate, value);
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        createSnackBar(
          message: "Default budget currency updated",
          icon: Icon(
            Ionicons.checkmark_circle_outline,
            color: accentColors[6],
          )
        )
      );
    }).onError((error, stackTrace) {
      print("Got error when update default budget currency!");
      print(error.toString());

      selectedCurrency = currentCurrency;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        createSnackBar(
          message: "Unable to update default budget currency",
        )
      );
    });
  }

  Future<void> updateDefaultWallet(int walletId) async {
    // show the loader dialog
    showLoaderDialog(context);

    Future.wait([
      walletHTTP.updateDefaultWallet(walletId),
    ]).then((_) {
      refreshUserMe();
      currentWallet = selectedWallet!;
      Navigator.pop(context);
      
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
    }).onError((error, stackTrace) {
      print("Got error when update default wallet!");
      print(error.toString());

      selectedWallet = currentWallet;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        createSnackBar(
          message: "Error when updating default wallet",
        )
      );
    });
  }

  Future<void> refreshTransactionTag() async {
    Future.wait([
      transactionHTTP.fetchLastTransaction("income", true),
      transactionHTTP.fetchLastTransaction("expense", true)
    ]).then((_) {
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
    });
  }

  void showRemovePinDialog() {
    late Future<bool?> result = ShowMyDialog(
            dialogTitle: "Remove Pin",
            dialogText: "Do you want to remove PIN?",
            confirmText: "Remove",
            cancelText: "Cancel")
        .show(context);

    // check the result of the dialog box
    result.then((value) async {
      if (value == true) {
        // navigate to the remove pin screen.
        final result = await Navigator.push(context, createAnimationRoute(new PinRemovePage()));
        if(result) {
          // set the pin as disabled
          setIsPinEnabled(false);
          // refresh the pin model value
          pinUser = PinSharedPreferences.getPin();

          ScaffoldMessenger.of(context).showSnackBar(
          createSnackBar(
            message: "PIN is removed",
            icon: Icon(
              Ionicons.checkmark_circle_outline,
              color: accentColors[6],
            )
          )
        );
        }
      }
    });
  }

  void showSetupPin() async {
    // navigate to the remove pin screen.
    final result = await Navigator.push(context, createAnimationRoute(new PinSetupPage()));
    // debugPrint("Result are " + result.toString());
    if(result) {
      // set the pin as disabled
      setIsPinEnabled(true);
      // refresh the pin model value
      pinUser = PinSharedPreferences.getPin();

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