import 'package:flutter/material.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/widgets/chart/multi_line_chart_painter.dart';

class MultiLineChart extends StatelessWidget {
  final double? height;
  final List<Map<String, double>> data;
  final List<Color> color;
  final List<String>? legend;
  final int? dateOffset;
  const MultiLineChart({Key? key, this.height, required this.data, required this.color, this.legend, this.dateOffset}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double chartHeight = height ?? 250;
    List<String> point = _generatePoint();
    List<String> legendData = legend ?? [];
    List<double> minMax = _getMinMax();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          child: CustomPaint(
            painter: MultiLineChartPainter(
              min: minMax[0],
              max: minMax[1],
              color: color,
              data: data,
              point: point,
              dateOffset: dateOffset,
            ),
            child: Container(
              height: chartHeight,
            ),
          ),
        ),
        Visibility(
          visible: (legendData.isNotEmpty && color.isNotEmpty && legendData.length == color.length),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(legendData.length, (index) {
                return _legend(color: color[index], text: legendData[index]);
              }),
            ),
          ),
        ),
        const SizedBox(height: 10,),
      ],
    );
  }

  Widget _legend({required Color color, required String text}) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 5,),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  List<double> _getMinMax() {
    List<double> result = [];
    double min = double.infinity;
    double max = double.negativeInfinity;

    // loop thru all the data
    for(int i=0; i < data.length; i++) {
      data[i].forEach((key, value) {
        if (value > max) {
          max = value;
        }
        if (value < min) {
          min = value;
        }
      });
    }

    // add min and max
    result.add(min);
    result.add(max);
    return result;
  }

  List<String> _generatePoint() {
    Map<String, bool> combineLegend = {};
    List<String> result = [];

    // loop thru all the data
    for (Map<String, double> elements in data) {
      elements.forEach((key, value) {
        if (!combineLegend.containsKey(key)) {
          combineLegend[key] = true;
        }
      });
    }

    // convert from map to list
    combineLegend.forEach((key, value) {
      result.add(key);
    });

    // return result
    return result;
  }
}