import 'dart:async';
import 'dart:convert';
import 'package:my_expense/_index.g.dart';

class WalletHTTPService {
  Future<List<WalletModel>> fetchWallets({
    required bool showDisabled,
    bool force = false,
  }) async {
    // check if we need to force to get the wallet or not?
    // if not need, it means we will just load it from shared preferences
    // instead.
    if (!force) {
      // check if we got wallets already on the shared preferences or not?
      List<WalletModel> walletsPref =
          WalletSharedPreferences.getWallets(showDisabled);
      if (walletsPref.isNotEmpty) {
        // return back from proc, no need to fetch to server
        return walletsPref;
      }
    }

    // send the request to get the wallet
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}wallets',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // parse the result
    List<dynamic> body = jsonDecode(result);

    // map the body into List of WalletModel
    List<WalletModel> wallets =
        body.map((dynamic item) => WalletModel.fromJson(item)).toList();

    // store the wallet on the shared preferences
    await WalletSharedPreferences.setWallets(wallets);

    // once finished then return all the wallets
    return wallets;
  }

  Future<List<CurrencyModel>> fetchWalletCurrencies({
    bool force = false,
  }) async {
    // check if we need to force to get the wallet or not?
    // if not need, it means we will just load it from shared preferences
    // instead.
    if (!force) {
      // check if we got wallets already on the shared preferences or not?
      List<CurrencyModel> walletsCurrencyPref = WalletSharedPreferences.getWalletUserCurrency();
      if (walletsCurrencyPref.isNotEmpty) {
        return walletsCurrencyPref;
      }
    }

    // send the request to get wallet currency
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}wallets/findcurrencies',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // parse the result
    List<dynamic> body = jsonDecode(result);

    // map the body into List of WalletModel
    List<CurrencyModel> currencies =
        body.map((dynamic item) => CurrencyModel.fromJson(item)).toList();

    // store the wallet on the shared preferences
    await WalletSharedPreferences.setWalletUserCurrency(currencies);

    // once finished then return all the wallets
    return currencies;
  }

  Future<WalletModel> fetchWalletsID({required int id}) async {
    // send the request to get wallet ID
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}wallets/$id',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // parse json data
    dynamic body = jsonDecode(result);

    // map the body into List of WalletModel
    WalletModel wallet = WalletModel.fromJson(body);

    return wallet;
  }

  Future<List<WorthModel>> fetchWalletsWorth({
    required DateTime to,
    bool force = false,
  }) async {
    String dateTo = Globals.dfyyyyMMdd.format(to.toLocal());
    
    // check if we need to force to get the wallet or not?
    // if not need, it means we will just load it from shared preferences
    // instead.
    if (!force) {
      // check if we got wallets already on the shared preferences or not?
      List<WorthModel> walletsPref = WalletSharedPreferences.getWalletWorth(dateTo);
      if (walletsPref.isNotEmpty) {
        // return back from proc, no need to fetch to server
        return walletsPref;
      }
    }

    // send the request to get wallet worth
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}wallets/worth/$dateTo',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // parse the result
    List<dynamic> body = jsonDecode(result);

    // map the body into List of WalletModel
    List<WorthModel> worth =
        body.map((dynamic item) => WorthModel.fromJson(item)).toList();

    // store the wallet on the shared preferences
    await WalletSharedPreferences.setWalletWorth(dateTo, worth);

    // once finished then return all the wallets
    return worth;
  }

  Future<WalletModel> addWallet({required WalletModel txn}) async {
    // prepare the JSON data
    var walletAdd = {
      "name": txn.name,
      "startBalance": txn.startBalance,
      "changeBalance": 0,
      "useForStats": txn.useForStats,
      "wallet_type": {"id": txn.walletType.id},
      "currency": {"id": txn.currency.id},
      "users_permissions_user": {"id": txn.userPermissionUsers.id}
    };
    
    // send the request to add new wallet
    final String result = await NetUtils.post(
      url: '${Globals.apiURL}wallets',
      body: walletAdd
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // here the server will response with the WalletModel, so we can just
    // parse it to WalletModel and return back to the widget
    WalletModel ret = WalletModel.fromJson(jsonDecode(result));

    // return back the wallet add
    return ret;
  }

  Future<WalletModel> updateWallet({required WalletModel txn}) async {
    // prepare the JSON data
    var walletEdit = {
      "name": txn.name,
      "startBalance": txn.startBalance,
      "changeBalance": 0,
      "useForStats": txn.useForStats,
      "enabled": txn.enabled,
      "wallet_type": {"id": txn.walletType.id},
      "currency": {"id": txn.currency.id},
      "users_permissions_user": {"id": txn.userPermissionUsers.id}
    };
    
    // send the request to update wallet
    final String result = await NetUtils.put(
      url: '${Globals.apiURL}wallets/${txn.id}',
      body: walletEdit
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // here the server will response with the WalletModel, so we can just
    // parse it to WalletModel and return back to the widget
    WalletModel ret = WalletModel.fromJson(jsonDecode(result));

    // return back the wallet add
    return ret;
  }

  Future<List<WalletModel>> deleteWallets({required int id}) async {
    // send the request to delete wallet
    await NetUtils.delete(
      url: '${Globals.apiURL}wallets/$id',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // if delete success, get the latest wallet data now from the API services
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}wallets',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // parse the result
    List<dynamic> body = jsonDecode(result);

    // map the body into List of WalletModel
    List<WalletModel> wallets =
        body.map((dynamic item) => WalletModel.fromJson(item)).toList();

    // store the wallet on the shared preferences
    await WalletSharedPreferences.setWallets(wallets);

    // return the wallets
    return wallets;
  }

  Future<List<WalletModel>> enableWallet({
    required WalletModel txn,
    required bool isEnabled
  }) async {
    // prepare the JSON data
    var enableWallet = {"enabled": isEnabled};

    // send the request to enable wallet
    final String result = await NetUtils.put(
      url: '${Globals.apiURL}wallets/enable/${txn.id}',
      body: enableWallet
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // Here the server will return with the updated wallet model, so now
    // what we can do is traverse thru all the wallet and then just update
    // the wallet id with the one that response by the server
    WalletModel walletEnabled =
        WalletModel.fromJson(jsonDecode(result));

    List<WalletModel> wallets = WalletSharedPreferences.getWallets(true);

    // set the wallet that we want to disabled
    for (int i = 0; i < wallets.length; i++) {
      if (wallets[i].id == walletEnabled.id) {
        wallets[i] = walletEnabled;
        //print("Disable wallet index : " + i.toString());
      }
    }

    // sort the wallet before we stored it again on the shared preferences.
    wallets = sortWallets(wallets: wallets);

    // now store back the _wallets to the sharedPreferences
    WalletSharedPreferences.setWallets(wallets);

    // return back the new wallet list, which we can used as setup for provider
    // the back side of update the shared preferences, it means that the
    // order will be wrong, since we sort the order with enabled and id
    // during fetch, so this wallet will be definitely on the wrong order.
    return wallets;
  }

  List<WalletModel> sortWallets({required List<WalletModel> wallets}) {
    List<WalletModel> walletList = wallets;
    WalletModel tmpWallet;

    // ensure we have data to be sorted out
    if(walletList.isEmpty) {
      return [];
    }

    // push the disabled to behind
    int lastPos = walletList.length-1;
    for (int i = 0; i < (walletList.length - 1) && (lastPos > 0); i++) {
      if (!walletList[i].enabled) {
        // put on behind
        while(!walletList[lastPos].enabled) {
          lastPos--;
        }

        // check if last pos is > i
        // if more, then it means that this disable already on the back of the pack
        if(i > lastPos) {
          break;
        }

        // put current wallet to last pos
        tmpWallet = walletList[i];
        walletList[i] = walletList[lastPos];
        walletList[lastPos] = tmpWallet;

        // move last post
        lastPos--;
      }
    }

    // sort it out based on the id and the wallet type
    // this is assuming all the disabled already put behind as per code
    // before this.
    for (int i = 0; i < walletList.length - 1; i++) {
      for (int j = (i + 1); j < walletList.length; j++) {
        if (walletList[i].enabled && walletList[j].enabled) {
          if (walletList[i].walletType.id > walletList[j].walletType.id) {
            // swap this
            tmpWallet = walletList[i];
            walletList[i] = walletList[j];
            walletList[j] = tmpWallet;
          } else if (walletList[i].walletType.id == walletList[j].walletType.id) {
            // this is the same wallet type, check if the wallet id is bigger
            // or not?
            if (walletList[i].id > walletList[j].id) {
              tmpWallet = walletList[i];
              walletList[i] = walletList[j];
              walletList[j] = tmpWallet;
            }
          }
        }
      }
    }

    // return the wallets back to the caller proc
    return walletList;
  }

  /// WalletTypes API call
  Future<List<WalletTypeModel>> fetchWalletTypes({bool force = false}) async {
    if (!force) {
      // check if we got wallets already on the shared preferences or not?
      List<WalletTypeModel> walletTypes =
          WalletSharedPreferences.getWalletTypes();
      if (walletTypes.isNotEmpty) {
        // return back from proc, no need to fetch to server
        return walletTypes;
      }
    }

    // if we don't have the data from shared preferences, or the data there
    // is 0, then we can try to get the data from backend instead.
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}wallet-types',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // parse the result
    List<dynamic> body = jsonDecode(result);

    // map the body into List of WalletTypeModel
    List<WalletTypeModel> walletTypes =
        body.map((dynamic item) => WalletTypeModel.fromJson(item)).toList();

    // store the wallet on the shared preferences
    await WalletSharedPreferences.setWalletTypes(walletTypes);

    // once finished then return all the wallets
    return walletTypes;
  }

  /// Currency API call
  Future<List<CurrencyModel>> fetchCurrency({bool force = false}) async {
    if (!force) {
      // check if we got wallets already on the shared preferences or not?
      List<CurrencyModel> currencies =
          WalletSharedPreferences.getWalletCurrency();
      if (currencies.isNotEmpty) {
        // return back from proc, no need to fetch to server
        return currencies;
      }
    }

    // if we don't have the data from shared preferences, or the data there
    // is 0, then we can try to get the data from backend instead.
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}currencies',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // parse the result
    List<dynamic> body = jsonDecode(result);

    // map the body into List of WalletTypeModel
    List<CurrencyModel> currencies =
        body.map((dynamic item) => CurrencyModel.fromJson(item)).toList();

    // store the wallet on the shared preferences
    await WalletSharedPreferences.setWalletCurrency(currencies);

    // once finished then return all the wallets
    return currencies;
  }

  Future<void> updateDefaultWallet({required int walletId}) async {
    // check from shared preferences if we already have loaded category data
    UsersMeModel userMe = UserSharedPreferences.getUserMe();

    // prepare the body request
    var body = {
      'wallet': {'id': walletId},
      'users_permissions_user': {'id': userMe.id}
    };

    // send the request to update default wallet
    final String result = await NetUtils.put(
      url: '${Globals.apiURL}wallets/default',
      body: body
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // success, it will return the userMe model, so we can just replace the current userMe
    userMe = UsersMeModel.fromJson(jsonDecode(result));
    await UserSharedPreferences.setUserMe(userMe);
  }

  Future<List<WalletStatModel>> getStat({required int id}) async {
    // send the request to get wallet statistic
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}wallets/stat/$id',
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // parse the result
    List<dynamic> jsonData = jsonDecode(result);
    List<WalletStatModel> walletStatModel =  jsonData.map((e) => WalletStatModel.fromJson(e)).toList();
    return walletStatModel;
  }

  Future<List<WalletStatAllModel>> getAllStat({int? ccy}) async {
    String url = '${Globals.apiURL}wallets/statall';
    if (ccy != null) {
      url += '/$ccy';
    }

    // send the request to get all wallet statistic
    final String result = await NetUtils.get(
      url: url,
    ).onError((error, stackTrace) {
      throw Exception(error);
    });

    // parse the result
    List<dynamic> jsonData = jsonDecode(result);
    List<WalletStatAllModel> walletStatAllModel =  jsonData.map((e) => WalletStatAllModel.fromJson(e)).toList();
    return walletStatAllModel;
  }
}
