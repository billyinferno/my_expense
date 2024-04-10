class PinModel {
    PinModel({ this.hashKey, this.hashPin });

    final String? hashKey;
    final String? hashPin;

    factory PinModel.fromJson(Map<String, dynamic> json) => PinModel(
        hashKey: json["hashKey"],
        hashPin: json["hashPin"],
    );

    Map<String, dynamic> toJson() => {
        "hashKey": (hashKey),
        "hashPin": (hashPin),
    };
}