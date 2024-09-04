import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:my_expense/_index.g.dart';

class IconColorList {
  static Icon getExpenseIcon(String name, [double? size]) {
    double currentSize = (size ?? 20);
    String iconName = name.toLowerCase().trim().replaceAll(RegExp('${String.fromCharCode(160)}+'), ' ');

    switch(iconName) {
      case "auto":
        return Icon(FontAwesomeIcons.car, color: textColor, size: currentSize,);
      case "bank charge":
        return Icon(FontAwesomeIcons.fileInvoiceDollar, color: textColor, size: currentSize);
      case "cash":
        return Icon(FontAwesomeIcons.moneyBill, color: textColor, size: currentSize);
      case "charity":
        return Icon(FontAwesomeIcons.circleDollarToSlot, color: textColor, size: currentSize);
      case "childcare":
        return Icon(FontAwesomeIcons.baby, color: textColor, size: currentSize);
      case "clothing":
        return Icon(FontAwesomeIcons.shirt, color: textColor, size: currentSize);
      case "credit card":
        return Icon(FontAwesomeIcons.solidCreditCard, color: textColor, size: currentSize);
      case "dining":
        return Icon(FontAwesomeIcons.utensils, color: textColor, size: currentSize);
      case "eating out": 
        return Icon(FontAwesomeIcons.utensils, color: textColor, size: currentSize);
      case "education":
        return Icon(FontAwesomeIcons.school, color: textColor, size: currentSize);
      case "entertainment":
        return Icon(FontAwesomeIcons.champagneGlasses, color: textColor, size: currentSize);
      case "gifts":
        return Icon(FontAwesomeIcons.gift, color: textColor, size: currentSize);
      case "groceries":
        return Icon(FontAwesomeIcons.basketShopping, color: textColor, size: currentSize);
      case "grooming":
        return Icon(FontAwesomeIcons.scissors, color: textColor, size: currentSize);
      case "health":
        return Icon(FontAwesomeIcons.suitcaseMedical, color: textColor, size: currentSize);
      case "holiday":
        return Icon(FontAwesomeIcons.plane, color: textColor, size: currentSize);
      case "home repair":
        return Icon(FontAwesomeIcons.hammer, color: textColor, size: currentSize);
      case "household":
        return Icon(FontAwesomeIcons.toiletPaper, color: textColor, size: currentSize);
      case "insurance":
        return Icon(FontAwesomeIcons.carBurst, color: textColor, size: currentSize);
      case "investment":
        return Icon(FontAwesomeIcons.scaleUnbalanced, color: textColor, size: currentSize);
      case "loan":
        return Icon(FontAwesomeIcons.moneyCheck, color: textColor, size: currentSize);
      case "medical":
        return Icon(FontAwesomeIcons.capsules, color: textColor, size: currentSize);
      case "misc":
        return Icon(FontAwesomeIcons.box, color: textColor, size: currentSize);
      case "mortgage":
        return Icon(FontAwesomeIcons.house, color: textColor, size: currentSize);
      case "others":
        return Icon(FontAwesomeIcons.dollarSign, color: textColor, size: currentSize);
      case "pets":
        return Icon(FontAwesomeIcons.dog, color: textColor, size: currentSize);
      case "rent":
        return Icon(FontAwesomeIcons.houseUser, color: textColor, size: currentSize);
      case "tax":
        return Icon(FontAwesomeIcons.fileInvoice, color: textColor, size: currentSize);
      case "transport":
        return Icon(FontAwesomeIcons.bus, color: textColor, size: currentSize);
      case "travel":
        return Icon(FontAwesomeIcons.earthAsia, color: textColor, size: currentSize);
      case "utilities":
        return Icon(FontAwesomeIcons.solidLightbulb, color: textColor, size: currentSize);
      case "utilities: cable tv":
        return Icon(FontAwesomeIcons.tv, color: textColor, size: currentSize);
      case "utilities: garbage":
        return Icon(FontAwesomeIcons.solidTrashCan, color: textColor, size: currentSize);
      case "utilities: gas & electric":
        return Icon(FontAwesomeIcons.chargingStation, color: textColor, size: currentSize);
      case "utilities: internet":
        return Icon(FontAwesomeIcons.wifi, color: textColor, size: currentSize);
      case "utilities: telephone":
        return Icon(FontAwesomeIcons.mobileScreenButton, color: textColor, size: currentSize);
      case "utilities: water":
        return Icon(FontAwesomeIcons.shower, color: textColor, size: currentSize);
      default:
        return Icon(FontAwesomeIcons.dollarSign, color: textColor, size: currentSize);
    }
  }

