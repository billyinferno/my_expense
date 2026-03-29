import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:my_expense/_index.g.dart';

class MyExpenseIconData {
  final IconData iconData;
  final double offset;

  MyExpenseIconData({required this.iconData, this.offset = 0});
}

class IconColorList {
  static final Map<String, MyExpenseIconData> expenseIcons = {
    "auto": MyExpenseIconData(iconData: FontAwesomeIcons.car.data, offset: 0.2),
    "bank charge": MyExpenseIconData(iconData: FontAwesomeIcons.fileInvoiceDollar.data, offset: 0.19),
    "cash": MyExpenseIconData(iconData: FontAwesomeIcons.moneyBill.data, offset: 0.18),
    "charity": MyExpenseIconData(iconData: FontAwesomeIcons.circleDollarToSlot.data, offset: 0.17),
    "childcare": MyExpenseIconData(iconData: FontAwesomeIcons.baby.data, offset: 0.16),
    "clothing": MyExpenseIconData(iconData: FontAwesomeIcons.shirt.data, offset: 0.14),
    "credit card": MyExpenseIconData(iconData: FontAwesomeIcons.solidCreditCard.data, offset: 0.13),
    "dining": MyExpenseIconData(iconData: FontAwesomeIcons.utensils.data, offset: 0.12),
    "eating out": MyExpenseIconData(iconData: FontAwesomeIcons.utensils.data, offset: 0.11),
    "education": MyExpenseIconData(iconData: FontAwesomeIcons.school.data, offset: 0.1),
    "entertainment": MyExpenseIconData(iconData: FontAwesomeIcons.champagneGlasses.data, offset: 0.09),
    "gifts": MyExpenseIconData(iconData: FontAwesomeIcons.gift.data, offset: 0.08),
    "groceries": MyExpenseIconData(iconData: FontAwesomeIcons.basketShopping.data, offset: 0.07),
    "grooming": MyExpenseIconData(iconData: FontAwesomeIcons.scissors.data, offset: 0.06),
    "health": MyExpenseIconData(iconData: FontAwesomeIcons.suitcaseMedical.data, offset: 0.04),
    "holiday": MyExpenseIconData(iconData: FontAwesomeIcons.plane.data, offset: 0.03),
    "home repair": MyExpenseIconData(iconData: FontAwesomeIcons.hammer.data, offset: 0.02),
    "household": MyExpenseIconData(iconData: FontAwesomeIcons.toiletPaper.data, offset: 0.01),
    "insurance": MyExpenseIconData(iconData: FontAwesomeIcons.carBurst.data, offset: 0),
    "investment": MyExpenseIconData(iconData: FontAwesomeIcons.scaleUnbalanced.data, offset: -0.01),
    "loan": MyExpenseIconData(iconData: FontAwesomeIcons.moneyCheck.data, offset: -0.02),
    "medical": MyExpenseIconData(iconData: FontAwesomeIcons.capsules.data, offset: -0.03),
    "misc": MyExpenseIconData(iconData: FontAwesomeIcons.box.data, offset: -0.04),
    "mortgage": MyExpenseIconData(iconData: FontAwesomeIcons.house.data, offset: -0.06),
    "others": MyExpenseIconData(iconData: FontAwesomeIcons.dollarSign.data, offset: -0.07),
    "pets": MyExpenseIconData(iconData: FontAwesomeIcons.dog.data, offset: -0.08),
    "rent": MyExpenseIconData(iconData: FontAwesomeIcons.houseUser.data, offset: -0.09),
    "tax": MyExpenseIconData(iconData: FontAwesomeIcons.fileInvoice.data, offset  : -0.1),
    "transport": MyExpenseIconData(iconData: FontAwesomeIcons.bus.data, offset: -0.11),
    "travel": MyExpenseIconData(iconData: FontAwesomeIcons.earthAsia.data, offset: -0.12),
    "utilities": MyExpenseIconData(iconData: FontAwesomeIcons.solidLightbulb.data, offset: -0.13),
    "utilities: cable tv": MyExpenseIconData(iconData: FontAwesomeIcons.tv.data, offset: -0.14),
    "utilities: garbage": MyExpenseIconData(iconData: FontAwesomeIcons.solidTrashCan.data, offset: -0.16),
    "utilities: gas & electric": MyExpenseIconData(iconData: FontAwesomeIcons.chargingStation.data, offset: -0.17),
    "utilities: internet": MyExpenseIconData(iconData: FontAwesomeIcons.wifi.data, offset: -0.18),
    "utilities: telephone": MyExpenseIconData(iconData: FontAwesomeIcons.mobileScreenButton.data, offset: -0.19),
    "utilities: water": MyExpenseIconData(iconData: FontAwesomeIcons.shower.data, offset: -0.2),
  };

