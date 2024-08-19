import 'dart:convert';
import 'package:my_expense/_index.g.dart';

ErrorModel parseErrorMessage(String errorMessage) {
  // first check if we got string "res=" inside of it or not?
  int resLoc = errorMessage.indexOf("res=");
  if(resLoc > 0) {
    // get the string from there until end
    String actualErrorString = errorMessage.substring(resLoc+4);

    // decode the error message to JSON
    ErrorModel errModel = ErrorModel.fromJson(jsonDecode(actualErrorString));
    return errModel;
  }
  ErrorModel invalidErrorMessage = ErrorModel(-1, "Error", errorMessage);
  return invalidErrorMessage;
}