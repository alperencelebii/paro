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
import 'package:finance_track/features/home/services/paro_calm_coach_service.dart';
import 'package:finance_track/features/home/services/paro_insights_service.dart';
import 'package:finance_track/features/income_list/bloc/income_list_bloc.dart';
import 'package:finance_track/features/income_list/bloc/income_list_event.dart';
import 'package:finance_track/features/income_list/bloc/income_list_state.dart';
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
            final dailyStatus = ParoCalmCoachService.dailyStatus(
              expenses: expenses,
              incomes: incomes,
            );
            final calmSuggestions = ParoCalmCoachService.suggestions(
              expenses: expenses,
              incomes: incomes,
            );
            final gentleNotifications = ParoCalmCoachService.gentleNotifications(
              expenses: expenses,
              incomes: incomes,
            );
            final quickAdds = ParoCalmCoachService.quickAdds(expenses);
            final comfortScore = ParoCalmCoachService.financialComfortScore(
              expenses: expenses,
              incomes: incomes,
            );

            String money(double amount) => CurrencyFormatter.format(amount, currency);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroBalanceCard(
                  balance: money(balance),
                  monthNet: money(monthNet),
                  income: money(monthIncomeTotal),
                  expense: money(monthExpenseTotal),
                  isPositive: monthNet >= 0,
                  comfortScore: comfortScore,
                ),
                SizedBox(height: 14.h),
                _DailyComfortCard(
                  data: dailyStatus,
                  onPrimaryAction: () => _addExpense(context),
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
                _OneTapAddCard(
                  suggestions: quickAdds,
                  formatter: money,
                  onTap: () => _addExpense(context),
                ),
                SizedBox(height: 14.h),
                _SmartInsightCard(insights: insights),
                SizedBox(height: 14.h),
                _CalmSuggestionsCard(
                  suggestions: calmSuggestions,
                  onGoals: () => context.pushNamed(AppRoutes.savingsGoals),
                ),
                SizedBox(height: 14.h),
                _GentleNotificationsCard(
                  notifications: gentleNotifications,
                  onSettings: () => context.pushNamed(AppRoutes.reminderSettings),
                ),
                SizedBox(height: 14.h),
                _TrendAndPreviewRow(
                  values: trendValues,
                  total: money(
                    trendValues.fold<double>(0, (sum, item) => sum + item),
                  ),
                ),
                SizedBox(height: 14.h),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 360;
                    final goals = _SavingsPreviewCard(
                      service: SavingsGoalService(),
                      onTap: () => context.pushNamed(AppRoutes.savingsGoals),
                    );
                    final recurring = _RecurringPreviewCard(
                      service: RecurringExpenseService(),
                      currencyFormatter: money,
                      onTap: () => context.pushNamed(AppRoutes.recurringExpenses),
                    );
                    if (narrow) {
                      return Column(
                        children: [
                          goals,
                          SizedBox(height: 12.h),
                          recurring,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: goals),
                        SizedBox(width: 12.w),
                        Expanded(child: recurring),
                      ],
                    );
                  },
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

class _SafeText extends StatelessWidget {
  const _SafeText(
    this.text, {
    this.style,
    this.maxLines = 1,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final int maxLines;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      softWrap: maxLines > 1,
      textAlign: textAlign,
      style: style,
    );
  }
}

class _HeroBalanceCard extends StatelessWidget {
  const _HeroBalanceCard({
    required this.balance,
    required this.monthNet,
    required this.income,
    required this.expense,
    required this.isPositive,
    required this.comfortScore,
  });

