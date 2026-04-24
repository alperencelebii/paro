// ignore_for_file: use_build_context_synchronously

import 'package:finance_track/features/expense_list/bloc/expense_list_bloc.dart';
import 'package:finance_track/features/expense_list/bloc/expense_list_state.dart';
import 'package:finance_track/features/income_list/bloc/income_list_bloc.dart';
import 'package:finance_track/features/monthly_summary/models/transaction_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/utils.dart';
import '../../../data/models/income_model.dart';
import '../../../data/models/expense_model.dart';
import '../blocs/monthly_summary_cubit.dart';
import '../widgets/analytics_card.dart';
import '../widgets/transcation_type_overview_card.dart';
import '../widgets/daily_spending_card.dart';
import '../widgets/month_comparison_card.dart';
import '../../expense_list/screens/expense_list_screen.dart';
import '../../income_list/screens/income_list_screen.dart';

/// Screen that displays monthly summary information
class MonthlySummaryScreen extends StatefulWidget {
  static const routeName = '/monthly-summary';

  const MonthlySummaryScreen({super.key});

  @override
  State<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends State<MonthlySummaryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _overviewScrollController;
  late ScrollController _transactionsScrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _overviewScrollController = ScrollController();
    _transactionsScrollController = ScrollController();

    // Add listener to handle tab changes
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update the nested scroll controller
    });

    context.read<MonthlySummaryCubit>().loadMonthlySummary(context);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _overviewScrollController.dispose();
    _transactionsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MonthlySummaryCubit, MonthlySummaryState>(
      builder: (context, state) {
        if (state is MonthlySummaryLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is MonthlySummaryError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<MonthlySummaryCubit>()
                          .loadMonthlySummary(context);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is! MonthlySummaryLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Stack(
          children: [
            Scaffold(
              body: NestedScrollView(
                controller: _tabController.index == 0
                    ? _overviewScrollController
                    : _transactionsScrollController,
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      // expandedHeight: 120,
                      pinned: true,
                      backgroundColor: Theme.of(context).primaryColor,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      title: const Text(
                        'Monthly Summary',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.date_range_rounded,
                              color: Colors.white),
                          onPressed: () async {
                            final now = DateTime.now();
                            final firstDayOfCurrentMonth =
                                DateTime(now.year, now.month, 1);
                            final lastPossibleDay =
                                DateTime(now.year, now.month, now.day);

                            // Show date range picker
                            final DateTimeRange? selectedRange =
                                await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: lastPossibleDay,
                              initialDateRange: state.dateRange ??
                                  DateTimeRange(
                                    start: firstDayOfCurrentMonth,
                                    end: now,
                                  ),
                              saveText: 'Apply',
                              builder: (BuildContext context, Widget? child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Theme.of(context).primaryColor,
                                      onPrimary: Colors.white,
                                      surface: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );

                            if (selectedRange != null) {
                              context
                                  .read<MonthlySummaryCubit>()
                                  .selectDateRange(selectedRange, context);
                            }
                          },
                        ),
                        if (state.dateRange != null)
                          IconButton(
                            icon:
                                const Icon(Icons.refresh, color: Colors.white),
                            onPressed: () {
                              context
                                  .read<MonthlySummaryCubit>()
                                  .resetToCurrentMonth(context);
                            },
                            tooltip: 'Reset to current month',
                          ),
                      ],
                      // bottom: null,
                    ),
                    SliverPersistentHeader(
                      pinned: false,
                      delegate: _MonthSelectorHeaderDelegate(
                        state: state,
                        cubit: context.read<MonthlySummaryCubit>(),
                        context: context,
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _TabBarHeaderDelegate(
                        tabController: _tabController,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    // Overview Tab
                    SingleChildScrollView(
                      controller: _overviewScrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Analytics Card
                          AnalyticsCard(
                            totalIncome: state.income,
                            totalExpenses: state.expense,
                            balance: state.balance,
                          ),

                          // Income Overview - Only show if there's data
                          if (state.incomeCategories.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            TransactionTypeOverviewCard(
                              categoryBreakdown: state.incomeCategories,
                              totalAmount: state.income,
                              isIncome: true,
                            ),
                          ],

                          // Expense Overview - Only show if there's data
                          if (state.expenseCategories.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            TransactionTypeOverviewCard(
                              categoryBreakdown: state.expenseCategories,
                              totalAmount: state.expense,
                              isIncome: false,
                            ),
                          ],

                          // Income vs Expense Trend Chart - Add before Daily Spending

                          // Daily Spending - Show if there's data
                          if ((state.dailyExpenses != null &&
                                  state.dailyExpenses!.isNotEmpty) ||
                              state.incomes.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            DailySpendingCard(
                              dailySpending: state.dateRange != null
                                  ? state.dailyExpensesMap
                                  : state.dailyExpenses != null
                                      ? Map.fromEntries(
                                          state.dailyExpenses!.entries.map(
                                            (e) => MapEntry(
                                              DateTime(
                                                int.parse(state.year),
                                                DateFormat('MMMM')
                                                    .parse(state.month)
                                                    .month,
                                                e.key,
                                              ),
                                              e.value,
                                            ),
                                          ),
                                        )
                                      : {},
                              dailyIncome: state.dateRange != null
                                  ? state.dailyIncomesMap
                                  : _processDailyIncomes(
                                      state.incomes,
                                      state.year,
                                      state.month,
                                    ),
                            ),
                          ],

                          // Month Comparison - Only show if there's data
                          if (state.previousMonthTotal != null) ...[
                            const SizedBox(height: 16),
                            MonthComparisonCard(
                              monthComparison: {
                                'current': state.expense,
                                'previous': state.previousMonthTotal!,
                              },
                            ),
                          ],

                          // Add bottom padding for better scrolling
                          SizedBox(height: 40.h),
                        ],
                      ),
                    ),

                    // Transactions Tab
                    SingleChildScrollView(
                      controller: _transactionsScrollController,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Transactions header with filter

                          if (state.expenses.isEmpty && state.incomes.isEmpty)
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 48.r,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.5),
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    'No transactions yet',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.7),
                                        ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Add some expenses or income to see them here',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.5),
                                        ),
                                  ),
                                ],
                              ),
                            )
                          else ...[
                            _buildDateWiseTransactions(context, state),
                          ],

                          // Add bottom padding for better scrolling
                          SizedBox(height: 60.h),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper method to process daily incomes
  Map<DateTime, double> _processDailyIncomes(
    List<Income> incomes,
    String year,
    String month,
  ) {
    final Map<DateTime, double> result = {};

    for (final income in incomes) {
      final day = income.date.day;
      final date = DateTime(
        int.parse(year),
        DateFormat('MMMM').parse(month).month,
        day,
      );

      if (result.containsKey(date)) {
        result[date] = result[date]! + income.amount;
      } else {
        result[date] = income.amount;
      }
    }

    return result;
  }

  /// Builds a grouped list of transactions organized by date
  Widget _buildDateWiseTransactions(
    BuildContext context,
    MonthlySummaryLoaded state,
  ) {
    // Combine expenses and incomes into a unified transactions list
    final combinedTransactions = <TransactionItem>[];

    // Add expenses to combined list
    for (final expense in state.expenses) {
      final category = expense.category;
      combinedTransactions.add(
        TransactionItem(
          id: expense.uuid,
          title: expense.title,
          amount: expense.amount,
          date: expense.date,
          isExpense: true,
          categoryName: _getExpenseCategoryName(category),
          categoryIcon: _getExpenseCategoryIcon(category),
          categoryColor: _getExpenseCategoryColor(category),
          notes: expense.notes,
          extraInfo: expense.paymentMethod,
          category: category,
        ),
      );
    }

    // Add incomes to combined list
    for (final income in state.incomes) {
      final category = income.category;
      combinedTransactions.add(
        TransactionItem(
          id: income.uuid,
          title: income.title,
          amount: income.amount,
          date: income.date,
          isExpense: false,
          categoryName: _getIncomeCategoryName(category),
          categoryIcon: _getIncomeCategoryIcon(category),
          categoryColor: _getIncomeCategoryColor(category),
          notes: income.notes,
          extraInfo: income.source,
          category: category,
        ),
      );
    }

    // Sort transactions by date (newest first)
    combinedTransactions.sort((a, b) => b.date.compareTo(a.date));

    // Group transactions by date
    final Map<String, List<TransactionItem>> groupedTransactions = {};

    for (final transaction in combinedTransactions) {
      // Format date as 'yyyy-MM-dd' to use as key for grouping
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);

      if (!groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey] = [];
      }

      groupedTransactions[dateKey]!.add(transaction);
    }

    // Sort dates (newest first)
    final sortedDateKeys = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final dateKey in sortedDateKeys) ...[
          // Date header

          Text(
            formatTransactionDate(DateTime.parse(dateKey)),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),

          // Transactions for this date
          ...groupedTransactions[dateKey]!.map(
            (transaction) {
              final isExpense = transaction.isExpense;
              final expenseModel = context.read<ExpenseListBloc>().state;
              final incomeModel = context.read<IncomeListBloc>().state;

              if (isExpense) {
                try {
                  // Cast to correct type
                  final expenseListLoaded = expenseModel as ExpenseListLoaded;
                  final expense = expenseListLoaded.expenses
                      .firstWhere((e) => e.uuid == transaction.id);
                  return ExpenseListItemWidget(expense: expense);
                } catch (e) {
                  // If expense not found, show transaction item directly
                  return ListTile(
                    title: Text(transaction.title),
                    subtitle: const Text('Transaction data unavailable'),
                    leading: Icon(
                      transaction.categoryIcon,
                      color: transaction.categoryColor,
                    ),
                  );
                }
              } else {
                try {
                  // Access incomes from IncomeListState
                  final income = incomeModel.incomes
                      .firstWhere((i) => i.uuid == transaction.id);
                  return IncomeListItemWidget(income: income);
                } catch (e) {
                  // If income not found, show transaction item directly
                  return ListTile(
                    title: Text(transaction.title),
                    subtitle: const Text('Transaction data unavailable'),
                    leading: Icon(
                      transaction.categoryIcon,
                      color: transaction.categoryColor,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ],
    );
  }

  /// Format transaction date for display

  // Helper methods for expense categories
  String _getExpenseCategoryName(ExpenseCategory category) {
    return category.displayName;
  }

  IconData _getExpenseCategoryIcon(ExpenseCategory category) {
    return category.icon;
  }

  Color _getExpenseCategoryColor(ExpenseCategory category) {
    return category.color;
  }

  // Helper methods for income categories
  String _getIncomeCategoryName(IncomeCategory category) {
    return category.displayName;
  }

  IconData _getIncomeCategoryIcon(IncomeCategory category) {
    return category.icon;
  }

  Color _getIncomeCategoryColor(IncomeCategory category) {
    return category.color;
  }
}

class _MonthSelectorHeaderDelegate extends SliverPersistentHeaderDelegate {
  final MonthlySummaryState state;
  final MonthlySummaryCubit cubit;
  final BuildContext context;

  _MonthSelectorHeaderDelegate({
    required this.state,
    required this.cubit,
    required this.context,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final opacity = 1.0 - (shrinkOffset / maxExtent).clamp(0.0, 1.0);

    if (state is! MonthlySummaryLoaded) {
      return Container(height: 0);
    }

    final loadedState = state as MonthlySummaryLoaded;

    return Opacity(
      opacity: opacity,
      child: Container(
        color: Theme.of(context).primaryColor,
        child: loadedState.dateRange != null
            ? Container(
                height: 99.h,
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                alignment: Alignment.center,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.date_range,
                        color: Theme.of(context).primaryColor,
                        size: 20.r,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        loadedState.periodTitle,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Container(
                height: 99.h,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    scrollbars: false,
                    physics: const BouncingScrollPhysics(),
                    overscroll: false,
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 12,
                    controller: ScrollController(
                      initialScrollOffset: 0,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemBuilder: (context, index) {
                      final now = DateTime.now();
                      final month = DateTime(now.year, now.month - index, 1);
                      final isSelected = month.year.toString() ==
                              loadedState.year &&
                          DateFormat('MMMM').format(month) == loadedState.month;

                      return Container(
                        width: 72,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              cubit.selectMonth(month, context);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.white.withValues(alpha: 0.1),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('MMM').format(month),
                                    style: TextStyle(
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.white,
                                      fontSize: 14.sp,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    month.year.toString(),
                                    style: TextStyle(
                                      color: isSelected
                                          ? Theme.of(context)
                                              .primaryColor
                                              .withValues(alpha: 0.8)
                                          : Colors.white.withValues(alpha: 0.7),
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      margin: EdgeInsets.only(top: 6.h),
                                      height: 3,
                                      width: 24,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
      ),
    );
  }

  @override
  double get maxExtent => 99.h;

  @override
  double get minExtent => 0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

class _TabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final Color color;

  _TabBarHeaderDelegate({
    required this.tabController,
    required this.color,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: color,
      child: TabBar(
        controller: tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Transactions'),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
