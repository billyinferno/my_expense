import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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
  final _walletHttpService = WalletHTTPService();

  final ScrollController _scrollControllerWallet = ScrollController();
  late Future<bool> _getData;

  @override
  void initState() {
    _getData = _refreshWallet();
    super.initState();
  }

  @override
  void dispose() {
    _scrollControllerWallet.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(
        title: const Center(child: Text("Account")),
        iconItem: const Icon(
          Ionicons.create,
          size: 20,
        ),
        onUserPress: () {
          Navigator.pushNamed(context, '/user');
        },
        onActionPress: () {
          Navigator.pushNamed(context, '/wallet/add');
        },
      ),
      body: FutureBuilder(
        future: _getData,
        builder: ((context, snapshot) {
          if (snapshot.hasError) {
            // got error when fetching the wallet data
            return const Center(
              child: Text("Error when loading wallet data"),
            );
          } else if (snapshot.hasData) {
            // generate the main view
            return _generateWalletView();
          } else {
            // still loading
            return Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SpinKitFadingCube(
                  color: accentColors[6],
                ),
                const SizedBox(
                  height: 20,
                ),
                const Text(
                  "Loading Wallet",
                  style: TextStyle(
                    color: textColor2,
                    fontSize: 10,
                  ),
                )
              ],
            ));
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
        return (Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: RefreshIndicator(
            color: accentColors[6],
            onRefresh: () async {
              _getData = _refreshWallet(showDialog: true);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _scrollControllerWallet,
              itemCount: wallets.length + 1,
              itemBuilder: (BuildContext ctx, int index) {
                if (index < wallets.length) {
                  WalletModel wallet = wallets[index];
                  return _generateSlidable(wallet);
                } else {
                  return const SizedBox(
                    height: 30,
                  );
                }
              },
            ),
          ),
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
      walletList = _walletHttpService.deleteWallets(id),
      walletCurrencyList = _walletHttpService.fetchWalletCurrencies(true),
    ]).then((_) {
      // set the provider so it can tell the consumer to update/build the widget.
      walletList.then((wallets) {
        if (mounted) {
          Provider.of<HomeProvider>(context, listen: false)
              .setWalletList(wallets);
        }
      });
      walletCurrencyList.then((walletsCurrency) {
        if (mounted) {
          Provider.of<HomeProvider>(context, listen: false)
              .setWalletCurrency(walletsCurrency);
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
      futureWallets = _walletHttpService.fetchWallets(true, true),
    ]).then((_) {
      futureWallets.then((wallets) {
        if (wallets.isNotEmpty && mounted) {
          Provider.of<HomeProvider>(
            context,
            listen: false
          ).setWalletList(wallets);
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

  Widget _generateSlidable(WalletModel wallet) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Slidable(
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
              icon: (wallet.enabled ? Ionicons.alert : Ionicons.checkmark),
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
              icon: Ionicons.bar_chart,
              iconColor: accentColors[3],
              text: 'Stat',
              onTap: () {
                Navigator.pushNamed(context, '/wallet/stat', arguments: wallet);
              },
            ),
          ],
        ),
        child: Wallet(wallet: wallet),
      ),
    );
  }

  Future<bool> _enableDisableWallet(WalletModel wallet) async {
    Future<List<WalletModel>> walletList;
    Future<List<CurrencyModel>> walletCurrencyList;

    // show loading screen
    LoadingScreen.instance().show(context: context);

    await Future.wait([
      walletList = _walletHttpService.enableWallet(wallet, !wallet.enabled),
      walletCurrencyList = _walletHttpService.fetchWalletCurrencies(true),
    ]).then((_) {
      // set the provider with the new wallets we got
      walletList.then((wallets) {
        if (mounted) {
          Provider.of<HomeProvider>(
            context,
            listen: false
          ).setWalletList(wallets);
        }
      });

      walletCurrencyList.then((walletsCurrency) {
        if (mounted) {
          Provider.of<HomeProvider>(
            context,
            listen: false
          ).setWalletCurrency(walletsCurrency);
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
    // clear the cache here, we will clear the transaction
    // provider and cache, user will be need to refresh the
    // application once finished.
    LoadingScreen.instance().show(context: context);

    Provider.of<HomeProvider>(context, listen: false).clearTransactionList();
    Provider.of<HomeProvider>(context, listen: false).clearBudgetList();
    Future.wait([
      TransactionSharedPreferences.clearTransaction(),
      BudgetSharedPreferences.clearBudget(),
      //TODO: clear the statistic also, and then after that we can perform hard refresh to all the transaction, and budget
    ]).then((_) {
      // do nothing
    }).onError((error, stackTrace) {
      Log.error(
        message: "Error at _clearCache",
        error: error,
        stackTrace: stackTrace,
      );
    }).whenComplete(() {
      LoadingScreen.instance().hide();
    });
  }
}
