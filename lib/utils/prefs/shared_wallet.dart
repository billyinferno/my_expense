import 'dart:convert';
import 'package:my_expense/_index.g.dart';

class WalletSharedPreferences {
  static const _walletKey = "wallet";
  static const _walletTypeKey = "walletType";
  static const _walletCurrencyKey = "walletCurrency";
  static const _walletUserCurrency = "walletUserCurrency";
  static const _walletWorthKey = "walletWorth";

  static Future setWallets({required List<WalletModel> wallet}) async {
    List<String> data = wallet.map((e) => jsonEncode(e.toJson())).toList();
    if(data.isNotEmpty) {
      await MyBox.putStringList(key: _walletKey, value: data);
    }
  }

  static List<WalletModel> getWallets({required bool showDisabled}) {
    List<String>? data = MyBox.getStringList(key: _walletKey);

    if(data != null) {
      List<WalletModel> wallet = data.map((e) => WalletModel.fromJson(jsonDecode(e))).toList();
      if(showDisabled) {
        return wallet;
      }
      else {
        List<WalletModel> resultWallet = [];
        for (int i = 0; i < wallet.length; i++) {
          if (wallet[i].enabled) {
            resultWallet.add(wallet[i]);
          }
        }
        // return only the enabled wallet
        return resultWallet;
      }
    }
    else {
      return [];
    }
  }

  static Future setWalletTypes({required List<WalletTypeModel> walletType}) async {
    List<String> data = walletType.map((e) => jsonEncode(e.toJson())).toList();
    if(data.isNotEmpty) {
      await MyBox.putStringList(key: _walletTypeKey, value: data);
    }
  }

  static List<WalletTypeModel> getWalletTypes() {
    List<String>? data = MyBox.getStringList(key: _walletTypeKey);

    if(data != null) {
      List<WalletTypeModel> walletType = data.map((e) => WalletTypeModel.fromJson(jsonDecode(e))).toList();
      return walletType;
    }
    else {
      return [];
    }
  }

  static Future setWalletCurrency({required List<CurrencyModel> walletCurrency}) async {
    List<String> data = walletCurrency.map((e) => jsonEncode(e.toJson())).toList();
    if(data.isNotEmpty) {
      await MyBox.putStringList(key: _walletCurrencyKey, value: data);
    }
  }

  static List<CurrencyModel> getWalletCurrency() {
    List<String>? data = MyBox.getStringList(key: _walletCurrencyKey);

    if(data != null) {
      List<CurrencyModel> currency = data.map((e) => CurrencyModel.fromJson(jsonDecode(e))).toList();
      return currency;
    }
    else {
      return [];
    }
  }

  static Map<String, CurrencyModel> getMapWalletCurrency() {
    List<String>? data = MyBox.getStringList(key: _walletCurrencyKey);

    if(data != null) {
      List<CurrencyModel> currencies = data.map((e) => CurrencyModel.fromJson(jsonDecode(e))).toList();
      
      // loop thru currency and generate map
      Map<String, CurrencyModel> currenciesMap = {};
      for(CurrencyModel ccy in currencies) {
        currenciesMap[ccy.name] = ccy;
      }

      return currenciesMap;
    }
    else {
      return {};
    }
  }

  static Map<int, CurrencyModel> getMapWalletCurrencyID() {
    List<String>? data = MyBox.getStringList(key: _walletCurrencyKey);

    if(data != null) {
      List<CurrencyModel> currencies = data.map((e) => CurrencyModel.fromJson(jsonDecode(e))).toList();
      
      // loop thru currency and generate map
      Map<int, CurrencyModel> currenciesMap = {};
      for(CurrencyModel ccy in currencies) {
        currenciesMap[ccy.id] = ccy;
      }

      return currenciesMap;
    }
    else {
      return {};
    }
  }

  static Future<void> setWalletUserCurrency({required List<CurrencyModel> currencies}) async {
    List<String> data = currencies.map((e) => jsonEncode(e.toJson())).toList();
    if(data.isNotEmpty) {
      await MyBox.putStringList(key: _walletUserCurrency, value: data);
    }
  }

  static List<CurrencyModel> getWalletUserCurrency() {
    List<String>? data = MyBox.getStringList(key: _walletUserCurrency);

    if(data != null) {
      List<CurrencyModel> currency = data.map((e) => CurrencyModel.fromJson(jsonDecode(e))).toList();
      return currency;
    }
    else {
      return [];
    }
  }

  static Future setWalletWorth({
    required String dateTo,
    required List<WorthModel> walletWorth
  }) async {
    List<String> data = walletWorth.map((e) => jsonEncode(e.toJson())).toList();
    if(data.isNotEmpty) {
      await MyBox.putStringList(key: "${_walletWorthKey}_$dateTo", value: data);
    }
  }

