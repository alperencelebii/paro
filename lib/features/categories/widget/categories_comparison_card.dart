// import 'dart:async';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../../core/models/currency_model.dart';
// import '../../../data/models/expense_model.dart';
// import '../../../data/models/income_model.dart';
// import '../../../data/repositories/expense_repository.dart';
// import '../../../data/repositories/income_repository.dart';
// import '../../dashboard/bloc/category_analysis_bloc.dart';
// import '../screens/category_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

// class CategoriesComparisonCard extends StatefulWidget {
//   final Map<ExpenseCategory, double> expenseCategoriesAmount;
//   final Map<IncomeCategory, double> incomeCategoriesAmount;
//   final Map<ExpenseCategory, double> expenseCategoriesPercentage;
//   final Map<IncomeCategory, double> incomeCategoriesPercentage;
//   final double totalExpenses;
//   final double totalIncomes;
//   final String currencyCode;
//   final String currencySymbol;
//   final Function(int) onTimeFrameChanged;
//   final Function(bool, bool) onDataTypeToggled;
//   final VoidCallback onViewMorePressed;

//   const CategoriesComparisonCard({
//     super.key,
//     required this.expenseCategoriesAmount,
//     required this.incomeCategoriesAmount,
//     required this.expenseCategoriesPercentage,
//     required this.incomeCategoriesPercentage,
//     required this.totalExpenses,
//     required this.totalIncomes,
//     required this.currencyCode,
//     required this.currencySymbol,
//     required this.onTimeFrameChanged,
//     required this.onDataTypeToggled,
//     required this.onViewMorePressed,
//   });

//   @override
//   State<CategoriesComparisonCard> createState() =>
//       _CategoriesComparisonCardState();
// }

// class _CategoriesComparisonCardState extends State<CategoriesComparisonCard> {
//   int _selectedTimeFrame = 30; // Default to 30 days
//   bool _showExpense = true;
//   bool _showIncome = true;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final formatter = NumberFormat.currency(
//       symbol: widget.currencySymbol,
//       decimalDigits: 2,
//     );

//     return Container(
//       width: double.infinity,
//       margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
//           // Header with title and time filter
//           Padding(
//             padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 20.h),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Categories',
//                   style: theme.textTheme.titleLarge?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 // Time filter dropdown
//                 DropdownButtonHideUnderline(
//                   child: DropdownButton<int>(
//                     value: _selectedTimeFrame,
//                     icon: Icon(
//                       Icons.keyboard_arrow_down,
//                       color: theme.colorScheme.primary,
//                     ),
//                     items: const [
//                       DropdownMenuItem(
//                         value: 7,
//                         child: Text('Last 7 days'),
//                       ),
//                       DropdownMenuItem(
//                         value: 30,
//                         child: Text('Last 30 days'),
//                       ),
//                       DropdownMenuItem(
//                         value: 90,
//                         child: Text('Last 3 months'),
//                       ),
//                       DropdownMenuItem(
//                         value: 365,
//                         child: Text('Last year'),
//                       ),
//                     ],
//                     onChanged: (value) {
//                       if (value != null) {
//                         setState(() {
//                           _selectedTimeFrame = value;
//                         });
//                         widget.onTimeFrameChanged(value);
//                       }
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Toggle buttons for expense/income
//           Padding(
//             padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 16.h),
//             child: Row(
//               children: [
//                 _buildToggleButton(
//                   context,
//                   'Expenses',
//                   _showExpense,
//                   Colors.redAccent,
//                   Icons.arrow_downward_rounded,
//                   () {
//                     setState(() {
//                       _showExpense = !_showExpense;
//                       // Ensure at least one is selected
//                       if (!_showExpense && !_showIncome) {
//                         _showIncome = true;
//                       }
//                     });
//                     widget.onDataTypeToggled(_showExpense, _showIncome);
//                   },
//                 ),
//                 SizedBox(width: 8.w),
//                 _buildToggleButton(
//                   context,
//                   'Income',
//                   _showIncome,
//                   Colors.greenAccent.shade700,
//                   Icons.arrow_upward_rounded,
//                   () {
//                     setState(() {
//                       _showIncome = !_showIncome;
//                       // Ensure at least one is selected
//                       if (!_showIncome && !_showExpense) {
//                         _showExpense = true;
//                       }
//                     });
//                     widget.onDataTypeToggled(_showExpense, _showIncome);
//                   },
//                 ),
//               ],
//             ),
//           ),

