import 'package:my_expense/_index.g.dart';

class WalletModel {
  final int id;
  final String name;
  final double startBalance;
  final double changeBalance;
  final double futureAmount;
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
      this.futureAmount,
      this.useForStats,
      this.enabled,
      this.walletType,
      this.currency,
      this.userPermissionUsers);

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    WalletTypeModel walletType = WalletTypeModel.fromJson(json['wallet_type']);
    CurrencyModel currency = CurrencyModel.fromJson(json['currency']);
    UserPermissionModel userPermissionUsers =
        UserPermissionModel.fromJson(json['users_permissions_user']);

    return WalletModel(
        json['id'],
        json['name'],
        (json['startBalance'] ?? 0).toDouble(),
        (json['changeBalance'] ?? 0).toDouble(),
        (json['futureAmount'] ?? 0).toDouble(),
        json['useForStats'],
        json['enabled'],
        walletType,
        currency,
        userPermissionUsers);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'startBalance': startBalance,
        'changeBalance': changeBalance,
        'futureAmount': futureAmount,
        'useForStats': useForStats,
        'enabled': enabled,
        'wallet_type': walletType.toJson(),
        'currency': currency.toJson(),
        'users_permissions_user': userPermissionUsers.toJson(),
      };
}
