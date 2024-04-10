import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:my_expense/model/currency_model.dart';
import 'package:my_expense/model/users_me_model.dart';
import 'package:my_expense/model/wallet_model.dart';
import 'package:my_expense/model/wallet_stat_all_model.dart';
import 'package:my_expense/model/wallet_stat_model.dart';
import 'package:my_expense/model/wallet_type_model.dart';
import 'package:my_expense/model/worth_model.dart';
import 'package:my_expense/utils/globals.dart';
import 'package:my_expense/utils/prefs/shared_user.dart';
import 'package:my_expense/utils/prefs/shared_wallet.dart';

class WalletHTTPService {
  //late LoginModel _loginModel;
  late String _bearerToken;

  WalletHTTPService() {
    //_loginModel = UserSharedPreferences.getUserLogin();
    _bearerToken = UserSharedPreferences.getJWT();
  }

  void refreshJWTToken() {
    _bearerToken = UserSharedPreferences.getJWT();
  }

  Future<List<WalletModel>> fetchWallets(bool showDisabled,
      [bool? force]) async {
    bool isForce = (force ?? false);
    _checkJWT();
    String bearerToken = _bearerToken;

    // check if we need to force to get the wallet or not?
    // if not need, it means we will just load it from shared preferences
    // instead.
    if (!isForce) {
      // check if we got wallets already on the shared preferences or not?
      List<WalletModel> walletsPref =
          WalletSharedPreferences.getWallets(showDisabled);
      if (walletsPref.isNotEmpty) {
        // return back from proc, no need to fetch to server
        return walletsPref;
      }
    }

    // ensure we have the bearer token when we are actually want to perform
    // fetch on the backend.
    if (bearerToken.isNotEmpty) {
      final response =
          await http.get(Uri.parse('${Globals.apiURL}wallets'), headers: {
        HttpHeaders.authorizationHeader: "Bearer $bearerToken",
      });

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);

        // map the body into List of WalletModel
        List<WalletModel> wallets =
            body.map((dynamic item) => WalletModel.fromJson(item)).toList();

        // store the wallet on the shared preferences
        await WalletSharedPreferences.setWallets(wallets);

        // once finished then return all the wallets
        return wallets;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized to fetchWallets","message":"Empty token"}');
    }
  }

  Future<List<CurrencyModel>> fetchWalletCurrencies([bool? force]) async {
    bool isForce = (force ?? false);
    _checkJWT();
    String bearerToken = _bearerToken;

    // check if we need to force to get the wallet or not?
    // if not need, it means we will just load it from shared preferences
    // instead.
    if (!isForce) {
      // check if we got wallets already on the shared preferences or not?
      List<CurrencyModel> walletsCurrencyPref = WalletSharedPreferences.getWalletUserCurrency();
      if (walletsCurrencyPref.isNotEmpty) {
        return walletsCurrencyPref;
      }
    }

    // ensure we have the bearer token when we are actually want to perform
    // fetch on the backend.
    if (bearerToken.isNotEmpty) {
      final response = await http
          .get(Uri.parse('${Globals.apiURL}wallets/findcurrencies'), headers: {
        HttpHeaders.authorizationHeader: "Bearer $bearerToken",
      });

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);

        // map the body into List of WalletModel
        List<CurrencyModel> currencies =
            body.map((dynamic item) => CurrencyModel.fromJson(item)).toList();

        // store the wallet on the shared preferences
        await WalletSharedPreferences.setWalletUserCurrency(currencies);

        // once finished then return all the wallets
        return currencies;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized to fetchWallets","message":"Empty token"}');
    }
  }

  Future<WalletModel> fetchWalletsID(int id) async {
    _checkJWT();
    String bearerToken = _bearerToken;

    if (bearerToken.isNotEmpty) {
      final response = await http.get(
          Uri.parse('${Globals.apiURL}wallets/$id'),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer $bearerToken",
          });

      if (response.statusCode == 200) {
        dynamic body = jsonDecode(response.body);

        // map the body into List of WalletModel
        WalletModel wallet = WalletModel.fromJson(body);
        return wallet;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized to fetchWalletsID","message":"Empty token"}');
    }
  }

  Future<List<WorthModel>> fetchWalletsWorth(DateTime to, [bool? force]) async {
    bool isForce = (force ?? false);
    String dateTo = DateFormat('yyyy-MM-dd').format(to.toLocal());
    
    _checkJWT();
    String bearerToken = _bearerToken;

    // check if we need to force to get the wallet or not?
    // if not need, it means we will just load it from shared preferences
    // instead.
    if (!isForce) {
      // check if we got wallets already on the shared preferences or not?
      List<WorthModel> walletsPref = WalletSharedPreferences.getWalletWorth(dateTo);
      if (walletsPref.isNotEmpty) {
        // return back from proc, no need to fetch to server
        return walletsPref;
      }
    }

    // ensure we have the bearer token when we are actually want to perform
    // fetch on the backend.
    if (bearerToken.isNotEmpty) {
      final response =
          await http.get(Uri.parse('${Globals.apiURL}wallets/worth/$dateTo'), headers: {
        HttpHeaders.authorizationHeader: "Bearer $bearerToken",
      });

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);

        // map the body into List of WalletModel
        List<WorthModel> worth =
            body.map((dynamic item) => WorthModel.fromJson(item)).toList();

        // store the wallet on the shared preferences
        await WalletSharedPreferences.setWalletWorth(dateTo, worth);

        // once finished then return all the wallets
        return worth;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized to fetchWalletsWorth","message":"Empty token"}');
    }
  }

  Future<WalletModel> addWallet(WalletModel txn) async {
    _checkJWT();
    String bearerToken = _bearerToken;

    // here we will sent the add wallet to the backend, and if success we will
    // just get the current wallet from shared preferences, add the added wallet
    // to the shared preferences and provider.
    if (bearerToken.isNotEmpty) {
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

      // post the JSON data to the server
      final response = await http.post(Uri.parse('${Globals.apiURL}wallets'),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer $bearerToken",
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(walletAdd));

      if (response.statusCode == 200) {
        // here the server will response with the WalletModel, so we can just
        // parse it to WalletModel and return back to the widget
        WalletModel walletAdd = WalletModel.fromJson(jsonDecode(response.body));

        // return back the wallet add
        return walletAdd;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized to addWallet","message":"Empty token"}');
    }
  }

  Future<WalletModel> updateWallet(WalletModel txn) async {
    _checkJWT();
    String bearerToken = _bearerToken;

    // here we will sent the add wallet to the backend, and if success we will
    // just get the current wallet from shared preferences, add the added wallet
    // to the shared preferences and provider.
    if (bearerToken.isNotEmpty) {
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

      // post the JSON data to the server
      final response = await http.put(Uri.parse('${Globals.apiURL}wallets/${txn.id}'),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer $bearerToken",
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(walletEdit));

      if (response.statusCode == 200) {
        // here the server will response with the WalletModel, so we can just
        // parse it to WalletModel and return back to the widget
        WalletModel walletEdit = WalletModel.fromJson(jsonDecode(response.body));

        // return back the wallet add
        return walletEdit;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized to updateWallet","message":"Empty token"}');
    }
  }

  Future<List<WalletModel>> deleteWallets(int id) async {
    _checkJWT();
    String bearerToken = _bearerToken;

    if (bearerToken.isNotEmpty) {
      final response = await http.delete(
          Uri.parse('${Globals.apiURL}wallets/$id'),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer $bearerToken",
          });

      if (response.statusCode == 200) {
        // get the latest wallet data now from the API services
        final responseWalletList =
            await http.get(Uri.parse('${Globals.apiURL}wallets'), headers: {
          HttpHeaders.authorizationHeader: "Bearer $bearerToken",
        });

        if (responseWalletList.statusCode == 200) {
          List<dynamic> body = jsonDecode(responseWalletList.body);

          // map the body into List of WalletModel
          List<WalletModel> wallets =
              body.map((dynamic item) => WalletModel.fromJson(item)).toList();

          // store the wallet on the shared preferences
          await WalletSharedPreferences.setWallets(wallets);

          // return the wallets
          return wallets;
        }

        throw Exception(responseWalletList.body);
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized to deleteWallets","message":"Empty token"}');
    }
  }

  Future<List<WalletModel>> enableWallet(
      WalletModel txn, bool isEnabled) async {
    _checkJWT();
    String bearerToken = _bearerToken;

    if (bearerToken.isNotEmpty) {
      // prepare the JSON data
      var enableWallet = {"enabled": isEnabled};

      // post the JSON data to the server
      final response = await http.put(
          Uri.parse('${Globals.apiURL}wallets/enable/${txn.id}'),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer $bearerToken",
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(enableWallet));

      if (response.statusCode == 200) {
        // Here the server will return with the updated wallet model, so now
        // what we can do is traverse thru all the wallet and then just update
        // the wallet id with the one that response by the server
        WalletModel walletEnabled =
            WalletModel.fromJson(jsonDecode(response.body));

        List<WalletModel> wallets = WalletSharedPreferences.getWallets(true);

        // set the wallet that we want to disabled
        for (int i = 0; i < wallets.length; i++) {
          if (wallets[i].id == walletEnabled.id) {
            wallets[i] = walletEnabled;
            //print("Disable wallet index : " + i.toString());
          }
        }

        // sort the wallet before we stored it again on the shared preferences.
        wallets = sortWallets(wallets);

        // now store back the _wallets to the sharedPreferences
        WalletSharedPreferences.setWallets(wallets);

        // return back the new wallet list, which we can used as setup for provider
        // the back side of update the shared preferences, it means that the
        // order will be wrong, since we sort the order with enabled and id
        // during fetch, so this wallet will be definitely on the wrong order.
        return wallets;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized to enableWallet","message":"Empty token"}');
    }
  }

  List<WalletModel> sortWallets(List<WalletModel> wallets) {
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
        //print("Wallet " + _wallets[i].name + " is disabled");
        // put on behind
        while(!walletList[lastPos].enabled) {
          lastPos--;
        }

        // check if last pos is > i
        // if more, then it means that this disable already on the back of the pack
        if(i > lastPos) {
          //print("This wallet already behind, no need to sort");
          break;
        }

        // put current wallet to last pos
        //print("Move wallets " + _wallets[i].name + " on position " + i.toString() + " to wallets " + _wallets[_lastPos].name + " in position " + _lastPos.toString());
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
            //print("wallet " + _wallets[i].name + " type bigger than " + _wallets[j].name + " Move from " + i.toString() + " to " + j.toString());
            tmpWallet = walletList[i];
            walletList[i] = walletList[j];
            walletList[j] = tmpWallet;
          } else if (walletList[i].walletType.id == walletList[j].walletType.id) {
            // this is the same wallet type, check if the wallet id is bigger
            // or not?
            if (walletList[i].id > walletList[j].id) {
              //print("wallet id bigger - Move from " + i.toString() + " to " + j.toString());
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
  Future<List<WalletTypeModel>> fetchWalletTypes([bool? force]) async {
    bool isForce = (force ?? false);
    _checkJWT();
    String bearerToken = _bearerToken;

    if (!isForce) {
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
    if (bearerToken.isNotEmpty) {
      final response =
          await http.get(Uri.parse('${Globals.apiURL}wallet-types'), headers: {
        HttpHeaders.authorizationHeader: "Bearer $bearerToken",
      });

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);

        // map the body into List of WalletTypeModel
        List<WalletTypeModel> walletTypes =
            body.map((dynamic item) => WalletTypeModel.fromJson(item)).toList();

        // store the wallet on the shared preferences
        await WalletSharedPreferences.setWalletTypes(walletTypes);

        // once finished then return all the wallets
        return walletTypes;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized to fetchWalletTypes","message":"Empty token"}');
    }
  }

  /// Currency API call
  Future<List<CurrencyModel>> fetchCurrency([bool? force]) async {
    bool isForce = (force ?? false);
    _checkJWT();
    String bearerToken = _bearerToken;

    if (!isForce) {
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
    if (bearerToken.isNotEmpty) {
      final response =
          await http.get(Uri.parse('${Globals.apiURL}currencies'), headers: {
        HttpHeaders.authorizationHeader: "Bearer $bearerToken",
      });

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);

        // map the body into List of WalletTypeModel
        List<CurrencyModel> currencies =
            body.map((dynamic item) => CurrencyModel.fromJson(item)).toList();

        // store the wallet on the shared preferences
        await WalletSharedPreferences.setWalletCurrency(currencies);

        // once finished then return all the wallets
        return currencies;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized to fetchCurrency","message":"Empty token"}');
    }
  }

  Future<void> updateDefaultWallet(int walletId) async {
    _checkJWT();
    String bearerToken = _bearerToken;

    // check from shared preferences if we already have loaded category data
    UsersMeModel userMe = UserSharedPreferences.getUserMe();

    // check if we got JWT token or not?
    if (bearerToken.isNotEmpty) {
      var body = {
        'wallet': {'id': walletId},
        'users_permissions_user': {'id': userMe.id}
      };

      final response =
          await http.put(Uri.parse('${Globals.apiURL}wallets/default'),
              headers: {
                HttpHeaders.authorizationHeader: "Bearer $bearerToken",
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(body));

      if (response.statusCode == 200) {
        // success, it will return the userMe model, so we can just replace the current userMe
        userMe = UsersMeModel.fromJson(jsonDecode(response.body));
        await UserSharedPreferences.setUserMe(userMe);
        return;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<List<WalletStatModel>> getStat(int id) async {
    _checkJWT();

    // check if we got JWT token or not?
    if (_bearerToken.isNotEmpty) {
      final response = await http.get(
          Uri.parse('${Globals.apiURL}wallets/stat/$id'),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer $_bearerToken",
          });

      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        List<WalletStatModel> walletStatModel =  jsonData.map((e) => WalletStatModel.fromJson(e)).toList();
        return walletStatModel;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  Future<List<WalletStatAllModel>> getAllStat(int? ccy) async {
    _checkJWT();

    String url = '${Globals.apiURL}wallets/statall';
    if (ccy != null) {
      url += '/$ccy';
    }

    // check if we got JWT token or not?
    if (_bearerToken.isNotEmpty) {
      final response = await http.get(
          Uri.parse(url),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer $_bearerToken",
          });

      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        List<WalletStatAllModel> walletStatAllModel =  jsonData.map((e) => WalletStatAllModel.fromJson(e)).toList();
        return walletStatAllModel;
      }

      throw Exception("res=${response.body}");
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  void _checkJWT() {
    if (_bearerToken.isEmpty) {
      _bearerToken = UserSharedPreferences.getJWT();
    }
  }
}
