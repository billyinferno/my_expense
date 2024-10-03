import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:my_expense/_index.g.dart';

class Globals {
  static String apiURL = (dotenv.env['API_URL'] ?? 'http://192.168.1.176:1337/');
  static int apiTimeOut = 45;
  static String appVersion = (dotenv.env['APP_VERSION'] ?? '0.0.1');
  static String flutterVersion = (dotenv.env['FLUTTER_VERSION'] ?? 'beta');

  static final DateFormat dfyyyyMMdd = DateFormat('yyyy-MM-dd');
  static final DateFormat dfyyyyMM = DateFormat('yyyy-MM');
  static final DateFormat dfddMMyyyy = DateFormat('dd/MM/yyyy');
  static final DateFormat dfddMMyy = DateFormat('dd/MM/yy');
  static final DateFormat dfddMMMyyyy = DateFormat('dd MMM yyyy');
  static final DateFormat dfddMMMMyyyy = DateFormat('dd MMMM yyyy');
  static final DateFormat dfyyyy = DateFormat('yyyy');
  static final DateFormat dfMMM = DateFormat('MMM');
  static final DateFormat dfMMMM = DateFormat('MMMM');
  static final DateFormat dfMMyy = DateFormat('MM/yy');
  static final DateFormat dfMMMyyyy = DateFormat('MMM yyyy');
  static final DateFormat dfMMMMyyyy = DateFormat('MMMM yyyy');
  static final DateFormat dfeddMMMyyyy = DateFormat('E, dd MMM yyyy');
  static final DateFormat dfeMMMMddyyyy = DateFormat('E, MMMM dd, yyyy');
  static final DateFormat dfd = DateFormat('d');
  static final DateFormat dfddMM = DateFormat('dd/MM');

  static final NumberFormat fCCY = NumberFormat("#,##0.00", "en_US");
  static final NumberFormat fCCY2 = NumberFormat("0.00", "en_US");
  static final NumberFormat fCCYnf = NumberFormat.decimalPattern("en_US")..maximumFractionDigits = 2;

  static (String, Color) runAs() {
    if (kIsWasm) {
      return ("WASM", accentColors[1]);
    }
    if (kIsWeb) {
      return ("JS", accentColors[0]);
    }
    return ("Native", accentColors[2]);
  }

  static ThemeData themeData = ThemeData(
    fontFamily: '--apple-system',
    brightness: Brightness.dark,
    appBarTheme: const AppBarTheme(backgroundColor: primaryDark),
    scaffoldBackgroundColor: primaryBackground,
    splashColor: primaryBackground,
    dividerColor: primaryLight,
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
