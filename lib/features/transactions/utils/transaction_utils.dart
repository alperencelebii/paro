import 'package:flutter/material.dart';
import 'package:finance_track/features/navigation/notifications/bottom_sheet_visibility_notification.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/income_model.dart';
import '../screens/add_transaction_bottom_sheet.dart';
import '../../profile/currency/bloc/currency/currency_bloc.dart';
import '../../profile/currency/bloc/currency/currency_state.dart';
import '../../../core/models/currency_model.dart';
import '../../../core/utils/currency_formatter.dart';

/// Utility class for transaction-related operations
class TransactionUtils {
  /// Show the add transaction bottom sheet
  static Future<bool?> showAddTransactionSheet({
    required BuildContext context,
    TransactionType initialType = TransactionType.expense,
  }) async {
    return AddTransactionBottomSheet.show(
      context: context,
      initialType: initialType,
    );
  }

  /// Show the add expense bottom sheet (shorthand)
  static Future<bool?> showAddExpenseSheet({
    required BuildContext context,
  }) async {
    return showAddTransactionSheet(
      context: context,
      initialType: TransactionType.expense,
    );
  }

  /// Show the add income bottom sheet (shorthand)
  static Future<bool?> showAddIncomeSheet({
    required BuildContext context,
  }) async {
    return showAddTransactionSheet(
      context: context,
      initialType: TransactionType.income,
    );
  }

