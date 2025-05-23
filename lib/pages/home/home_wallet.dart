import 'package:easy_sticky_header/easy_sticky_header.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:my_expense/_index.g.dart';

class HomeWallet extends StatefulWidget {
  const HomeWallet({super.key});

  @override
  State<HomeWallet> createState() => _HomeWalletState();
}

class _HomeWalletState extends State<HomeWallet> {
  final WalletHTTPService _walletHTTP = WalletHTTPService();
  final BudgetHTTPService _budgetHTTP = BudgetHTTPService();

  final ScrollController _scrollControllerWallet = ScrollController();
  final ScrollController _accountTypeController = ScrollController();
  late Future<bool> _getData;
  final Map<String, String> _accountMap = {};
  final Map<String, List<WalletModel>> _walletsFilter = {};
  final Map<String, Map<String, double>> _walletsFilterSummary = {};
  late Map<String, CurrencyModel> _currencies;
  late String _tabSelected;
  late bool _showDisabled;

  @override
  void initState() {
    super.initState();

    // default the tab selected to 'all'
    _tabSelected = 'all';

    // get the currencies map that will be needed for the wallet summary here
    _currencies = WalletSharedPreferences.getMapWalletCurrency();

    // default to show disabled waller
    _showDisabled = true;

    // get wallet
    _getData = _refreshWallet();
  }

