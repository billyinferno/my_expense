import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ionicons/ionicons.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:my_expense/api/wallet_api.dart';
import 'package:my_expense/model/currency_model.dart';
import 'package:my_expense/widgets/appbar/home_appbar.dart';
import 'package:my_expense/provider/home_provider.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/model/wallet_model.dart';
import 'package:my_expense/utils/misc/show_dialog.dart';
import 'package:my_expense/utils/prefs/shared_budget.dart';
import 'package:my_expense/utils/prefs/shared_transaction.dart';
import 'package:my_expense/widgets/input/wallet.dart';
import 'package:my_expense/widgets/modal/overlay_loading_modal.dart';
import 'package:provider/provider.dart';

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
            return const Center(child: Text("Error when loading wallet data"),);
          }
          else if (snapshot.hasData) {
            // generate the main view
            return _generateWalletView();
          }
          else {
            // still loading
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitFadingCube(color: accentColors[6],),
                  const SizedBox(height: 20,),
                  const Text(
                    "Loading Wallet",
                    style: TextStyle(
                      color: textColor2,
                      fontSize: 10,
                    ),
                  )
                ],
              )
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
        return (Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: RefreshIndicator(
            color: accentColors[6],
            onRefresh: () async {
              _getData = _refreshWallet();
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _scrollControllerWallet,
              itemCount: wallets.length + 1,
              itemBuilder: (BuildContext ctx, int index) {
                if (index < wallets.length) {
                  WalletModel wallet = wallets[index];
                  return _generateSlidable(wallet);
                }
                else {
                  return const SizedBox(height: 30,);
                }
              },
            ),
          ),
        ));
      },
    );
  }

  Future<void> _deleteWallet(int id) async {
    Future <List<CurrencyModel>> walletCurrencyList;
    Future <List<WalletModel>> walletList;

    // show loading screen
    LoadingScreen.instance().show(context: context);

    await Future.wait([
      walletList = _walletHttpService.deleteWallets(id),
      walletCurrencyList = _walletHttpService.fetchWalletCurrencies(true),
    ]).then((_) {
      // set the provider so it can tell the consumer to update/build the widget.
      walletList.then((wallets) {
        if (mounted) {
          Provider.of<HomeProvider>(context, listen: false).setWalletList(wallets);
        }
      });
      walletCurrencyList.then((walletsCurrency) {
        if (mounted) {
          Provider.of<HomeProvider>(context, listen: false).setWalletCurrency(walletsCurrency);
        }
      });
    }).onError((error, stackTrace) {
      debugPrint("Error on <_deleteWallet>");
      debugPrint(error.toString());
      debugPrintStack(stackTrace: stackTrace);
    }).whenComplete(() {
      // remove the loading screen
      LoadingScreen.instance().hide();
    },);
  }

  Future<bool> _refreshWallet() async {
    Future<List<WalletModel>> futureWallets;

    // showed a debug print message to knew that we refresh the wallet
    debugPrint("💳 Refresh Wallet");

    // fetch the new wallet data from API
    await Future.wait([
      futureWallets = _walletHttpService.fetchWallets(true, true),
    ]).then((_) {
      futureWallets.then((wallets) {
        if(wallets.isNotEmpty && mounted) {
          Provider.of<HomeProvider>(context, listen: false).setWalletList(wallets);
        }
      });
    }).onError((error, stackTrace) {
      debugPrint("Error when do <_refreshWallet>");
      debugPrint(error.toString());
      debugPrintStack(stackTrace: stackTrace);
      throw Exception("Error when get wallet data");
    });

    return true;
  }

  Widget _generateSlidable(WalletModel wallet) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.9,
        children: <SlidableAction>[
          SlidableAction(
            label: 'Edit',
            padding: const EdgeInsets.all(0),
            foregroundColor: accentColors[1],
            backgroundColor: primaryBackground,
            icon: Ionicons.pencil,
            onPressed: ((_) {
              Navigator.pushNamed(context, '/wallet/edit', arguments: wallet);
            })
          ),
          SlidableAction(
            label: 'Delete',
            padding: const EdgeInsets.all(0),
            foregroundColor: accentColors[2],
            backgroundColor: primaryBackground,
            icon: Ionicons.trash,
            onPressed: ((_) {
              late Future<bool?> result = ShowMyDialog(
                dialogTitle: "Delete Wallet",
                dialogText: "Do you want to delete ${wallet.name}?\nThis will also delete all related transaction to this wallet.",
                confirmText: "Delete",
                confirmColor: accentColors[2],
                cancelText: "Cancel"
              ).show(context);

              // check the result of the dialog box
              result.then((value) async {
                if(value == true) {
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
                    debugPrint("Error when clicking delete wallet");
                  });
                }
              });
            })
          ),
          SlidableAction(
            label: (wallet.enabled ? 'Disable' : 'Enable'),
            padding: const EdgeInsets.all(0),
            foregroundColor: (wallet.enabled ? accentColors[7] : accentColors[6]),
            backgroundColor: primaryBackground,
            icon: (wallet.enabled ? Ionicons.alert : Ionicons.checkmark),
            onPressed: ((_) {
              late Future<bool?> result = ShowMyDialog(
                dialogTitle: "${wallet.enabled ? 'Disable' : 'Enable'} Wallet",
                dialogText: "Do you want to ${wallet.enabled ? 'Disable' : 'Enable'} ${wallet.name}?",
                confirmText: (wallet.enabled ? 'Disable' : 'Enable'),
                confirmColor: (wallet.enabled ? accentColors[7] : accentColors[6]),
                cancelText: "Cancel")
                .show(context);

              // check the result of the dialog box
              result.then((value) {
                if (value == true) {
                  // enable/disable the wallet
                  _getData = _enableDisableWallet(wallet);
                }
              });
            })
          ),
          SlidableAction(
            label: 'Stat',
            padding: const EdgeInsets.all(0),
            foregroundColor: accentColors[3],
            backgroundColor: primaryBackground,
            icon: Ionicons.bar_chart,
            onPressed: ((_) {
              Navigator.pushNamed(context, '/wallet/stat', arguments: wallet);
            })
          ),
        ],
      ),
      child: Wallet(wallet: wallet),
    );
  }

  Future<bool> _enableDisableWallet(WalletModel wallet) async {
    Future <List<WalletModel>> walletList;
    Future <List<CurrencyModel>> walletCurrencyList;

    Future.wait([
      walletList = _walletHttpService.enableWallet(wallet, !wallet.enabled),
      walletCurrencyList = _walletHttpService.fetchWalletCurrencies(true),
    ]).then((_) {
      // set the provider with the new wallets we got
      walletList.then((wallets) {
        if (mounted) {
          Provider.of<HomeProvider>(context, listen: false).setWalletList(wallets);
        }
      });

      walletCurrencyList.then((walletsCurrency) {
        if (mounted) {
          Provider.of<HomeProvider>(context, listen: false).setWalletCurrency(walletsCurrency);
        }
      });
    }).onError((error, stackTrace) {
      // got error when we try to enable/disable wallet
      debugPrint("Error <_enableWallet>");
      debugPrint(error.toString());
      debugPrintStack(stackTrace: stackTrace);
      throw Exception("Error when enabling the wallet");
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
      debugPrint("Error at _clearCache");
      debugPrint(error.toString());
    }).whenComplete(() {
      LoadingScreen.instance().hide();
    });
  }
}
