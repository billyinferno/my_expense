@ECHO OFF
ECHO Build myWealth for windows

ECHO Clean current flutter directory
flutter clean

ECHO Flutter pub get
flutter pub get

ECHO Build application
flutter build windows --release -t lib/main.dart --verbose
