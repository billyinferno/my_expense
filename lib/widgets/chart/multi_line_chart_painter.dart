import 'package:flutter/material.dart';
import 'package:my_expense/_index.g.dart';

class MultiLineChartPainter extends CustomPainter {
  final double min;
  final double max;
  final List<String> point;
  final List<Color> color;
  final List<Map<String, double>> data;
  final int? dateOffset;
  
  const MultiLineChartPainter({
    required this.min,
    required this.max,
    required this.point,
    required this.color,
    required this.data,
    this.dateOffset
  });

  @override
  void paint(Canvas canvas, Size size) {
    // calculate the center
    Offset center = Offset(size.width / 2, size.height / 2);
    bool isAllGood = true;

    // ensure that we at least have more than 1 data, because if only 1 data
    // then the min or max probably will be the same.
    if (point.isNotEmpty && data.isNotEmpty && color.isNotEmpty) {
      // ensure all the data is not empty and all the data got the same length
      // as legend
      for (int i = 0; i < data.length || !isAllGood; i++) {
        if (data[i].length != point.length) {
          isAllGood = false;
        }
      }

      // ensure the data.length equal to color.length
      if (data.length != color.length) {
        isAllGood = false;
      }

      // if all is good only then we will draw the chart
      if (isAllGood) {
        _drawPoint(canvas, size, center);
        for (int i = 0; i < data.length || !isAllGood; i++) {
          _drawLine(data[i], color[i], canvas, size, center);
        }
        _draw0Point(canvas, size, center);
      }
    }

    // first let's draw the border
    _drawBorder(canvas, size, center);
  }

  @override
  bool shouldRepaint(covariant MultiLineChartPainter oldDelegate) {
    return listEquals<Map<String, double>>(oldDelegate.data, data);
  }

  void _draw0Point(Canvas canvas, Size size, Offset center) {
    Paint graphRectBorderWhite = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    Rect graphRect = Rect.fromLTRB(10, 10, size.width - 10, size.height - 30);

    // draw the 0 line if min is less than 0
    if (min < 0) {
      double yD = ((min * -1) / (max - min)) * graphRect.height;

      _drawDashedLine(canvas, graphRect, 2, yD, graphRectBorderWhite);
      _drawText(
        canvas: canvas,
        position: Offset(graphRect.right, graphRect.bottom - yD),
        width: 60,
        text: 0.0.formatCurrency(),
        left: 0,
        top: -10,
        minHeight: 10,
        maxHeight: graphRect.height,
        minWidth: 10,
        maxWidth: graphRect.width + 8,
      );
    }
  }

  void _drawBorder(Canvas canvas, Size size, Offset center) {
    // set the rectangle position
    Rect rect = Rect.fromCenter(
        center: center, width: (size.width - 20), height: (size.height - 20));
    Paint border = Paint()
      ..color = primaryLight
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // draw the rectangle
    canvas.drawRect(rect, border);
  }

