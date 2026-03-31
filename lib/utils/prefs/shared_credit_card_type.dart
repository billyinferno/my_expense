import 'dart:convert';

import 'package:my_expense/_index.g.dart';

class CreditCardTypeSharedPreferences {
  static const String _creditCardTypeKey = "credit_card_type";

  static Future setCreditCardType({
    required List<CreditCardTypeModel> creditCardType,
  }) async {
    // convert both expense and income into List<String>
    List<String> jsonCreditCardType = [];

    if(creditCardType.isNotEmpty) {
      jsonCreditCardType = creditCardType.map((e) => jsonEncode(e.toJson())).toList();
    }

    await MyBox.putStringList(
      key: _creditCardTypeKey,
      value: jsonCreditCardType
    );
  }

  static List<CreditCardTypeModel> getCreditCardType() {
    List<String>? data = MyBox.getStringList(key: _creditCardTypeKey);

    if(data != null) {
      List<CreditCardTypeModel> creditCardType = data.map((e) => CreditCardTypeModel.fromJson(jsonDecode(e))).toList();
      return creditCardType;
    }
    else {
      return [];
    }
  }
}