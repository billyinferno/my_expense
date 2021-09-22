import 'package:my_expense/model/currency_model.dart';
import 'package:my_expense/model/user_permission_model.dart';
import 'package:my_expense/model/wallet_type_model.dart';

class WalletModel {
  final int id;
  final String name;
  final double startBalance;
  final double changeBalance;
  final bool useForStats;
  final bool enabled;
  final WalletTypeModel walletType;
  final CurrencyModel currency;
  final UserPermissionModel userPermissionUsers;

  WalletModel(
      this.id,
      this.name,
      this.startBalance,
      this.changeBalance,
      this.useForStats,
      this.enabled,
      this.walletType,
      this.currency,
      this.userPermissionUsers);

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    WalletTypeModel _walletType = WalletTypeModel.fromJson(json['wallet_type']);
    CurrencyModel _currency = CurrencyModel.fromJson(json['currency']);
    UserPermissionModel _userPermissionUsers = UserPermissionModel.fromJson(json['users_permissions_user']);

    return WalletModel(
        json['id'],
        json['name'],
        json['startBalance'],
        (json['changeBalance'] ?? 0.00),
        json['useForStats'],
        json['enabled'],
        _walletType,
        _currency,
        _userPermissionUsers
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'startBalance': startBalance,
    'changeBalance': changeBalance,
    'useForStats': useForStats,
    'enabled': enabled,
    'wallet_type': walletType.toJson(),
    'currency': currency.toJson(),
    'users_permissions_user': userPermissionUsers.toJson(),
  };
}