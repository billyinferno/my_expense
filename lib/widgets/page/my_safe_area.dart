import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class MySafeArea extends StatelessWidget {
  final bool top;
  final bool left;
  final bool right;
  final bool bottom;
  final Widget child;
  final Color? color;
  final double? bottomPadding;
  const MySafeArea({
    super.key,
    this.top = true,
    this.left = true,
    this.right = true,
    this.bottom = true,
    required this.child,
    this.color,
    this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || kIsWasm) {
      // for we we will need to add additional 15 pixel on bottom
      return SafeArea(
        child: Container(
          color: (color ?? Colors.transparent),
          padding: EdgeInsets.fromLTRB(0, 0, 0, (bottomPadding ?? 25)),
          child: child,
        ),
      );
    }
    else {
      return SafeArea(
        top: top,
        left: left,
        right: right,
        bottom: bottom,
        child: child
      );
    }
  }
}