import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Bar graph library

class DailyAnalyticsPage extends StatelessWidget {
  const DailyAnalyticsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: BarChart(
        BarChartData(
          barGroups: [
            BarChartGroupData(
                x: 0, barRods: [BarChartRodData(toY: 2, color: Colors.green)]),
            BarChartGroupData(
                x: 1, barRods: [BarChartRodData(toY: 4, color: Colors.orange)]),
            BarChartGroupData(
                x: 2, barRods: [BarChartRodData(toY: 6, color: Colors.red)]),
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
