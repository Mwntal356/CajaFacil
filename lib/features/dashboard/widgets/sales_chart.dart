import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';

class SalesChart extends StatelessWidget {
  const SalesChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.only(top: 24, right: 24, left: 12),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 3),
                FlSpot(2, 2.5),
                FlSpot(4, 5),
                FlSpot(6, 4.5),
                FlSpot(8, 7),
                FlSpot(10, 6.5),
                FlSpot(12, 8),
              ],
              isCurved: true,
              color: AppColors.green,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.green.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
