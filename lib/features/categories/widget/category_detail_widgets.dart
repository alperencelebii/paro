import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:finance_track/core/localization/localization.dart';

/// A custom tab bar header delegate for category detail screen
class TabBarHeaderDelegate extends StatelessWidget {
  final TabController tabController;
  final Color categoryColor;

  const TabBarHeaderDelegate({
    super.key,
    required this.tabController,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: categoryColor,
      child: TabBar(
        controller: tabController,
        indicatorColor: theme.colorScheme.onPrimary,
        labelColor: theme.colorScheme.onPrimary,
        unselectedLabelColor:
            theme.colorScheme.onPrimary.withValues(alpha: 0.7),
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14.sp,
        ),
        dividerColor: Colors.transparent,
        dividerHeight: 0,
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 14.sp,
        ),
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 3,
        onTap: (value) {
          tabController.animateTo(value);
        },
        tabs: const [
          Tab(child: LocalizedText('Overview')),
          Tab(child: LocalizedText('Transactions')),
        ],
      ),
    );
  }
}

// /// A widget to display category summary statistics
// class CategorySummaryCard extends StatelessWidget {
//   final ThemeData theme;
//   final String categoryName;
//   final double amount;
//   final double percentage;
//   final double totalAmount;
//   final bool isExpense;
//   final Color color;
//   final IconData icon;
//   final NumberFormat formatter;

