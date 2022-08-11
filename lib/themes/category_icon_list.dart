import 'package:flutter/material.dart';
import 'package:my_expense/themes/color_utils.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

Icon getExpenseIcon(String name, [double? size]) {
  double _size = (size ?? 20);
  switch(name.toLowerCase()) {
    case "auto": { return Icon(FontAwesomeIcons.car, color: textColor, size: _size,); }
    case "bank charge": { return Icon(FontAwesomeIcons.fileInvoiceDollar, color: textColor, size: _size); }
    case "cash": { return Icon(FontAwesomeIcons.moneyBill, color: textColor, size: _size); }
    case "charity": { return Icon(FontAwesomeIcons.circleDollarToSlot, color: textColor, size: _size); }
    case "childcare": { return Icon(FontAwesomeIcons.baby, color: textColor, size: _size); }
    case "clothing": { return Icon(FontAwesomeIcons.shirt, color: textColor, size: _size); }
    case "credit card": { return Icon(FontAwesomeIcons.solidCreditCard, color: textColor, size: _size); }
    case "dining": { return Icon(FontAwesomeIcons.utensils, color: textColor, size: _size); }
    case "eating out": { return Icon(FontAwesomeIcons.utensils, color: textColor, size: _size); }
    case "education": { return Icon(FontAwesomeIcons.school, color: textColor, size: _size); }
    case "entertainment": { return Icon(FontAwesomeIcons.champagneGlasses, color: textColor, size: _size); }
    case "gifts": { return Icon(FontAwesomeIcons.gift, color: textColor, size: _size); }
    case "groceries": { return Icon(FontAwesomeIcons.basketShopping, color: textColor, size: _size); }
    case "grooming": { return Icon(FontAwesomeIcons.scissors, color: textColor, size: _size); }
    case "health": { return Icon(FontAwesomeIcons.suitcaseMedical, color: textColor, size: _size); }
    case "holiday": { return Icon(FontAwesomeIcons.plane, color: textColor, size: _size); }
    case "home repair": { return Icon(FontAwesomeIcons.hammer, color: textColor, size: _size); }
    case "household": { return Icon(FontAwesomeIcons.toiletPaper, color: textColor, size: _size); }
    case "insurance": { return Icon(FontAwesomeIcons.carBurst, color: textColor, size: _size); }
    case "investment": { return Icon(FontAwesomeIcons.scaleUnbalanced, color: textColor, size: _size); }
    case "loan": { return Icon(FontAwesomeIcons.moneyCheck, color: textColor, size: _size); }
    case "medical": { return Icon(FontAwesomeIcons.capsules, color: textColor, size: _size); }
    case "misc": { return Icon(FontAwesomeIcons.box, color: textColor, size: _size); }
    case "mortgage": { return Icon(FontAwesomeIcons.house, color: textColor, size: _size); }
    case "others": { return Icon(FontAwesomeIcons.dollarSign, color: textColor, size: _size); }
    case "pets": { return Icon(FontAwesomeIcons.dog, color: textColor, size: _size); }
    case "rent": { return Icon(FontAwesomeIcons.houseUser, color: textColor, size: _size); }
    case "tax": { return Icon(FontAwesomeIcons.fileInvoice, color: textColor, size: _size); }
    case "transport": { return Icon(FontAwesomeIcons.bus, color: textColor, size: _size); }
    case "travel": { return Icon(FontAwesomeIcons.earthAsia, color: textColor, size: _size); }
    case "utilities": { return Icon(FontAwesomeIcons.solidLightbulb, color: textColor, size: _size); }
    case "utilities: cable tv": { return Icon(FontAwesomeIcons.tv, color: textColor, size: _size); }
    case "utilities: garbage": { return Icon(FontAwesomeIcons.solidTrashCan, color: textColor, size: _size); }
    case "utilities: gas & electric": { return Icon(FontAwesomeIcons.chargingStation, color: textColor, size: _size); }
    case "utilities: internet": { return Icon(FontAwesomeIcons.wifi, color: textColor, size: _size); }
    case "utilities: telephone": { return Icon(FontAwesomeIcons.mobileScreenButton, color: textColor, size: _size); }
    case "utilities: water": { return Icon(FontAwesomeIcons.shower, color: textColor, size: _size); }
    default: { return Icon(FontAwesomeIcons.dollarSign, color: textColor, size: _size); }
  }
}

