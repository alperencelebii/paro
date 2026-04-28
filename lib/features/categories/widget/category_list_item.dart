import 'package:finance_track/core/models/currency_model.dart';
import 'package:finance_track/data/models/expense_model.dart';
import 'package:finance_track/data/models/income_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:finance_track/core/localization/localization.dart';

/// A widget to display a single category item in the list
class CategoryListItem extends StatelessWidget {
  final dynamic category;
  final double amount;
  final double percentage;
  final bool isExpense;
  final Currency currency;
  final VoidCallback onTap;

  const CategoryListItem({
    super.key,
    required this.category,
    required this.amount,
    required this.percentage,
    required this.isExpense,
    required this.currency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: 2,
    );

    String categoryName;
    Color color;
    IconData icon;

    if (category is String) {
      categoryName = category;
      color = isExpense ? Colors.redAccent : Colors.green;
      icon = isExpense ? Icons.money_off : Icons.attach_money;
    } else if (isExpense) {
      final expenseCategory = category as ExpenseCategory;
      categoryName = expenseCategory.displayName;
      color = expenseCategory.color;
      icon = expenseCategory.icon;
    } else {
      final incomeCategory = category as IncomeCategory;
      categoryName = incomeCategory.displayName;
      color = incomeCategory.color;
      icon = incomeCategory.icon;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      color: color.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44.r,
                    height: 44.r,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 22.r,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LocalizedText(
                          categoryName,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        LocalizedText(
                          formatter.format(amount),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: LocalizedText('${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 5.h,
                borderRadius: BorderRadius.circular(2.5.r),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
