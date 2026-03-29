import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:my_expense/_index.g.dart';

class IconList {
  static final Map<String, IconData> walletIcons = {
    "all": FontAwesomeIcons.asterisk.data,
    "wallet": FontAwesomeIcons.wallet.data,
    "asset": FontAwesomeIcons.fileInvoiceDollar.data,
    "cash": FontAwesomeIcons.moneyBill1.data,
    "checking": FontAwesomeIcons.solidCreditCard.data,
    "credit card": FontAwesomeIcons.solidCreditCard.data,
    "debit card": FontAwesomeIcons.solidCreditCard.data,
    "investment": FontAwesomeIcons.chartArea.data,
    "loan": FontAwesomeIcons.handHoldingDollar.data,
    "savings": FontAwesomeIcons.piggyBank.data,
    "other": FontAwesomeIcons.coins.data,
  };

  static final Map<String, IconData> walletCCIcons = {
    "amazon": FontAwesomeIcons.amazonPay.data,
    "amex": FontAwesomeIcons.ccAmex.data,
    "apple": FontAwesomeIcons.ccApplePay.data,
    "diners": FontAwesomeIcons.ccDinersClub.data,
    "discover": FontAwesomeIcons.ccDiscover.data,
    "jcb": FontAwesomeIcons.ccJcb.data,
    "mastercard": FontAwesomeIcons.ccMastercard.data,
    "paypal": FontAwesomeIcons.ccPaypal.data,
    "stripe": FontAwesomeIcons.ccStripe.data,
    "visa": FontAwesomeIcons.ccVisa.data,
  };

  static Icon getIcon(String name, {double size = 20, Color color = Colors.white, String ccType = ""}) {
    String iconName = name.toLowerCase();
    if (iconName == "credit card" || iconName == "debit card") {
      String ccIconName = ccType.toLowerCase();
      return Icon(walletCCIcons[ccIconName] ?? FontAwesomeIcons.solidCreditCard.data, color: color, size: size);
    }
    else {
      return Icon(walletIcons[iconName] ?? FontAwesomeIcons.question.data, color: color, size: size);
    }
  }

  static final Map<String, Color> walletColors = {
    "wallet": accentColors[0],
    "asset": accentColors[10],
    "cash": accentColors[5],
    "checking": accentColors[9],
    "credit card": accentColors[6],
    "debit card": accentColors[7],
    "investment": accentColors[1],
    "loan": accentColors[2],
    "savings": accentColors[4],
    "other": accentColors[3],
    "all": secondaryBackground.lighten(),
  };

  static final Map<String, Color> walletDarkColors = {
    "wallet": darkAccentColors[0],
    "asset": darkAccentColors[10],
    "cash": darkAccentColors[5],
    "checking": darkAccentColors[9],
    "credit card": darkAccentColors[6],
    "debit card": darkAccentColors[7],
    "investment": darkAccentColors[1],
    "loan": darkAccentColors[2],
    "savings": darkAccentColors[4],
    "other": darkAccentColors[3],
    "all": secondaryBackground,
  };

  static final Map<String, Color> walletLightColors = {
    "wallet": lightAccentColors[0],
    "asset": lightAccentColors[10],
    "cash": lightAccentColors[5],
    "checking": lightAccentColors[9],
    "credit card": lightAccentColors[6],
    "debit card": lightAccentColors[7],
    "investment": lightAccentColors[1],
    "loan": lightAccentColors[2],
    "savings": lightAccentColors[4],
    "other": lightAccentColors[3],
    "all": secondaryBackground.lighten(amount: 0.3),
  };

  static Color getColor(String name, {bool enabled = true}) {
    if (!enabled) {
      return Colors.grey[800]!;
    }
    return walletColors[name.toLowerCase()] ?? Colors.grey[800]!;
  }

  static Color getDarkColor(String name, {bool enabled = true}) {
    if (!enabled) {
      return Colors.grey[900]!;
    }
    return walletDarkColors[name.toLowerCase()] ?? Colors.grey[900]!;
  }

  static Color getLightColor(String name, {bool enabled = true}) {
    if (!enabled) {
      return Colors.grey[700]!;
    }
    return walletLightColors[name.toLowerCase()] ?? Colors.grey[700]!;
  }
}