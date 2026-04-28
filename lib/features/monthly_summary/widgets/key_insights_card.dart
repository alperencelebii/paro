import 'package:finance_track/core/localization/localization.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:intl/intl.dart';

// import '../../../core/models/currency_model.dart';

// class KeyInsightsCard extends StatelessWidget {
//   final Map<String, double> categoryBreakdown;
//   final double totalExpenses;

//   const KeyInsightsCard({
//     super.key,
//     required this.categoryBreakdown,
//     required this.totalExpenses,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final currencyFormat = NumberFormat.currency(symbol: '\$');
//     final insights = _generateInsights();

//     return Card(
//       elevation: 5,
//       color: Theme.of(context).cardTheme.color,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             LocalizedText(
//               'Key Insights',
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),
//             const SizedBox(height: 16),
//             ...insights.map((insight) => _buildInsightItem(
//                   context,
//                   insight.icon,
//                   insight.title,
//                   insight.value,
//                   insight.color,
//                 )),
//           ],
//         ),
//       ),
//     );
//   }

//   List<InsightData> _generateInsights() {
//     final currencyFormat = NumberFormat.currency(symbol: '\$');
//     final insights = <InsightData>[];

//     if (categoryBreakdown.isNotEmpty) {
//       // Highest spending category
//       final highestCategory =
//           categoryBreakdown.entries.reduce((a, b) => a.value > b.value ? a : b);
//       insights.add(
//         InsightData(
//           icon: Icons.arrow_circle_up,
//           title: 'Highest Spending Category',
//           value:
//               '${highestCategory.key} (${currencyFormat.format(highestCategory.value)})',
//           color: Colors.red,
//         ),
//       );

//       // Average daily spending
//       final daysInMonth = DateTime.now().day;
//       final averageDaily = totalExpenses / daysInMonth;
//       insights.add(
//         InsightData(
//           icon: Icons.calendar_today,
//           title: 'Average Daily Spending',
//           value: currencyFormat.format(averageDaily),
//           color: Colors.blue,
//         ),
//       );

//       // Category with lowest spending
//       final lowestCategory =
//           categoryBreakdown.entries.reduce((a, b) => a.value < b.value ? a : b);
//       insights.add(
//         InsightData(
//           icon: Icons.arrow_circle_down,
//           title: 'Lowest Spending Category',
//           value:
//               '${lowestCategory.key} (${currencyFormat.format(lowestCategory.value)})',
//           color: Colors.green,
//         ),
//       );
//     }

//     return insights;
//   }

//   Widget _buildInsightItem(
//     BuildContext context,
//     IconData icon,
//     String title,
//     String value,
//     Color color,
//   ) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12.0),
//       child: Row(
//         children: [
//           Icon(icon, color: color),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 LocalizedText(
//                   title,
//                   style: Theme.of(context).textTheme.titleSmall?.copyWith(
//                         color: Colors.grey[600],
//                       ),
//                 ),
//                 const SizedBox(height: 4),
//                 LocalizedText(
//                   value,
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                         fontWeight: FontWeight.bold,
//                       ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class InsightData {
//   final IconData icon;
//   final String title;
//   final String value;
//   final Color color;

//   InsightData({
//     required this.icon,
//     required this.title,
//     required this.value,
//     required this.color,
//   });
// }
