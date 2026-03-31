import 'dart:convert';

import 'package:my_expense/_index.g.dart';

class CreditCardTypeHTTPService {
  Future<void> fetchCreditCardType({
    bool force = false
  }) async {
    if (!force) {
      // check whether we have data on shared preferences or not?
      List<CreditCardTypeModel> creditCardTypePref =
          CreditCardTypeSharedPreferences.getCreditCardType();

      // check if we got data there or not?
      if (creditCardTypePref.isNotEmpty) {
        return;
      }
    }

    // send request to API
    final String result = await NetUtils.get(
      url: '${Globals.apiURL}credit-card-types',
    ).onError((error, stackTrace) {
      Log.error(
        message: 'Error on fetchCreditCardTypes',
        error: error,
        stackTrace: stackTrace,
      );
      throw error as NetException;
    });

    // parse the credit card type data
    List<dynamic> jsonData = jsonDecode(result);
    List<CreditCardTypeModel> creditCardTypeList =
        jsonData.map((e) => CreditCardTypeModel.fromJson(e)).toList();

    // saved the expense and income category model
    CreditCardTypeSharedPreferences.setCreditCardType(
      creditCardType: creditCardTypeList
    );
  }
}