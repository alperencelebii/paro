import 'package:finance_track/core/extensions/currency_context_extension.dart';
import 'package:finance_track/core/router/app_router.dart';
import 'package:finance_track/features/subscription/cubits/subscription_cubit/subscription_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:finance_track/core/localization/localization.dart';

/// Widget for displaying current month detailed summary
class CurrentMonthSummaryCard extends StatelessWidget {
  final double thisMonthIncome;
  final double thisMonthExpense;
  final double thisMonthBalance;
  final Map<dynamic, double> topExpenseCategories;
  final Map<dynamic, double> topIncomeCategories;

  const CurrentMonthSummaryCard({
    super.key,
    required this.thisMonthIncome,
    required this.thisMonthExpense,
    required this.thisMonthBalance,
    required this.topExpenseCategories,
    required this.topIncomeCategories,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = context.selectedCurrency;
    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: 2,
    );

    void requirePremium(VoidCallback onAllowed) {
      final subscriptionCubit = context.read<SubscriptionCubit>();
      // final purchasesCubit = context.read<PurchasesCubit>();
      subscriptionCubit.ensureProStatus().then((isPro) {
        if (!context.mounted) return;
        if (isPro) {
          onAllowed();
        } else {
          // purchasesCubit.loadOfferings();
          context.pushNamed(AppRoutes.purchasesPage);
        }
      });
    }

    // Current month name and year
    final now = DateTime.now();
    final currentMonth = DateFormat('MMMM').format(now);
    final currentYear = now.year.toString();

    // Calculate days passed and total days in current month
    final totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day;
    final daysLeft = totalDaysInMonth - daysPassed;
    final monthProgress = daysPassed / totalDaysInMonth;

    // Calculate estimated end of month balance with safeguards
    double projectedEndBalance;

    // Use a more realistic projection based on actual daily averages
    if (daysPassed < 2) {
      // If it's early in the month, use thisMonthBalance as-is
      projectedEndBalance = thisMonthBalance;
    } else {
      // Calculate daily average income and expense
      final dailyAvgIncome = thisMonthIncome / daysPassed;
      final dailyAvgExpense = thisMonthExpense / daysPassed;

      // Project remaining days using these averages
      final projectedRemainingIncome = dailyAvgIncome * daysLeft;
      final projectedRemainingExpense = dailyAvgExpense * daysLeft;

      // Calculate projected end balance
      projectedEndBalance = thisMonthBalance +
          projectedRemainingIncome -
          projectedRemainingExpense;

      // Apply a sensible cap to prevent unrealistic projections
      // If projection is more than 3 times the current balance, limit it
      if (projectedEndBalance > 0 &&
          projectedEndBalance > thisMonthBalance * 3) {
        projectedEndBalance = thisMonthBalance * 1.5;
      }
    }

    // Determine saving or overspending status

    // Budget utilization
    final budgetUtilization =
        thisMonthIncome > 0 ? (thisMonthExpense / thisMonthIncome * 100) : 0.0;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 4),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with month info and visual indicator
          _buildHeader(
            context,
            currentMonth,
            currentYear,
            daysPassed,
            totalDaysInMonth,
            monthProgress,
            thisMonthBalance,
            formatter,
          ),

