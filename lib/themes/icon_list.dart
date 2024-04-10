import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:my_expense/themes/colors.dart';

class IconList {
  static Icon getIcon(String name, [double? size]) {
    double currentSize = (size ?? 20);
    switch(name.toLowerCase()) {
      case "wallet": { return Icon(FontAwesomeIcons.wallet, color: const Color(0xFFFFFFFF), size: currentSize,); }
      case "asset": { return Icon(FontAwesomeIcons.fileInvoiceDollar, color: const Color(0xFFFFFFFF), size: currentSize); }
      case "cash": { return Icon(FontAwesomeIcons.moneyBill1, color: const Color(0xFFFFFFFF), size: currentSize); }
      case "checking": { return Icon(FontAwesomeIcons.solidCreditCard, color: const Color(0xFFFFFFFF), size: currentSize); }
      case "credit card": { return Icon(FontAwesomeIcons.ccVisa, color: const Color(0xFFFFFFFF), size: currentSize); }
      case "debit card": { return Icon(FontAwesomeIcons.solidCreditCard, color: const Color(0xFFFFFFFF), size: currentSize); }
      case "investment": { return Icon(FontAwesomeIcons.chartArea, color: const Color(0xFFFFFFFF), size: currentSize); }
      case "loan": { return Icon(FontAwesomeIcons.handHoldingDollar, color: const Color(0xFFFFFFFF), size: currentSize); }
      case "savings": { return Icon(FontAwesomeIcons.piggyBank, color: const Color(0xFFFFFFFF), size: currentSize); }
      case "other": { return Icon(FontAwesomeIcons.wallet, color: const Color(0xFFFFFFFF), size: currentSize); }
      default: { return Icon(FontAwesomeIcons.wallet, color: const Color(0xFFFFFFFF), size: currentSize); }
    }
  }

  static Color getColor(String name) {
    switch(name.toLowerCase()) {
      case "wallet": { return accentColors[0]; }
      case "asset": { return accentColors[3]; }
      case "cash": { return accentColors[5]; }
      case "checking": { return accentColors[9]; }
      case "credit card": { return accentColors[6]; }
      case "debit card": { return accentColors[7]; }
      case "investment": { return accentColors[1]; }
      case "loan": { return accentColors[2]; }
      case "savings": { return accentColors[4]; }
      case "other": { return accentColors[3]; }
      default: { return accentColors[0]; }
    }
  }

  static Color getDarkColor(String name) {
    switch(name.toLowerCase()) {
      case "wallet": { return darkAccentColors[0]; }
      case "asset": { return darkAccentColors[3]; }
      case "cash": { return darkAccentColors[5]; }
      case "checking": { return darkAccentColors[9]; }
      case "credit card": { return darkAccentColors[6]; }
      case "debit card": { return darkAccentColors[7]; }
      case "investment": { return darkAccentColors[1]; }
      case "loan": { return darkAccentColors[2]; }
      case "savings": { return darkAccentColors[4]; }
      case "other": { return darkAccentColors[3]; }
      default: { return darkAccentColors[0]; }
    }
  }

  static Color getLightColor(String name) {
    switch(name.toLowerCase()) {
      case "wallet": { return lightAccentColors[0]; }
      case "asset": { return lightAccentColors[3]; }
      case "cash": { return lightAccentColors[5]; }
      case "checking": { return lightAccentColors[9]; }
      case "credit card": { return lightAccentColors[6]; }
      case "debit card": { return lightAccentColors[7]; }
      case "investment": { return lightAccentColors[1]; }
      case "loan": { return lightAccentColors[2]; }
      case "savings": { return lightAccentColors[4]; }
      case "other": { return lightAccentColors[3]; }
      default: { return lightAccentColors[0]; }
    }
  }
}