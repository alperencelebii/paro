import 'package:finance_track/core/extensions/currency_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../data/models/expense_model.dart';
import '../../../data/models/income_model.dart';
import '../../expense_list/bloc/expense_list_bloc.dart';
import '../../expense_list/bloc/expense_list_event.dart';
import '../../income_list/bloc/income_list_bloc.dart';
import '../../income_list/bloc/income_list_event.dart';
import '../../transactions/utils/transaction_utils.dart';

/// A reusable bottom sheet for editing transactions (both income and expense)
class TransactionEditSheet extends StatefulWidget {
  /// The transaction to edit (either Income or Expense)
  final dynamic transaction;

  /// Whether this is an expense transaction
  final bool isExpense;

  /// Constructor
  const TransactionEditSheet({
    super.key,
    required this.transaction,
    required this.isExpense,
  });

  /// Show the transaction edit bottom sheet
  static Future<void> show({
    required BuildContext context,
    required dynamic transaction,
    required bool isExpense,
  }) async {
    // Use the utility method to handle bottom nav bar visibility
    await TransactionUtils.showModalBottomSheetWithNavBar(
      context: context,
      isScrollControlled: true,
      builder: (context) => TransactionEditSheet(
        transaction: transaction,
        isExpense: isExpense,
      ),
    );
  }

  @override
  State<TransactionEditSheet> createState() => _TransactionEditSheetState();
}

