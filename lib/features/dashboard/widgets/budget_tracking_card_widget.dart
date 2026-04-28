import 'dart:async';
import 'package:finance_track/core/localization/localization.dart';

import 'package:finance_track/core/models/currency_model.dart';
import 'package:finance_track/core/router/app_router.dart';
import 'package:finance_track/features/budget/bloc/budget_bloc/budget_bloc.dart';
import 'package:finance_track/features/budget/screens/budget_form_screen.dart';
import 'package:finance_track/features/dashboard/cubit/dashboard_state.dart';
import 'package:finance_track/features/dashboard/widgets/monthly_budget_card.dart';
// import 'package:finance_track/features/subscription/cubits/purchases_cubit/purchases_cubit.dart';
import 'package:finance_track/features/subscription/cubits/subscription_cubit/subscription_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:finance_track/core/extensions/currency_context_extension.dart';

class BudgetTrackingCardWidget extends StatelessWidget {
  const BudgetTrackingCardWidget(
      {super.key, required this.state, required this.currency});
  final DashboardLoaded state;
  final Currency currency;

  // void _requirePremium(
  //   BuildContext context,
  //   void Function(BuildContext) onAllowed,
  // ) {
  //   final subscriptionCubit = context.read<SubscriptionCubit>();
  //   final purchasesCubit = context.read<PurchasesCubit>();
  //   subscriptionCubit.ensureProStatus().then((isPro) {
  //     if (!context.mounted) return;
  //     if (isPro) {
  //       onAllowed(context);
  //     } else {
  //       purchasesCubit.loadOfferings(autoPresentPaywall: false);
  //       context.pushNamed(AppRoutes.purchasesPage);
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final subscriptionState = context.watch<SubscriptionCubit>().state;
    if (subscriptionState.status == SubscriptionStatus.initial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.read<SubscriptionCubit>().ensureProStatus();
      });
    }

    return BlocBuilder<BudgetBloc, BudgetState>(
      builder: (context, budgetState) {
        if (budgetState is BudgetLoaded) {
          // Calculate days remaining in current month
          final now = DateTime.now();
          final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
          final daysRemaining = lastDayOfMonth.day - now.day;

          // Find current month's budget if available
          final currentMonthBudget = budgetState.activeBudget;

          // Calculate spent amount from expenses
          final double spentAmount = state.thisMonthExpenses;
          if (currentMonthBudget == null) {
            // No active budget → show compact "spent only" with CTA to create budget
            return _noBudgetCompact(context, spentAmount);
          }

          final double totalBudget = currentMonthBudget.amount.toDouble();
          final double remainingAmount =
              totalBudget > spentAmount ? totalBudget - spentAmount : 0.0;

          // if (!subscriptionState.isProUser &&
          //     subscriptionState.status == SubscriptionStatus.success) {
          //   return _lockedBudgetPreview(
          //     context: context,
          //     spentAmount: spentAmount,
          //     totalBudget: totalBudget,
          //     daysRemaining: daysRemaining,
          //   );
          // }

          // if (!subscriptionState.isProUser &&
          //     subscriptionState.status == SubscriptionStatus.loading) {
          //   return _buildPlaceholderBudgetCard(context);
          // }

          return MonthlyBudgetCard(
            onBudgetEdit: () {
              // _requirePremium(context, (ctx) {
              //   unawaited(
              //     budgetFormDialog(ctx, budget: currentMonthBudget),
              //   );
              // });
              unawaited(
                budgetFormDialog(context, budget: currentMonthBudget),
              );
            },
            totalBudget: totalBudget,
            spentAmount: spentAmount,
            remainingAmount: remainingAmount,
            daysRemaining: daysRemaining,
            onTap: () {
              // _requirePremium(context, (ctx) {
              //   if (currentMonthBudget.id != null) {
              //     ctx.pushNamed(
              //       AppRoutes.budgetDetail,
              //       extra: {'budget': currentMonthBudget},
              //     );
              //   } else {
              //     ctx.pushNamed(AppRoutes.budgetSettings);
              //   }
              // });
              context.pushNamed(
                AppRoutes.budgetDetail,
                extra: {'budget': currentMonthBudget},
              );
            },
            onViewAllBudgets: () {
              // _requirePremium(context, (ctx) {
              //   ctx.pushNamed(AppRoutes.budgetSettings);
              // });
              context.pushNamed(AppRoutes.budgetSettings);
            },
          );
        } else if (budgetState is BudgetLoading) {
          return _buildPlaceholderBudgetCard(context);
        } else if (budgetState is BudgetError) {
          return Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            height: 150.h,
            child: Center(
              child: LocalizedText('Error loading budget: ${budgetState.message}',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14.sp,
                ),
              ),
            ),
          );
        }
        return _buildPlaceholderBudgetCard(context);
      },
    );
  }

  Widget _noBudgetCompact(BuildContext context, double spentAmount) {
    final symbol = context.currencySymbol;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizedText('Used $symbol${spentAmount.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              SizedBox(height: 4.h),
              LocalizedText('No active budget',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              // _requirePremium(context, (ctx) {
              //   ctx.pushNamed(AppRoutes.budgetSettings);
              // });
              context.pushNamed(AppRoutes.budgetSettings);
            },
            child: const LocalizedText('Set Budget'),
          )
        ],
      ),
    );
  }

  Widget _buildPlaceholderBudgetCard(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      height: 150.h,
      child: Row(
        children: [
          // Left side (progress circle placeholder)
          Container(
            width: 80.r,
            height: 80.r,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 16.w),
          // Right side (text placeholders)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 24.h,
                  width: 150.w,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  height: 16.h,
                  width: 100.w,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  height: 16.h,
                  width: 120.w,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _lockedBudgetPreview({
  //   required BuildContext context,
  //   required double spentAmount,
  //   required double totalBudget,
  //   required int daysRemaining,
  // }) {
  //   final symbol = context.currencySymbol;
  //   final percentUsed =
  //       totalBudget <= 0 ? 0.0 : (spentAmount / totalBudget).clamp(0.0, 1.0);
  //   final percentText = '${(percentUsed * 100).round()}% used';

  //   return Container(
  //     width: double.infinity,
  //     margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
  //     padding: EdgeInsets.all(20.r),
  //     decoration: BoxDecoration(
  //       gradient: const LinearGradient(
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //         colors: [
  //           Color(0xFF6C63FF),
  //           Color(0xFF574ED7),
  //         ],
  //       ),
  //       borderRadius: BorderRadius.circular(24.r),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withValues(alpha: 0.08),
  //           offset: const Offset(0, 8),
  //           blurRadius: 20,
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Container(
  //               padding: EdgeInsets.all(8.r),
  //               decoration: BoxDecoration(
  //                 color: Colors.white.withValues(alpha: 0.2),
  //                 shape: BoxShape.circle,
  //               ),
  //               child: Icon(
  //                 Icons.lock_outline,
  //                 color: Colors.white,
  //                 size: 18.r,
  //               ),
  //             ),
  //             SizedBox(width: 12.w),
  //             Expanded(
  //               child: LocalizedText(
  //                 'Budget insights preview',
  //                 style: TextStyle(
  //                   color: Colors.white,
  //                   fontWeight: FontWeight.bold,
  //                   fontSize: 16.sp,
  //                 ),
  //               ),
  //             ),
  //             Container(
  //               padding: EdgeInsets.symmetric(
  //                 horizontal: 12.w,
  //                 vertical: 4.h,
  //               ),
  //               decoration: BoxDecoration(
  //                 color: Colors.white.withValues(alpha: 0.2),
  //                 borderRadius: BorderRadius.circular(12.r),
  //               ),
  //               child: LocalizedText(
  //                 'Premium',
  //                 style: TextStyle(
  //                   color: Colors.white,
  //                   fontWeight: FontWeight.w600,
  //                   fontSize: 12.sp,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         SizedBox(height: 18.h),
  //         LocalizedText(
  //           'Spent $symbol${spentAmount.toStringAsFixed(0)} this month',
  //           style: TextStyle(
  //             color: Colors.white,
  //             fontWeight: FontWeight.bold,
  //             fontSize: 20.sp,
  //           ),
  //         ),
  //         SizedBox(height: 8.h),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: ClipRRect(
  //                 borderRadius: BorderRadius.circular(6.r),
  //                 child: LinearProgressIndicator(
  //                   value: percentUsed,
  //                   backgroundColor: Colors.white.withValues(alpha: 0.25),
  //                   valueColor:
  //                       const AlwaysStoppedAnimation<Color>(Colors.white),
  //                   minHeight: 6.r,
  //                 ),
  //               ),
  //             ),
  //             SizedBox(width: 12.w),
  //             LocalizedText(
  //               percentText,
  //               style: TextStyle(
  //                 color: Colors.white.withValues(alpha: 0.9),
  //                 fontWeight: FontWeight.w600,
  //                 fontSize: 12.sp,
  //               ),
  //             ),
  //           ],
  //         ),
  //         SizedBox(height: 16.h),
  //         LocalizedText(
  //           daysRemaining > 0
  //               ? '$daysRemaining days left in your plan.'
  //               : 'This month is complete.',
  //           style: TextStyle(
  //             color: Colors.white.withValues(alpha: 0.85),
  //             fontSize: 12.sp,
  //             fontWeight: FontWeight.w500,
  //           ),
  //         ),
  //         SizedBox(height: 10.h),
  //         LocalizedText(
  //           'Unlock remaining balance, daily allowance and smart alerts with Premium.',
  //           style: TextStyle(
  //             color: Colors.white.withValues(alpha: 0.8),
  //             fontSize: 12.sp,
  //             height: 1.4,
  //           ),
  //         ),
  //         SizedBox(height: 16.h),
  //         SizedBox(
  //           width: double.infinity,
  //           child: ElevatedButton(
  //             onPressed: () => _promptUpgrade(context),
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.white,
  //               foregroundColor: const Color(0xFF574ED7),
  //               elevation: 0,
  //               padding: EdgeInsets.symmetric(vertical: 12.h),
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(14.r),
  //               ),
  //             ),
  //             child: const LocalizedText('Unlock Premium Insights'),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // void _promptUpgrade(BuildContext context) {
  //   final purchasesCubit = context.read<PurchasesCubit>();
  //   purchasesCubit.loadOfferings(autoPresentPaywall: false);
  //   context.pushNamed(AppRoutes.purchasesPage);
  // }
}