//   const CategorySummaryCard({
//     super.key,
//     required this.theme,
//     required this.categoryName,
//     required this.amount,
//     required this.percentage,
//     required this.totalAmount,
//     required this.isExpense,
//     required this.color,
//     required this.icon,
//     required this.formatter,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(12.r),
//       decoration: BoxDecoration(
//         color: theme.cardTheme.color ?? Colors.white,
//         borderRadius: BorderRadius.circular(24.r),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha:0.05),
//             offset: const Offset(0, 4),
//             blurRadius: 12,
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           LocalizedText(
//             'Summary',
//             style: theme.textTheme.titleMedium?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           SizedBox(height: 20.h),
//           Row(
//             children: [
//               Expanded(
//                 child: _SummaryItem(
//                   title: 'Total Amount',
//                   value: formatter.format(amount),
//                   color: color,
//                   icon: Icons.account_balance_wallet,
//                 ),
//               ),
//               SizedBox(width: 16.w),
//               Expanded(
//                 child: _SummaryItem(
//                   title: 'Average',
//                   value: formatter.format(amount / (percentage > 0 ? 1 : 1)),
//                   color: color.withValues(alpha:0.8),
//                   icon: Icons.trending_up,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 16.h),
//           Row(
//             children: [
//               Expanded(
//                 child: _SummaryItem(
//                   title: 'Transactions',
//                   value: percentage.toStringAsFixed(1),
//                   color: color.withValues(alpha:0.6),
//                   icon: Icons.receipt_long,
//                 ),
//               ),
//               SizedBox(width: 16.w),
//               Expanded(
//                 child: _SummaryItem(
//                   title: '% of Total',
//                   value: '${percentage.toStringAsFixed(1)}%',
//                   color: color.withValues(alpha:0.7),
//                   icon: Icons.pie_chart,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// A helper widget for summary items
// class _SummaryItem extends StatelessWidget {
//   final String title;
//   final String value;
//   final Color color;
//   final IconData icon;

//   const _SummaryItem({
//     required this.title,
//     required this.value,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Container(
//       padding: EdgeInsets.all(16.r),
//       decoration: BoxDecoration(
//         color: color.withValues(alpha:0.1),
//         borderRadius: BorderRadius.circular(16.r),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 icon,
//                 color: color,
//                 size: 18.r,
//               ),
//               SizedBox(width: 8.w),
//               Expanded(
//                 child: LocalizedText(
//                   title,
//                   style: theme.textTheme.bodySmall?.copyWith(
//                     fontWeight: FontWeight.w500,
//                   ),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 8.h),
//           LocalizedText(
//             value,
//             style: theme.textTheme.titleMedium?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     );
//   }
// }

/// A widget to display category trends
// class CategoryTrendChart extends StatelessWidget {
//   final ThemeData theme;
//   final List<PeriodicData> data;
//   final Color color;
//   final bool isExpense;

//   const CategoryTrendChart({
//     super.key,
//     required this.theme,
//     required this.data,
//     required this.color,
//     required this.isExpense,
//   });

//   @override
//   Widget build(BuildContext context) {
//     if (data.isEmpty) {
//       return Container(
//         padding: EdgeInsets.all(20.r),
//         decoration: BoxDecoration(
//           color: theme.cardTheme.color ?? Colors.white,
//           borderRadius: BorderRadius.circular(24.r),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha:0.05),
//               offset: const Offset(0, 4),
//               blurRadius: 12,
//             ),
//           ],
//         ),
//         child: Center(
//           child: Padding(
//             padding: EdgeInsets.symmetric(vertical: 32.h),
//             child: Column(
//               children: [
//                 Icon(
//                   Icons.timeline,
//                   size: 48.r,
//                   color: Colors.grey.withValues(alpha:0.5),
//                 ),
//                 SizedBox(height: 16.h),
//                 LocalizedText(
//                   'No data available for selected period',
//                   style: theme.textTheme.bodyLarge?.copyWith(
//                     color: Colors.grey,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }

//     return Container(
//       padding: EdgeInsets.all(12.r),
//       decoration: BoxDecoration(
//         color: theme.cardTheme.color ?? Colors.white,
//         borderRadius: BorderRadius.circular(24.r),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha:0.05),
//             offset: const Offset(0, 4),
//             blurRadius: 12,
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           LocalizedText(
//             'Spending Trend',
//             style: theme.textTheme.titleMedium?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           SizedBox(height: 24.h),
//           SizedBox(
//             height: 200.h,
//             child: LineChart(
//               LineChartData(
//                 gridData: FlGridData(
//                   show: true,
//                   drawVerticalLine: false,
//                   getDrawingHorizontalLine: (value) {
//                     return FlLine(
//                       color: theme.dividerColor.withValues(alpha:0.3),
//                       strokeWidth: 1,
//                       dashArray: [5, 5],
//                     );
//                   },
//                 ),
//                 titlesData: FlTitlesData(
//                   rightTitles: const AxisTitles(
//                     sideTitles: SideTitles(showTitles: false),
//                   ),
//                   topTitles: const AxisTitles(
//                     sideTitles: SideTitles(showTitles: false),
//                   ),
//                   bottomTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       getTitlesWidget: (value, meta) {
//                         if (value.toInt() >= 0 && value.toInt() < data.length) {
//                           return Padding(
//                             padding: EdgeInsets.only(top: 8.h),
//                             child: LocalizedText(
//                               DateFormat('MMM d')
//                                   .format(data[value.toInt()].date),
//                               style: theme.textTheme.bodySmall,
//                             ),
//                           );
//                         }
//                         return const SizedBox();
//                       },
//                       reservedSize: 30,
//                     ),
//                   ),
//                   leftTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       getTitlesWidget: (value, meta) {
//                         return Padding(
//                           padding: EdgeInsets.only(right: 8.w),
//                           child: LocalizedText(
//                             NumberFormat.compactCurrency(
//                               symbol: '\$',
//                               decimalDigits: 0,
//                             ).format(value),
//                             style: theme.textTheme.bodySmall,
//                           ),
//                         );
//                       },
//                       reservedSize: 40,
//                     ),
//                   ),
//                 ),
//                 borderData: FlBorderData(show: false),
//                 lineBarsData: [
//                   LineChartBarData(
//                     spots: List.generate(
//                       data.length,
//                       (index) => FlSpot(
//                         index.toDouble(),
//                         data[index].amount,
//                       ),
//                     ),
//                     isCurved: true,
//                     color: color,
//                     barWidth: 3,
//                     isStrokeCapRound: true,
//                     dotData: FlDotData(
//                       show: true,
//                       getDotPainter: (spot, percent, barData, index) {
//                         return FlDotCirclePainter(
//                           radius: 4,
//                           color: color,
//                           strokeWidth: 2,
//                           strokeColor: Colors.white,
//                         );
//                       },
//                     ),
//                     belowBarData: BarAreaData(
//                       show: true,
//                       color: color.withValues(alpha:0.2),
//                     ),
//                   ),
//                 ],
//                 lineTouchData: LineTouchData(
//                   touchTooltipData: LineTouchTooltipData(
//                     tooltipBgColor: theme.colorScheme.surface.withValues(alpha:0.8),
//                     tooltipRoundedRadius: 8,
//                     getTooltipItems: (touchedSpots) {
//                       return touchedSpots.map((spot) {
//                         final index = spot.x.toInt();
//                         if (index >= 0 && index < data.length) {
//                           final item = data[index];
//                           return LineTooltipItem(
//                             '${DateFormat('MMM d').format(item.date)}\n${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(item.amount)}',
//                             TextStyle(
//                               color: theme.colorScheme.onSurface,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           );
//                         }
//                         return null;
//                       }).toList();
//                     },
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