  void _drawPoint(Canvas canvas, Size size, Offset center) {
    Paint graphRectBorderWhite = Paint()
      ..color = primaryLight.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    Paint graphRectBorder = Paint()
      ..color = primaryDark.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    Rect graphRect = Rect.fromLTRB(10, 10, size.width - 10, size.height - 30);
    double xLeft = graphRect.left;
    double guideW = graphRect.size.width / (point.length - 1);

    // check for the date print offset
    int datePrintOffset = (dateOffset ?? 3);
    if (point.length < datePrintOffset) {
      datePrintOffset = point.length - 1;
    }

    for (int i = 0; i < point.length; i++) {
      Offset p1 = Offset(xLeft, graphRect.bottom);
      Offset p2 = Offset(xLeft, graphRect.top);

      if (i % datePrintOffset == 0 && i > 0 && i < (point.length - 1)) {
        canvas.drawLine(p1, p2, graphRectBorderWhite);
        _drawText(
          canvas: canvas,
          position: Offset(xLeft, graphRect.bottom),
          width: 60,
          text: point[i],
          left: -15,
          top: 5,
          minHeight: 0,
          maxHeight: graphRect.height + 20,
          minWidth: 0,
          maxWidth: graphRect.width + 20
        );
      } else {
        canvas.drawLine(p1, p2, graphRectBorder);
      }

      // next
      xLeft += guideW;
    }

    // draw horizontal line
    double yD = graphRect.size.height / 4;
    for (int i = 0; i < 4; i++) {
      Offset p1 = Offset(graphRect.left, graphRect.bottom - (yD * i));
      Offset p2 = Offset(graphRect.right, graphRect.bottom - (yD * i));
      canvas.drawLine(p1, p2, graphRectBorder);

      double currVal = min + (((max - min) / 4.0) * i.toDouble());
      _drawText(
        canvas: canvas,
        position: Offset(graphRect.left, graphRect.bottom - (yD * i) - 5),
        width: 60,
        text: currVal.formatCurrency(),
        left: 0,
        top: -5,
        minHeight: 10,
        maxHeight: graphRect.height,
        minWidth: 10,
        maxWidth: graphRect.width
      );
    }

    // put the max price
    _drawText(
      canvas: canvas,
      position: Offset(graphRect.left, graphRect.top),
      width: 60,
      text: max.formatCurrency(),
      left: 0,
      top: -5,
      minHeight: 10,
      maxHeight: graphRect.height,
      minWidth: 10,
      maxWidth: graphRect.width
    );

    canvas.drawRect(graphRect, graphRectBorder);
  }

  void _drawLine(Map<String, double> data, Color color, Canvas canvas, Size size, Offset center) {
    double x;
    double y;

    // create the rect that we will use as a guide for the graph
    Rect graphRect = Rect.fromLTRB(10, 10, size.width - 10, size.height - 30);

    double gap = graphRect.width / (data.length.toDouble() - 1);
    double ratio;
    if ((max - min) == 0) {
      ratio = graphRect.height / min;
    } else {
      ratio = graphRect.height / (max - min);
    }

    Path pt = Path();
    bool isFirst = true;

    x = graphRect.left;
    y = 0;

    // loop thru data
    data.forEach((key, value) {
      y = 10 + graphRect.height - ((value - min) * ratio);

      // check whether this is the first data?
      if (isFirst) {
        pt.moveTo(x, y);
        isFirst = false;
      } else {
        pt.lineTo(x, y);
      }

      // next column
      x += gap;
    });
    // end of chart

    // draw the path
    Paint dp = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawPath(pt, dp);
  }

  void _drawText(
      {required Canvas canvas,
      required Offset position,
      required double width,
      required String text,
      required double left,
      required double top,
      required double minHeight,
      required double maxHeight,
      required double minWidth,
      required double maxWidth,
      Color? textColor}) {
    final TextSpan textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: (textColor ?? Colors.white.withValues(alpha: 0.5)),
        fontSize: 10,
      ),
    );

    final TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );
    textPainter.layout(minWidth: 0, maxWidth: width);
    double dx = position.dx + left;
    if (dx < minWidth) {
      dx = minWidth;
    }
    if (dx > maxWidth) {
      dx = maxWidth - textPainter.width;
    }

    double dy = position.dy + top;
    if (dy < minHeight) {
      dy = minHeight;
    }
    if (dy > maxHeight) {
      dy = maxHeight - textPainter.height;
    }

    textPainter.paint(canvas, Offset(dx, dy));
  }

  void _drawDashedLine(Canvas canvas, Rect graph, double width, double offset, Paint paint) {
    int j = 0;
    for (double i = graph.left; i <= graph.right; i = (i + width)) {
      if (j % 2 == 0) {
        canvas.drawLine(
          Offset(i, graph.bottom - offset), Offset((i + width), graph.bottom - offset),
          paint
        );
      }
      // odd and even to print the line
      j = j + 1;
    }
  }
}
