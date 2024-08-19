import 'package:flutter/cupertino.dart';
import 'package:my_expense/_index.g.dart';

class MyBottomSheet extends StatelessWidget {

  final BuildContext context;
  final String title;
  final Widget child;
  final double? screenRatio;
  final bool? safeArea;
  final Widget? actionButton;
  const MyBottomSheet({
    super.key,
    required this.context,
    required this.title,
    required this.child,
    this.actionButton,
    this.screenRatio,
    this.safeArea,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * (screenRatio ?? 0.45),
      color: secondaryDark,
      child: Column(
        children: <Widget>[
          Container(
            height: 40,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: primaryLight,
                  width: 1.0
                )
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Center(
                    child: Text(title),
                  ),
                ),
                const SizedBox(width: 5,),
                (actionButton ?? const SizedBox.shrink()),
                (actionButton != null ? const SizedBox(width: 10,) : const SizedBox.shrink()),
              ],
            ),
          ),
          Expanded(
            child: child,
          ),
          Visibility(
            visible: (safeArea ?? true),
            child: const SizedBox(height: 20,)
          ), // safe area
        ],
      ),
    );
  }
}