//           // Summary totals
//           if (_showExpense || _showIncome)
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
//               child: Row(
//                 children: [
//                   if (_showExpense)
//                     Expanded(
//                       child: _buildSummaryCard(
//                         context,
//                         'Total Expenses',
//                         formatter.format(widget.totalExpenses),
//                         Colors.redAccent,
//                         widget.expenseCategoriesAmount.length,
//                       ),
//                     ),
//                   if (_showExpense && _showIncome) SizedBox(width: 16.w),
//                   if (_showIncome)
//                     Expanded(
//                       child: _buildSummaryCard(
//                         context,
//                         'Total Income',
//                         formatter.format(widget.totalIncomes),
//                         Colors.greenAccent.shade700,
//                         widget.incomeCategoriesAmount.length,
//                       ),
//                     ),
//                 ],
//               ),
//             ),

//           // Enhanced category list
//           if (_showExpense && widget.expenseCategoriesAmount.isNotEmpty)
//             _buildCategorySection(
//               context,
//               'Expense Categories',
//               Colors.redAccent,
//               widget.expenseCategoriesAmount,
//               widget.expenseCategoriesPercentage,
//               formatter,
//               true,
//             ),

//           if (_showIncome && widget.incomeCategoriesAmount.isNotEmpty)
//             _buildCategorySection(
//               context,
//               'Income Categories',
//               Colors.greenAccent.shade700,
//               widget.incomeCategoriesAmount,
//               widget.incomeCategoriesPercentage,
//               formatter,
//               false,
//             ),

//           // No data states
//           if (_showExpense &&
//               _showIncome &&
//               widget.expenseCategoriesAmount.isEmpty &&
//               widget.incomeCategoriesAmount.isEmpty)
//             _buildEmptyState(
//               context,
//               'No transactions found for the selected period',
//               Icons.bar_chart,
//             ),
//           if (_showExpense &&
//               !_showIncome &&
//               widget.expenseCategoriesAmount.isEmpty)
//             _buildEmptyState(
//               context,
//               'No expense transactions found',
//               Icons.arrow_downward_rounded,
//             ),
//           if (!_showExpense &&
//               _showIncome &&
//               widget.incomeCategoriesAmount.isEmpty)
//             _buildEmptyState(
//               context,
//               'No income transactions found',
//               Icons.arrow_upward_rounded,
//             ),

//           // View more button
//           Padding(
//             padding: EdgeInsets.all(16.r),
//             child: Center(
//               child: TextButton.icon(
//                 onPressed: widget.onViewMorePressed,
//                 icon: Text(
//                   'Detailed Analysis',
//                   style: theme.textTheme.bodyMedium?.copyWith(
//                     color: theme.colorScheme.primary,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 label: Icon(
//                   Icons.arrow_forward,
//                   size: 16.r,
//                   color: theme.colorScheme.primary,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildToggleButton(
//     BuildContext context,
//     String title,
//     bool isSelected,
//     Color color,
//     IconData icon,
//     VoidCallback onTap,
//   ) {
//     final theme = Theme.of(context);

//     return Expanded(
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12.r),
//         child: Container(
//           padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
//           decoration: BoxDecoration(
//             color: isSelected ? color.withValues(alpha:0.15) : Colors.transparent,
//             borderRadius: BorderRadius.circular(12.r),
//             border: Border.all(
//               color: isSelected ? color : theme.dividerColor,
//               width: 1.5,
//             ),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 icon,
//                 color: isSelected
//                     ? color
//                     : theme.colorScheme.onSurface.withValues(alpha:0.7),
//                 size: 18.r,
//               ),
//               SizedBox(width: 8.w),
//               Text(
//                 title,
//                 style: theme.textTheme.bodyMedium?.copyWith(
//                   color: isSelected
//                       ? color
//                       : theme.colorScheme.onSurface.withValues(alpha:0.7),
//                   fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSummaryCard(
//     BuildContext context,
//     String title,
//     String amount,
//     Color color,
//     int categoryCount,
//   ) {
//     final theme = Theme.of(context);

