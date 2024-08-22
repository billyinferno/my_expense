import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:my_expense/_index.g.dart';

class Globals {
  static String apiURL = (dotenv.env['API_URL'] ?? 'http://192.168.1.176:1337/');
  static int apiTimeOut = 10;
  static String appVersion = (dotenv.env['APP_VERSION'] ?? '0.0.1');
  static String flutterVersion = (dotenv.env['FLUTTER_VERSION'] ?? 'beta');

  static DateFormat dfyyyyMMdd = DateFormat('yyyy-MM-dd');
  static DateFormat dfyyyyMM = DateFormat('yyyy-MM');
  static DateFormat dfddMMyyyy = DateFormat('dd/MM/yyyy');
  static DateFormat dfddMMyy = DateFormat('dd/MM/yy');
  static DateFormat dfddMMMyyyy = DateFormat('dd MMM yyyy');
  static DateFormat dfddMMMMyyyy = DateFormat('dd MMMM yyyy');
  static DateFormat dfyyyy = DateFormat('yyyy');
  static DateFormat dfMMM = DateFormat('MMM');
  static DateFormat dfMMMM = DateFormat('MMMM');
  static DateFormat dfMMyy = DateFormat('MM/yy');
  static DateFormat dfMMMyyyy = DateFormat('MMM yyyy');
  static DateFormat dfMMMMyyyy = DateFormat('MMMM yyyy');
  static DateFormat dfeddMMMyyyy = DateFormat('E, dd MMM yyyy');
  static DateFormat dfeMMMMddyyyy = DateFormat('E, MMMM dd, yyyy');
  static DateFormat dfd = DateFormat('d');
  static DateFormat dfddMM = DateFormat('dd/MM');

  static String runAs() {
    if (kIsWasm) {
      return " run as WASM";
    }
    if (kIsWeb) {
      return " run as JS";
    }
    return "";
  }

  static ThemeData themeData = ThemeData(
    fontFamily: '--apple-system',
    brightness: Brightness.dark,
    appBarTheme: const AppBarTheme(backgroundColor: primaryDark),
    scaffoldBackgroundColor: primaryBackground,
    primaryColor: primaryBackground,
    //accentColor: accentColors[0],
    iconTheme: const IconThemeData().copyWith(color: textColor),
    // fontFamily: 'Roboto',
    textTheme: const TextTheme(
      displayMedium: TextStyle(
        color: textColor,
        fontSize: 32.0,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: textColor2,
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
        letterSpacing: 2.0,
      ),
      bodyLarge: TextStyle(
        color: textColor,
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
      ),
      bodyMedium: TextStyle(
        color: textColor,
        letterSpacing: 1.0,
      ),
    ), colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      error: Colors.red,
      onError: textColor,
      onPrimary: textColor,
      onSecondary: textColor2,
      onSurface: textColor,
      primary: primaryBackground,
      secondary: secondaryBackground,
      surface: primaryLight
    ),
  );
}