  final String balance;
  final String monthNet;
  final String income;
  final String expense;
  final bool isPositive;
  final int comfortScore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18.w,
            top: -28.h,
            child: Container(
              width: 128.r,
              height: 128.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
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
                    child: _SafeText(
                      'PARO kontrol merkezi',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: _Pill(
                        icon: isPositive
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        label: monthNet,
                        color: isPositive ? AppColors.income : AppColors.expense,
                        foreground: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 22.h),
              Text(
                'Toplam bakiye',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  balance,
                  maxLines: 1,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 30.sp,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 320;
                  final items = [
                    _HeroMiniStat(
                      label: 'Bu ay gelir',
                      value: income,
                      icon: Icons.arrow_downward_rounded,
                      color: AppColors.income,
                    ),
                    _HeroMiniStat(
                      label: 'Bu ay gider',
                      value: expense,
                      icon: Icons.arrow_upward_rounded,
                      color: AppColors.expense,
                    ),
                    _HeroMiniStat(
                      label: 'Rahatlık',
                      value: '$comfortScore/100',
                      icon: Icons.spa_rounded,
                      color: AppColors.gradientStart,
                    ),
                  ];
                  if (narrow) {
                    return Column(
                      children: [
                        for (final item in items) ...[
                          item,
                          if (item != items.last) SizedBox(height: 8.h),
                        ],
                      ],
                    );
                  }
                  return Row(
                    children: [
                      for (int i = 0; i < items.length; i++) ...[
                        Expanded(child: items[i]),
                        if (i != items.length - 1) SizedBox(width: 8.w),
                      ],
                    ],
                  );
                },
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
      constraints: BoxConstraints(minHeight: 72.h),
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14.r, color: color),
              SizedBox(width: 4.w),
              Expanded(
                child: _SafeText(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 5.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyComfortCard extends StatelessWidget {
  const _DailyComfortCard({
    required this.data,
    required this.onPrimaryAction,
  });

  final ParoComfortCardData data;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBubble(icon: data.icon, color: data.color),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SafeText(
                  data.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6.h),
                _SafeText(
                  data.message,
                  maxLines: 3,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                    height: 1.35,
                  ),
                ),
                if (data.actionLabel != null) ...[
                  SizedBox(height: 10.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onPrimaryAction,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: Size(0, 34.h),
                      ),
                      icon: Icon(Icons.add_rounded, size: 16.r),
                      label: _SafeText(data.actionLabel!),
                    ),
                  ),
                ],
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
    final actions = [
      _ActionSpec('Gider', Icons.remove_rounded, AppColors.expense, onAddExpense),
      _ActionSpec('Gelir', Icons.add_rounded, AppColors.income, onAddIncome),
      _ActionSpec('Fiş tara', Icons.document_scanner_rounded, AppColors.primary, onScan),
      _ActionSpec('Hedef', Icons.flag_rounded, AppColors.accent, onGoals),
      _ActionSpec('Abonelik', Icons.repeat_rounded, AppColors.warning, onRecurring),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth < 340 ? 2 : 3;
        return GridView.builder(
          itemCount: actions.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            mainAxisSpacing: 10.h,
            crossAxisSpacing: 10.w,
            childAspectRatio: count == 2 ? 1.75 : 1.15,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            return _QuickActionTile(spec: action);
          },
        );
      },
    );
  }
}

