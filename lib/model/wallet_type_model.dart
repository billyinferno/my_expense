class WalletTypeModel {
  final int id;
  final String type;

  WalletTypeModel(this.id, this.type);

  factory WalletTypeModel.fromJson(Map<String, dynamic> json) {
    return WalletTypeModel(json['id'], json['type']);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
  };
}