import 'dart:async';
import 'package:finance_track/core/models/currency_model.dart';
import 'package:finance_track/core/router/app_router.dart';
import 'package:finance_track/data/models/expense_model.dart';
import 'package:finance_track/data/models/income_model.dart';
import 'package:finance_track/data/repositories/expense_repository.dart';
import 'package:finance_track/data/repositories/income_repository.dart';
import 'package:finance_track/features/dashboard/bloc/category_analysis_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:finance_track/core/extensions/currency_context_extension.dart';
import 'package:finance_track/core/localization/localization.dart';

class CategoriesAnalysisCard extends StatelessWidget {
  const CategoriesAnalysisCard({super.key});

  @override
  Widget build(BuildContext context) {
    final currency = context.selectedCurrency;

    return BlocConsumer<CategoryAnalysisBloc, CategoryAnalysisState>(
      listener: (context, analyticsState) {
        // Handle any side effects from the CategoryAnalysisBloc here
        if (analyticsState is CategoryAnalysisError) {
          // Optionally show a snackbar for analytics errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: LocalizedText(analyticsState.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, analyticsState) {
        if (analyticsState is CategoryAnalysisLoading) {
          return Container(
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
            height: 200.h,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (analyticsState is CategoryAnalysisError) {
          return Container(
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 32.r,
                ),
                SizedBox(height: 16.h),
                LocalizedText('Error loading category analysis',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 8.h),
                LocalizedText(
                  analyticsState.message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ),
                SizedBox(height: 16.h),
                TextButton.icon(
                  onPressed: () {
                    context
                        .read<CategoryAnalysisBloc>()
                        .add(const LoadCategoryAnalysis());
                  },
                  icon: const Icon(Icons.refresh),
                  label: const LocalizedText('Retry'),
                ),
              ],
            ),
          );
        }

        if (analyticsState is CategoryAnalysisLoaded) {
          return _buildCategoriesCard(
            context,
            currency,
            analyticsState,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCategoriesCard(
    BuildContext context,
    Currency currency,
    CategoryAnalysisLoaded state,
  ) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: 2,
    );

    // Sort expense categories by amount (descending)
    final sortedExpenses = state.expenseCategoriesAmount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Sort income categories by amount (descending)
    final sortedIncomes = state.incomeCategoriesAmount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
          // Header with title and time filter dropdown
          Padding(
            padding: EdgeInsets.all(20.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LocalizedText('Top Categories',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Time frame dropdown
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: state.timeFrame,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: theme.colorScheme.primary,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 7,
                        child: LocalizedText('Last 7 days'),
                      ),
                      DropdownMenuItem(
                        value: 30,
                        child: LocalizedText('Last 30 days'),
                      ),
                      DropdownMenuItem(
                        value: 90,
                        child: LocalizedText('Last 3 months'),
                      ),
                      DropdownMenuItem(
                        value: 365,
                        child: LocalizedText('Last year'),
                      ),
                    ],
                    onChanged: (value) {
                      context
                          .read<CategoryAnalysisBloc>()
                          .add(UpdateTimeFrame(value ?? 365));
                    },
                  ),
                ),
              ],
            ),
          ),