class _TransactionEditSheetState extends State<TransactionEditSheet> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late TextEditingController _sourceController;
  late DateTime _selectedDate;
  late dynamic _selectedCategory;
  bool _isLoading = false;
  final FocusNode _amountFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeControllers();

    // Handle amount text selection when focused
    _amountFocus.addListener(() {
      if (_amountFocus.hasFocus) {
        // Select all text when focusing
        Future.delayed(const Duration(milliseconds: 100), () {
          _amountController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _amountController.text.length,
          );
        });
      }
    });
  }

  void _initializeControllers() {
    // Get the selected currency from the CurrencyBloc

    if (widget.isExpense) {
      final expense = widget.transaction as Expense;
      _titleController = TextEditingController(text: expense.title);
      _amountController = TextEditingController(
        // Just store the raw amount to match add transaction UI
        text: expense.amount.toString(),
      );
      _notesController = TextEditingController(text: expense.notes ?? '');
      _sourceController = TextEditingController(text: expense.paymentMethod);
      _selectedDate = expense.date;
      _selectedCategory = expense.category;
    } else {
      final income = widget.transaction as Income;
      _titleController = TextEditingController(text: income.title);
      _amountController = TextEditingController(
        // Just store the raw amount to match add transaction UI
        text: income.amount.toString(),
      );
      _notesController = TextEditingController(text: income.notes ?? '');
      _sourceController = TextEditingController(text: income.source);
      _selectedDate = income.date;
      _selectedCategory = income.category;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _sourceController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  double _parseAmount(String amount) {
    // Remove currency symbol and commas
    final sanitized = amount.replaceAll(RegExp(r'[^0-9\.]'), '');
    return double.tryParse(sanitized) ?? 0.0;
  }

  void _saveChanges(BuildContext context) {
    // Validate input
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar(context, 'Please enter a title');
      return;
    }

    final parsedAmount = _parseAmount(_amountController.text);
    if (parsedAmount <= 0) {
      _showErrorSnackBar(context, 'Please enter a valid amount');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.isExpense) {
        final expense = widget.transaction as Expense;

        // Use the copyWith method to update fields while preserving the ID
        final updatedExpense = expense.copyWith(
          title: _titleController.text.trim(),
          amount: parsedAmount,
          date: _selectedDate,
          category: _selectedCategory as ExpenseCategory,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          paymentMethod: _sourceController.text.trim(),
        );

        // Update expense in the repository
        context.read<ExpenseListBloc>().add(UpdateExpense(updatedExpense));

        // Show success message and close the sheet
        _showSuccessSnackBar(context, 'Expense updated successfully');
        Navigator.of(context).pop();
      } else {
        final income = widget.transaction as Income;

        // Use the copyWith method to update fields while preserving the ID
        final updatedIncome = income.copyWith(
          title: _titleController.text.trim(),
          amount: parsedAmount,
          date: _selectedDate,
          category: _selectedCategory as IncomeCategory,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          source: _sourceController.text.trim(),
        );

        // Update income in the repository
        context.read<IncomeListBloc>().add(UpdateIncome(updatedIncome));

        // Show success message and close the sheet
        _showSuccessSnackBar(context, 'Income updated successfully');
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error message
      _showErrorSnackBar(
          context, 'Error updating transaction: ${e.toString()}');
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8.w),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        margin: EdgeInsets.only(bottom: 16.h, left: 16.w, right: 16.w),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8.w),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        margin: EdgeInsets.only(bottom: 16.h, left: 16.w, right: 16.w),
      ),
    );
  }

  void _showDatePicker() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _showCategoryPicker() {
    if (widget.isExpense) {
      _showExpenseCategoryPicker();
    } else {
      _showIncomeCategoryPicker();
    }
  }

  void _showExpenseCategoryPicker() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Expense Category',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                ),
                itemCount: ExpenseCategory.values.length,
                itemBuilder: (context, index) {
                  final category = ExpenseCategory.values[index];
                  final isSelected = _selectedCategory == category;
                  final color =
                      TransactionUtils.getCategoryColor(category, true);
                  final icon = TransactionUtils.getCategoryIcon(category);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.2)
                            : theme.colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isSelected
                              ? color
                              : theme.colorScheme.outline
                                  .withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40.r,
                            height: 40.r,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            TransactionUtils.getCategoryDisplayName(category),
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
    );
  }

  void _showIncomeCategoryPicker() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Income Category',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                ),
                itemCount: IncomeCategory.values.length,
                itemBuilder: (context, index) {
                  final category = IncomeCategory.values[index];
                  final isSelected = _selectedCategory == category;
                  final color =
                      TransactionUtils.getCategoryColor(category, false);
                  final icon = TransactionUtils.getCategoryIcon(category);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.2)
                            : theme.colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isSelected
                              ? color
                              : theme.colorScheme.outline
                                  .withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40.r,
                            height: 40.r,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            TransactionUtils.getCategoryDisplayName(category),
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAmountField(),
                        SizedBox(height: 12.h),
                        _buildTitleField(),
                        SizedBox(height: 12.h),
                        _buildDateAndCategoryRow(),
                        SizedBox(height: 12.h),
                        widget.isExpense
                            ? _buildPaymentMethodField()
                            : _buildSourceField(),
                        SizedBox(height: 8.h),
                        _buildNotesField(),
                        SizedBox(height: 16.h),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final accentColor = widget.isExpense ? Colors.redAccent : Colors.green;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 4.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 8.h),

          // Title and close button
          Row(
            children: [
              Icon(
                widget.isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                color: accentColor,
                size: 18.r,
              ),
              SizedBox(width: 6.w),
              Text(
                'Edit ${widget.isExpense ? 'Expense' : 'Income'}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, size: 20.r),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
                style: IconButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                constraints: BoxConstraints(
                  minWidth: 36.w,
                  minHeight: 36.h,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    final theme = Theme.of(context);
    final accentColor = widget.isExpense ? Colors.redAccent : Colors.green;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            context.currencySymbol,
            style: theme.textTheme.headlineMedium!.copyWith(
              color: accentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: TextField(
              controller: _amountController,
              focusNode: _amountFocus,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.left,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: '0.00',
                isDense: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _titleController,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          hintText: widget.isExpense
              ? 'Title (e.g., Lunch at Restaurant)'
              : 'Title (e.g., Monthly Salary)',
          prefixIcon: Icon(
            widget.isExpense
                ? Icons.shopping_bag_outlined
                : Icons.payments_outlined,
            color: theme.colorScheme.primary,
            size: 20.r,
          ),
        ),
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }

  Widget _buildDateAndCategoryRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildCompactDatePicker(),
        ),
        SizedBox(width: 12.w),
        Expanded(
          flex: 3,
          child: _buildCompactCategorySelector(),
        ),
      ],
    );
  }

  Widget _buildCompactDatePicker() {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('MMM d, yyyy').format(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Date',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        SizedBox(height: 6.h),
        InkWell(
          onTap: _showDatePicker,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16.r,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    formattedDate,
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactCategorySelector() {
    final theme = Theme.of(context);
    final category = _selectedCategory;
    final categoryName = widget.isExpense
        ? TransactionUtils.getCategoryDisplayName(category as ExpenseCategory)
        : TransactionUtils.getCategoryDisplayName(category as IncomeCategory);
    final categoryIcon = TransactionUtils.getCategoryIcon(category);
    final categoryColor =
        TransactionUtils.getCategoryColor(category, widget.isExpense);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Category',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        SizedBox(height: 6.h),
        InkWell(
          onTap: _showCategoryPicker,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24.r,
                  height: 24.r,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    categoryIcon,
                    size: 14.r,
                    color: categoryColor,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    categoryName,
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20.r,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSourceField() {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _sourceController,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          hintText: 'Source (e.g., Company Name)',
          prefixIcon: Icon(
            Icons.account_balance_outlined,
            color: theme.colorScheme.primary,
            size: 20.r,
          ),
        ),
        textCapitalization: TextCapitalization.words,
      ),
    );
  }

  Widget _buildPaymentMethodField() {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _sourceController,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          hintText: 'Payment Method (e.g., Credit Card)',
          prefixIcon: Icon(
            Icons.payment_outlined,
            color: theme.colorScheme.primary,
            size: 20.r,
          ),
        ),
        textCapitalization: TextCapitalization.words,
      ),
    );
  }

  Widget _buildNotesField() {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _notesController,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          hintText: 'Notes (Optional)',
          prefixIcon: Icon(
            Icons.note_outlined,
            color: theme.colorScheme.primary,
            size: 20.r,
          ),
        ),
        textCapitalization: TextCapitalization.sentences,
        maxLines: 3,
        minLines: 1,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _isLoading ? null : () => _saveChanges(context),
        style: FilledButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          backgroundColor: widget.isExpense ? Colors.redAccent : Colors.green,
        ),
        child: _isLoading
            ? SizedBox(
                height: 20.h,
                width: 20.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Update ${widget.isExpense ? 'Expense' : 'Income'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
      ),
    );
  }
}
