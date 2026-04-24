import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A widget to display empty state for categories
class EmptyCategoriesView extends StatelessWidget {
  final bool isExpense;
  final VoidCallback? onClearFilters;

  const EmptyCategoriesView({
    super.key,
    required this.isExpense,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Card(
        elevation: 2,
        color: theme.colorScheme.surface,
        margin: EdgeInsets.all(24.r),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isExpense ? Icons.trending_down : Icons.trending_up,
                size: 56.r,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
              SizedBox(height: 24.h),
              Text(
                isExpense
                    ? 'No expense categories found'
                    : 'No income categories found',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'Try selecting a different time period',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              if (onClearFilters != null) ...[
                SizedBox(height: 24.h),
                ElevatedButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Filters'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
