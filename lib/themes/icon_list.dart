import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:my_expense/_index.g.dart';

class IconList {
  static Icon getIcon(String name, {double size = 20, Color color = Colors.white}) {
    switch(name.toLowerCase()) {
      case "all": { return Icon(FontAwesomeIcons.asterisk, color: color, size: size,); }
      case "wallet": { return Icon(FontAwesomeIcons.wallet, color: color, size: size,); }
      case "asset": { return Icon(FontAwesomeIcons.fileInvoiceDollar, color: color, size: size); }
      case "cash": { return Icon(FontAwesomeIcons.moneyBill1, color: color, size: size); }
      case "checking": { return Icon(FontAwesomeIcons.solidCreditCard, color: color, size: size); }
      case "credit card": { return Icon(FontAwesomeIcons.ccVisa, color: color, size: size); }
      case "debit card": { return Icon(FontAwesomeIcons.solidCreditCard, color: color, size: size); }
      case "investment": { return Icon(FontAwesomeIcons.chartArea, color: color, size: size); }
      case "loan": { return Icon(FontAwesomeIcons.handHoldingDollar, color: color, size: size); }
      case "savings": { return Icon(FontAwesomeIcons.piggyBank, color: color, size: size); }
      case "other": { return Icon(FontAwesomeIcons.coins, color: color, size: size); }
      default: { return Icon(FontAwesomeIcons.question, color: color, size: size); }
    }
  }

  static Color getColor(String name, {bool enabled = true}) {
    if (!enabled) {
      return Colors.grey[800]!;
    }

    switch(name.toLowerCase()) {
      case "wallet": { return accentColors[0]; }
      case "asset": { return accentColors[10]; }
      case "cash": { return accentColors[5]; }
      case "checking": { return accentColors[9]; }
      case "credit card": { return accentColors[6]; }
      case "debit card": { return accentColors[7]; }
      case "investment": { return accentColors[1]; }
      case "loan": { return accentColors[2]; }
      case "savings": { return accentColors[4]; }
      case "other": { return accentColors[3]; }
      case "all": { return secondaryBackground.lighten(); }
      default: { return Colors.grey[800]!; }
    }
  }

  static Color getDarkColor(String name, {bool enabled = true}) {
    if (!enabled) {
      return Colors.grey[900]!;
    }

    switch(name.toLowerCase()) {
      case "wallet": { return darkAccentColors[0]; }
      case "asset": { return darkAccentColors[10]; }
      case "cash": { return darkAccentColors[5]; }
      case "checking": { return darkAccentColors[9]; }
      case "credit card": { return darkAccentColors[6]; }
      case "debit card": { return darkAccentColors[7]; }
      case "investment": { return darkAccentColors[1]; }
      case "loan": { return darkAccentColors[2]; }
      case "savings": { return darkAccentColors[4]; }
      case "other": { return darkAccentColors[3]; }
      case "all": { return secondaryBackground; }
      default: { return Colors.grey[900]!; }
    }
  }

  static Color getLightColor(String name, {bool enabled = true}) {
    if (!enabled) {
      return Colors.grey[700]!;
    }

    switch(name.toLowerCase()) {
      case "wallet": { return lightAccentColors[0]; }
      case "asset": { return lightAccentColors[10]; }
      case "cash": { return lightAccentColors[5]; }
      case "checking": { return lightAccentColors[9]; }
      case "credit card": { return lightAccentColors[6]; }
      case "debit card": { return lightAccentColors[7]; }
      case "investment": { return lightAccentColors[1]; }
      case "loan": { return lightAccentColors[2]; }
      case "savings": { return lightAccentColors[4]; }
      case "other": { return lightAccentColors[3]; }
      case "all": { return secondaryBackground.lighten(amount: 0.3); }
      default: { return Colors.grey[700]!; }
    }
  }
}