class ErrorModel {
  final int statusCode;
  final String error;
  final String message;

  ErrorModel(this.statusCode, this.error, this.message);

  factory ErrorModel.fromJson(Map<String, dynamic> json) {
    return ErrorModel(
        json['statusCode'],
        json['error'],
        json['message'].toString()
    );
  }

  Map<String, dynamic> toJson() => {
    'statusCode': statusCode,
    'error': error,
    'message': message
  };
}