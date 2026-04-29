
import 'dart:math' as math;

import 'package:finance_track/core/colors/app_colors.dart';
import 'package:finance_track/core/extensions/currency_context_extension.dart';
import 'package:finance_track/core/localization/localization.dart';
import 'package:finance_track/core/router/app_router.dart';
import 'package:finance_track/core/utils/currency_formatter.dart';
import 'package:finance_track/data/models/expense_model.dart';
import 'package:finance_track/data/models/income_model.dart';
import 'package:finance_track/features/expense_list/bloc/expense_list_bloc.dart';
import 'package:finance_track/features/expense_list/bloc/expense_list_event.dart';
import 'package:finance_track/features/expense_list/bloc/expense_list_state.dart';
import 'package:finance_track/features/home/services/paro_insights_service.dart';
import 'package:finance_track/features/income_list/bloc/income_list_bloc.dart';
import 'package:finance_track/features/income_list/bloc/income_list_event.dart';
import 'package:finance_track/features/income_list/bloc/income_list_state.dart';
import 'package:finance_track/features/navigation/cubit/navigation_cubit.dart';
import 'package:finance_track/features/recurring_expenses/services/recurring_expense_service.dart';
import 'package:finance_track/features/savings_goals/services/savings_goal_service.dart';
import 'package:finance_track/features/transactions/utils/transaction_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class ParoPremiumDashboard extends StatelessWidget {
  const ParoPremiumDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseListBloc, ExpenseListState>(
      builder: (context, expenseState) {
        final expenses = expenseState is ExpenseListLoaded
            ? expenseState.expenses
            : const <Expense>[];

        return BlocBuilder<IncomeListBloc, IncomeListState>(
          builder: (context, incomeState) {
            final incomes = incomeState.status == IncomeListStatus.loaded
                ? incomeState.incomes
                : const <Income>[];
            final currency = context.selectedCurrency;
            final now = DateTime.now();

            final monthExpenses =
                expenses.where((e) => _isSameMonth(e.date, now)).toList();
            final monthIncomes =
                incomes.where((i) => _isSameMonth(i.date, now)).toList();
            final totalExpenses =
                expenses.fold<double>(0, (sum, item) => sum + item.amount);
            final totalIncomes =
                incomes.fold<double>(0, (sum, item) => sum + item.amount);
            final monthExpenseTotal =
                monthExpenses.fold<double>(0, (sum, item) => sum + item.amount);
            final monthIncomeTotal =
                monthIncomes.fold<double>(0, (sum, item) => sum + item.amount);
            final balance = totalIncomes - totalExpenses;
            final monthNet = monthIncomeTotal - monthExpenseTotal;
            final trendValues =
                ParoInsightsService.dailyExpenseTrend(expenses, days: 7);
            final insights = ParoInsightsService.buildInsights(
              expenses: expenses,
              incomes: incomes,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroBalanceCard(
                  balance: CurrencyFormatter.format(balance, currency),
                  monthNet: CurrencyFormatter.format(monthNet, currency),
                  income: CurrencyFormatter.format(monthIncomeTotal, currency),
                  expense: CurrencyFormatter.format(monthExpenseTotal, currency),
                  isPositive: monthNet >= 0,
                ),
                SizedBox(height: 14.h),
                _QuickActionsGrid(
                  onAddExpense: () => _addExpense(context),
                  onAddIncome: () => _addIncome(context),
                  onScan: () {
                    HapticFeedback.lightImpact();
                    context.push(AppPaths.invoiceScanner);
                  },
                  onGoals: () {
                    HapticFeedback.lightImpact();
                    context.pushNamed(AppRoutes.savingsGoals);
                  },
                  onRecurring: () {
                    HapticFeedback.lightImpact();
                    context.pushNamed(AppRoutes.recurringExpenses);
                  },
                ),
                SizedBox(height: 14.h),
                _SmartInsightCard(insights: insights),
                SizedBox(height: 14.h),
                _TrendAndPreviewRow(
                  values: trendValues,
                  total: CurrencyFormatter.format(
                    trendValues.fold<double>(0, (sum, item) => sum + item),
                    currency,
                  ),
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: _SavingsPreviewCard(
                        service: SavingsGoalService(),
                        onTap: () => context.pushNamed(AppRoutes.savingsGoals),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _RecurringPreviewCard(
                        service: RecurringExpenseService(),
                        currencyFormatter: (amount) =>
                            CurrencyFormatter.format(amount, currency),
                        onTap: () =>
                            context.pushNamed(AppRoutes.recurringExpenses),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  static bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  Future<void> _addExpense(BuildContext context) async {
    HapticFeedback.lightImpact();
    final result = await TransactionUtils.showAddExpenseSheet(context: context);
    if (result == true && context.mounted) {
      context.read<ExpenseListBloc>().add(const LoadExpenses());
    }
  }

  Future<void> _addIncome(BuildContext context) async {
    HapticFeedback.lightImpact();
    final result = await TransactionUtils.showAddIncomeSheet(context: context);
    if (result == true && context.mounted) {
      context.read<IncomeListBloc>().add(const LoadIncomes());
    }
  }
}

class _HeroBalanceCard extends StatelessWidget {
  const _HeroBalanceCard({
    required this.balance,
    required this.monthNet,
    required this.income,
    required this.expense,
    required this.isPositive,
  });

  final String balance;
  final String monthNet;
  final String income;
  final String expense;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12.w,
            top: -24.h,
            child: Container(
              width: 120.r,
              height: 120.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 8.w,
            bottom: -32.h,
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white.withValues(alpha: 0.08),
              size: 128.r,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14.r),
                    child: Image.asset(
                      'assets/images/paro_logo.png',
                      width: 42.r,
                      height: 42.r,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: LocalizedText(
                      'PARO kontrol merkezi',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: (isPositive ? AppColors.income : AppColors.expense)
                          .withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: Colors.white,
                          size: 14.r,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          monthNet,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              LocalizedText(
                'Toplam bakiye',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                balance,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 30.sp,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 22.h),
              Row(
                children: [
                  Expanded(
                    child: _HeroMiniStat(
                      label: 'Bu ay gelir',
                      value: income,
                      icon: Icons.arrow_downward_rounded,
                      color: AppColors.income,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _HeroMiniStat(
                      label: 'Bu ay gider',
                      value: expense,
                      icon: Icons.arrow_upward_rounded,
                      color: AppColors.expense,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMiniStat extends StatelessWidget {
  const _HeroMiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 30.r,
            height: 30.r,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16.r, color: Colors.white),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedText(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.onAddExpense,
    required this.onAddIncome,
    required this.onScan,
    required this.onGoals,
    required this.onRecurring,
  });

  final VoidCallback onAddExpense;
  final VoidCallback onAddIncome;
  final VoidCallback onScan;
  final VoidCallback onGoals;
  final VoidCallback onRecurring;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionTile(
                title: 'Gider',
                icon: Icons.remove_rounded,
                color: AppColors.expense,
                onTap: onAddExpense,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _QuickActionTile(
                title: 'Gelir',
                icon: Icons.add_rounded,
                color: AppColors.income,
                onTap: onAddIncome,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _QuickActionTile(
                title: 'Fiş tara',
                icon: Icons.document_scanner_rounded,
                color: AppColors.primary,
                onTap: onScan,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _WideActionTile(
                title: 'Birikim hedefleri',
                icon: Icons.flag_rounded,
                color: AppColors.accent,
                onTap: onGoals,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _WideActionTile(
                title: 'Abonelikler',
                icon: Icons.repeat_rounded,
                color: AppColors.warning,
                onTap: onRecurring,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.22),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22.r),
            ),
            SizedBox(height: 8.h),
            LocalizedText(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideActionTile extends StatelessWidget {
  const _WideActionTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20.r),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: LocalizedText(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmartInsightCard extends StatelessWidget {
  const _SmartInsightCard({required this.insights});

  final List<ParoInsight> insights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = insights.isNotEmpty
        ? insights.first
        : const ParoInsight(
            title: 'PARO analiz',
            message: 'Veri ekledikçe daha akıllı öneriler gelecek.',
            icon: Icons.auto_awesome_rounded,
            color: AppColors.primary,
          );

    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  first.color.withValues(alpha: 0.18),
                  AppColors.primary.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(first.icon, color: first.color, size: 24.r),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedText(
                  first.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5.h),
                LocalizedText(
                  first.message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendAndPreviewRow extends StatelessWidget {
  const _TrendAndPreviewRow({
    required this.values,
    required this.total,
  });

  final List<double> values;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniTrendCard(values: values, total: total),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _BudgetNudgeCard(
            onTap: () {
              final String path = AppPaths.getPathForTab(NavigationTab.analytics);
              context.go(path);
              context.read<NavigationCubit>().changeTab(NavigationTab.analytics);
            },
          ),
        ),
      ],
    );
  }
}

class _MiniTrendCard extends StatelessWidget {
  const _MiniTrendCard({
    required this.values,
    required this.total,
  });

  final List<double> values;
  final String total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 142.h,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalizedText(
            '7 gün gider',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            total,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12.h),
          Expanded(
            child: CustomPaint(
              painter: _MiniTrendPainter(values: values),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTrendPainter extends CustomPainter {
  const _MiniTrendPainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = values.isEmpty ? 0 : values.reduce(math.max);
    final safeMax = maxValue <= 0 ? 1 : maxValue;
    final barWidth = size.width / (values.length * 1.8);
    final gap = (size.width - barWidth * values.length) / (values.length - 1);
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.gradientStart, AppColors.gradientEnd],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(Offset.zero & size);

    for (var i = 0; i < values.length; i++) {
      final normalized = values[i] / safeMax;
      final height = math.max(8.0, size.height * normalized);
      final left = i * (barWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, size.height - height, barWidth, height),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniTrendPainter oldDelegate) =>
      oldDelegate.values != values;
}

class _BudgetNudgeCard extends StatelessWidget {
  const _BudgetNudgeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        height: 142.h,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.95),
              AppColors.gradientStart.withValues(alpha: 0.82),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.insights_rounded,
              color: Colors.white,
              size: 28.r,
            ),
            const Spacer(),
            LocalizedText(
              'Detaylı analiz',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 5.h),
            LocalizedText(
              'Kategori kırılımını ve trendlerini gör.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.84),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingsPreviewCard extends StatelessWidget {
  const _SavingsPreviewCard({
    required this.service,
    required this.onTap,
  });

  final SavingsGoalService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currency = context.selectedCurrency;
    final theme = Theme.of(context);

    return FutureBuilder(
      future: service.getGoals(),
      builder: (context, snapshot) {
        final goals = snapshot.data ?? const [];
        final saved = goals.fold<double>(0, (sum, goal) => sum + goal.savedAmount);
        final target =
            goals.fold<double>(0, (sum, goal) => sum + goal.targetAmount);
        final progress = target <= 0 ? 0.0 : (saved / target).clamp(0.0, 1.0).toDouble();

        return _PreviewShell(
          onTap: onTap,
          icon: Icons.flag_rounded,
          color: AppColors.accent,
          title: 'Hedefler',
          value: goals.isEmpty
              ? 'Başlat'
              : CurrencyFormatter.format(saved, currency),
          subtitle: goals.isEmpty
              ? 'Birikim hedefi ekle'
              : '%${(progress * 100).toStringAsFixed(0)} tamamlandı',
          bottom: LinearProgressIndicator(
            value: progress,
            minHeight: 6.h,
            backgroundColor: AppColors.accent.withValues(alpha: 0.12),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      },
    );
  }
}

class _RecurringPreviewCard extends StatelessWidget {
  const _RecurringPreviewCard({
    required this.service,
    required this.currencyFormatter,
    required this.onTap,
  });

  final RecurringExpenseService service;
  final String Function(double amount) currencyFormatter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: service.monthlyEstimate(),
      builder: (context, snapshot) {
        final estimate = snapshot.data ?? 0.0;
        return _PreviewShell(
          onTap: onTap,
          icon: Icons.repeat_rounded,
          color: AppColors.warning,
          title: 'Abonelik',
          value: estimate <= 0 ? 'Ekle' : currencyFormatter(estimate),
          subtitle: estimate <= 0 ? 'Tekrarlayan gider' : 'aylık tahmini',
          bottom: Row(
            children: [
              Icon(Icons.schedule_rounded, size: 14.r, color: AppColors.warning),
              SizedBox(width: 5.w),
              Expanded(
                child: LocalizedText(
                  'Yaklaşan ödemeleri izle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.58),
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PreviewShell extends StatelessWidget {
  const _PreviewShell({
    required this.onTap,
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.bottom,
  });

  final VoidCallback onTap;
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;
  final Widget bottom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        height: 142.h,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.24),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20.r),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.34),
                ),
              ],
            ),
            const Spacer(),
            LocalizedText(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8.h),
            LocalizedText(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
              ),
            ),
            SizedBox(height: 8.h),
            bottom,
          ],
        ),
      ),
    );
  }
}
