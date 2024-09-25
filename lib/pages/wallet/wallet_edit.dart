import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:my_expense/_index.g.dart';

class WalletEditPage extends StatefulWidget {
  final Object? walletData;
  const WalletEditPage({super.key, required this.walletData});

  @override
  State<WalletEditPage> createState() => _WalletEditPageState();
}

class _WalletEditPageState extends State<WalletEditPage> {
  // format variable
  double _currentAmountFontSize = 25;

  final WalletHTTPService _walletHttp = WalletHTTPService();
  List<WalletTypeModel> _walletType = [];
  List<CurrencyModel> _currencies = [];
  late UsersMeModel? _userMe;
  late WalletTypeModel _currentWalletType;
  late CurrencyModel _currentCurrency;
  late int _currentWalletID;
  late bool _currentUseForStats;
  late bool _currentEnabled;
  late double _currentLimit;
  late double _currentStartBalance;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _limitController = TextEditingController();
  final ScrollController _scrollControllerWallet = ScrollController();
  final ScrollController _scrollControllerCurrency = ScrollController();

  @override
  void initState() {
    super.initState();

    // get the wallet data from param
    final WalletModel walletData = widget.walletData as WalletModel;

    _walletType = WalletSharedPreferences.getWalletTypes();
    _currencies = WalletSharedPreferences.getWalletCurrency();
    _userMe = UserSharedPreferences.getUserMe();

    // initialize the data for the wallet
    _currentWalletID = walletData.id;
    _currentWalletType = walletData.walletType;
    _currentCurrency = walletData.currency;
    _currentUseForStats = walletData.useForStats;
    _currentEnabled = walletData.enabled;
    _currentLimit = walletData.limit;
    _currentStartBalance = walletData.startBalance;

    // set all the input data based on the initialize data above
    _nameController.text = walletData.name;
    if(_currentStartBalance > 0) {
      _amountController.text = "$_currentStartBalance";
      _currentAmountFontSize = 25 - ((10/6) * (_amountController.text.length - 6));
    }

    // check if _currentLimit is > 0, if more then we put the limit on the
    // text fields, if not defaulted to empty.
    if (_currentLimit > 0) {
      _limitController.text = "$_currentLimit";
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _limitController.dispose();
    _scrollControllerWallet.dispose();
    _scrollControllerCurrency.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text("Edit Account")),
        leading: IconButton(
          onPressed: () {
            Navigator.maybePop(context, false);
          },
          icon: const Icon(
            Ionicons.close,
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () async {
              await _updateWallet().then((_) {
                if (context.mounted) {
                  // finished, so we can just go back to the previous page
                  Navigator.pop(context);
                }
              }).onError((error, stackTrace) async {
                // print the error
                Log.error(
                  message: "Error when update wallet data",
                  error: error,
                  stackTrace: stackTrace,
                );
                
                if (context.mounted) {
                  // show the error dialog
                  await ShowMyDialog(
                    cancelEnabled: false,
                    confirmText: "OK",
                    dialogTitle: "Error Update",
                    dialogText: "Unable to update wallet data."
                  ).show(context);
                }
              });
            },
            icon: const Icon(
              Ionicons.checkmark,
            ),
          ),
          const SizedBox(width: 10,),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          // header
          Container(
            height: 100,
            color: secondaryDark,
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                GestureDetector(
                  child: _getCurrentWalletTypeIcon(),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return MyBottomSheet(
                          context: context,
                          title: "Account Type",
                          screenRatio: 0.55,
                          child: ListView.builder(
                            controller: _scrollControllerWallet,
                            itemCount: _walletType.length,
                            itemBuilder: (BuildContext context, int index) {
                              return SimpleItem(
                                color: IconList.getColor(_walletType[index].type.toLowerCase()),
                                title: _walletType[index].type,
                                isSelected: (_currentWalletType.id == _walletType[index].id),
                                onTap: (() {
                                  setState(() {
                                    _currentWalletType = _walletType[index];
                                  });
                                  Navigator.pop(context);
                                }),
                                icon: IconList.getIcon(_walletType[index].type.toLowerCase()),
                              );
                            },
                          ),
                        );
                      }
                    );
                  },
                ),
                const SizedBox(width: 10,),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: "Account name",
                          hintStyle: TextStyle(
                            color: primaryLight,
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.zero,
                          isCollapsed: true,
                        ),
                      ),
                      const SizedBox(height: 5,),
                      Text(
                        (_currentWalletType.id < 0 ? "Account type" : _currentWalletType.type),
                        style: const TextStyle(
                          color: textColor2,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        "Start Balance",
                        style: TextStyle(
                          color: secondaryLight,
                        ),
                      ),
                      TextFormField(
                        controller: _amountController,
                        textAlign: TextAlign.right,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: "0.00",
                          hintStyle: TextStyle(
                            color: primaryLight,
                          ),
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
                            if(value.isNotEmpty) {
                              try {
                                _currentStartBalance = double.parse(value);
                              }
                              catch(e) {
                                // if failed to parse then default this to -1
                                // to make it invalid when save
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
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 50,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: primaryLight,
                        width: 1.0
                      )
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Ionicons.alert_circle_outline,
                        size: 20,
                        color: textColor,
                      ),
                      const SizedBox(width: 10,),
                      Expanded(
                        child: TextFormField(
                          controller: _limitController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: "No Limit",
                            hintStyle: TextStyle(
                              color: textColor.withValues(alpha: 0.5),
                            ),
                            border: const OutlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.zero,
                            isCollapsed: true,
                          ),
                          cursorColor: primaryDark,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(12),
                            DecimalTextInputFormatter(decimalRange: 2),
                          ],
                          onChanged: (value) {
                            // convert the string to double
                            if(value.isNotEmpty) {
                              try {
                                _currentLimit = double.parse(value);
                              }
                              catch(e) {
                                // if failed to parse then default this to -1
                                // to make it default to unlimited
                                _currentLimit = -1;
                              }
                            }
                            else {
                              // if value is empty, default the value into -1
                              _currentLimit = -1;
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10,),
                      GestureDetector(
                        onTap: (() {
                          // remove limit
                          _limitController.text = '';
                          _currentLimit = -1;
                        }),
                        child: Container(
                          width: 40,
                          height: 30,
                          color: Colors.transparent,
                          child: Icon(
                            Ionicons.close_circle,
                            size: 20,
                            color: accentColors[2].lighten(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  child: Container(
                    height: 50,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: primaryLight,
                          width: 1.0
                        )
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.money_dollar_circle,
                          size: 20,
                          color: textColor,
                        ),
                        const SizedBox(width: 10,),
                        Text((_currentCurrency.id < 0 ? "Currency" : "${_currentCurrency.description} (${_currentCurrency.symbol})")),
                      ],
                    ),
                  ),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return MyBottomSheet(
                          context: context,
                          title: "Currencies",
                          screenRatio: 0.55,
                          child: ListView.builder(
                            controller: _scrollControllerCurrency,
                            itemCount: _currencies.length,
                            itemBuilder: (BuildContext context, int index) {
                              return SimpleItem(
                                color: accentColors[6],
                                title: _currencies[index].description,
                                isSelected: (_currentCurrency.id == _currencies[index].id),
                                onTap: (() {
                                  setState(() {
                                    _currentCurrency = _currencies[index];
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
                  },
                ),
                Container(
                  height: 50,
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Ionicons.checkbox_outline,
                        size: 20,
                        color: textColor,
                      ),
                      const SizedBox(width: 10,),
                      const Expanded(child: Text("Use For Stats")),
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
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Ionicons.checkbox_outline,
                        size: 20,
                        color: textColor,
                      ),
                      const SizedBox(width: 10,),
                      const Expanded(child: Text("Enabled")),
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
    );
  }

  Widget _getCurrentWalletTypeIcon() {
    // check what is the current wallet type being selected
    if(_currentWalletType.id < 0) {
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
          color: IconList.getColor(_currentWalletType.type),
        ),
        child: IconList.getIcon(_currentWalletType.type),
      );
    }
  }

  Future<void> _updateWallet() async {
    // perform validation, in case there are any error, then just throw an
    // exception, it will automatically create the snackbar, as we already
    // using future for the transaction.
    if(_currentWalletID < 0) {
      throw Exception("Wrong wallet ID");
    }

    // first check if walletTypeID is less than 0?
    // if so, user haven't select any walletType for this
    if(_currentWalletType.id < 0) {
      throw Exception("Please select account type");
    }

    // check if account name already filled?
    if(_nameController.text.trim().isEmpty) {
      throw Exception("Account name is empty");
    }

    // check if user already selected any currency?
    if(_currentCurrency.id < 0) {
      throw Exception("Please select account currency");
    }

    // check if the startBalance is less than 0?
    if(_currentStartBalance < 0) {
      throw Exception("Start balance is invalid");
    }

    // check if the limit is 0 or -1
    // if 0 or less than -1, then just default it to -1
    if(_currentLimit == 0 || _currentLimit < -1) {
      _currentLimit = -1;
    }

    // all is good, we can generate a wallet data here before passed it to the
    // wallet API for add the transaction
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
      _currentLimit,
      _currentWalletType,
      _currentCurrency,
      userPermission
    );

    // call the wallet API for add
    Future <WalletModel> walletEdit;
    Future <List<CurrencyModel>> walletCurrencyList;

    // show the loading screen
    LoadingScreen.instance().show(context: context);

    await Future.wait([
      walletEdit = _walletHttp.updateWallet(wallet: wallet),
      walletCurrencyList = _walletHttp.fetchWalletCurrencies(force: true),
    ]).then((_) {
      walletEdit.then((walletEdit) {
        // here we got the walletEdit, so we need to get the walletList from the
        // shared preferences, and add this at the end.
        List<WalletModel> walletList = WalletSharedPreferences.getWallets(showDisabled: true);
        for(int i=0; i<walletList.length; i++) {
          if(walletList[i].id == walletEdit.id) {
            // changet his wallet to the newly updated wallet
            walletList[i] = walletEdit;
            // since edit will be only one, we can break from the for loop after
            // we update this 1 wallet
            break;
          }
        }

        walletList = _walletHttp.sortWallets(wallets: walletList);

        // set the shared preferences with this list
        WalletSharedPreferences.setWallets(wallet: walletList);

        if (mounted) {
          // set the provider with this
          Provider.of<HomeProvider>(
            context,
            listen: false
          ).setWalletList(wallets: walletList);
        }
      });

      walletCurrencyList.then((walletsCurrency) {
        if (mounted) {
          Provider.of<HomeProvider>(
            context,
            listen: false
          ).setWalletCurrency(currencies: walletsCurrency);
        }
      });
    }).onError((error, stackTrace) {
      Log.error(
        message: "error <updateTransaction>",
        error: error,
        stackTrace: stackTrace,
      );
      throw Exception("Error when edit wallet");
    }).whenComplete(() {
      // remove the loading screen
      LoadingScreen.instance().hide();
    },);
  }
}