  /// Show a modal bottom sheet that properly handles navigation bar visibility
  static Future<T?> showModalBottomSheetWithNavBar<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    Color? backgroundColor = Colors.transparent,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    Color? barrierColor,
  }) async {
    // Notify that bottom sheet is visible to hide nav bar
    const BottomSheetVisibilityNotification(true).dispatch(context);

    try {
      return await showModalBottomSheet<T>(
        context: context,
        isScrollControlled: isScrollControlled,
        backgroundColor: backgroundColor,
        elevation: elevation,
        shape: shape ??
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
        clipBehavior: clipBehavior ?? Clip.antiAlias,
        barrierColor: barrierColor ?? Colors.black54,
        builder: builder,
      );
    } finally {
      // Ensure nav bar is shown again when sheet is dismissed
      if (context.mounted) {
        const BottomSheetVisibilityNotification(false).dispatch(context);
      }
    }
  }

  /// Format currency amount for display
  static String formatCurrency(double amount, {Currency? currency}) {
    return CurrencyFormatter.format(amount, currency ?? Currencies.inr);
  }

  /// Format a date for display
  static String formatDate(DateTime date, {bool includeYear = true}) {
    return includeYear
        ? DateFormat('MMM d, yyyy').format(date)
        : DateFormat('MMM d').format(date);
  }

  /// Show transaction details in a visually appealing bottom sheet
  static Future<void> showTransactionDetails({
    required BuildContext context,
    required dynamic transaction,
    required bool isExpense,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) async {
    final theme = Theme.of(context);
    final isExpen = isExpense;

    // Extract data from transaction
    final String title = isExpen ? transaction.title : transaction.title;
    final double amount = transaction.amount;
    final DateTime date = transaction.date;
    final dynamic category =
        isExpen ? transaction.category : transaction.category;
    final String? notes = transaction.notes;
    final String methodSource =
        isExpen ? transaction.paymentMethod : transaction.source;

    // Safely get color and icon to prevent extension method errors
    final Color accentColor = getCategoryColor(category, isExpen);
    final IconData categoryIcon = getCategoryIcon(category);

    // Formatting helpers
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    // Get the selected currency from the CurrencyBloc
    final currencyState = context.read<CurrencyBloc>().state;
    final currency = currencyState is CurrencyLoaded
        ? currencyState.selectedCurrency
        : Currencies.inr;

    await showModalBottomSheetWithNavBar(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.80, // Reduced height factor
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            child: Scaffold(
              backgroundColor: theme.colorScheme.surface,
              extendBodyBehindAppBar: true,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(0), // Minimal app bar
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  toolbarHeight: 0,
                ),
              ),
              body: Column(
                children: [
                  // Top transaction header section
                  Container(
                    padding: EdgeInsets.only(top: 10.h),
                    decoration: BoxDecoration(
                      color: accentColor,
                    ),
                    child: Column(
                      children: [
                        // Close button
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: 8.w),
                            child: IconButton(
                              icon: Container(
                                padding: EdgeInsets.all(8.r),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 20.r,
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),

                        // Category icon
                        Container(
                          width: 56.r,
                          height: 56.r,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            categoryIcon,
                            color: Colors.white,
                            size: 28.r,
                          ),
                        ),

                        // Amount
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8.h,
                            horizontal: 24.w,
                          ),
                          child: Text(
                            formatCurrency(amount, currency: currency),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 24.sp,
                            ),
                          ),
                        ),

                        // Transaction type and date
                        Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: Text(
                            '${isExpen ? 'Expense' : 'Income'} · ${DateFormat('MMM d, yyyy').format(date)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),

                        // Bottom divider line
                        Container(
                          height: 4.h,
                          width: 40.w,
                          margin: EdgeInsets.only(bottom: 8.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content section
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 16.h),

                              // Grid layout for all details
                              GridView.count(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                crossAxisCount: 2,
                                childAspectRatio: 1.6,
                                crossAxisSpacing: 12.w,
                                mainAxisSpacing: 12.h,
                                children: [
                                  // Title card
                                  _buildDetailCard(
                                    icon: Icons.description_outlined,
                                    color: accentColor,
                                    label: 'Title',
                                    value: title,
                                    theme: theme,
                                  ),

                                  // Category card
                                  _buildDetailCard(
                                    icon: Icons.category_outlined,
                                    color: accentColor,
                                    label: 'Category',
                                    value: getCategoryDisplayName(category),
                                    theme: theme,
                                  ),

                                  // Date & Time card
                                  _buildDetailCard(
                                    icon: Icons.access_time_rounded,
                                    color: accentColor,
                                    label: 'Date & Time',
                                    value:
                                        '${dateFormat.format(date)}\n${timeFormat.format(date)}',
                                    theme: theme,
                                  ),

                                  // Payment method/Source card
                                  _buildDetailCard(
                                    icon: isExpen
                                        ? Icons.account_balance_wallet_outlined
                                        : Icons.account_balance_outlined,
                                    color: accentColor,
                                    label:
                                        isExpen ? 'Payment Method' : 'Source',
                                    value: methodSource,
                                    theme: theme,
                                  ),
                                ],
                              ),

                              // Notes section if available
                              if (notes != null && notes.isNotEmpty) ...[
                                SizedBox(height: 16.h),
                                _buildFullWidthCard(
                                  icon: Icons.sticky_note_2_outlined,
                                  color: accentColor,
                                  label: 'Notes',
                                  value: notes,
                                  theme: theme,
                                ),
                              ],

                              SizedBox(height: 12.h),

                              // Action buttons
                              Row(
                                children: [
                                  if (onEdit != null)
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          onEdit();
                                        },
                                        icon: Icon(
                                          Icons.edit_outlined,
                                          size: 18.r,
                                        ),
                                        label: const Text('Edit'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: accentColor,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10.h),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12.r),
                                          ),
                                          elevation: 2,
                                        ),
                                      ),
                                    ),
                                  if (onEdit != null && onDelete != null)
                                    SizedBox(width: 12.w),
                                  if (onDelete != null)
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          onDelete();
                                        },
                                        icon: Icon(
                                          Icons.delete_outline,
                                          size: 18.r,
                                          color: theme.colorScheme.error,
                                        ),
                                        label: Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: theme.colorScheme.error,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10.h),
                                          side: BorderSide(
                                            color: theme.colorScheme.error,
                                            width: 1.5,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12.r),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              SizedBox(
                                  height: 16.h +
                                      MediaQuery.of(context).padding.bottom),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Helper method to build card-style detail items for grid layout
  static Widget _buildDetailCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and label row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 14.r,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // Value
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to build full-width card for notes
  static Widget _buildFullWidthCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and label row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 14.r,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // Value
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to safely get category color
  static Color getCategoryColor(dynamic category, bool isExpense) {
    if (isExpense) {
      // For expense categories
      if (category is ExpenseCategory) {
        switch (category) {
          case ExpenseCategory.food:
            return Colors.redAccent;
          case ExpenseCategory.transportation:
            return Colors.blueAccent;
          case ExpenseCategory.entertainment:
            return Colors.purpleAccent;
          case ExpenseCategory.utilities:
            return Colors.orangeAccent;
          case ExpenseCategory.shopping:
            return Colors.greenAccent.shade700;
          case ExpenseCategory.health:
            return Colors.pinkAccent;
          case ExpenseCategory.education:
            return Colors.tealAccent.shade700;
          case ExpenseCategory.travel:
            return Colors.amberAccent;
          case ExpenseCategory.other:
            return Colors.blueGrey;
        }
      } else {
        return Colors.grey;
      }
    } else {
      // For income categories
      if (category is IncomeCategory) {
        switch (category) {
          case IncomeCategory.salary:
            return Colors.green;
          case IncomeCategory.freelance:
            return Colors.blue;
          case IncomeCategory.business:
            return Colors.purple;
          case IncomeCategory.investment:
            return Colors.amber;
          case IncomeCategory.rental:
            return Colors.orange;
          case IncomeCategory.gift:
            return Colors.pink;
          case IncomeCategory.refund:
            return Colors.teal;
          case IncomeCategory.other:
            return Colors.grey;
        }
      } else {
        return Colors.grey;
      }
    }
  }

  /// Helper method to safely get category icon
  static IconData getCategoryIcon(dynamic category) {
    if (category is ExpenseCategory) {
      switch (category) {
        case ExpenseCategory.food:
          return Icons.restaurant;
        case ExpenseCategory.transportation:
          return Icons.directions_car;
        case ExpenseCategory.entertainment:
          return Icons.movie;
        case ExpenseCategory.utilities:
          return Icons.power;
        case ExpenseCategory.shopping:
          return Icons.shopping_bag;
        case ExpenseCategory.health:
          return Icons.medical_services;
        case ExpenseCategory.education:
          return Icons.school;
        case ExpenseCategory.travel:
          return Icons.flight;
        case ExpenseCategory.other:
          return Icons.category;
      }
    } else if (category is IncomeCategory) {
      switch (category) {
        case IncomeCategory.salary:
          return Icons.work;
        case IncomeCategory.freelance:
          return Icons.computer;
        case IncomeCategory.business:
          return Icons.business;
        case IncomeCategory.investment:
          return Icons.trending_up;
        case IncomeCategory.rental:
          return Icons.home;
        case IncomeCategory.gift:
          return Icons.card_giftcard;
        case IncomeCategory.refund:
          return Icons.assignment_return;
        case IncomeCategory.other:
          return Icons.attach_money;
      }
    } else {
      // Fallback icon in case of error
      return Icons.category;
    }
  }

  /// Helper method to safely get category display name
  static String getCategoryDisplayName(dynamic category) {
    if (category is ExpenseCategory) {
      switch (category) {
        case ExpenseCategory.food:
          return 'Food & Dining';
        case ExpenseCategory.transportation:
          return 'Transportation';
        case ExpenseCategory.entertainment:
          return 'Entertainment';
        case ExpenseCategory.utilities:
          return 'Utilities';
        case ExpenseCategory.shopping:
          return 'Shopping';
        case ExpenseCategory.health:
          return 'Health & Medical';
        case ExpenseCategory.education:
          return 'Education';
        case ExpenseCategory.travel:
          return 'Travel';
        case ExpenseCategory.other:
          return 'Other';
      }
    } else if (category is IncomeCategory) {
      switch (category) {
        case IncomeCategory.salary:
          return 'Salary';
        case IncomeCategory.freelance:
          return 'Freelance';
        case IncomeCategory.business:
          return 'Business';
        case IncomeCategory.investment:
          return 'Investment';
        case IncomeCategory.rental:
          return 'Rental';
        case IncomeCategory.gift:
          return 'Gift';
        case IncomeCategory.refund:
          return 'Refund';
        case IncomeCategory.other:
          return 'Other';
      }
    } else {
      return 'Unknown Category';
    }
  }
}
