import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

// /// A widget to display summary statistics for a category
// class CategorySummaryCard extends StatelessWidget {
//   final String categoryName;
//   final Color categoryColor;
//   final double totalAmount;
//   final double averageAmount;
//   final int transactionCount;
//   final double percentageOfTotal;
//   final Currency currency;

//   const CategorySummaryCard({
//     super.key,
//     required this.categoryName,
//     required this.categoryColor,
//     required this.totalAmount,
//     required this.averageAmount,
//     required this.transactionCount,
//     required this.percentageOfTotal,
//     required this.currency,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final formatter = NumberFormat.currency(
//       symbol: currency.symbol,
//       decimalDigits: 2,
//     );

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
//           Text(
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
//                   value: formatter.format(totalAmount),
//                   color: categoryColor,
//                   icon: Icons.account_balance_wallet,
//                 ),
//               ),
//               SizedBox(width: 16.w),
//               Expanded(
//                 child: _SummaryItem(
//                   title: 'Average',
//                   value: formatter.format(averageAmount),
//                   color: categoryColor.withValues(alpha:0.8),
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
//                   value: transactionCount.toString(),
//                   color: categoryColor.withValues(alpha:0.6),
//                   icon: Icons.receipt_long,
//                 ),
//               ),
//               SizedBox(width: 16.w),
//               Expanded(
//                 child: _SummaryItem(
//                   title: '% of Total',
//                   value: '${percentageOfTotal.toStringAsFixed(1)}%',
//                   color: categoryColor.withValues(alpha:0.7),
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
//                 child: Text(
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
//           Text(
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

/// A widget to display category summary statistics
class CategorySummaryCard extends StatelessWidget {
  final ThemeData theme;
  final String categoryName;
  final double amount;
  final double percentage;
  final double totalAmount;
  final bool isExpense;
  final Color color;
  final IconData icon;
  final NumberFormat formatter;

  const CategorySummaryCard({
    super.key,
    required this.theme,
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.totalAmount,
    required this.isExpense,
    required this.color,
    required this.icon,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  title: 'Total Amount',
                  value: formatter.format(amount),
                  color: color,
                  icon: Icons.account_balance_wallet,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _SummaryItem(
                  title: 'Average',
                  value: formatter.format(amount / (percentage > 0 ? 1 : 1)),
                  color: color.withValues(alpha: 0.8),
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  title: 'Transactions',
                  value: percentage.toStringAsFixed(1),
                  color: color.withValues(alpha: 0.6),
                  icon: Icons.receipt_long,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _SummaryItem(
                  title: '% of Total',
                  value: '${percentage.toStringAsFixed(1)}%',
                  color: color.withValues(alpha: 0.7),
                  icon: Icons.pie_chart,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A helper widget for summary items
class _SummaryItem extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 18.r,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