//     return Container(
//       padding: EdgeInsets.all(12.r),
//       decoration: BoxDecoration(
//         color: color.withValues(alpha:0.1),
//         borderRadius: BorderRadius.circular(16.r),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: theme.textTheme.bodySmall?.copyWith(
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           SizedBox(height: 4.h),
//           Text(
//             amount,
//             style: theme.textTheme.titleLarge?.copyWith(
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//           SizedBox(height: 4.h),
//           Text(
//             '$categoryCount ${categoryCount == 1 ? 'category' : 'categories'}',
//             style: theme.textTheme.bodySmall?.copyWith(
//               color: theme.colorScheme.onSurface.withValues(alpha:0.7),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCategorySection(
//     BuildContext context,
//     String title,
//     Color color,
//     Map<dynamic, double> categoriesAmount,
//     Map<dynamic, double> categoriesPercentage,
//     NumberFormat formatter,
//     bool isExpense,
//   ) {
//     final theme = Theme.of(context);

//     // Sort categories by amount (descending)
//     final sortedCategories = categoriesAmount.entries.toList()
//       ..sort((a, b) => b.value.compareTo(a.value));

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding:
//               EdgeInsets.only(left: 20.w, right: 20.w, top: 16.h, bottom: 8.h),
//           child: Text(
//             title,
//             style: theme.textTheme.titleMedium?.copyWith(
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//         ),
//         ListView.builder(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           itemCount: sortedCategories.length > 5 ? 5 : sortedCategories.length,
//           itemBuilder: (context, index) {
//             final category = sortedCategories[index].key;
//             final amount = sortedCategories[index].value;
//             final percentage = categoriesPercentage[category] ?? 0.0;

//             String name;
//             IconData icon;
//             Color categoryColor;

//             if (isExpense) {
//               final expenseCategory = category as ExpenseCategory;
//               name = expenseCategory.displayName;
//               icon = expenseCategory.icon;
//               categoryColor = expenseCategory.color;
//             } else {
//               final incomeCategory = category as IncomeCategory;
//               name = incomeCategory.displayName;
//               icon = incomeCategory.icon;
//               categoryColor = incomeCategory.color;
//             }

//             return Material(
//               color: Colors.transparent,
//               child: InkWell(
//                 onTap: () =>
//                     _navigateToCategoryDetail(context, category, isExpense),
//                 child: Padding(
//                   padding:
//                       EdgeInsets.symmetric(vertical: 8.h, horizontal: 20.w),
//                   child: Row(
//                     children: [
//                       // Category icon
//                       Container(
//                         width: 40.r,
//                         height: 40.r,
//                         decoration: BoxDecoration(
//                           color: categoryColor.withValues(alpha:0.15),
//                           shape: BoxShape.circle,
//                         ),
//                         child: Icon(
//                           icon,
//                           color: categoryColor,
//                           size: 20.r,
//                         ),
//                       ),
//                       SizedBox(width: 12.w),