  static List<WorthModel> getWalletWorth({required String dateTo}) {
    List<String>? data = MyBox.getStringList(key: "${_walletWorthKey}_$dateTo");

    if(data != null) {
      List<WorthModel> walletWorth = data.map((e) => WorthModel.fromJson(jsonDecode(e))).toList();
      return walletWorth;
    }
    else {
      return [];
    }
  }

  static Future<void> addWalletWorth({required TransactionListModel txn}) async {
    // get the date of the transaction
    String dateTo = Globals.dfyyyyMMdd.formatLocal(txn.date);
    List<WorthModel> worth = getWalletWorth(dateTo: dateTo);
    double amount = 0.0;
    double amountTo = 0.0;

    switch(txn.type) {
      case "expense":
        // by right it should only have fromWallet
        amount = txn.amount * (-1);
        break;
      case "income":
        // by right it should only have fromWallet
        amount = txn.amount;
        break;
      default:
        // should have both wallet from and to
        amount = txn.amount * (-1);
        amountTo = txn.amount * txn.exchangeRate;
        break;
    }

    if(worth.isNotEmpty) {
      for(int i=0; i<worth.length; i++) {
        if(worth[i].currenciesId == txn.wallet.currencyId) {
          // add this amount to the _worth
          worth[i] = WorthModel(
            currenciesId: worth[i].currenciesId,
            currenciesName: worth[i].currenciesName,
            currenciesDescription: worth[i].currenciesDescription,
            currenciesSymbol: worth[i].currenciesSymbol,
            walletsStartBalance: worth[i].walletsStartBalance,
            walletsChangesAmount: worth[i].walletsChangesAmount + amount
          );
        }
        // if wallet to is not null, it means that this is transfer
        // so we need to add the worth
        if(txn.walletTo != null) {
          if(txn.walletTo!.id == worth[i].currenciesId) {
            // add this amount to the _worth
            worth[i] = WorthModel(
              currenciesId: worth[i].currenciesId,
              currenciesName: worth[i].currenciesName,
              currenciesDescription: worth[i].currenciesDescription,
              currenciesSymbol: worth[i].currenciesSymbol,
              walletsStartBalance: worth[i].walletsStartBalance,
              walletsChangesAmount: worth[i].walletsChangesAmount + amountTo
            );
          }
        }
      }

      // set the wallet net worth
      await setWalletWorth(dateTo: dateTo, walletWorth: worth);
    }
  }

  static Future<void> deleteWalletWorth({required TransactionListModel txn}) async {
    // get the date of the transaction
    String dateTo = Globals.dfyyyyMMdd.formatLocal(txn.date);
    List<WorthModel> worth = getWalletWorth(dateTo: dateTo);
    double amount = 0.0;
    double amountTo = 0.0;

    switch(txn.type) {
      case "expense":
        // by right it should only have fromWallet
        amount = txn.amount;
        break;
      case "income":
        // by right it should only have fromWallet
        amount = txn.amount * (-1);
        break;
      default:
        // should have both wallet from and to
        amount = txn.amount;
        amountTo = txn.amount * txn.exchangeRate * (-1);
        break;
    }

    if(worth.isNotEmpty) {
      for(int i=0; i<worth.length; i++) {
        if(worth[i].currenciesId == txn.wallet.currencyId) {
          // add this amount to the _worth
          worth[i] = WorthModel(
            currenciesId: worth[i].currenciesId,
            currenciesName: worth[i].currenciesName,
            currenciesDescription: worth[i].currenciesDescription,
            currenciesSymbol: worth[i].currenciesSymbol,
            walletsStartBalance: worth[i].walletsStartBalance,
            walletsChangesAmount: worth[i].walletsChangesAmount + amount
          );
        }
        // if wallet to is not null, it means that this is transfer
        // so we need to add the worth
        if(txn.walletTo != null) {
          if(txn.walletTo!.id == worth[i].currenciesId) {
            // add this amount to the _worth
            worth[i] = WorthModel(
              currenciesId: worth[i].currenciesId,
              currenciesName: worth[i].currenciesName,
              currenciesDescription: worth[i].currenciesDescription,
              currenciesSymbol: worth[i].currenciesSymbol,
              walletsStartBalance: worth[i].walletsStartBalance,
              walletsChangesAmount: worth[i].walletsChangesAmount + amountTo
            );
          }
        }
      }

      // set the wallet net worth
      await setWalletWorth(dateTo: dateTo, walletWorth: worth);
    }
  }
}