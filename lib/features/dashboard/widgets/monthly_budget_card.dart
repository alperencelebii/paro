import 'package:finance_track/core/extensions/currency_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:finance_track/core/localization/localization.dart';

/// Monthly Budget Card for the dashboard
class MonthlyBudgetCard extends StatelessWidget {
  final double totalBudget;
  final double spentAmount;
  final double remainingAmount;
  final int daysRemaining;
  final VoidCallback onTap;
  final VoidCallback? onViewAllBudgets;
  final VoidCallback? onBudgetEdit;
  const MonthlyBudgetCard({
    Key? key,
    required this.totalBudget,
    required this.spentAmount,
    required this.remainingAmount,
    required this.daysRemaining,
    required this.onTap,
    this.onViewAllBudgets,
    this.onBudgetEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = context.selectedCurrency;
    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: 0,
    );

    // Calculate percentage used - protect against div by zero
    final percentUsed = totalBudget > 0
        ? (spentAmount / totalBudget * 100).clamp(0.0, 100.0)
        : 0.0;

    // Round to nearest whole number
    final displayPercent = percentUsed.round();

    // Calculate daily budget safely
    final double dailyBudget = remainingAmount > 0 && daysRemaining > 0
        ? remainingAmount / daysRemaining
        : 0.0;

    // Get status color based on percentage used
    final statusColor = percentUsed < 70
        ? const Color(0xFF4CAF50) // Green
        : percentUsed < 90
            ? const Color(0xFFFFA726) // Orange
            : const Color(0xFFF44336); // Red

    // Get status text based on percentage used
    final statusText = percentUsed < 70
        ? 'On Track'
        : percentUsed < 90
            ? 'Caution'
            : 'Over Budget';

    // Use Material widget to make card tappable
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24.r),
          child: Container(
            width: double.infinity,
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
              children: [
                // Header with gradient background
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6C63FF),
                        Color(0xFF574ED7),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24.r),
                      topRight: Radius.circular(24.r),
                    ),
                  ),
                  padding: EdgeInsets.all(20.r),
                  child: Column(
                    children: [
                      // Budget title and status indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and days remaining
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8.r),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.account_balance_wallet,
                                        color: Colors.white,
                                        size: 18.r,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: LocalizedText('Monthly Budget',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18.sp,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        color: Colors.white,
                                        size: 14.r,
                                      ),
                                      SizedBox(width: 4.w),
                                      LocalizedText(
                                        daysRemaining > 0
                                            ? '$daysRemaining days remaining'
                                            : 'Month complete',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(width: 8.w),

                          // Circular progress indicator
                          RepaintBoundary(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                  begin: 0, end: percentUsed / 100),
                              duration: const Duration(milliseconds: 750),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) {
                                return CircularPercentIndicator(
                                  radius: 28.r,
                                  lineWidth: 5.r,
                                  percent: value,
                                  center: Padding(
                                    padding: const EdgeInsets.all(4).h,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        LocalizedText('$displayPercent%',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                        LocalizedText('Used',
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                            fontSize: 9.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  circularStrokeCap: CircularStrokeCap.round,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.2),
                                  progressColor: Colors.white,
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20.h),

                      // Budget amount row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Total budget
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LocalizedText('Total Budget',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13.sp,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              LocalizedText(
                                formatter.format(totalBudget),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.sp,
                                ),
                              ),
                            ],
                          ),

                          // Line divider
                          Container(
                            height: 40.h,
                            width: 1.w,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),

                          // Spent amount
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LocalizedText('Spent',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13.sp,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              LocalizedText(
                                formatter.format(spentAmount),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.sp,
                                ),
                              ),
                            ],
                          ),

                          // Line divider
                          Container(
                            height: 40.h,
                            width: 1.w,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),

                          // Remaining amount
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LocalizedText('Remaining',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13.sp,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              LocalizedText(
                                formatter.format(remainingAmount),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Daily Budget Section with status indicator
                Padding(
                  padding: EdgeInsets.all(12.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          LocalizedText('Budget Status',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8.r,
                                  height: 8.r,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                LocalizedText(
                                  statusText,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20.h),

                      // Daily budget display
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFEEF1FF),
                              Color(0xFFE6E9FF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              offset: const Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Daily budget amount circle
                            Container(
                              width: 60.r,
                              height: 60.r,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6C63FF)
                                        .withValues(alpha: 0.2),
                                    offset: const Offset(0, 3),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    LocalizedText(
                                      context.currencySymbol,
                                      style: TextStyle(
                                        color: const Color(0xFF6C63FF),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18.sp,
                                      ),
                                    ),
                                    LocalizedText('DAILY',
                                      style: TextStyle(
                                        color: const Color(0xFF6C63FF),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 8.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),

                            // Daily budget text information
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LocalizedText(
                                    daysRemaining > 0
                                        ? formatter.format(dailyBudget)
                                        : '---',
                                    style: TextStyle(
                                      color: const Color(0xFF6C63FF),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22.sp,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  LocalizedText(
                                    daysRemaining > 0
                                        ? 'Available to spend today'
                                        : 'Month complete',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // // Information icon with tooltip
                            // Tooltip(
                            //   message:
                            //       'Daily budget is calculated by dividing remaining budget by days left in the month.',
                            //   child: Container(
                            //     width: 36.r,
                            //     height: 36.r,
                            //     decoration: const BoxDecoration(
                            //       color: Colors.white,
                            //       shape: BoxShape.circle,
                            //     ),
                            //     child: Icon(
                            //       Icons.info_outline,
                            //       color: Colors.grey.shade600,
                            //       size: 20.r,
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Action buttons row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onBudgetEdit,
                              icon: Icon(
                                Icons.edit,
                                size: 18.r,
                                color: const Color(0xFF6C63FF),
                              ),
                              label: const LocalizedText('Edit Budget',
                                style: TextStyle(
                                  color: Color(0xFF6C63FF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                side:
                                    const BorderSide(color: Color(0xFF6C63FF)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onViewAllBudgets,
                              icon: Icon(
                                Icons.visibility,
                                size: 18.r,
                              ),
                              label: const LocalizedText('All Budgets'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C63FF),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
