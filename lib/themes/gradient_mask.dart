import 'package:flutter/material.dart';
import 'package:my_expense/_index.g.dart';

class RadiantGradientMask extends StatelessWidget {
  const RadiantGradientMask({
    super.key,
    required this.child,
    required this.color,
    this.endColor,
    this.align = Alignment.center,
    this.radius = 0.5,
    this.tileMode = TileMode.mirror,
  });

  final Widget child;
  final Color color;
  final Color? endColor;
  final Alignment align;
  final double radius;
  final TileMode tileMode;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => RadialGradient(
        center: align,
        radius: radius,
        colors: [color, (endColor ?? (color.lighten()))],
        tileMode: tileMode,
      ).createShader(bounds),
      child: child,
    );
  }
}