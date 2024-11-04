import 'package:flutter/material.dart';
import 'package:gauge_indicator/gauge_indicator.dart';

class GaugeWidget extends StatelessWidget {
  final double value;

  const GaugeWidget({Key? key, required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150, // Adjusted height
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedRadialGauge(
            duration: const Duration(seconds: 1),
            curve: Curves.elasticOut,
            radius: 150, // Adjusted radius
            value: value,
            axis: GaugeAxis(
              min: 0,
              max: 18,
              degrees: 180,
              style: const GaugeAxisStyle(
                thickness: 21, // Adjusted thickness
                background: Color(0xFFDFE2EC),
                segmentSpacing: 3,
              ),
              progressBar: GaugeProgressBar.rounded(
                color: null,
                gradient: const GaugeAxisGradient(
                  colors: [
                    Color.fromARGB(255, 69, 204, 73),
                    Color.fromARGB(255, 202, 60, 41)
                  ],
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 50), // Adjusted spacing
              Text(
                'Today',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 72, 100, 68),
                ),
              ),
              SizedBox(height: 5), // Adjusted spacing
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${value.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: value >= 18
                          ? Colors.red
                          : value >= 15
                              ? Colors.deepOrangeAccent
                              : value >= 12
                                  ? const Color.fromARGB(255, 245, 179, 93)
                                  : value >= 9
                                      ? const Color.fromARGB(255, 150, 221, 36)
                                      : value >= 6
                                          ? const Color.fromARGB(
                                              255, 131, 223, 78)
                                          : value >= 3
                                              ? const Color.fromARGB(
                                                  255, 132, 247, 79)
                                              : Colors.green,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'kWh',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5), // Adjusted spacing
              Text(
                value == 0.00
                    ? 'No Energy Consumed'
                    : value <= 6
                        ? 'Low Energy Consumption'
                        : value > 6 && value <= 9
                            ? 'Average Energy Consumption'
                            : value > 9 && value <= 12
                                ? 'High Energy Consumption'
                                : 'Extremely High Consumption',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.normal,
                  color: value == 0
                      ? Colors.grey
                      : value <= 6
                          ? Colors.green
                          : value > 6 && value <= 9
                              ? const Color.fromARGB(255, 115, 180, 9)
                              : value > 9 && value <= 12
                                  ? Colors.orange
                                  : Colors.red,
                ),
              ),
              SizedBox(height: 10), // Adjusted spacing
            ],
          ),
          // Adjusted positions and font sizes for the gauge labels
          Positioned(
            top: 135, // Moved down by 20
            left: 35, // Moved right by 50
            child: Text('0',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          Positioned(
            top: 80, // Moved down by 20
            left: 55, // Moved right by 50
            child: Text('3',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          Positioned(
            top: 45, // Moved down by 20
            left: 90, // Moved right by 50
            child: Text('6',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          Positioned(
            top: 32, // Moved down by 20
            left: 145, // Moved right by 50
            child: Text('9',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          Positioned(
            top: 45, // Moved down by 20
            left: 200, // Moved right by 50
            child: Text('12',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          Positioned(
            top: 80, // Moved down by 20
            left: 235, // Moved right by 50
            child: Text('15',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          Positioned(
            top: 135, // Moved down by 20
            left: 250, // Moved right by 50
            child: Text('18',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
