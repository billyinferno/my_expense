import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:my_expense/_index.g.dart';

class CommonLoadingPage extends StatelessWidget {
  final bool isNeedScaffold;
  final String loadingText;
  const CommonLoadingPage({
    super.key,
    this.isNeedScaffold = true,
    this.loadingText = "Loading data...",
  });

  @override
  Widget build(BuildContext context) {
    if ((isNeedScaffold)) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          color: primaryBackground,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SpinKitFadingCube(
                color: accentColors[6],
                size: 25,
              ),
              const SizedBox(height: 5,),
              Text(
                loadingText,
                style: TextStyle(
                  color: textColor2,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        )
      );
    }
    else {
      // no need scaffold as this is probably coming from embeded page like
      // from insight that already have scaffold inside.
      return Container(
        width: double.infinity,
        color: primaryBackground,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SpinKitFadingCube(
              color: accentColors[6],
              size: 25,
            ),
            const SizedBox(height: 5,),
            Text(
              loadingText,
              style: TextStyle(
                color: textColor2,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }
  }
}