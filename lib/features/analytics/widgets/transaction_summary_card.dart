import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/models/currency_model.dart';
import '../bloc/transaction_analytics_event.dart';

/// Card displaying transaction summary information
class TransactionSummaryCard extends StatelessWidget {
  final int totalTransactions;
  final double totalAmount;
  final TransactionType transactionType;
  final Currency currency;

  const TransactionSummaryCard({
    super.key,
    required this.totalTransactions,
    required this.totalAmount,
    required this.transactionType,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: 2,
    );

    final theme = Theme.of(context);

    // Determine color based on transaction type
    final Color amountColor = transactionType == TransactionType.expenses
        ? Colors.redAccent
        : transactionType == TransactionType.incomes
            ? Colors.green
            : totalAmount >= 0
                ? Colors.green
                : Colors.redAccent;

    // Get appropriate title based on transaction type
    final String title = transactionType == TransactionType.expenses
        ? 'Total Expenses'
        : transactionType == TransactionType.incomes
            ? 'Total Income'
            : 'Net Balance';

    // Get appropriate icon based on transaction type
    final IconData icon = transactionType == TransactionType.expenses
        ? Icons.arrow_downward
        : transactionType == TransactionType.incomes
            ? Icons.arrow_upward
            : totalAmount >= 0
                ? Icons.account_balance_wallet
                : Icons.account_balance_wallet;

    // Get gradient colors based on transaction type
    final List<Color> gradientColors =
        transactionType == TransactionType.expenses
            ? [
                Colors.redAccent.withValues(alpha: 0.1),
                Colors.redAccent.withValues(alpha: 0.15),
                Colors.redAccent.withValues(alpha: 0.05),
              ]
            : transactionType == TransactionType.incomes
                ? [
                    Colors.green.withValues(alpha: 0.05),
                    Colors.green.withValues(alpha: 0.15),
                    Colors.green.withValues(alpha: 0.1),
                  ]
                : [
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.05),
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                  ];

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: amountColor.withValues(alpha: 0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
        border: Border.all(
          color: amountColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                icon,
                size: 120.r,
                color: amountColor.withValues(alpha: 0.05),
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and icon
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: amountColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: amountColor,
                          size: 20.r,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  // Amount
                  Text(
                    formatter.format(totalAmount),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                      letterSpacing: -0.5,
                      fontSize: 28.sp,
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Transaction count
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: amountColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 14.r,
                          color: amountColor.withValues(alpha: 0.8),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '$totalTransactions transaction${totalTransactions == 1 ? '' : 's'}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: amountColor.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
