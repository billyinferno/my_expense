import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:my_expense/model/currency_model.dart';
import 'package:my_expense/model/users_me_model.dart';
import 'package:my_expense/model/wallet_model.dart';
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
    bool _force = (force ?? false);
    _checkJWT();
    String bearerToken = _bearerToken;

    // check if we need to force to get the wallet or not?
    // if not need, it means we will just load it from shared preferences
    // instead.
    if (!_force) {
      // check if we got wallets already on the shared preferences or not?
      List<WalletModel> _walletsPref =
          WalletSharedPreferences.getWallets(showDisabled);
      if (_walletsPref.length > 0) {
        // return back from proc, no need to fetch to server
        return _walletsPref;
      }
    }

    // ensure we have the bearer token when we are actually want to perform
    // fetch on the backend.
    if (bearerToken.length > 0) {
      final response =
          await http.get(Uri.parse(Globals.apiURL + 'wallets'), headers: {
        HttpHeaders.authorizationHeader: "Bearer " + bearerToken,
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

      print("Got error <fetchWallets>");
      throw Exception("res=" + response.body);
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized to fetchWallets","message":"Empty token"}');
    }
  }

  Future<List<CurrencyModel>> fetchWalletCurrencies([bool? force]) async {
    bool _force = (force ?? false);
    _checkJWT();
    String bearerToken = _bearerToken;

    // check if we need to force to get the wallet or not?
    // if not need, it means we will just load it from shared preferences
    // instead.
    if (!_force) {
      // check if we got wallets already on the shared preferences or not?
      List<CurrencyModel> _walletsCurrencyPref = WalletSharedPreferences.getWalletUserCurrency();
      if (_walletsCurrencyPref.length > 0) {
        return _walletsCurrencyPref;
      }
    }

    // ensure we have the bearer token when we are actually want to perform
    // fetch on the backend.
    if (bearerToken.length > 0) {
      final response = await http
          .get(Uri.parse(Globals.apiURL + 'wallets/findcurrencies'), headers: {
        HttpHeaders.authorizationHeader: "Bearer " + bearerToken,
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

      print("Got error <fetchWalletCurrencies>");
      throw Exception("res=" + response.body);
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized to fetchWallets","message":"Empty token"}');
    }
  }

  Future<WalletModel> fetchWalletsID(int id) async {
    _checkJWT();
    String bearerToken = _bearerToken;

    if (bearerToken.length > 0) {
      final response = await http.get(
          Uri.parse(Globals.apiURL + 'wallets/' + id.toString()),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer " + bearerToken,
          });

      if (response.statusCode == 200) {
        dynamic body = jsonDecode(response.body);

        // map the body into List of WalletModel
        WalletModel wallet = WalletModel.fromJson(body);
        return wallet;
      }

      print("Got error <fetchWalletsID>");
      throw Exception("res=" + response.body);
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized to fetchWalletsID","message":"Empty token"}');
    }
  }

  Future<List<WorthModel>> fetchWalletsWorth(DateTime to, [bool? force]) async {
    bool _force = (force ?? false);
    String _dateTo = DateFormat('yyyy-MM-dd').format(to.toLocal());
    
    _checkJWT();
    String bearerToken = _bearerToken;

    // check if we need to force to get the wallet or not?
    // if not need, it means we will just load it from shared preferences
    // instead.
    if (!_force) {
      // check if we got wallets already on the shared preferences or not?
      List<WorthModel> _walletsPref = WalletSharedPreferences.getWalletWorth(_dateTo);
      if (_walletsPref.length > 0) {
        // return back from proc, no need to fetch to server
        return _walletsPref;
      }
    }

    // ensure we have the bearer token when we are actually want to perform
    // fetch on the backend.
    if (bearerToken.length > 0) {
      final response =
          await http.get(Uri.parse(Globals.apiURL + 'wallets/worth/' + _dateTo), headers: {
        HttpHeaders.authorizationHeader: "Bearer " + bearerToken,
      });

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);

        // map the body into List of WalletModel
        List<WorthModel> worth =
            body.map((dynamic item) => WorthModel.fromJson(item)).toList();

        // store the wallet on the shared preferences
        await WalletSharedPreferences.setWalletWorth(_dateTo, worth);

        // once finished then return all the wallets
        return worth;
      }

      print("Got error <fetchWalletsWorth>");
      throw Exception("res=" + response.body);
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
    if (bearerToken.length > 0) {
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
      final response = await http.post(Uri.parse(Globals.apiURL + 'wallets'),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer " + bearerToken,
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

      print("Got error <addWallet>");
      throw Exception("res=" + response.body);
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
    if (bearerToken.length > 0) {
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
      final response = await http.put(Uri.parse(Globals.apiURL + 'wallets/' + txn.id.toString()),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer " + bearerToken,
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

      print("Got error <updateWallet>");
      throw Exception("res=" + response.body);
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized to updateWallet","message":"Empty token"}');
    }
  }

  Future<List<WalletModel>> deleteWallets(int id) async {
    _checkJWT();
    String bearerToken = _bearerToken;

    if (bearerToken.length > 0) {
      final response = await http.delete(
          Uri.parse(Globals.apiURL + 'wallets/' + id.toString()),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer " + bearerToken,
          });

      if (response.statusCode == 200) {
        // get the latest wallet data now from the API services
        final responseWalletList =
            await http.get(Uri.parse(Globals.apiURL + 'wallets'), headers: {
          HttpHeaders.authorizationHeader: "Bearer " + bearerToken,
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

        print("Got error when fetch again!");
        throw Exception(responseWalletList.body);
      }

      print("Got error <deleteWallets>");
      throw Exception("res=" + response.body);
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized to deleteWallets","message":"Empty token"}');
    }
  }

  Future<List<WalletModel>> enableWallet(
      WalletModel txn, bool isEnabled) async {
    _checkJWT();
    String bearerToken = _bearerToken;

    if (bearerToken.length > 0) {
      // prepare the JSON data
      var enableWallet = {"enabled": isEnabled};

      // post the JSON data to the server
      final response = await http.put(
          Uri.parse(Globals.apiURL + 'wallets/enable/' + txn.id.toString()),
          headers: {
            HttpHeaders.authorizationHeader: "Bearer " + bearerToken,
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(enableWallet));

      if (response.statusCode == 200) {
        // Here the server will return with the updated wallet model, so now
        // what we can do is traverse thru all the wallet and then just update
        // the wallet id with the one that response by the server
        WalletModel walletEnabled =
            WalletModel.fromJson(jsonDecode(response.body));

        List<WalletModel> _wallets = WalletSharedPreferences.getWallets(true);

        // set the wallet that we want to disabled
        for (int i = 0; i < _wallets.length; i++) {
          if (_wallets[i].id == walletEnabled.id) {
            _wallets[i] = walletEnabled;
            //print("Disable wallet index : " + i.toString());
          }
        }

        // sort the wallet before we stored it again on the shared preferences.
        _wallets = sortWallets(_wallets);

        // now store back the _wallets to the sharedPreferences
        WalletSharedPreferences.setWallets(_wallets);

        // return back the new wallet list, which we can used as setup for provider
        // the back side of update the shared preferences, it means that the
        // order will be wrong, since we sort the order with enabled and id
        // during fetch, so this wallet will be definitely on the wrong order.
        return _wallets;
      }

      print("Got error <enableWallet>");
      throw Exception("res=" + response.body);
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized to enableWallet","message":"Empty token"}');
    }
  }

  List<WalletModel> sortWallets(List<WalletModel> wallets) {
    List<WalletModel> _wallets = wallets;
    WalletModel _tmpWallet;

    // ensure we have data to be sorted out
    if(_wallets.length <= 0) {
      return [];
    }

    // push the disabled to behind
    int _lastPos = _wallets.length-1;
    for (int i = 0; i < (_wallets.length - 1) && (_lastPos > 0); i++) {
      if (!_wallets[i].enabled) {
        //print("Wallet " + _wallets[i].name + " is disabled");
        // put on behind
        while(!_wallets[_lastPos].enabled) {
          _lastPos--;
        }

        // check if last pos is > i
        // if more, then it means that this disable already on the back of the pack
        if(i > _lastPos) {
          //print("This wallet already behind, no need to sort");
          break;
        }

        // put current wallet to last pos
        //print("Move wallets " + _wallets[i].name + " on position " + i.toString() + " to wallets " + _wallets[_lastPos].name + " in position " + _lastPos.toString());
        _tmpWallet = _wallets[i];
        _wallets[i] = _wallets[_lastPos];
        _wallets[_lastPos] = _tmpWallet;

        // move last post
        _lastPos--;
      }
    }

    // sort it out based on the id and the wallet type
    // this is assuming all the disabled already put behind as per code
    // before this.
    for (int i = 0; i < _wallets.length - 1; i++) {
      for (int j = (i + 1); j < _wallets.length; j++) {
        if (_wallets[i].enabled && _wallets[j].enabled) {
          if (_wallets[i].walletType.id > _wallets[j].walletType.id) {
            // swap this
            //print("wallet " + _wallets[i].name + " type bigger than " + _wallets[j].name + " Move from " + i.toString() + " to " + j.toString());
            _tmpWallet = _wallets[i];
            _wallets[i] = _wallets[j];
            _wallets[j] = _tmpWallet;
          } else if (_wallets[i].walletType.id == _wallets[j].walletType.id) {
            // this is the same wallet type, check if the wallet id is bigger
            // or not?
            if (_wallets[i].id > _wallets[j].id) {
              //print("wallet id bigger - Move from " + i.toString() + " to " + j.toString());
              _tmpWallet = _wallets[i];
              _wallets[i] = _wallets[j];
              _wallets[j] = _tmpWallet;
            }
          }
        }
      }
    }

    // return the wallets back to the caller proc
    return _wallets;
  }

  /// WalletTypes API call
  Future<List<WalletTypeModel>> fetchWalletTypes([bool? force]) async {
    bool _force = (force ?? false);
    _checkJWT();
    String bearerToken = _bearerToken;

    if (!_force) {
      // check if we got wallets already on the shared preferences or not?
      List<WalletTypeModel> _walletTypes =
          WalletSharedPreferences.getWalletTypes();
      if (_walletTypes.length > 0) {
        // return back from proc, no need to fetch to server
        return _walletTypes;
      }
    }

    // if we don't have the data from shared preferences, or the data there
    // is 0, then we can try to get the data from backend instead.
    if (bearerToken.length > 0) {
      final response =
          await http.get(Uri.parse(Globals.apiURL + 'wallet-types'), headers: {
        HttpHeaders.authorizationHeader: "Bearer " + bearerToken,
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

      print("Got error <fetchWalletTypes>");
      throw Exception("res=" + response.body);
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized to fetchWalletTypes","message":"Empty token"}');
    }
  }

  /// Currency API call
  Future<List<CurrencyModel>> fetchCurrency([bool? force]) async {
    bool _force = (force ?? false);
    _checkJWT();
    String bearerToken = _bearerToken;

    if (!_force) {
      // check if we got wallets already on the shared preferences or not?
      List<CurrencyModel> _currencies =
          WalletSharedPreferences.getWalletCurrency();
      if (_currencies.length > 0) {
        // return back from proc, no need to fetch to server
        return _currencies;
      }
    }

    // if we don't have the data from shared preferences, or the data there
    // is 0, then we can try to get the data from backend instead.
    if (bearerToken.length > 0) {
      final response =
          await http.get(Uri.parse(Globals.apiURL + 'currencies'), headers: {
        HttpHeaders.authorizationHeader: "Bearer " + bearerToken,
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

      print("Got error <fetchCurrency>");
      throw Exception("res=" + response.body);
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized to fetchCurrency","message":"Empty token"}');
    }
  }

  Future<void> updateDefaultWallet(int walletId) async {
    _checkJWT();
    String bearerToken = _bearerToken;

    // check from shared preferences if we already have loaded category data
    UsersMeModel _userMe = UserSharedPreferences.getUserMe();

    // check if we got JWT token or not?
    if (bearerToken.length > 0) {
      var _body = {
        'wallet': {'id': walletId},
        'users_permissions_user': {'id': _userMe.id}
      };

      final response =
          await http.put(Uri.parse(Globals.apiURL + 'wallets/default'),
              headers: {
                HttpHeaders.authorizationHeader: "Bearer " + bearerToken,
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(_body));

      if (response.statusCode == 200) {
        // success, it will return the userMe model, so we can just replace the current userMe
        _userMe = UsersMeModel.fromJson(jsonDecode(response.body));
        await UserSharedPreferences.setUserMe(_userMe);
        return;
      }

      print("Got error <updateDefaultWallet>");
      throw Exception("res=" + response.body);
    } else {
      throw Exception(
          'res={"statusCode":403,"error":"Unauthorized","message":"Empty token"}');
    }
  }

  void _checkJWT() {
    if (_bearerToken.length <= 0) {
      _bearerToken = UserSharedPreferences.getJWT();
    }
  }
}
