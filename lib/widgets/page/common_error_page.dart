import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

class CommonErrorPage extends StatelessWidget {
  final bool isNeedScaffold;
  final String errorText;
  const CommonErrorPage({
    super.key,
    this.isNeedScaffold = true,
    required this.errorText,
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
              Icon(
                Ionicons.warning,
                color: accentColors[2],
                size: 25,
              ),
              const SizedBox(height: 5,),
              Text(
                errorText,
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
            Icon(
                Ionicons.warning,
                color: accentColors[2],
                size: 25,
              ),
            const SizedBox(height: 5,),
            Text(
              errorText,
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