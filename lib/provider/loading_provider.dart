import 'package:flutter/material.dart';

class LoadingProvider extends ChangeNotifier {
  int? totalLoaded;
  int? totalData;
  double? percentage;
  String? loadText;

  void setTotalData(int total) {
    totalData = total;
    notifyListeners();
  }

  void setLoadText({required String text}) {
    loadText = text;
    notifyListeners();
  }

  void resetTotalLoaded() {
    totalLoaded = 0;
    percentage = 0;
    notifyListeners();
  }

  void addTotalLoaded() {
    totalLoaded = (totalLoaded ?? 0) + 1;
    percentage = (totalLoaded ?? 0) / (totalData ?? 1);
    notifyListeners();
  }
}