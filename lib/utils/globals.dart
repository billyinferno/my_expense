import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_expense/themes/colors.dart';

class Globals {
  static String apiURL = (dotenv.env['API_URL'] ?? 'http://192.168.1.176:1337/');
  static String appVersion = (dotenv.env['APP_VERSION'] ?? '0.0.1');
  static ThemeData themeData = ThemeData(
      fontFamily: '--apple-system',
      brightness: Brightness.dark,
      backgroundColor: primaryBackground,
      appBarTheme: const AppBarTheme(backgroundColor: primaryDark),
      scaffoldBackgroundColor: primaryBackground,
      primaryColor: primaryBackground,
      //accentColor: accentColors[0],
      iconTheme: const IconThemeData().copyWith(color: textColor),
      // fontFamily: 'Roboto',
      textTheme: TextTheme(
        headline2: const TextStyle(
          color: textColor,
          fontSize: 32.0,
          fontWeight: FontWeight.bold,
        ),
        headline4: const TextStyle(
          color: textColor2,
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
          letterSpacing: 2.0,
        ),
        bodyText1: const TextStyle(
          color: textColor,
          fontSize: 14.0,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
        bodyText2: const TextStyle(
          color: textColor,
          letterSpacing: 1.0,
        ),
      ),
    );
}