          // Financial stats section
          Container(
            decoration: const BoxDecoration(
                // Color based on status - light background matching the status
                // color: isPositiveProjection
                //     ? const Color.fromARGB(255, 234, 243, 234)
                //     : const Color.fromARGB(255, 255, 245, 245),
                // borderRadius: BorderRadius.circular(16.r),
                ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 14.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month projection panel
                  _buildProjectionPanel(
                    context,
                    daysLeft,
                    projectedEndBalance,
                    formatter,
                    budgetUtilization,
                  ),

                  SizedBox(height: 16.h),

                  // View details button
                  ElevatedButton.icon(
                    onPressed: () {
                      requirePremium(() {
                        context.pushNamed(AppRoutes.monthlySummary);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: Size(double.infinity, 50.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    icon: Icon(
                      Icons.analytics_outlined,
                      size: 20.r,
                    ),
                    label: LocalizedText('View Detailed Analysis',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Builds the header section with month info and balance
  Widget _buildHeader(
    BuildContext context,
    String month,
    String year,
    int daysPassed,
    int totalDaysInMonth,
    double monthProgress,
    double balance,
    NumberFormat formatter,
  ) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6C63FF),
            Color(0xFF4942E4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Column(
        children: [
          // Month header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Month and year
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 20.r,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocalizedText('$month $year',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      LocalizedText('$daysPassed of $totalDaysInMonth days',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Month progress indicator
              Column(
                children: [
                  SizedBox(
                    height: 46.r,
                    width: 46.r,
                    child: Stack(
                      children: [
                        CircularPercentIndicator(
                          radius: 23.r,
                          lineWidth: 4.5.w,
                          percent: monthProgress,
                          circularStrokeCap: CircularStrokeCap.round,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          progressColor: Colors.white,
                          center: LocalizedText('${(monthProgress * 100).toInt()}%',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  LocalizedText('${totalDaysInMonth - daysPassed} days left',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // Balance row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText('Current Balance',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        LocalizedText(
                          formatter.format(balance),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 28.sp,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: balance >= 0
                                ? Colors.green.withValues(alpha: 0.3)
                                : Colors.red.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                balance >= 0
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                                color: Colors.white,
                                size: 14.r,
                              ),
                              SizedBox(width: 4.w),
                              LocalizedText(
                                balance >= 0 ? 'Positive' : 'Negative',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Builds the month projection panel
  Widget _buildProjectionPanel(
    BuildContext context,
    int daysLeft,
    double projectedBalance,
    NumberFormat formatter,
    double budgetUtilization,
  ) {
    final theme = Theme.of(context);
    final isPositiveProjection = projectedBalance >= 0;
    final now = DateTime.now();
    final daysPassed = now.day;

    // Determine budget status and color based on actual budget utilization
    String budgetStatus;
    Color statusColor;
    Color badgeBackgroundColor;

    if (budgetUtilization <= 80) {
      budgetStatus = 'On Track';
      statusColor = const Color(0xFF4CAF50); // Green
      badgeBackgroundColor = const Color(0xFFE8F5E9); // Light green
    } else if (budgetUtilization <= 100) {
      budgetStatus = 'Caution';
      statusColor = const Color(0xFFFFA000); // Amber
      badgeBackgroundColor = const Color(0xFFFFF3E0); // Light amber
    } else {
      budgetStatus = 'Over Budget';
      statusColor = const Color(0xFFE53935); // Red
      badgeBackgroundColor = const Color(0xFFFFDCDC); // Light red
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row with icon, title and badge
        Row(
          children: [
            // Icon container with color based on projection
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: isPositiveProjection
                    ? const Color(0xFFCCEDCC)
                    : const Color(0xFFFFDCDC),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPositiveProjection
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: isPositiveProjection
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFE53935),
                size: 14.r,
              ),
            ),
            SizedBox(width: 12.w),

            // Title
            Expanded(
              child: LocalizedText('Month End Forecast',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Badge for budget status with dynamic content based on actual status
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: badgeBackgroundColor,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6.r,
                    height: 6.r,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  LocalizedText(
                    budgetStatus, // Dynamic status text
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // Balance section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedText('Projected Balance',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: LocalizedText(
                    formatter.format(projectedBalance),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                      color: isPositiveProjection
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFE53935),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                LocalizedText(
                  // Show daily average context rather than just the final amount
                  thisMonthIncome > 0
                      ? 'Avg. daily income: ${formatter.format(thisMonthIncome / daysPassed)}'
                      : 'No income recorded yet',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),

            // Days remaining
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 12.r,
                    color: Colors.indigo,
                  ),
                  SizedBox(width: 4.w),
                  LocalizedText('$daysLeft days left',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.indigo,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Add spending analysis row
        Padding(
          padding: EdgeInsets.only(top: 6.h),
          child: LocalizedText(
            // Show daily average expense context
            'Avg. daily expense: ${formatter.format(thisMonthExpense / (daysPassed > 0 ? daysPassed : 1))}',
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.black54,
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Budget usage section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            LocalizedText('Budget Usage',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12.sp,
                color: Colors.black54,
              ),
            ),
            LocalizedText('${budgetUtilization.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
                color: statusColor,
              ),
            ),
          ],
        ),

        SizedBox(height: 8.h),

        // Progress bar with actual budget utilization
        ClipRRect(
          borderRadius: BorderRadius.circular(6.r),
          child: SizedBox(
            height: 10.h,
            width: double.infinity,
            child: LayoutBuilder(builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;

              // Calculate progress width based on actual budget utilization
              final progressWidth = (budgetUtilization / 100 * availableWidth)
                  .clamp(0.0, availableWidth);

              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 10.h,
                  width: progressWidth,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _getProgressGradient(budgetUtilization),
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // // Progress labels
        // Padding(
        //   padding: EdgeInsets.only(top: 6.h),
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //     children: [
        //       LocalizedText(
        //         '0%',
        //         style: TextStyle(
        //           color: Colors.black.withValues(alpha:0.7),
        //           fontSize: 10.sp,
        //         ),
        //       ),
        //       LocalizedText(
        //         '50%',
        //         style: TextStyle(
        //           color: Colors.black.withValues(alpha:0.7),
        //           fontSize: 10.sp,
        //         ),
        //       ),
        //       LocalizedText(
        //         '100%',
        //         style: TextStyle(
        //           color: Colors.black.withValues(alpha:0.7),
        //           fontSize: 10.sp,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  // Helper method to get progress gradient colors
  List<Color> _getProgressGradient(double percentage) {
    if (percentage < 70) {
      return [Colors.greenAccent, const Color.fromARGB(255, 81, 214, 150)];
    } else if (percentage < 90) {
      return [Colors.greenAccent, Colors.orangeAccent];
    } else {
      return [Colors.orangeAccent, Colors.redAccent];
    }
  }
}
