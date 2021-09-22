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
    List<String> _data = wallet.map((e) => jsonEncode(e.toJson())).toList();
    if(_data.length > 0) {
      await MyBox.putStringList(_walletKey, _data);
      // await _pref!.setStringList(_walletKey, _data);
    }
  }

  static List<WalletModel> getWallets(bool showDisabled) {
    List<String>? _data = MyBox.getStringList(_walletKey);
    // List<String>? _data = _pref!.getStringList(_walletKey);

    if(_data != null) {
      List<WalletModel> _wallet = _data.map((e) => WalletModel.fromJson(jsonDecode(e))).toList();
      if(showDisabled) {
        return _wallet;
      }
      else {
        List<WalletModel> _resultWallet = [];
        for (int i = 0; i < _wallet.length; i++) {
          if (_wallet[i].enabled) {
            _resultWallet.add(_wallet[i]);
          }
        }
        // return only the enabled wallet
        return _resultWallet;
      }
    }
    else {
      return [];
    }
  }

  static Future setWalletTypes(List<WalletTypeModel> walletType) async {
    List<String> _data = walletType.map((e) => jsonEncode(e.toJson())).toList();
    if(_data.length > 0) {
      await MyBox.putStringList(_walletTypeKey, _data);
      // await _pref!.setStringList(_walletTypeKey, _data);
    }
  }

  static List<WalletTypeModel> getWalletTypes() {
    List<String>? _data = MyBox.getStringList(_walletTypeKey);
    // List<String>? _data = _pref!.getStringList(_walletTypeKey);

    if(_data != null) {
      List<WalletTypeModel> _walletType = _data.map((e) => WalletTypeModel.fromJson(jsonDecode(e))).toList();
      return _walletType;
    }
    else {
      return [];
    }
  }

  static Future setWalletCurrency(List<CurrencyModel> walletCurrency) async {
    List<String> _data = walletCurrency.map((e) => jsonEncode(e.toJson())).toList();
    if(_data.length > 0) {
      await MyBox.putStringList(_walletCurrencyKey, _data);
      // await _pref!.setStringList(_walletCurrencyKey, _data);
    }
  }

  static List<CurrencyModel> getWalletCurrency() {
    List<String>? _data = MyBox.getStringList(_walletCurrencyKey);
    // List<String>? _data = _pref!.getStringList(_walletCurrencyKey);

    if(_data != null) {
      List<CurrencyModel> _currency = _data.map((e) => CurrencyModel.fromJson(jsonDecode(e))).toList();
      return _currency;
    }
    else {
      return [];
    }
  }

  static Future<void> setWalletUserCurrency(List<CurrencyModel> currencies) async {
    List<String> _data = currencies.map((e) => jsonEncode(e.toJson())).toList();
    if(_data.length > 0) {
      await MyBox.putStringList(_walletUserCurrency, _data);
      // await _pref!.setStringList(_walletUserCurrency, _data);
    }
  }

  static List<CurrencyModel> getWalletUserCurrency() {
    
    List<String>? _data = MyBox.getStringList(_walletUserCurrency);
    // List<String>? _data = _pref!.getStringList(_walletUserCurrency);

    if(_data != null) {
      List<CurrencyModel> _currency = _data.map((e) => CurrencyModel.fromJson(jsonDecode(e))).toList();
      return _currency;
    }
    else {
      return [];
    }
  }

  static Future setWalletWorth(String dateTo, List<WorthModel> walletWorth) async {
    List<String> _data = walletWorth.map((e) => jsonEncode(e.toJson())).toList();
    if(_data.length > 0) {
      await MyBox.putStringList(_walletWorthKey + "_" + dateTo, _data);
    }
  }

  static List<WorthModel> getWalletWorth(String dateTo) {
    List<String>? _data = MyBox.getStringList(_walletWorthKey + "_" + dateTo);

    if(_data != null) {
      List<WorthModel> _walletWorth = _data.map((e) => WorthModel.fromJson(jsonDecode(e))).toList();
      return _walletWorth;
    }
    else {
      return [];
    }
  }

  static Future<void> addWalletWorth(TransactionListModel txn) async {
    // get the date of the transaction
    String _dateTo = DateFormat('yyyy-MM-dd').format(txn.date.toLocal());
    List<WorthModel> _worth = getWalletWorth(_dateTo);
    double _amount = 0.0;
    double _amountTo = 0.0;

    switch(txn.type) {
      case "expense":
        // by right it should only have fromWallet
        _amount = txn.amount * (-1);
        break;
      case "income":
        // by right it should only have fromWallet
        _amount = txn.amount;
        break;
      default:
        // should have both wallet from and to
        _amount = txn.amount * (-1);
        _amountTo = txn.amount * txn.exchangeRate;
        break;
    }

    if(_worth.length > 0) {
      for(int i=0; i<_worth.length; i++) {
        if(_worth[i].currenciesId == txn.wallet.currencyId) {
          // add this amount to the _worth
          _worth[i] = WorthModel(
            currenciesId: _worth[i].currenciesId,
            currenciesName: _worth[i].currenciesName,
            currenciesDescription: _worth[i].currenciesDescription,
            currenciesSymbol: _worth[i].currenciesSymbol,
            walletsStartBalance: _worth[i].walletsStartBalance,
            walletsChangesAmount: _worth[i].walletsChangesAmount + _amount
          );
        }
        // if wallet to is not null, it means that this is transfer
        // so we need to add the worth
        if(txn.walletTo != null) {
          if(txn.walletTo!.id == _worth[i].currenciesId) {
            // add this amount to the _worth
            _worth[i] = WorthModel(
              currenciesId: _worth[i].currenciesId,
              currenciesName: _worth[i].currenciesName,
              currenciesDescription: _worth[i].currenciesDescription,
              currenciesSymbol: _worth[i].currenciesSymbol,
              walletsStartBalance: _worth[i].walletsStartBalance,
              walletsChangesAmount: _worth[i].walletsChangesAmount + _amountTo
            );
          }
        }
      }

      // set the wallet net worth
      await setWalletWorth(_dateTo, _worth);
    }
  }

  static Future<void> deleteWalletWorth(TransactionListModel txn) async {
    // get the date of the transaction
    String _dateTo = DateFormat('yyyy-MM-dd').format(txn.date.toLocal());
    List<WorthModel> _worth = getWalletWorth(_dateTo);
    double _amount = 0.0;
    double _amountTo = 0.0;

    switch(txn.type) {
      case "expense":
        // by right it should only have fromWallet
        _amount = txn.amount;
        break;
      case "income":
        // by right it should only have fromWallet
        _amount = txn.amount * (-1);
        break;
      default:
        // should have both wallet from and to
        _amount = txn.amount;
        _amountTo = txn.amount * txn.exchangeRate * (-1);
        break;
    }

    if(_worth.length > 0) {
      for(int i=0; i<_worth.length; i++) {
        if(_worth[i].currenciesId == txn.wallet.currencyId) {
          // add this amount to the _worth
          _worth[i] = WorthModel(
            currenciesId: _worth[i].currenciesId,
            currenciesName: _worth[i].currenciesName,
            currenciesDescription: _worth[i].currenciesDescription,
            currenciesSymbol: _worth[i].currenciesSymbol,
            walletsStartBalance: _worth[i].walletsStartBalance,
            walletsChangesAmount: _worth[i].walletsChangesAmount + _amount
          );
        }
        // if wallet to is not null, it means that this is transfer
        // so we need to add the worth
        if(txn.walletTo != null) {
          if(txn.walletTo!.id == _worth[i].currenciesId) {
            // add this amount to the _worth
            _worth[i] = WorthModel(
              currenciesId: _worth[i].currenciesId,
              currenciesName: _worth[i].currenciesName,
              currenciesDescription: _worth[i].currenciesDescription,
              currenciesSymbol: _worth[i].currenciesSymbol,
              walletsStartBalance: _worth[i].walletsStartBalance,
              walletsChangesAmount: _worth[i].walletsChangesAmount + _amountTo
            );
          }
        }
      }

      // set the wallet net worth
      await setWalletWorth(_dateTo, _worth);
    }
  }
}