  static Color getExpenseColor(String name) {
    String iconName = name.toLowerCase().trim().replaceAll(RegExp('${String.fromCharCode(160)}+'), ' ');
    switch (iconName) {
      case "auto": { return accentColors[2].darken(amount: 0.2); }
      case "bank charge": { return accentColors[2].darken(amount: 0.19); }
      case "cash": { return accentColors[2].darken(amount: 0.18); }
      case "charity": { return accentColors[2].darken(amount: 0.17); }
      case "childcare": { return accentColors[2].darken(amount: 0.16); }
      case "clothing": { return accentColors[2].darken(amount: 0.14); }
      case "credit card": { return accentColors[2].darken(amount: 0.13); }
      case "dining": { return accentColors[2].darken(amount: 0.12); }
      case "eating out": { return accentColors[2].darken(amount: 0.11); }
      case "education": { return accentColors[2].darken(amount: 0.1); }
      case "entertainment": { return accentColors[2].darken(amount: 0.09); }
      case "gifts": { return accentColors[2].darken(amount: 0.08); }
      case "groceries": { return accentColors[2].darken(amount: 0.07); }
      case "grooming": { return accentColors[2].darken(amount: 0.06); }
      case "health": { return accentColors[2].darken(amount: 0.04); }
      case "holiday": { return accentColors[2].darken(amount: 0.03); }
      case "home repair": { return accentColors[2].darken(amount: 0.02); }
      case "household": { return accentColors[2].darken(amount: 0.01); }
      case "insurance": { return accentColors[2]; }
      case "investment": { return accentColors[2].lighten(amount: 0.01); }
      case "loan": { return accentColors[2].lighten(amount: 0.02); }
      case "medical": { return accentColors[2].lighten(amount: 0.03); }
      case "misc": { return accentColors[2].lighten(amount: 0.04); }
      case "mortgage": { return accentColors[2].lighten(amount: 0.06); }
      case "others": { return accentColors[2].lighten(amount: 0.07); }
      case "pets": { return accentColors[2].lighten(amount: 0.08); }
      case "rent": { return accentColors[2].lighten(amount: 0.09); }
      case "tax": { return accentColors[2].lighten(amount: 0.1); }
      case "transport": { return accentColors[2].lighten(amount: 0.11); }
      case "travel": { return accentColors[2].lighten(amount: 0.12); }
      case "utilities": { return accentColors[2].lighten(amount: 0.13); }
      case "utilities: cable tv": { return accentColors[2].lighten(amount: 0.14); }
      case "utilities: garbage": { return accentColors[2].lighten(amount: 0.16); }
      case "utilities: gas & electric": { return accentColors[2].lighten(amount: 0.17); }
      case "utilities: internet": { return accentColors[2].lighten(amount: 0.18); }
      case "utilities: telephone": { return accentColors[2].lighten(amount: 0.19); }
      case "utilities: water": { return accentColors[2].lighten(amount: 0.2); }
      default: { return accentColors[2]; }
    }
  }

  static Icon getIncomeIcon(String name, [double? size]) {
    double currentSize = (size ?? 20);
    String iconName = name.toLowerCase().trim().replaceAll(RegExp('${String.fromCharCode(160)}+'), ' ');
    switch(iconName) {
      case "bonus": { return Icon(FontAwesomeIcons.gift, color: textColor, size: currentSize); }
      case "investment": { return Icon(FontAwesomeIcons.scaleUnbalancedFlip, color: textColor, size: currentSize); }
      case "loan payment": { return Icon(FontAwesomeIcons.fileInvoiceDollar, color: textColor, size: currentSize); }
      case "misc": { return Icon(FontAwesomeIcons.box, color: textColor, size: currentSize); }
      case "others": { return Icon(FontAwesomeIcons.dollarSign, color: textColor, size: currentSize); }
      case "salary": { return Icon(FontAwesomeIcons.moneyCheckDollar, color: textColor, size: currentSize); }
      case "deposit": { return Icon(FontAwesomeIcons.moneyCheck, color: textColor, size: currentSize); }
      case "tax refund": { return Icon(FontAwesomeIcons.fileInvoice, color: textColor, size: currentSize); }
      default: { return Icon(FontAwesomeIcons.dollarSign, color: textColor, size: currentSize); }
    }
  }

  static Color getIncomeColor(String name) {
    String iconName = name.toLowerCase().trim().replaceAll(RegExp('${String.fromCharCode(160)}+'), ' ');
    switch (iconName) {
      case "bonus": { return accentColors[0].darken(amount: 0.15); }
      case "investment": { return accentColors[0].darken(amount: 0.1); }
      case "loan payment": { return accentColors[0].darken(amount: 0.05); }
      case "misc": { return accentColors[0]; }
      case "others": { return accentColors[0].darken(amount: 0.05); }
      case "salary": { return accentColors[0].darken(amount: 0.1); }
      case "deposit": { return accentColors[0].darken(amount: 0.15); }
      case "tax refund": { return accentColors[0].darken(amount: 0.2); }
      default: { return accentColors[0]; }
    }
  }

  static Icon getIcon(String name, String type, [double? size]) {
    if (type == "expense") {
      return getExpenseIcon(name, (size ?? 20));
    }
    else {
      return getIncomeIcon(name, (size ?? 20));
    }
  }

  static Color getColor(String name, String type) {
    if (type == "expense") {
      return getExpenseColor(name);
    }
    else {
      return getIncomeColor(name);
    }
  }
}