import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_expense/router.dart';
import 'package:my_expense/utils/prefs/shared_box.dart';

Future main() async {
  // run all the initialisation on the runZonedGuarded to ensure that all the
  // init already finished before we perform runApp.
  await runZonedGuarded(() async {
    // ensure that the flutter widget already binding
    WidgetsFlutterBinding.ensureInitialized();

    // after that we can initialize the box
    await Future.wait([
      dotenv.load(fileName: "conf/.dev.env"),
      Hive.initFlutter(),
      MyBox.init(),
    ]);

    // run the actual application
    debugPrint("🚀 Initialize finished, run application");
    runApp(const MyApp());
  }, (error, stack) {
    debugPrint("Error: ${error.toString()}");
    debugPrintStack(stackTrace: stack);
  },);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // return the router page, we will control all the route from here instead
    return const RouterPage();
  }
}