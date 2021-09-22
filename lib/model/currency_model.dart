class CurrencyModel {
  final int id;
  final String name;
  final String description;
  final String symbol;

  CurrencyModel(this.id, this.name, this.description, this.symbol);

  CurrencyModel.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        description = json['description'],
        symbol = json['symbol']
  ;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'symbol': symbol
  };
}