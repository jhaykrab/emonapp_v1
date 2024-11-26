import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Line graph library

class RealtimeAnalyticsPage extends StatelessWidget {
  const RealtimeAnalyticsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: [
                FlSpot(0, 0),
                FlSpot(1, 1.5),
                FlSpot(2, 1),
                FlSpot(3, 2.5),
                FlSpot(4, 2),
              ],
              isCurved: true,
              barWidth: 4,
              colors: [Colors.blue],
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: SideTitles(showTitles: true),
            bottomTitles: SideTitles(showTitles: true),
          ),
        ),
      ),
    );
  }
}
