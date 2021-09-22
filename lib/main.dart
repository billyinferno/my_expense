import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_expense/router.dart';
import 'package:my_expense/utils/prefs/shared_box.dart';

Future main() async {
  // this is needed to ensure that all the binding already initialized before
  // we plan to load the shared preferences.
  WidgetsFlutterBinding.ensureInitialized();

  // initialize the shared preferences we will used
  Future.wait([
    dotenv.load(fileName: "conf/.dev.env"),
    Hive.initFlutter(),
    MyBox.init(),
  ]).then((value) {
    // run the actual application
    debugPrint("🚀 Initialize finished, run application");
    runApp(MyApp());
  });
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // return the router page, we will control all the route from here instead
    return RouterPage();
  }
}