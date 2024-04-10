import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:my_expense/model/currency_model.dart';
import 'package:my_expense/model/transaction_list_model.dart';
import 'package:my_expense/model/wallet_model.dart';
import 'package:my_expense/model/wallet_type_model.dart';
import 'package:my_expense/model/worth_model.dart';
import 'package:my_expense/utils/prefs/shared_box.dart';

class WalletSharedPreferences {
  static const _walletKey = "wallet";
  static const _walletTypeKey = "walletType";
  static const _walletCurrencyKey = "walletCurrency";
  static const _walletUserCurrency = "walletUserCurrency";
  static const _walletWorthKey = "walletWorth";

  static Future setWallets(List<WalletModel> wallet) async {
    List<String> data = wallet.map((e) => jsonEncode(e.toJson())).toList();
    if(data.isNotEmpty) {
      await MyBox.putStringList(_walletKey, data);
    }
  }

  static List<WalletModel> getWallets(bool showDisabled) {
    List<String>? data = MyBox.getStringList(_walletKey);

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

  static Future setWalletTypes(List<WalletTypeModel> walletType) async {
    List<String> data = walletType.map((e) => jsonEncode(e.toJson())).toList();
    if(data.isNotEmpty) {
      await MyBox.putStringList(_walletTypeKey, data);
    }
  }

  static List<WalletTypeModel> getWalletTypes() {
    List<String>? data = MyBox.getStringList(_walletTypeKey);

    if(data != null) {
      List<WalletTypeModel> walletType = data.map((e) => WalletTypeModel.fromJson(jsonDecode(e))).toList();
      return walletType;
    }
    else {
      return [];
    }
  }

  static Future setWalletCurrency(List<CurrencyModel> walletCurrency) async {
    List<String> data = walletCurrency.map((e) => jsonEncode(e.toJson())).toList();
    if(data.isNotEmpty) {
      await MyBox.putStringList(_walletCurrencyKey, data);
    }
  }

  static List<CurrencyModel> getWalletCurrency() {
    List<String>? data = MyBox.getStringList(_walletCurrencyKey);

    if(data != null) {
      List<CurrencyModel> currency = data.map((e) => CurrencyModel.fromJson(jsonDecode(e))).toList();
      return currency;
    }
    else {
      return [];
    }
  }

  static Future<void> setWalletUserCurrency(List<CurrencyModel> currencies) async {
    List<String> data = currencies.map((e) => jsonEncode(e.toJson())).toList();
    if(data.isNotEmpty) {
      await MyBox.putStringList(_walletUserCurrency, data);
    }
  }

  static List<CurrencyModel> getWalletUserCurrency() {
    List<String>? data = MyBox.getStringList(_walletUserCurrency);

    if(data != null) {
      List<CurrencyModel> currency = data.map((e) => CurrencyModel.fromJson(jsonDecode(e))).toList();
      return currency;
    }
    else {
      return [];
    }
  }

  static Future setWalletWorth(String dateTo, List<WorthModel> walletWorth) async {
    List<String> data = walletWorth.map((e) => jsonEncode(e.toJson())).toList();
    if(data.isNotEmpty) {
      await MyBox.putStringList("${_walletWorthKey}_$dateTo", data);
    }
  }

  static List<WorthModel> getWalletWorth(String dateTo) {
    List<String>? data = MyBox.getStringList("${_walletWorthKey}_$dateTo");

    if(data != null) {
      List<WorthModel> walletWorth = data.map((e) => WorthModel.fromJson(jsonDecode(e))).toList();
      return walletWorth;
    }
    else {
      return [];
    }
  }

  static Future<void> addWalletWorth(TransactionListModel txn) async {
    // get the date of the transaction
    String dateTo = DateFormat('yyyy-MM-dd').format(txn.date.toLocal());
    List<WorthModel> worth = getWalletWorth(dateTo);
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
      await setWalletWorth(dateTo, worth);
    }
  }

  static Future<void> deleteWalletWorth(TransactionListModel txn) async {
    // get the date of the transaction
    String dateTo = DateFormat('yyyy-MM-dd').format(txn.date.toLocal());
    List<WorthModel> worth = getWalletWorth(dateTo);
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
      await setWalletWorth(dateTo, worth);
    }
  }
}