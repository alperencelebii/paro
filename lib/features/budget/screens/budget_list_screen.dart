import 'package:finance_track/features/budget/screens/budget_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../profile/currency/bloc/currency/currency_bloc.dart';
import '../../profile/currency/bloc/currency/currency_state.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/repositories/expense_repository.dart';
import '../bloc/budget_bloc/budget_bloc.dart';

/// Screen for viewing and managing budgets
class BudgetListScreen extends StatefulWidget {
  const BudgetListScreen({super.key});

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen> {
  List<Expense> _allExpenses = [];

  @override
  void initState() {
    super.initState();
    _loadBudgetsAndExpenses();
  }

  Future<void> _loadBudgetsAndExpenses() async {
    // Check if widget is still mounted before accessing context
    if (!mounted) return;
    
    // Load expenses first
    final expenseRepository = context.read<ExpenseRepository>();
    final expenses = await expenseRepository.getAllExpenses();

    if (mounted) {
      setState(() {
        _allExpenses = expenses;
      });

      // Load budgets and calculate stats
      if (mounted) {
        final budgetBloc = context.read<BudgetBloc>();
        budgetBloc.add(const LoadBudget());

        // Calculate budget stats with expenses
        budgetBloc.add(CalculateBudgetStats(expenses));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocBuilder<BudgetBloc, BudgetState>(
        builder: (context, state) {
          if (state is BudgetLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is BudgetError) {
            return Center(
              child: SelectableText.rich(
                TextSpan(
                  text: 'Error: ',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 16.sp),
                  children: [
                    TextSpan(
                      text: state.message,
                      style: TextStyle(
                          fontWeight: FontWeight.normal, fontSize: 16.sp),
                    ),
                  ],
                ),
              ),
            );
          } else if (state is BudgetLoaded) {
            final budgets = state.allBudgets;
            final activeBudget = state.activeBudget;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 130.h,
                  pinned: true,
                  centerTitle: true,
                  backgroundColor: theme.colorScheme.primary,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (mounted) {
                        context.pop();
                      }
                    },
                    iconSize: 20.r, // Smaller icon
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    title: Padding(
                      padding: EdgeInsets.only(left: 35.w),
                      child: Text(
                        'Budget Settings',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    titlePadding: EdgeInsets.only(left: 16.w, bottom: 16.h),
                    background: Stack(
                      children: [
                        // Decorative elements with gradient
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  theme.colorScheme.primary,
                                  Color.lerp(theme.colorScheme.primary,
                                          Colors.indigo, 0.4) ??
                                      theme.colorScheme.primary,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Decorative circles
                        Positioned(
                          top: -20.r,
                          right: -20.r,
                          child: Container(
                            width: 100.r,
                            height: 100.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -30.r,
                          left: -30.r,
                          child: Container(
                            width: 120.r,
                            height: 120.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        // Additional decorative element
                        Positioned(
                          top: 40.r,
                          left: 100.r,
                          child: Container(
                            width: 40.r,
                            height: 40.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          color: Colors.white),
                      onPressed: () {
                        if (mounted) {
                          _navigateToCreateBudget(context);
                        }
                      },
                      tooltip: 'Create New Budget',
                    ),
                    SizedBox(width: 8.w),
                  ],
                ),

                // Summary section - only shown when there are budgets
                if (budgets.isNotEmpty && activeBudget != null)
                  SliverToBoxAdapter(
                    child: _buildActiveBudgetSummary(context, activeBudget),
                  ),

                // Content
                if (budgets.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmptyState(theme),
                  )
                else
                  SliverPadding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Your Budgets',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.add_circle,
                                  color: theme.colorScheme.primary,
                                  size: 28.r,
                                ),
                                onPressed: () {
                                  if (mounted) {
                                    _navigateToCreateBudget(context);
                                  }
                                },
                                tooltip: 'Create New Budget',
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),

                          // Grid View of budgets
                          BlocBuilder<CurrencyBloc, CurrencyState>(
                            builder: (context, currencyState) {
                              final currencySymbol =
                                  currencyState is CurrencyLoaded
                                      ? currencyState.currency.symbol
                                      : '₹';

                              return _buildBudgetGrid(context, budgets,
                                  activeBudget, currencySymbol);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildActiveBudgetSummary(BuildContext context, Budget budget) {
    final theme = Theme.of(context);

    // Get real budget stats from bloc state
    return BlocBuilder<BudgetBloc, BudgetState>(
      builder: (context, budgetState) {
        double percentUsed = 0.0;
        double spent = 0.0;
        double remaining = budget.amount;

        if (budgetState is BudgetLoaded) {
          // Use real stats from state if available
          if (budgetState.activeBudget?.id == budget.id) {
            percentUsed = budgetState.percentUsed;
            spent = budgetState.spent;
            remaining = budgetState.remaining;
          } else {
            // Calculate stats for this specific budget
            final periodExpenses = _allExpenses.where((expense) {
              return expense.date.isAfter(
                      budget.startDate.subtract(const Duration(days: 1))) &&
                  expense.date
                      .isBefore(budget.endDate.add(const Duration(days: 1)));
            }).toList();

            spent = periodExpenses.fold<double>(
                0.0, (sum, expense) => sum + expense.amount);
            remaining = budget.amount - spent;
            percentUsed = budget.amount > 0
                ? (spent / budget.amount).clamp(0.0, 1.0)
                : 0.0;
          }
        } else {
          // Fallback: calculate from expenses
          final periodExpenses = _allExpenses.where((expense) {
            return expense.date.isAfter(
                    budget.startDate.subtract(const Duration(days: 1))) &&
                expense.date
                    .isBefore(budget.endDate.add(const Duration(days: 1)));
          }).toList();

          spent = periodExpenses.fold<double>(
              0.0, (sum, expense) => sum + expense.amount);
          remaining = budget.amount - spent;
          percentUsed =
              budget.amount > 0 ? (spent / budget.amount).clamp(0.0, 1.0) : 0.0;
        }

        return _buildActiveBudgetCard(
            theme, budget, percentUsed, spent, remaining);
      },
    );
  }

  Widget _buildActiveBudgetCard(
    ThemeData theme,
    Budget budget,
    double percentUsed,
    double spent,
    double remaining,
  ) {
    return Container(
      margin: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.8),
            theme.colorScheme.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Stack(
          children: [
            // Decorative elements
            Positioned(
              right: -30.r,
              top: -30.r,
              child: Container(
                width: 100.r,
                height: 100.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              left: -20.r,
              bottom: -20.r,
              child: Container(
                width: 80.r,
                height: 80.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(16.r),
              child: BlocBuilder<CurrencyBloc, CurrencyState>(
                builder: (context, currencyState) {
                  final currencySymbol = currencyState is CurrencyLoaded
                      ? currencyState.currency.symbol
                      : '₹';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with icon and title
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Colors.white,
                              size: 22.r,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Active Budget',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14.sp,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  budget.title.isNotEmpty
                                      ? budget.title
                                      : '${budget.period.displayName} Budget',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              budget.period.displayName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20.h),

                      // Budget usage progress bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Budget Usage',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12.sp,
                                ),
                              ),
                              Text(
                                '${(percentUsed * 100).toInt()}%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4.r),
                            child: LinearProgressIndicator(
                              value: percentUsed,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                percentUsed > 0.8
                                    ? Colors.red.shade300
                                    : Colors.white,
                              ),
                              minHeight: 8.h,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20.h),

                      // Budget stats
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryItem(
                              title: 'Total',
                              value:
                                  '$currencySymbol${budget.amount.toStringAsFixed(0)}',
                              color: Colors.white,
                              iconData: Icons.account_balance_outlined,
                            ),
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              title: 'Remaining',
                              value:
                                  '$currencySymbol${remaining.clamp(0.0, double.infinity).toStringAsFixed(0)}',
                              color: Colors.white,
                              iconData: Icons.savings_outlined,
                            ),
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              title: 'Days Left',
                              value: '${budget.daysRemaining}',
                              color: Colors.white,
                              iconData: Icons.calendar_today_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to calculate budget stats
  Map<String, double> _calculateBudgetStats(Budget budget) {
    final periodExpenses = _allExpenses.where((expense) {
      return expense.date
              .isAfter(budget.startDate.subtract(const Duration(days: 1))) &&
          expense.date.isBefore(budget.endDate.add(const Duration(days: 1)));
    }).toList();

    final spent = periodExpenses.fold<double>(
        0.0, (sum, expense) => sum + expense.amount);
    final remaining = budget.amount - spent;
    final percentUsed =
        budget.amount > 0 ? (spent / budget.amount).clamp(0.0, 1.0) : 0.0;

    return {
      'spent': spent,
      'remaining': remaining,
      'percentUsed': percentUsed,
    };
  }

  Widget _buildSummaryItem({
    required String title,
    required String value,
    required Color color,
    IconData? iconData,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (iconData != null) ...[
              Icon(
                iconData,
                size: 12.r,
                color: color.withValues(alpha: 0.7),
              ),
              SizedBox(width: 4.w),
            ],
            Text(
              title,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetGrid(
    BuildContext context,
    List<Budget> budgets,
    Budget? activeBudget,
    String currencySymbol,
  ) {
    // Use a ListView for simpler layout
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: budgets.length,
      itemBuilder: (context, index) {
        final budget = budgets[index];
        final isActive = budget.id == activeBudget?.id;

        return _buildBudgetCard(
          context,
          budget: budget,
          isActive: isActive,
          currencySymbol: currencySymbol,
        );
      },
    );
  }

  Widget _buildBudgetCard(
    BuildContext context, {
    required Budget budget,
    required bool isActive,
    required String currencySymbol,
  }) {
    final theme = Theme.of(context);

    // Calculate real budget stats from expenses
    final stats = _calculateBudgetStats(budget);
    final percentUsed = stats['percentUsed']!;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: isActive
            ? Border.all(
                color: theme.colorScheme.primary,
                width: 2.w,
              )
            : Border.all(
                color: Colors.grey.shade200,
                width: 1.w,
              ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
          child: InkWell(
          onTap: () {
            if (mounted) {
              context.pushNamed(
                AppRoutes.budgetDetail,
                extra: {'budget': budget},
              );
            }
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and title
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getBudgetIcon(budget.period),
                        color: theme.colorScheme.primary,
                        size: 20.r,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.title.isNotEmpty
                              ? budget.title
                              : '${budget.period.displayName} Budget',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${DateFormat('MMM d').format(budget.startDate)} - ${DateFormat('MMM d').format(budget.endDate)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (isActive)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          'Active',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 16.h),

                // Budget amount
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$currencySymbol${budget.amount.toStringAsFixed(0)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Total Budget',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (isActive)
                      Container(
                        height: 42.h,
                        width: 42.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.3),
                            width: 2.w,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Circular progress indicator
                            SizedBox(
                              width: 42.h,
                              height: 42.h,
                              child: CircularProgressIndicator(
                                value: percentUsed,
                                strokeWidth: 3.w,
                                backgroundColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  percentUsed > 0.8
                                      ? Colors.red
                                      : percentUsed > 0.5
                                          ? Colors.orange
                                          : theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            // Percentage text
                            Text(
                              '${(percentUsed * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () {
                          if (mounted && budget.id != null) {
                            _setActiveBudget(context, budget.id!);
                          }
                        },
                        icon: Icon(
                          Icons.check_circle_outline,
                          size: 16.r,
                          color: theme.colorScheme.primary,
                        ),
                        label: Text(
                          'Set Active',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 13.sp,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 8.h),
                          side: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.w,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                      ),
                  ],
                ),

                if (isActive) ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14.r,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${budget.daysRemaining} days left',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 16.h),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (mounted) {
                            _navigateToEditBudget(context, budget);
                          }
                        },
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 16.r,
                        ),
                        label: Text(
                          'Edit',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          side: BorderSide(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (mounted) {
                            _showDeleteConfirmation(context, budget);
                          }
                        },
                        icon: Icon(
                          Icons.delete_outline,
                          size: 16.r,
                          color: Colors.red,
                        ),
                        label: Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14.sp,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation container for icon
          AnimatedContainer(
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOut,
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 64.r,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'No Budgets Found',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              'Create a budget to track your spending and save money',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 32.h),
          ElevatedButton.icon(
            onPressed: () {
              if (mounted) {
                _navigateToCreateBudget(context);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Budget'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: 32.w,
                vertical: 16.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _setActiveBudget(BuildContext context, int budgetId) {
    if (!mounted) return;
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Setting budget as active...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Set the budget as active
    if (mounted) {
      context.read<BudgetBloc>().add(SetActiveBudget(budgetId));
    }

    // Reload budgets after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadBudgetsAndExpenses();
      }
    });
  }

  IconData _getBudgetIcon(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.monthly:
        return Icons.calendar_month;
      case BudgetPeriod.weekly:
        return Icons.view_week;
      case BudgetPeriod.yearly:
        return Icons.calendar_today;
    }
  }

  void _navigateToCreateBudget(BuildContext context) async {
    if (!mounted) return;
    await budgetFormDialog(context);
    if (mounted) {
      _loadBudgetsAndExpenses();
    }
  }

  void _navigateToEditBudget(BuildContext context, Budget budget) async {
    if (!mounted) return;
    await budgetFormDialog(context, budget: budget);
    if (mounted) {
      _loadBudgetsAndExpenses();
    }
  }

  void _showDeleteConfirmation(BuildContext context, Budget budget) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text(
            'Are you sure you want to delete this ${budget.period.displayName} budget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (budget.id != null) {
                // Close the dialog
                Navigator.of(context).pop();

                // Check if widget is still mounted before using context
                if (!mounted) return;

                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Deleting budget...'),
                    duration: Duration(seconds: 1),
                  ),
                );

                // Delete the budget
                if (mounted) {
                  context.read<BudgetBloc>().add(DeleteBudget(budget.id!));
                }

                /// Navigate to home Screen
                if (mounted) {
                  context.goNamed(AppRoutes.home);
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