  @override
  void dispose() {
    _scrollControllerWallet.dispose();
    _accountTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(
        title: const Center(child: Text("Account")),
        iconItem: Icon(
          Ionicons.create,
          size: 20,
        ),
        additionalIconItem: Icon(
          (_showDisabled ? Ionicons.eye : Ionicons.eye_off),
          size: 20,
        ),
        onUserPress: () {
          Navigator.pushNamed(context, '/user');
        },
        onActionPress: () {
          Navigator.pushNamed(context, '/wallet/add');
        },
        onAdditionalActionPress: () {
          setState(() {
            _showDisabled = !_showDisabled;
          });
        },
      ),
      body: FutureBuilder(
        future: _getData,
        builder: ((context, snapshot) {
          if (snapshot.hasError) {
            // got error when fetching the wallet data
            return CommonErrorPage(
              isNeedScaffold: false,
              errorText: "Error when loading wallet data",
            );
          } else if (snapshot.hasData) {
            // generate the main view
            return _generateWalletView();
          } else {
            // still loading
            return CommonLoadingPage(
              isNeedScaffold: false,
            );
          }
        }),
      ),
    );
  }

  Widget _generateWalletView() {
    // generate the wallet list view
    List<WalletModel> wallets = [];

    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        wallets = homeProvider.walletList;

        // generate the account map
        _generateAccountMap(wallets: wallets);

        // generate wallet filter that we will use to show the data
        _generateWalletFilter(wallets: wallets);
        
        return (Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              color: secondaryDark,
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  ScrollableTab(
                    controller: _accountTypeController,
                    data: _accountMap,
                    borderColor: secondaryBackground,
                    backgroundColor: secondaryDark,
                    showIcon: true,
                    onTap: ((tab) {
                      setState(() {
                        _tabSelected = tab;
                      });
                    }),
                  ),
                  WalletSummary(
                    type: _tabSelected,
                    data: (_walletsFilterSummary[_tabSelected] ?? {}),
                    currencies: _currencies
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10,),
            Expanded(
              child: RefreshIndicator(
                color: accentColors[6],
                onRefresh: () async {
                  _getData = _refreshWallet(showDialog: true);
                },
                child: StickyHeader(
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: _scrollControllerWallet,
                    itemCount: _walletsFilter[_tabSelected]!.length + 1,
                    itemBuilder: (BuildContext ctx, int index) {
                      if (index < _walletsFilter[_tabSelected]!.length) {
                        // check whether we want to show disabled wallet or not?
                        if (!_showDisabled) {
                          // check whether this wallet is enabled or disabled?
                          if (!_walletsFilter[_tabSelected]![index].enabled) {
                            return const SizedBox.shrink();
                          }
                        }
                  
                        // check index to see whether we need to generate the
                        // sticky header or not?
                        bool generateStickyHeader = false;
                        String stickyHeaderText = '';
                        
                        // only generate for all tab
                        if (_tabSelected == 'all') {
                          // if index is = 0
                          if (index == 0) {
                            generateStickyHeader = true;
                          }
                          else {
                            // check if previous wallet is enabled and this one
                            // is being disabled or not?
                            if (_walletsFilter[_tabSelected]![index].enabled == false) {
                              if (
                                _walletsFilter[_tabSelected]![index].enabled == false &&
                                _walletsFilter[_tabSelected]![index - 1].enabled == true
                              ) {
                                generateStickyHeader = true;
                                stickyHeaderText = 'Disabled';
                              }
                            }
                            else {
                              // check if current wallet type is same as before or
                              // if not the same ensure that if previously is enabled
                              // and this one is disabled
                              if (_walletsFilter[_tabSelected]![index].walletType.type != _walletsFilter[_tabSelected]![index - 1].walletType.type) {
                                generateStickyHeader = true;
                              }
                            }
                          }
                  
                          // check if we need to generate sticky header or not?
                          if (generateStickyHeader) {
                            // check if the sticky header text is empty or not?
                            if (stickyHeaderText.isEmpty) {
                              // put the wallet type in the sticky header text
                              stickyHeaderText = _walletsFilter[_tabSelected]![index].walletType.type;
                            }
                          }
                        }
                        
                        if (generateStickyHeader) {
                          return _generateStickyHeader(
                            index: index,
                            text: stickyHeaderText,
                            child: _generateSlidable(
                              wallet: _walletsFilter[_tabSelected]![index]
                            ),
                          );
                        }
                        else {
                          return _generateSlidable(
                            wallet: _walletsFilter[_tabSelected]![index]
                          );
                        }
                      } else {
                        return const SizedBox(
                          height: 30,
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ));
      },
    );
  }

  Future<void> _deleteWallet(int id) async {
    Future<List<CurrencyModel>> walletCurrencyList;
    Future<List<WalletModel>> walletList;

    // show loading screen
    LoadingScreen.instance().show(context: context);

    await Future.wait([
      walletList = _walletHTTP.deleteWallets(id: id),
      walletCurrencyList = _walletHTTP.fetchWalletCurrencies(force: true),
    ]).then((_) {
      // set the provider so it can tell the consumer to update/build the widget.
      walletList.then((wallets) {
        if (mounted) {
          Provider.of<HomeProvider>(
            context,
            listen: false
          ).setWalletList(wallets: wallets);
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
        message: "Error on <_deleteWallet>",
        error: error,
        stackTrace: stackTrace,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          createSnackBar(
            message: "Error when deleting wallet"
          ),
        );
      }
    }).whenComplete(
      () {
        // remove the loading screen
        LoadingScreen.instance().hide();
      },
    );
  }

  Future<bool> _refreshWallet({
    bool showDialog = false,
  }) async {
    Future<List<WalletModel>> futureWallets;

    // showed a debug print message to knew that we refresh the wallet
    Log.info(message: "💳 Refresh Wallet");

    if (showDialog) {
      LoadingScreen.instance().show(context: context);
    }

    // fetch the new wallet data from API
    await Future.wait([
      futureWallets = _walletHTTP.fetchWallets(
        showDisabled: true,
        force: true,
      ),
    ]).then((_) {
      futureWallets.then((wallets) {
        if (wallets.isNotEmpty && mounted) {
          Provider.of<HomeProvider>(
            context,
            listen: false
          ).setWalletList(wallets: wallets);
        }
      });
    }).onError((error, stackTrace) {
      Log.error(
        message: "Error when do <_refreshWallet>",
        error: error,
        stackTrace: stackTrace,
      );
      throw Exception("Error when get wallet data");
    }).whenComplete(() {
      if (showDialog) {
        LoadingScreen.instance().hide();
      }
    });

    return true;
  }

  Widget _generateStickyHeader({
    required int index,
    required String text,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        StickyContainerWidget(
          index: index,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                IconList.getDarkColor(text),
                IconList.getColor(text),
              ]),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10,),
        child,
      ],
    );
  }

  Widget _generateSlidable({required WalletModel wallet}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Slidable(
        key: Key("slide_${wallet.name}_${wallet.id}"),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.9,
          children: <Widget>[
            SlideButton(
              icon: Ionicons.pencil,
              iconColor: accentColors[1],
              text: 'Edit',
              onTap: () {
                Navigator.pushNamed(context, '/wallet/edit', arguments: wallet);
              },
            ),
            SlideButton(
              icon: Ionicons.trash,
              iconColor: accentColors[2],
              text: 'Delete',
              onTap: () {
                late Future<bool?> result = ShowMyDialog(
                  dialogTitle: "Delete Wallet",
                  dialogText: "Do you want to delete ${wallet.name}?\nThis will also delete all related transaction to this wallet.",
                  confirmText: "Delete",
                  confirmColor: accentColors[2],
                  cancelText: "Cancel")
                .show(context);
      
                // check the result of the dialog box
                result.then((value) async {
                  if (value == true) {
                    await _deleteWallet(wallet.id).then((_) {
                      if (mounted) {
                        // clear all the cache for the application so we can just
                        // fetch again all data from internet, for this let user knew
                        // that we will delete all the cache
                        late Future<bool?> userConfirm = ShowMyDialog(
                          dialogTitle: "Cache Clear",
                          dialogText: "We will clear all the cache for the application.",
                          confirmText: "Okay",
                          confirmColor: accentColors[0],
                        ).show(context);
      
                        userConfirm.then((value) {
                          _clearCache();
                        });
                      }
                    }).onError((error, stackTrace) {
                      Log.error(message: "Error when clicking delete wallet");
                    });
                  }
                });
              },
            ),
            SlideButton(
              icon: (wallet.enabled ? Ionicons.close : Ionicons.checkmark),
              iconColor: (wallet.enabled ? accentColors[7] : accentColors[6]),
              text: (wallet.enabled ? 'Disable' : 'Enable'),
              onTap: () {
                late Future<bool?> result = ShowMyDialog(
                  dialogTitle: "${wallet.enabled ? 'Disable' : 'Enable'} Wallet",
                  dialogText: "Do you want to ${wallet.enabled ? 'Disable' : 'Enable'} ${wallet.name}?",
                  confirmText: (wallet.enabled ? 'Disable' : 'Enable'),
                  confirmColor: (
                    wallet.enabled
                    ? accentColors[7]
                    : accentColors[6]
                  ),
                  cancelText: "Cancel"
                ).show(context);
      
                // check the result of the dialog box
                result.then((value) {
                  if (value == true) {
                    // enable/disable the wallet
                    _getData = _enableDisableWallet(wallet);
                  }
                });
              },
            ),
            SlideButton(
              icon: Ionicons.analytics,
              iconColor: accentColors[3],
              text: 'Stat',
              onTap: () {
                Navigator.pushNamed(context, '/wallet/stat', arguments: wallet);
              },
            ),
          ],
        ),
        child: Wallet(
          wallet: wallet,
          onTap: () {
            Navigator.pushNamed(context, '/wallet/transaction', arguments: wallet);
          },
        ),
      ),
    );
  }

  Future<bool> _enableDisableWallet(WalletModel wallet) async {
    Future<List<WalletModel>> walletList;
    Future<List<CurrencyModel>> walletCurrencyList;

    // show loading screen
    LoadingScreen.instance().show(context: context);

    await Future.wait([
      walletList = _walletHTTP.enableWallet(
        txn: wallet,
        isEnabled: !wallet.enabled
      ),
      walletCurrencyList = _walletHTTP.fetchWalletCurrencies(force: true),
    ]).then((_) {
      // set the provider with the new wallets we got
      walletList.then((wallets) {
        if (mounted) {
          Provider.of<HomeProvider>(
            context,
            listen: false
          ).setWalletList(wallets: wallets);
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
      // got error when we try to enable/disable wallet
      Log.error(
        message: "Error <_enableWallet>",
        error: error,
        stackTrace: stackTrace,
      );
      throw Exception("Error when enabling the wallet");
    }).whenComplete(() {
      // remove the loading screen
      LoadingScreen.instance().hide();
    });

    return true;
  }

  Future<void> _clearCache() async {
    // show the loading screen
    LoadingScreen.instance().show(context: context);

    // first clear all the cache data
    Provider.of<HomeProvider>(context, listen: false).clearTransactionList();
    Provider.of<HomeProvider>(context, listen: false).clearBudgetList();
    await Future.microtask(() async {
      await TransactionSharedPreferences.clearTransaction();
      await BudgetSharedPreferences.clearBudget();
      
      await _walletHTTP.fetchWalletCurrencies(force: true).then((_) async {
        Log.success(message: "⏳ Fetch Wallet User Currency");
        await _fetchAllBudget();
      });
    }).then((_) {
      Log.success(message: "💯 Clear cache and get data again");
    }).onError((error, stackTrace) {
      Log.error(
        message: "🛑 Error when clear cache and get data",
        error: error,
        stackTrace: stackTrace,
      );
    }).whenComplete(() {
      LoadingScreen.instance().hide();
    });
  }
  
  Future<void> _fetchAllBudget() async {
    // loop thru all the currencies and get the budget
    List<CurrencyModel> ccyLists = WalletSharedPreferences.getWalletUserCurrency();
    for (CurrencyModel ccy in ccyLists) {
      // fetch the budget for this ccy
      await _budgetHTTP.fetchBudgetDate(
        currencyID: ccy.id,
        date: Globals.dfyyyyMMdd.formatLocal(
          DateTime(
            DateTime.now().year,
            DateTime.now().month,
            1
          )
        ),
        force: true
      ).then((_) {
        Log.success(message: "⏳ Fetch current budget for ${ccy.name}");
      },);
    }
  }

  void _generateAccountMap({required List<WalletModel> wallets}) {
    // clear the current account map
    _accountMap.clear();

    // add the account map, with initial value as "All"
    _accountMap['all'] = 'All';

    // loop thru wallets, and add the account map
    for (WalletModel wallet in wallets) {
      // check if this wallet type already in account map or not?
      if (!_accountMap.containsKey(wallet.walletType.type)) {
        // add this wallet type to the account map
        _accountMap[wallet.walletType.type] = wallet.walletType.type;
      }
    }
  }

  void _generateWalletFilter({required List<WalletModel> wallets}) {
    double currentValue = 0;

    // clear the _walletsFilter
    _walletsFilter.clear();

    // default add 'all' to the wallets filter, we will put all the wallet
    // inside here as default
    _walletsFilter['all'] = [];

    // loop thru wallets, and add the account map
    for (WalletModel wallet in wallets) {
      // check if this wallet type already in wallet filter or not?
      if (!_walletsFilter.containsKey(wallet.walletType.type)) {
        _walletsFilter[wallet.walletType.type] = [];
      }

      // add the wallet to the correct wallet filter
      _walletsFilter[wallet.walletType.type]!.add(wallet);
      // add also the wallet to all
      _walletsFilter['all']!.add(wallet);
    }

    // once we got the wallets filter, now we can generate the wallet filter
    // summary.

    // first clear the wallets filter summary.
    _walletsFilterSummary.clear();

    // loop thru all the data in the wallets filter
    _walletsFilter.forEach((key, wallets) {
      // add this key to the wallets filter summary
      _walletsFilterSummary[key] = {};

      // loop thru wallets, and calculate the summary
      for(WalletModel wallet in wallets) {
        // check if wallet is enabled or not?
        if (wallet.enabled) {
          // default current value to 0
          currentValue = 0;

          // check if this currency already in the wallets filter summary or not?
          if (_walletsFilterSummary[key]!.containsKey(wallet.currency.name)) {
            // already got data, it means that we need to get the current value
            // of this data before we calculate
            currentValue = _walletsFilterSummary[key]![wallet.currency.name]!;
          }

          // now add the current amount to the wallets filter summary
          _walletsFilterSummary[key]![wallet.currency.name] = 
            wallet.startBalance +
            wallet.changeBalance +
            currentValue;
        }
      }
    },);

    // check if tab selected is still exists, if not then we revert back
    // tab selected to all, this is can happen when user delete the wallet
    // and that wallet type doesn't have wallet anymore
    if (!_walletsFilter.containsKey(_tabSelected)) {
      _tabSelected = 'all';
    }
  }
}
