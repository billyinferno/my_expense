import 'package:flutter/material.dart';
import 'package:my_expense/_index.g.dart';

class RadiantGradientMask extends StatelessWidget {
  const RadiantGradientMask({super.key, required this.child, required this.color, this.endColor, this.align, this.radius, this.tileMode});
  final Widget child;
  final Color color;
  final Color? endColor;
  final Alignment? align;
  final double? radius;
  final TileMode? tileMode;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => RadialGradient(
        center: (align ?? Alignment.center),
        radius: (radius ?? 0.5),
        colors: [color, (endColor ?? lighten(color))],
        tileMode: (tileMode ?? TileMode.mirror),
      ).createShader(bounds),
      child: child,
    );
  }
}