  static Icon getExpenseIcon(String name, [double? size, Color? color]) {
    double currentSize = (size ?? 20);
    Color currentColor = (color ?? textColor);
    String iconName = name.toLowerCase().trim().replaceAll(RegExp('${String.fromCharCode(160)}+'), ' ');

    MyExpenseIconData? iconData = expenseIcons[iconName];
    if (iconData != null) {
      return Icon(iconData.iconData, color: currentColor, size: currentSize);
    }
    return Icon(FontAwesomeIcons.dollarSign.data, color: currentColor, size: currentSize);
  }

  static Color getExpenseColor(String name) {
    String iconName = name.toLowerCase().trim().replaceAll(RegExp('${String.fromCharCode(160)}+'), ' ');
    MyExpenseIconData? iconData = expenseIcons[iconName];
    double offset = 0;
    
    // check if we got icon data or not?
    if (iconData != null) {
      offset = iconData.offset;
    }

    // if offset is positive, darken the color, if negative, lighten the color
    if (offset > 0) {
      return accentColors[2].darken(amount: offset);
    }
    else if (offset < 0) {
      return accentColors[2].darken(amount: -offset);
    }

    // if offset is 0, return the original color
    return accentColors[2];
  }

  static final Map<String, MyExpenseIconData> incomeIcons = {
    "bonus": MyExpenseIconData(iconData: FontAwesomeIcons.gift.data),
    "investment": MyExpenseIconData(iconData: FontAwesomeIcons.scaleUnbalancedFlip.data),
    "loan payment": MyExpenseIconData(iconData: FontAwesomeIcons.fileInvoiceDollar.data),
    "misc": MyExpenseIconData(iconData: FontAwesomeIcons.box.data),
    "others": MyExpenseIconData(iconData: FontAwesomeIcons.dollarSign.data),
    "salary": MyExpenseIconData(iconData: FontAwesomeIcons.moneyCheckDollar.data),
    "deposit": MyExpenseIconData(iconData: FontAwesomeIcons.moneyCheck.data),
    "tax refund": MyExpenseIconData(iconData: FontAwesomeIcons.fileInvoice.data),
  };

  static Icon getIncomeIcon(String name, [double? size, Color? color]) {
    double currentSize = (size ?? 20);
    Color currentColor = (color ?? textColor);
    String iconName = name.toLowerCase().trim().replaceAll(RegExp('${String.fromCharCode(160)}+'), ' ');

    MyExpenseIconData? iconData = incomeIcons[iconName];
    if (iconData != null) {
      return Icon(iconData.iconData, color: currentColor, size: currentSize);
    }
    return Icon(FontAwesomeIcons.dollarSign.data, color: currentColor, size: currentSize);
  }

  static Color getIncomeColor(String name) {
    String iconName = name.toLowerCase().trim().replaceAll(RegExp('${String.fromCharCode(160)}+'), ' ');
    MyExpenseIconData? iconData = incomeIcons[iconName];
    double offset = 0;

    // check if we got icon data or not?
    if (iconData != null) {
      offset = iconData.offset;
    }

    // if offset is positive, darken the color, if negative, lighten the color
    if (offset > 0) {
      return accentColors[0].darken(amount: offset);
    }
    else if (offset < 0) {
      return accentColors[0].darken(amount: -offset);
    }

    // if offset is 0, return the original color
    return accentColors[0];
  }

  static Icon getIcon(String name, String type, [double? size, Color? color]) {
    if (type == "expense") {
      return getExpenseIcon(name, (size ?? 20), (color ?? textColor));
    }
    else {
      return getIncomeIcon(name, (size ?? 20), (color ?? textColor));
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