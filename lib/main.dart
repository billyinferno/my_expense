import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:my_expense/_index.g.dart';

Future main() async {
  // run all the initialisation on the runZonedGuarded to ensure that all the
  // init already finished before we perform runApp.
  await runZonedGuarded(
    () async {
      // ensure that the flutter widget already binding
      WidgetsFlutterBinding.ensureInitialized();

      // after that we can initialize the box
      await Future.microtask(() async {
        if (kReleaseMode) {
          await dotenv.load(fileName: "conf/.prod.env");
          Log.info(message: "⏳ Loading production environment variables");
        }
        else {
          await dotenv.load(fileName: "conf/.dev.env");
          Log.info(message: "⏳ Loading development environment variables");
        }
        await Hive.initFlutter();
        await MyBox.init();
      }).then((_) {
        // run the actual application
        Log.success(message: "🚀 Initialize finished, run application");
        if (kReleaseMode) {
          Log.info(message: "🚀 Application version v.${Globals.appVersion}");
        }
        else {
          Log.info(message: "🚀 Development mode");
        }
      }).onError(
        (error, stackTrace) {
          Log.error(
            message: "Error when initialize the application",
            error: error,
            stackTrace: stackTrace,
          );
        },
      ).whenComplete(
        () {
          // run the application when complete
          runApp(const MyApp());
        },
      );
    },
    (error, stack) {
      Log.error(
        message: "Error during run zone guarded",
        error: error,
        stackTrace: stack,
      );
    },
  );
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