class _ActionSpec {
  const _ActionSpec(this.title, this.icon, this.color, this.onTap);
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.spec});
  final _ActionSpec spec;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: spec.onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconBubble(icon: spec.icon, color: spec.color, size: 36.r),
              SizedBox(height: 8.h),
              _SafeText(
                spec.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OneTapAddCard extends StatelessWidget {
  const _OneTapAddCard({
    required this.suggestions,
    required this.formatter,
    required this.onTap,
  });

  final List<ParoQuickAddSuggestion> suggestions;
  final String Function(double amount) formatter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBubble(icon: Icons.touch_app_rounded, color: AppColors.primary),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SafeText(
                      'Tek dokunuşla hızlı kayıt',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    _SafeText(
                      'Öneriyi seç, tutarı onayla, bitti.',
                      maxLines: 2,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: suggestions.map((item) {
              return InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: item.color.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, color: item.color, size: 16.r),
                      SizedBox(width: 6.w),
                      Text(
                        '${item.label} · ${formatter(item.amount)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
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

    return _SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBubble(icon: first.icon, color: first.color),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SafeText(
                  first.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6.h),
                _SafeText(
                  first.message,
                  maxLines: 3,
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

class _CalmSuggestionsCard extends StatelessWidget {
  const _CalmSuggestionsCard({
    required this.suggestions,
    required this.onGoals,
  });

  final List<ParoComfortCardData> suggestions;
  final VoidCallback onGoals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBubble(icon: Icons.spa_rounded, color: AppColors.accent),
              SizedBox(width: 10.w),
              Expanded(
                child: _SafeText(
                  'Rahat öneriler',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          for (int i = 0; i < suggestions.length; i++) ...[
            _SuggestionRow(data: suggestions[i], onTap: onGoals),
            if (i != suggestions.length - 1) SizedBox(height: 10.h),
          ],
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.data, required this.onTap});
  final ParoComfortCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: data.color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(data.icon, color: data.color, size: 20.r),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SafeText(
                    data.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  _SafeText(
                    data.message,
                    maxLines: 3,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.64),
                      height: 1.30,
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

class _GentleNotificationsCard extends StatelessWidget {
  const _GentleNotificationsCard({
    required this.notifications,
    required this.onSettings,
  });

  final List<ParoGentleNotification> notifications;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = notifications.isEmpty
        ? const [
            ParoGentleNotification(
              title: 'Bildirimler sakin modda',
              message: 'PARO yalnızca faydalı ve yormayan hatırlatmalar göstermeye çalışır.',
              icon: Icons.notifications_none_rounded,
              priority: 0,
            ),
          ]
        : notifications;

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBubble(icon: Icons.notifications_active_rounded, color: AppColors.primary),
              SizedBox(width: 10.w),
              Expanded(
                child: _SafeText(
                  'Kullanışlı bildirimler',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: onSettings,
                child: const _SafeText('Ayarla'),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          for (final item in visible) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, color: AppColors.primary, size: 18.r),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SafeText(
                        item.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      _SafeText(
                        item.message,
                        maxLines: 2,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item != visible.last) SizedBox(height: 10.h),
          ],
        ],
      ),
    );
  }
}

class _TrendAndPreviewRow extends StatelessWidget {
  const _TrendAndPreviewRow({required this.values, required this.total});

  final List<double> values;
  final String total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBubble(icon: Icons.show_chart_rounded, color: AppColors.gradientStart),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SafeText(
                      'Son 7 gün harcama ritmi',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    _SafeText(
                      'Toplam: $total',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 82.h,
            child: CustomPaint(
              painter: _MiniBarPainter(
                values: values,
                color: AppColors.primary,
                trackColor: theme.colorScheme.outline.withValues(alpha: 0.14),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBarPainter extends CustomPainter {
  const _MiniBarPainter({
    required this.values,
    required this.color,
    required this.trackColor,
  });

  final List<double> values;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxValue = values.reduce(math.max).clamp(1.0, double.infinity);
    final gap = size.width / (values.length * 2.2);
    final barWidth = (size.width - gap * (values.length - 1)) / values.length;
    final radius = Radius.circular(barWidth / 2);

    for (int i = 0; i < values.length; i++) {
      final left = i * (barWidth + gap);
      final track = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, 0, barWidth, size.height),
        radius,
      );
      canvas.drawRRect(track, Paint()..color = trackColor);
      final height = (values[i] / maxValue) * size.height;
      final bar = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, size.height - height, barWidth, height),
        radius,
      );
      canvas.drawRRect(bar, Paint()..color = color.withValues(alpha: 0.82));
    }
  }

  @override
  bool shouldRepaint(covariant _MiniBarPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

class _SavingsPreviewCard extends StatelessWidget {
  const _SavingsPreviewCard({required this.service, required this.onTap});

  final SavingsGoalService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: service.getGoals(),
      builder: (context, snapshot) {
        final goals = snapshot.data ?? const [];
        final active = goals.length;
        return _SmallPreviewCard(
          title: 'Birikim',
          value: active == 0 ? 'Hedef yok' : '$active hedef',
          subtitle: active == 0 ? 'Küçük bir hedef oluştur' : 'İlerlemeni sakince takip et',
          icon: Icons.flag_rounded,
          color: AppColors.accent,
          onTap: onTap,
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
      future: service.getRecurringExpenses(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const [];
        final monthly = items.fold<double>(0, (sum, item) => sum + item.monthlyEstimate);
        return _SmallPreviewCard(
          title: 'Abonelik',
          value: items.isEmpty ? 'Yok' : currencyFormatter(monthly),
          subtitle: items.isEmpty ? 'Düzenli gider ekle' : 'Aylık tahmini toplam',
          icon: Icons.repeat_rounded,
          color: AppColors.warning,
          onTap: onTap,
        );
      },
    );
  }
}

class _SmallPreviewCard extends StatelessWidget {
  const _SmallPreviewCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(22.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22.r),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconBubble(icon: icon, color: color),
              SizedBox(height: 10.h),
              _SafeText(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.60),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(height: 3.h),
              _SafeText(
                subtitle,
                maxLines: 2,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
    this.foreground,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? color;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 14.r),
          SizedBox(width: 4.w),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.color,
    this.size,
  });

  final IconData icon;
  final Color color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final bubbleSize = size ?? 44.r;
    return Container(
      width: bubbleSize,
      height: bubbleSize,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Icon(icon, color: color, size: bubbleSize * 0.48),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
