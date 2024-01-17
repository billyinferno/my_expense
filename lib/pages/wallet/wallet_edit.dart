import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/api/wallet_api.dart';
import 'package:my_expense/model/currency_model.dart';
import 'package:my_expense/model/user_permission_model.dart';
import 'package:my_expense/model/users_me_model.dart';
import 'package:my_expense/model/wallet_model.dart';
import 'package:my_expense/model/wallet_type_model.dart';
import 'package:my_expense/provider/home_provider.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/themes/icon_list.dart';
import 'package:my_expense/utils/misc/decimal_formatter.dart';
import 'package:my_expense/utils/misc/show_loader_dialog.dart';
import 'package:my_expense/utils/misc/snack_bar.dart';
import 'package:my_expense/utils/prefs/shared_user.dart';
import 'package:my_expense/utils/prefs/shared_wallet.dart';
import 'package:my_expense/widgets/item/simple_item.dart';
import 'package:provider/provider.dart';

class WalletEditPage extends StatefulWidget {
  final Object? walletData;
  const WalletEditPage({Key? key, required this.walletData}) : super(key: key);

  @override
  _WalletEditPageState createState() => _WalletEditPageState();
}

class _WalletEditPageState extends State<WalletEditPage> {
  // format variable
  final fCCY = new NumberFormat("#,##0.00", "en_US");
  double _currentAmountFontSize = 25;

  late WalletHTTPService _walletHttp = WalletHTTPService();
  late List<WalletTypeModel> _walletType = [];
  late List<CurrencyModel> _currencies = [];
  late UsersMeModel? _userMe;

  int _currentWalletID = -1;
  int _currentWalletTypeID = -1;
  String _currentWalletTypeName = "";
  int _currentWalletCurrencyID = -1;
  String _currentWalletCurrencyDescription = "";
  String _currentWalletCurrencySymbol = "";
  bool _currentUseForStats = true;
  bool _currentEnabled = true;
  double _currentStartBalance = 0;

  TextEditingController _amountController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  ScrollController _scrollControllerWallet = ScrollController();
  ScrollController _scrollControllerCurrency = ScrollController();

  @override
  void initState() {
    super.initState();
    initWalletEdit();
  }