          // Summary totals
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'Expenses',
                    formatter.format(state.totalExpenses),
                    Colors.redAccent,
                    Icons.arrow_downward,
                    state.expenseCategoriesAmount.length,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'Income',
                    formatter.format(state.totalIncomes),
                    Colors.green,
                    Icons.arrow_upward,
                    state.incomeCategoriesAmount.length,
                  ),
                ),
              ],
            ),
          ),

          // Expense Categories
          if (sortedExpenses.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.only(
                  left: 20.w, right: 20.w, top: 20.h, bottom: 8.h),
              child: LocalizedText('Expense Categories',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedExpenses.length > 3 ? 3 : sortedExpenses.length,
              itemBuilder: (context, index) {
                final rawCategory = sortedExpenses[index].key;
                final amount = sortedExpenses[index].value;
                final percentage =
                    state.expenseCategoriesPercentage[rawCategory] ?? 0.0;

                String name;
                IconData icon;
                Color color;

                if (rawCategory is ExpenseCategory) {
                  name = rawCategory.displayName;
                  icon = rawCategory.icon;
                  color = rawCategory.color;
                } else if (rawCategory is String) {
                  name = rawCategory;
                  icon = Icons.category;
                  color = Colors.redAccent;
                } else {
                  name = rawCategory.toString();
                  icon = Icons.category;
                  color = Colors.redAccent;
                }

                return _buildCategoryItem(
                  context,
                  name,
                  icon,
                  color,
                  amount,
                  percentage,
                  formatter,
                  () => _navigateToCategoryDetail(
                      context, rawCategory, true, currency),
                );
              },
            ),
          ],

          // Income Categories
          if (sortedIncomes.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.only(
                  left: 20.w, right: 20.w, top: 20.h, bottom: 8.h),
              child: LocalizedText('Income Categories',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedIncomes.length > 3 ? 3 : sortedIncomes.length,
              itemBuilder: (context, index) {
                final category = sortedIncomes[index].key;
                final amount = sortedIncomes[index].value;
                final percentage =
                    state.incomeCategoriesPercentage[category] ?? 0.0;

                return _buildCategoryItem(
                  context,
                  category.displayName,
                  category.icon,
                  category.color,
                  amount,
                  percentage,
                  formatter,
                  () => _navigateToCategoryDetail(
                      context, category, false, currency),
                );
              },
            ),
          ],

          // No data state
          if (sortedExpenses.isEmpty && sortedIncomes.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 20.w),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 48.r,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                    SizedBox(height: 16.h),
                    LocalizedText('No transactions found for the selected period',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // View more button
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  // Switch bottom navigation to Analytics tab (index 2)
                  // so the All Categories screen is shown there
                  context.go(AppPaths.analytics);
                },
                icon: LocalizedText('View All Categories',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                label: Icon(
                  Icons.arrow_forward,
                  size: 16.r,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String title,
    String amount,
    Color color,
    IconData icon,
    int categoryCount,
  ) {
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
                size: 16.r,
                color: color,
              ),
              SizedBox(width: 8.w),
              LocalizedText(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          LocalizedText(
            amount,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          LocalizedText('$categoryCount ${categoryCount == 1 ? 'category' : 'categories'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    String name,
    IconData icon,
    Color color,
    double amount,
    double percentage,
    NumberFormat formatter,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 20.r,
              ),
            ),
            SizedBox(width: 16.w),

            // Category name and percentage
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  LocalizedText('${percentage.toStringAsFixed(1)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Amount
            LocalizedText(
              formatter.format(amount),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),

            SizedBox(width: 8.w),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              size: 20.r,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCategoryDetail(
    BuildContext context,
    dynamic category,
    bool isExpense,
    Currency currency,
  ) {
    try {
      const selectedTimeFrame = 30;
      debugPrint('Navigating to category detail with:');
      debugPrint('Category type: ${category.runtimeType}');
      debugPrint('Category value: $category');
      debugPrint('IsExpense: $isExpense');
      // Process the category to ensure correct type
      dynamic processedCategory;

      if (isExpense) {
        // Make sure we have a valid ExpenseCategory
        if (category is ExpenseCategory) {
          processedCategory = category;
        } else {
          // Try to convert from other forms if needed
          try {
            final int categoryIndex = int.tryParse(category.toString()) ??
                ExpenseCategory.values.indexWhere((c) =>
                    c.toString() == 'ExpenseCategory.$category' ||
                    c.toString().contains(category.toString()));

            if (categoryIndex >= 0 &&
                categoryIndex < ExpenseCategory.values.length) {
              processedCategory = ExpenseCategory.values[categoryIndex];
            } else {
              processedCategory = ExpenseCategory.other; // Default fallback
            }
          } catch (e) {
            debugPrint('Error processing expense category: $e');
            processedCategory = ExpenseCategory.other; // Default fallback
          }
        }
      } else {
        // Make sure we have a valid IncomeCategory
        if (category is IncomeCategory) {
          processedCategory = category;
        } else {
          // Try to convert from other forms if needed
          try {
            final int categoryIndex = int.tryParse(category.toString()) ??
                IncomeCategory.values.indexWhere((c) =>
                    c.toString() == 'IncomeCategory.$category' ||
                    c.toString().contains(category.toString()));

            if (categoryIndex >= 0 &&
                categoryIndex < IncomeCategory.values.length) {
              processedCategory = IncomeCategory.values[categoryIndex];
            } else {
              processedCategory = IncomeCategory.other; // Default fallback
            }
          } catch (e) {
            debugPrint('Error processing income category: $e');
            processedCategory = IncomeCategory.other; // Default fallback
          }
        }
      }

      debugPrint(
          'Processed category: $processedCategory (${processedCategory.runtimeType})');

      // Create a new bloc specifically for the detail screen
      // This avoids state conflicts and lifecycle issues
      final detailBloc = CategoryAnalysisBloc(
        expenseRepository: context.read<ExpenseRepository>(),
        incomeRepository: context.read<IncomeRepository>(),
      );
      final dateRange = DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: selectedTimeFrame)),
        end: DateTime.now(),
      );

      // Create the detail screen with the new bloc
      context.push(
        '/category-detail',
        extra: {
          'category': category,
          'isExpense': isExpense,
          'currency': currency,
          'timeFrame': selectedTimeFrame,
          'dateRange': dateRange,
        },
      );

      // Load data after navigation is complete
      Future.delayed(const Duration(milliseconds: 200), () {
        try {
          debugPrint('Adding LoadCategoryDetail event for $processedCategory');
          detailBloc.add(
            LoadCategoryDetail(
              category: processedCategory,
              isExpense: isExpense,
              timeFrame: 30,
              dateRange: DateTimeRange(
                start: DateTime.now().subtract(const Duration(days: 30)),
                end: DateTime.now(),
              ),
            ),
          );
        } catch (e) {
          debugPrint('Error loading category details: $e');
        }
      });
    } catch (e) {
      debugPrint('Error navigating to category detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: LocalizedText('Error navigating to category detail: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
