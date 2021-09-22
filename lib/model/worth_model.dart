class WorthModel {
    final int currenciesId;
    final String currenciesName;
    final String currenciesSymbol;
    final String currenciesDescription;
    final double walletsStartBalance;
    final double walletsChangesAmount;

    WorthModel({
        required this.currenciesId,
        required this.currenciesName,
        required this.currenciesSymbol,
        required this.currenciesDescription,
        required this.walletsStartBalance,
        required this.walletsChangesAmount,
    });

    factory WorthModel.fromJson(Map<String, dynamic> json) => WorthModel(
        currenciesId: json["currencies_id"],
        currenciesName: json["currencies_name"],
        currenciesSymbol: json["currencies_symbol"],
        currenciesDescription: json["currencies_description"],
        walletsStartBalance: json["wallets_start_balance"].toDouble(),
        walletsChangesAmount: json["wallets_changes_amount"].toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "currencies_id": currenciesId,
        "currencies_name": currenciesName,
        "currencies_symbol": currenciesSymbol,
        "currencies_description": currenciesDescription,
        "wallets_start_balance": walletsStartBalance,
        "wallets_changes_amount": walletsChangesAmount,
    };
}