Color getExpenseColor(String name) {
  switch (name.toLowerCase()) {
    case "auto": { return darken(accentColors[2],0.2); }
    case "bank charge": { return darken(accentColors[2],0.19); }
    case "cash": { return darken(accentColors[2],0.18); }
    case "charity": { return darken(accentColors[2],0.17); }
    case "childcare": { return darken(accentColors[2],0.16); }
    case "clothing": { return darken(accentColors[2],0.14); }
    case "credit card": { return darken(accentColors[2],0.13); }
    case "dining": { return darken(accentColors[2],0.12); }
    case "eating out": { return darken(accentColors[2],0.11); }
    case "education": { return darken(accentColors[2],0.1); }
    case "entertainment": { return darken(accentColors[2],0.09); }
    case "gifts": { return darken(accentColors[2],0.08); }
    case "groceries": { return darken(accentColors[2],0.07); }
    case "grooming": { return darken(accentColors[2],0.06); }
    case "health": { return darken(accentColors[2],0.04); }
    case "holiday": { return darken(accentColors[2],0.03); }
    case "home repair": { return darken(accentColors[2],0.02); }
    case "household": { return darken(accentColors[2],0.01); }
    case "insurance": { return accentColors[2]; }
    case "investment": { return lighten(accentColors[2],0.01); }
    case "loan": { return lighten(accentColors[2],0.02); }
    case "medical": { return lighten(accentColors[2],0.03); }
    case "misc": { return lighten(accentColors[2],0.04); }
    case "mortgage": { return lighten(accentColors[2],0.06); }
    case "others": { return lighten(accentColors[2],0.07); }
    case "pets": { return lighten(accentColors[2],0.08); }
    case "rent": { return lighten(accentColors[2],0.09); }
    case "tax": { return lighten(accentColors[2],0.1); }
    case "transport": { return lighten(accentColors[2],0.11); }
    case "travel": { return lighten(accentColors[2],0.12); }
    case "utilities": { return lighten(accentColors[2],0.13); }
    case "utilities: cable tv": { return lighten(accentColors[2],0.14); }
    case "utilities: garbage": { return lighten(accentColors[2],0.16); }
    case "utilities: gas & electric": { return lighten(accentColors[2],0.17); }
    case "utilities: internet": { return lighten(accentColors[2],0.18); }
    case "utilities: telephone": { return lighten(accentColors[2],0.19); }
    case "utilities: water": { return lighten(accentColors[2],0.2); }
    default: { return accentColors[2]; }
  }
}

Icon getIncomeIcon(String name, [double? size]) {
  double _size = (size ?? 20);
  switch(name.toLowerCase()) {
    case "bonus": { return Icon(FontAwesomeIcons.gift, color: textColor, size: _size); }
    case "investment": { return Icon(FontAwesomeIcons.scaleUnbalancedFlip, color: textColor, size: _size); }
    case "loan payment": { return Icon(FontAwesomeIcons.fileInvoiceDollar, color: textColor, size: _size); }
    case "misc": { return Icon(FontAwesomeIcons.box, color: textColor, size: _size); }
    case "others": { return Icon(FontAwesomeIcons.dollarSign, color: textColor, size: _size); }
    case "salary": { return Icon(FontAwesomeIcons.moneyCheckDollar, color: textColor, size: _size); }
    case "deposit": { return Icon(FontAwesomeIcons.moneyCheck, color: textColor, size: _size); }
    case "tax refund": { return Icon(FontAwesomeIcons.fileInvoice, color: textColor, size: _size); }
    default: { return Icon(FontAwesomeIcons.dollarSign, color: textColor, size: _size); }
  }
}

Color getIncomeColor(String name) {
  switch (name.toLowerCase()) {
    case "bonus": { return darken(accentColors[0],0.15); }
    case "investment": { return darken(accentColors[0],0.1); }
    case "loan payment": { return darken(accentColors[0],0.05); }
    case "misc": { return accentColors[0]; }
    case "others": { return darken(accentColors[0],0.05); }
    case "salary": { return darken(accentColors[0],0.1); }
    case "deposit": { return darken(accentColors[0],0.15); }
    case "tax refund": { return darken(accentColors[0],0.2); }
    default: { return accentColors[0]; }
  }
}