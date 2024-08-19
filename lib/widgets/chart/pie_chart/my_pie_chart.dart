import 'package:flutter/material.dart';
import 'package:my_expense/_index.g.dart';

class PieChartView extends StatelessWidget {
  final Color backgroundColor;
  final List<Color> chartColors;
  final List<double> chartAmount;

  const PieChartView({ super.key, required this.backgroundColor, required this.chartColors, required this.chartAmount });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(builder: (context, constraint) {
        return Container(
          color: backgroundColor,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: constraint.maxWidth,
              height: constraint.maxHeight,
              child: CustomPaint(
                foregroundPainter: PieChartPainter(
                  backgroundColor: backgroundColor,
                  chartAmount: chartAmount,
                  chartColors: chartColors,
                ),
                child: const SizedBox(),
              ),
            ),
          ),
        );
      }),
    );
  }
}