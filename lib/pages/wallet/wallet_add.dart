import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:my_expense/_index.g.dart';

class WalletAddPage extends StatefulWidget {
  const WalletAddPage({super.key});

  @override
  State<WalletAddPage> createState() => _WalletAddPageState();
}

class _WalletAddPageState extends State<WalletAddPage> {
  // format variable
  double _currentAmountFontSize = 25;

  final WalletHTTPService _walletHttp = WalletHTTPService();
  late List<WalletTypeModel> _walletType = [];
  late List<CurrencyModel> _currencies = [];
  late UsersMeModel? _userMe;

  int _currentWalletTypeID = -1;
  String _currentWalletTypeName = "";
  int _currentWalletCurrencyID = -1;
  String _currentWalletCurrencyDescription = "";
  String _currentWalletCurrencySymbol = "";
  bool _currentUseForStats = true;
  bool _currentEnabled = true;
  double _currentStartBalance = 0;

  final ScrollController _scrollControllerWallet = ScrollController();
  final ScrollController _scrollControllerCurrencies = ScrollController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    _walletType = WalletSharedPreferences.getWalletTypes();
    _currencies = WalletSharedPreferences.getWalletCurrency();
    _userMe = UserSharedPreferences.getUserMe();
    super.initState();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _scrollControllerWallet.dispose();
    _scrollControllerCurrencies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text("Add Account")),
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
              // show loading screen
              LoadingScreen.instance().show(context: context);
              await _saveWallet().then((_) {
                if (context.mounted) {
                  // finished, so we can just go back to the previous page
                  Navigator.pop(context);
                }
              }).onError((error, stackTrace) async {
                // print the error
                Log.error(
                  message: "Error when save wallet data",
                  error: error,
                  stackTrace: stackTrace,
                );

                if (context.mounted) {
                  // show the error dialog
                  await ShowMyDialog(
                    cancelEnabled: false,
                    confirmText: "OK",
                    dialogTitle: "Error Save",
                    dialogText: "Unable to save wallet data.")
                  .show(context);
                }
              }).whenComplete(() {
                // remove loading screen
                LoadingScreen.instance().hide();
              },
              );
            },
            icon: const Icon(
              Ionicons.checkmark,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
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
                                  color: IconList.getColor(
                                    _walletType[index].type.toLowerCase()
                                  ),
                                  title: _walletType[index].type,
                                  isSelected: (
                                    _currentWalletTypeID ==
                                    _walletType[index].id
                                  ),
                                  onTap: (() {
                                    setState(() {
                                      _currentWalletTypeID = _walletType[index].id;
                                      _currentWalletTypeName = _walletType[index].type;
                                    });
                                    Navigator.pop(context);
                                  }),
                                  icon: IconList.getIcon(
                                    _walletType[index].type.toLowerCase()
                                  ),
                                );
                              },
                            ),
                          );
                        });
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
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.zero,
                          isCollapsed: true,
                        ),
                      ),
                      const SizedBox(height: 5,),
                      Text(
                        (_currentWalletTypeID < 0
                            ? "Account type"
                            : _currentWalletTypeName),
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
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
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
                            if (value.length > 6) {
                              // change the font size
                              // target is 15 when 12 is filled
                              _currentAmountFontSize =
                                  25 - ((10 / 6) * (value.length - 6));
                            } else {
                              _currentAmountFontSize = 25;
                            }

                            // convert the string to double
                            if (value.isNotEmpty) {
                              try {
                                _currentStartBalance = double.parse(value);
                              } catch (e) {
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
                      children: <Widget>[
                        const Icon(
                          CupertinoIcons.money_dollar_circle,
                          size: 20,
                          color: textColor,
                        ),
                        const SizedBox(width: 10,),
                        Text(
                          (_currentWalletCurrencyID < 0 ? "Currency" : "$_currentWalletCurrencyDescription ($_currentWalletCurrencySymbol)")
                        ),
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
                            controller: _scrollControllerCurrencies,
                            itemCount: _currencies.length,
                            itemBuilder: (BuildContext context, int index) {
                              return SimpleItem(
                                color: accentColors[6],
                                title: _currencies[index].description,
                                isSelected: _currentWalletCurrencyID == _currencies[index].id,
                                onTap: (() {
                                  setState(() {
                                    _currentWalletCurrencyID = _currencies[index].id;
                                    _currentWalletCurrencyDescription = _currencies[index].description;
                                    _currentWalletCurrencySymbol = _currencies[index].symbol.toUpperCase();
                                  });
                                  Navigator.pop(context);
                                }),
                                icon: FittedBox(
                                  fit: BoxFit.contain,
                                  child: Text(
                                    _currencies[index].symbol.toUpperCase()
                                  ),
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
                    border: Border(
                      bottom: BorderSide(
                        color: primaryLight,
                        width: 1.0
                      )
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      const Icon(
                        Ionicons.checkbox_outline,
                        size: 20,
                        color: textColor,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
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
                    border: Border(
                      bottom: BorderSide(
                        color: primaryLight,
                        width: 1.0
                      )
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      const Icon(
                        Ionicons.checkbox_outline,
                        size: 20,
                        color: textColor,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
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
    if (_currentWalletTypeID < 0) {
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
    } else {
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

  Future<void> _saveWallet() async {
    // perform validation, in case there are any error, then just throw an
    // exception, it will automatically create the snackbar, as we already
    // using future for the transaction.

    // first check if walletTypeID is less than 0?
    // if so, user haven't select any walletType for this
    if (_currentWalletTypeID < 0) {
      throw Exception("Please select account type");
    }

    // check if account name already filled?
    if (_nameController.text.trim().isEmpty) {
      throw Exception("Account name is empty");
    }

    // check if user already selected any currency?
    if (_currentWalletCurrencyID < 0) {
      throw Exception("Please select account currency");
    }

    // check if the startBalance is less than 0?
    if (_currentStartBalance < 0) {
      throw Exception("Start balance is invalid");
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
      -1,
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
    Future<WalletModel> walletAdd;
    Future<List<CurrencyModel>> walletCurrencyList;

    await Future.wait([
      walletAdd = _walletHttp.addWallet(txn: wallet),
      walletCurrencyList = _walletHttp.fetchWalletCurrencies(force: true),
    ]).then((_) {
      walletAdd.then((walletAdd) {
        // here we got the walletAdd, so we need to get the walletList from the
        // shared preferences, and add this at the end.
        List<WalletModel> walletList = WalletSharedPreferences.getWallets(true);
        walletList.add(walletAdd);
        walletList = _walletHttp.sortWallets(wallets: walletList);

        // set the shared preferences with this list
        WalletSharedPreferences.setWallets(walletList);

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
        message: "error <saveTransaction>",
        error: error,
        stackTrace: stackTrace,
      );
      throw Exception("Error when add wallet");
    });
  }
}