//                       // Category name and percentage
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               name,
//                               style: theme.textTheme.bodyLarge?.copyWith(
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             Text(
//                               '${percentage.toStringAsFixed(1)}%',
//                               style: theme.textTheme.bodySmall?.copyWith(
//                                 color: theme.colorScheme.onSurface
//                                     .withValues(alpha:0.6),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),

//                       // Amount and trend
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.end,
//                         children: [
//                           Text(
//                             formatter.format(amount),
//                             style: theme.textTheme.titleMedium?.copyWith(
//                               fontWeight: FontWeight.bold,
//                               color:
//                                   isExpense ? Colors.redAccent : Colors.green,
//                             ),
//                           ),
//                           Row(
//                             children: [
//                               Icon(
//                                 Icons.arrow_forward_ios,
//                                 size: 12.r,
//                                 color: theme.colorScheme.primary,
//                               ),
//                               Text(
//                                 'Details',
//                                 style: theme.textTheme.bodySmall?.copyWith(
//                                   color: theme.colorScheme.primary,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),

//         // Show all categories button if more than 5
//         if (sortedCategories.length > 5)
//           Padding(
//             padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
//             child: TextButton(
//               onPressed: () {
//                 // Navigate to see all categories
//                 widget.onViewMorePressed();
//               },
//               child: Text(
//                 'See all ${sortedCategories.length} categories',
//                 style: theme.textTheme.bodyMedium?.copyWith(
//                   color: theme.colorScheme.primary,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ),

//         Divider(height: 16.h, thickness: 1, indent: 20.w, endIndent: 20.w),
//       ],
//     );
//   }

//   Widget _buildEmptyState(
//     BuildContext context,
//     String message,
//     IconData icon,
//   ) {
//     final theme = Theme.of(context);

//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: 32.h),
//       child: Center(
//         child: Column(
//           children: [
//             Icon(
//               icon,
//               size: 48.r,
//               color: Colors.grey.withValues(alpha:0.5),
//             ),
//             SizedBox(height: 16.h),
//             Text(
//               message,
//               style: theme.textTheme.bodyLarge?.copyWith(
//                 color: Colors.grey,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _navigateToCategoryDetail(
//     BuildContext context,
//     dynamic category,
//     bool isExpense,
//   ) {
//     try {
//       debugPrint(
//           'CategoriesComparisonCard - Navigating to category detail with:');
//       debugPrint('Category type: ${category.runtimeType}');
//       debugPrint('Category value: $category');
//       debugPrint('IsExpense: $isExpense');

//       // Ensure we're using the correct enum type
//       dynamic processedCategory;

//       if (isExpense) {
//         // Make sure we have a valid ExpenseCategory
//         if (category is ExpenseCategory) {
//           processedCategory = category;
//         } else {
//           // Try to convert from other forms if needed
//           try {
//             final int categoryIndex = int.tryParse(category.toString()) ??
//                 ExpenseCategory.values.indexWhere((c) =>
//                     c.toString() == 'ExpenseCategory.$category' ||
//                     c.toString().contains(category.toString()));

//             if (categoryIndex >= 0 &&
//                 categoryIndex < ExpenseCategory.values.length) {
//               processedCategory = ExpenseCategory.values[categoryIndex];
//             } else {
//               processedCategory = ExpenseCategory.other; // Default fallback
//             }
//           } catch (e) {
//             debugPrint('Error processing expense category: $e');
//             processedCategory = ExpenseCategory.other; // Default fallback
//           }
//         }
//       } else {
//         // Make sure we have a valid IncomeCategory
//         if (category is IncomeCategory) {
//           processedCategory = category;
//         } else {
//           // Try to convert from other forms if needed
//           try {
//             final int categoryIndex = int.tryParse(category.toString()) ??
//                 IncomeCategory.values.indexWhere((c) =>
//                     c.toString() == 'IncomeCategory.$category' ||
//                     c.toString().contains(category.toString()));

//             if (categoryIndex >= 0 &&
//                 categoryIndex < IncomeCategory.values.length) {
//               processedCategory = IncomeCategory.values[categoryIndex];
//             } else {
//               processedCategory = IncomeCategory.other; // Default fallback
//             }
//           } catch (e) {
//             debugPrint('Error processing income category: $e');
//             processedCategory = IncomeCategory.other; // Default fallback
//           }
//         }
//       }

//       // Log the processed category for debugging
//       debugPrint(
//           'Processed category: $processedCategory (${processedCategory.runtimeType})');

//       // Create a new bloc for this detail view to avoid state conflicts
//       final detailBloc = CategoryAnalysisBloc(
//         expenseRepository: context.read<ExpenseRepository>(),
//         incomeRepository: context.read<IncomeRepository>(),
//       );

//       // Prepare the currency data
//       final currency = Currency(
//         code: widget.currencyCode,
//         symbol: widget.currencySymbol,
//         name: widget.currencyCode,
//         flag: '🏳️', // Default flag as placeholder
//       );

//       // Create the detail screen with the new bloc
//       final detailScreen = BlocProvider(
//         create: (_) => detailBloc,
//         child: CategoryDetailScreen(
//           category: processedCategory,
//           isExpense: isExpense,
//           currency: currency,
//         ),
//       );

//       // Navigate immediately
//       Navigator.of(context, rootNavigator: true).push(
//         MaterialPageRoute(
//           builder: (context) => detailScreen,
//         ),
//       );

//       // Load data after navigation
//       Future.delayed(const Duration(milliseconds: 200), () {
//         try {
//           debugPrint('Adding LoadCategoryDetail event to bloc');
//           detailBloc.add(
//             LoadCategoryDetail(
//               category: processedCategory,
//               isExpense: isExpense,
//               timeFrame: 30,
//               dateRange: DateTimeRange(
//                 start: DateTime.now().subtract(const Duration(days: 30)),
//                 end: DateTime.now(),
//               ),
//             ),
//           );
//         } catch (e) {
//           debugPrint('Error loading category details: $e');
//         }
//       });
//     } catch (e) {
//       debugPrint('Error navigating to category detail: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error navigating to category detail: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   // Helper method to check if two categories are the same type
// }
/// A widget to display category comparison
class CategoryComparisonCard extends StatelessWidget {
  final ThemeData theme;
  final double currentAmount;
  final double previousAmount;
  final Color color;
  final NumberFormat formatter;

  const CategoryComparisonCard({
    super.key,
    required this.theme,
    required this.currentAmount,
    required this.previousAmount,
    required this.color,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final difference = currentAmount - previousAmount;
    final percentageChange = previousAmount > 0
        ? (difference / previousAmount * 100).toStringAsFixed(1)
        : '0.0';
    final bool isIncrease = difference > 0;
    final changeText = isIncrease
        ? '+$percentageChange% from previous period'
        : '$percentageChange% from previous period';
    final changeColor = isIncrease ? Colors.green : Colors.red;

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
            'Period Comparison',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _ComparisonPeriod(
                  title: 'Current Period',
                  amount: formatter.format(currentAmount),
                  dateRange: 'Current',
                ),
              ),
              Container(
                height: 50.h,
                width: 1,
                color: theme.dividerColor.withValues(alpha: 0.5),
                margin: EdgeInsets.symmetric(horizontal: 16.w),
              ),
              Expanded(
                child: _ComparisonPeriod(
                  title: 'Previous Period',
                  amount: formatter.format(previousAmount),
                  dateRange: 'Previous',
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                color: changeColor,
                size: 16.r,
              ),
              SizedBox(width: 4.w),
              Text(
                changeText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: changeColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _ComparisonInsight(
            isIncrease: isIncrease,
            percentageChange: percentageChange,
          ),
        ],
      ),
    );
  }
}

/// A helper widget for comparison periods
class _ComparisonPeriod extends StatelessWidget {
  final String title;
  final String amount;
  final String dateRange;

  const _ComparisonPeriod({
    required this.title,
    required this.amount,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          amount,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          dateRange,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

/// A helper widget for comparison insights
class _ComparisonInsight extends StatelessWidget {
  final bool isIncrease;
  final String percentageChange;

  const _ComparisonInsight({
    required this.isIncrease,
    required this.percentageChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insights,
            color: theme.colorScheme.primary,
            size: 20.r,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _getInsightText(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInsightText() {
    if (isIncrease) {
      final double percent = double.tryParse(percentageChange) ?? 0;
      if (percent > 20) {
        return 'Your spending has increased significantly. Consider setting a budget to control expenses.';
      } else {
        return 'Your spending has increased slightly compared to the previous period. Keep an eye on this trend.';
      }
    } else {
      return 'Great job! You\'ve reduced your spending compared to the previous period.';
    }
  }
}
