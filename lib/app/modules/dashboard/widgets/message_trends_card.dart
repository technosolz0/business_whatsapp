// import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';

// class MessageTrendsCard extends StatelessWidget {
//   final String title;
//   final int totalCount;
//   final String percentageText;
//   final List<double> values;
//   final List<String> days;
//   final int highlightedIndex;
//   final double barWidth;

//   const MessageTrendsCard({
//     super.key,
//     required this.title,
//     required this.totalCount,
//     required this.percentageText,
//     required this.values,
//     required this.days,
//     required this.highlightedIndex,
//     this.barWidth = 0.6,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     List<_ChartData> chartData = List.generate(
//       days.length,
//       (index) =>
//           _ChartData(days[index], values[index], index == highlightedIndex),
//     );

//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: isDark ? const Color(0xFF1F2937) : Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: isDark ? const Color(0xFF242424) : const Color(0xFFE5E7EB),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha:0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               color: isDark ? Colors.white : Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Row(
//             children: [
//               Text(
//                 totalCount.toString(),
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                   color: isDark ? Colors.white : Colors.black87,
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 percentageText,
//                 style: const TextStyle(
//                   fontSize: 14,
//                   color: Color(0xFF28A745),
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           SizedBox(
//             height: 200,
//             child: SfCartesianChart(
//               plotAreaBorderWidth: 0,
//               primaryXAxis: CategoryAxis(
//                 majorTickLines: const MajorTickLines(
//                   width: 0,
//                 ), // removes small ticks

//                 majorGridLines: const MajorGridLines(width: 0),
//                 axisLine: const AxisLine(width: 0),
//                 labelStyle: TextStyle(
//                   color: isDark ? Colors.grey[400] : Colors.grey[600],
//                   fontSize: 12,
//                 ),
//               ),
//               primaryYAxis: NumericAxis(
//                 isVisible: false,
//                 majorGridLines: const MajorGridLines(width: 0),
//                 axisLine: const AxisLine(width: 0),
//               ),
//               series: [
//                 ColumnSeries<_ChartData, String>(
//                   dataSource: chartData,
//                   spacing: 0.0,
//                   xValueMapper: (_ChartData data, _) => data.day,
//                   yValueMapper: (_ChartData data, _) => data.value,
//                   borderRadius: BorderRadius.circular(6),
//                   width: barWidth,
//                   color: const Color(0xFF137FEC).withValues(alpha:0.2),
//                   pointColorMapper: (data, _) => data.isActive
//                       ? const Color(0xFF137FEC)
//                       : const Color(0xFF137FEC).withValues(alpha:0.2),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _ChartData {
//   final String day;
//   final double value;
//   final bool isActive;

//   _ChartData(this.day, this.value, this.isActive);
// }

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class MessageTrendsCard extends StatelessWidget {
  final String title;
  final int totalCount;
  final String percentageText;
  final List<double> values;
  final List<String> days;
  final int highlightedIndex;
  final double barWidth;

  const MessageTrendsCard({
    super.key,
    required this.title,
    required this.totalCount,
    required this.percentageText,
    required this.values,
    required this.days,
    required this.highlightedIndex,
    this.barWidth = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Ensure values and days have the same length
    final safeLength = values.length < days.length
        ? values.length
        : days.length;
    final safeValues = values.take(safeLength).toList();
    final safeDays = days.take(safeLength).toList();

    List<_ChartData> chartData = List.generate(
      safeLength,
      (index) => _ChartData(
        safeDays[index],
        safeValues[index],
        index == highlightedIndex,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF242424) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                _formatNumber(totalCount),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                percentageText,
                style: TextStyle(
                  fontSize: 14,
                  color: percentageText.startsWith('+')
                      ? const Color(0xFF28A745)
                      : percentageText.startsWith('-')
                      ? const Color(0xFFDC3545)
                      : const Color(0xFF6C757D),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: chartData.isEmpty
                ? Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  )
                : SfCartesianChart(
                    plotAreaBorderWidth: 0,
                    primaryXAxis: CategoryAxis(
                      majorTickLines: const MajorTickLines(width: 0),
                      majorGridLines: const MajorGridLines(width: 0),
                      axisLine: const AxisLine(width: 0),
                      labelStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    primaryYAxis: NumericAxis(
                      isVisible: false,
                      majorGridLines: const MajorGridLines(width: 0),
                      axisLine: const AxisLine(width: 0),
                    ),
                    series: [
                      ColumnSeries<_ChartData, String>(
                        enableTooltip: true,
                        dataSource: chartData,
                        spacing: 0.0,
                        xValueMapper: (_ChartData data, _) => data.day,
                        yValueMapper: (_ChartData data, _) => data.value,
                        borderRadius: BorderRadius.circular(6),
                        width: barWidth,
                        color: const Color(0xFF137FEC).withValues(alpha: 0.2),
                        pointColorMapper: (data, _) => data.isActive
                            ? const Color(0xFF137FEC)
                            : const Color(0xFF137FEC).withValues(alpha: 0.2),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class _ChartData {
  final String day;
  final double value;
  final bool isActive;

  _ChartData(this.day, this.value, this.isActive);
}