  void initWalletEdit() async {
    // get the wallet data from param
    final WalletModel _walletData = widget.walletData as WalletModel;

    _walletType = WalletSharedPreferences.getWalletTypes();
    _currencies = WalletSharedPreferences.getWalletCurrency();
    _userMe = UserSharedPreferences.getUserMe();

    // initialize the data for the wallet
    _currentWalletID = _walletData.id;
    _currentWalletTypeID = _walletData.walletType.id;
    _currentWalletTypeName = _walletData.walletType.type;
    _currentWalletCurrencyID = _walletData.currency.id;
    _currentWalletCurrencyDescription = _walletData.currency.description;
    _currentWalletCurrencySymbol = _walletData.currency.symbol;
    _currentUseForStats = _walletData.useForStats;
    _currentEnabled = _walletData.enabled;
    _currentStartBalance = _walletData.startBalance;

    // set all the input data based on the initialize data above
    _nameController.text = _walletData.name;
    if(_currentStartBalance > 0) {
      _amountController.text = fCCY.format(_currentStartBalance);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _scrollControllerWallet.dispose();
    _scrollControllerCurrency.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text("Edit Account")),
        leading: IconButton(
          onPressed: () {
            Navigator.maybePop(context, false);
          },
          icon: Icon(
            Ionicons.close,
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () async {
              showLoaderDialog(context);
              await updateTransaction().then((_) {
                // remove the loader
                Navigator.pop(context);

                // finished, so we can just go back to the previous page
                Navigator.pop(context);
              }).onError((error, stackTrace) {
                // remove the loader
                Navigator.pop(context);

                // show the snackbar here?
                ScaffoldMessenger.of(context).showSnackBar(
                  createSnackBar(
                    message: error.toString(),
                  )
                );
              });
            },
            icon: Icon(
              Ionicons.checkmark,
            ),
          ),
          SizedBox(width: 10,),
        ],
      ),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            // header
            Container(
              height: 100,
              color: secondaryDark,
              padding: EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  GestureDetector(
                    child: getCurrentWalletTypeIcon(),
                    onTap: () {
                      showModalBottomSheet(context: context, builder: (BuildContext conext) {
                        return Container(
                          height: 300,
                          color: secondaryDark,
                          child: Column(
                            children: <Widget>[
                              Container(
                                height: 40,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                                ),
                                child: Center(child: Text("Account Type")),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  controller: _scrollControllerWallet,
                                  itemCount: _walletType.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    return SimpleItem(
                                      color: IconList.getColor(_walletType[index].type.toLowerCase()),
                                      child: IconList.getIcon(_walletType[index].type.toLowerCase()),
                                      description: _walletType[index].type,
                                      isSelected: (_currentWalletTypeID == _walletType[index].id),
                                      onTap: (() {
                                        setState(() {
                                          _currentWalletTypeID = _walletType[index].id;
                                          _currentWalletTypeName = _walletType[index].type;
                                        });
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
                      });
                    },
                  ),
                  SizedBox(width: 10,),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: "Account name",
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.zero,
                            isCollapsed: true,
                          ),
                        ),
                        SizedBox(height: 5,),
                        Text(
                          (_currentWalletTypeID < 0 ? "Account type" : _currentWalletTypeName),
                          style: TextStyle(
                            color: textColor2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 120,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          "Start Balance",
                          style: TextStyle(
                            color: secondaryLight,
                          ),
                        ),
                        TextFormField(
                          controller: _amountController,
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
                            fontSize: _currentAmountFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(12),
                            DecimalTextInputFormatter(decimalRange: 2),
                          ],
                          onChanged: (value) {
                            // check what is the length of the text now, and
                            // change the font size based on the length
                            setState(() {
                              if(value.length > 6) {
                                // change the font size
                                // target is 15 when 12 is filled
                                _currentAmountFontSize = 25 - ((10/6) * (value.length - 6));
                              }
                              else {
                                _currentAmountFontSize = 25;
                              }

                              // convert the string to double
                              if(value.length > 0) {
                                try {
                                  _currentStartBalance = double.parse(value);
                                }
                                catch(e) {
                                  _currentStartBalance = -1;
                                }
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // sub input
            Container(
              padding: EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  GestureDetector(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.money_dollar_circle,
                            size: 20,
                            color: textColor,
                          ),
                          SizedBox(width: 10,),
                          Text((_currentWalletCurrencyID < 0 ? "Currency" : _currentWalletCurrencyDescription + " (" + _currentWalletCurrencySymbol + ")")),
                        ],
                      ),
                    ),
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
                                child: Center(child: Text("Currencies")),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  controller: _scrollControllerCurrency,
                                  itemCount: _currencies.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    return SimpleItem(
                                      color: accentColors[6],
                                      child: FittedBox(
                                        child: Text(_currencies[index].symbol.toUpperCase()),
                                        fit: BoxFit.contain,
                                      ),
                                      description: _currencies[index].description,
                                      isSelected: (_currentWalletCurrencyID == _currencies[index].id),
                                      onTap: (() {
                                        setState(() {
                                          _currentWalletCurrencyID = _currencies[index].id;
                                          _currentWalletCurrencyDescription = _currencies[index].description;
                                          _currentWalletCurrencySymbol = _currencies[index].symbol.toUpperCase();
                                        });
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
                      });
                    },
                  ),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Ionicons.checkbox_outline,
                          size: 20,
                          color: textColor,
                        ),
                        SizedBox(width: 10,),
                        Expanded(child: Text("Use For Stats")),
                        CupertinoSwitch(
                          value: _currentUseForStats,
                          onChanged: (value) {
                            setState(() {
                              _currentUseForStats = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Ionicons.checkbox_outline,
                          size: 20,
                          color: textColor,
                        ),
                        SizedBox(width: 10,),
                        Expanded(child: Text("Enabled")),
                        CupertinoSwitch(
                          value: _currentEnabled,
                          onChanged: (value) {
                            setState(() {
                              _currentEnabled = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getCurrentWalletTypeIcon() {
    // check what is the current wallet type being selected
    if(_currentWalletTypeID < 0) {
      return Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: Colors.white,
        ),
        child: Icon(
          Ionicons.wallet_outline,
          color: accentColors[4],
        ),
      );
    }
    else {
      return Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: IconList.getColor(_currentWalletTypeName),
        ),
        child: IconList.getIcon(_currentWalletTypeName),
      );
    }
  }

  Future<void> updateTransaction() async {
    // perform validation, in case there are any error, then just throw an
    // exception, it will automatically create the snackbar, as we already
    // using future for the transaction.
    if(_currentWalletID < 0) {
      throw new Exception("Wrong wallet ID");
    }

    // first check if walletTypeID is less than 0?
    // if so, user haven't select any walletType for this
    if(_currentWalletTypeID < 0) {
      throw new Exception("Please select account type");
    }

    // check if account name already filled?
    if(_nameController.text.trim().length <= 0) {
      throw new Exception("Account name is empty");
    }

    // check if user already selected any currency?
    if(_currentWalletCurrencyID < 0) {
      throw new Exception("Please select account currency");
    }

    // check if the startBalance is less than 0?
    if(_currentStartBalance < 0) {
      throw new Exception("Start balance is invalid");
    }

    // all is good, we can generate a wallet data here before passed it to the
    // wallet API for add the transaction
    WalletTypeModel walletType = WalletTypeModel(
        _currentWalletTypeID,
        _currentWalletTypeName
    );

    CurrencyModel walletCurrency = CurrencyModel(
        _currentWalletCurrencyID,
        "",
        _currentWalletCurrencyDescription,
        _currentWalletCurrencySymbol
    );

    UserPermissionModel userPermission = UserPermissionModel(
        _userMe!.id,
        _userMe!.username,
        _userMe!.email
    );

    WalletModel wallet = WalletModel(
        _currentWalletID,
        _nameController.text,
        _currentStartBalance,
        0,
        0,
        _currentUseForStats,
        _currentEnabled,
        walletType,
        walletCurrency,
        userPermission
    );

    // call the wallet API for add
    Future <WalletModel> _walletEdit;
    Future <List<CurrencyModel>> _walletCurrencyList;

    Future.wait([
      _walletEdit = _walletHttp.updateWallet(wallet),
      _walletCurrencyList = _walletHttp.fetchWalletCurrencies(true),
    ]).then((_) {
      _walletEdit.then((walletEdit) {
        // here we got the walletEdit, so we need to get the walletList from the
        // shared preferences, and add this at the end.
        List<WalletModel> _walletList = WalletSharedPreferences.getWallets(true);
        for(int i=0; i<_walletList.length; i++) {
          if(_walletList[i].id == walletEdit.id) {
            // changet his wallet to the newly updated wallet
            _walletList[i] = walletEdit;
            // since edit will be only one, we can break from the for loop after
            // we update this 1 wallet
            break;
          }
        }

        _walletList = _walletHttp.sortWallets(_walletList);

        // set the shared preferences with this list
        WalletSharedPreferences.setWallets(_walletList);

        // set the provider with this
        Provider.of<HomeProvider>(context, listen: false).setWalletList(_walletList);
      });

      _walletCurrencyList.then((walletsCurrency) {
        Provider.of<HomeProvider>(context, listen: false).setWalletCurrency(walletsCurrency);
      });
    }).onError((error, stackTrace) {
      debugPrint("error <updateTransaction>");
      print(error.toString());
      throw Exception("Error when edit wallet");
    });
  }
}
