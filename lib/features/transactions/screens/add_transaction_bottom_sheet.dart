import 'package:finance_track/core/extensions/currency_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/income_model.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/repositories/income_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/models/user_category_model.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../expense_list/add_expense_bloc/add_expense_bloc.dart';
import '../../expense_list/add_expense_bloc/add_expense_event.dart';
import '../../expense_list/add_expense_bloc/add_expense_state.dart';
import '../../expense_list/bloc/expense_list_bloc.dart';
import '../../expense_list/bloc/expense_list_event.dart';
import '../../income_list/add_income_bloc/add_income_bloc.dart';
import '../../income_list/add_income_bloc/add_income_event.dart';
import '../../income_list/add_income_bloc/add_income_state.dart';
import '../../income_list/bloc/income_list_bloc.dart';
import '../../income_list/bloc/income_list_event.dart';
import '../utils/transaction_utils.dart';

/// Enum to represent transaction type
enum TransactionType {
  expense,
  income,
}

/// Modern bottom sheet for adding transactions (both expenses and incomes)
class AddTransactionBottomSheet extends StatefulWidget {
  /// Type of transaction (expense or income)
  final TransactionType initialType;

  /// Optional initial data for pre-filling the form
  final Map<String, dynamic>? initialData;

  /// Create a new transaction bottom sheet
  const AddTransactionBottomSheet({
    super.key,
    this.initialType = TransactionType.expense,
    this.initialData,
  });

  /// Show the bottom sheet
  static Future<bool?> show({
    required BuildContext context,
    TransactionType initialType = TransactionType.expense,
    Map<String, dynamic>? initialData,
  }) async {
    // Create fresh BLoC instances each time
    final expenseBloc = AddExpenseBloc(
      context.read<ExpenseRepository>(),
    );

    final incomeBloc = AddIncomeBloc(
      context.read<IncomeRepository>(),
    );

    // Pre-fill data if provided
    if (initialData != null && initialType == TransactionType.expense) {
      if (initialData['amount'] != null) {
        expenseBloc.add(UpdateAmount(initialData['amount'] as double));
      }
      if (initialData['date'] != null) {
        expenseBloc.add(UpdateDate(initialData['date'] as DateTime));
      }
      // Don't pre-fill bloc notes - let the UI controllers handle it
      // The submit method will combine title and notes when saving
      if (initialData['category'] != null) {
        expenseBloc
            .add(UpdateCategory(initialData['category'] as ExpenseCategory));
      }
      if (initialData['paymentMethod'] != null) {
        expenseBloc
            .add(UpdatePaymentMethod(initialData['paymentMethod'] as String));
      }
    }

    try {
      return await TransactionUtils.showModalBottomSheetWithNavBar<bool>(
        context: context,
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider<AddExpenseBloc>.value(
              value: expenseBloc,
            ),
            BlocProvider<AddIncomeBloc>.value(
              value: incomeBloc,
            ),
          ],
          child: AddTransactionBottomSheet(
            initialType: initialType,
            initialData: initialData,
          ),
        ),
      );
    } finally {
      // Ensure blocs are closed when the bottom sheet is dismissed
      await Future.delayed(const Duration(milliseconds: 300));
      expenseBloc.close();
      incomeBloc.close();
    }
  }

  @override
  State<AddTransactionBottomSheet> createState() =>
      _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends State<AddTransactionBottomSheet>
    with SingleTickerProviderStateMixin {
  late TransactionType _transactionType;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _sourceController = TextEditingController();
  late DateTime _selectedDate;
  ExpenseCategory _selectedExpenseCategory = ExpenseCategory.food;
  IncomeCategory _selectedIncomeCategory = IncomeCategory.salary;
  UserCategory? _selectedCustomExpenseCategory;
  final FocusNode _amountFocus = FocusNode();
  bool _isSubmitting = false;

  // Animation controller for tab switching
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _transactionType = widget.initialType;

    // Initialize with initial data if provided
    if (widget.initialData != null) {
      _selectedDate =
          widget.initialData!['date'] as DateTime? ?? DateTime.now();
      final amount = widget.initialData!['amount'] as double?;
      _amountController.text =
          amount != null && amount > 0 ? amount.toStringAsFixed(2) : '0.00';

      if (widget.initialData!['title'] != null) {
        _titleController.text = widget.initialData!['title'] as String;
      }
      if (widget.initialData!['notes'] != null) {
        _notesController.text = widget.initialData!['notes'] as String;
      }
      if (widget.initialData!['category'] != null) {
        _selectedExpenseCategory =
            widget.initialData!['category'] as ExpenseCategory;
      }
    } else {
      _selectedDate = DateTime.now();
      _amountController.text = '0.00';
    }

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Set initial animation value based on transaction type
    if (_transactionType == TransactionType.income) {
      _animationController.value = 1.0;
    }

    // Select entire text when field is focused
    _amountFocus.addListener(() {
      if (_amountFocus.hasFocus) {
        _amountController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _amountController.text.length,
        );
      }
    });

    // Sync with bloc state if initial data was provided
    if (widget.initialData != null &&
        _transactionType == TransactionType.expense) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final expenseBloc = context.read<AddExpenseBloc>();
        // The bloc should already have the data from the show method
        // Sync the UI controllers with bloc state
        final state = expenseBloc.state;
        if (state.amount > 0) {
          final amountText = state.amount.toStringAsFixed(2);
          if (_amountController.text != amountText) {
            _amountController.text = amountText;
          }
        }
        if (state.date != _selectedDate) {
          setState(() {
            _selectedDate = state.date;
          });
        }
        // Don't update from bloc state if we already have initial data
        // The controllers are already set from initialData in initState
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    _sourceController.dispose();
    _amountFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Switch between expense and income modes
  void _switchTransactionType(TransactionType type) {
    if (_transactionType == type) return;

    setState(() {
      _transactionType = type;

      // Animate the transition
      if (type == TransactionType.expense) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    });

    // Reset focus to provide better user feedback
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AddExpenseBloc, AddExpenseState>(
          listenWhen: (previous, current) =>
              previous.isSuccess != current.isSuccess ||
              previous.isSubmitting != current.isSubmitting ||
              (previous.errorMessage == null && current.errorMessage != null),
          listener: (context, state) {
            // Update loading state to match bloc state
            if (state.isSubmitting != _isSubmitting) {
              setState(() {
                _isSubmitting = state.isSubmitting;
              });
            }

            if (state.isSuccess) {
              // Refresh expense list to show new expense in real-time
              try {
                context.read<ExpenseListBloc>().add(const LoadExpenses());
              } catch (e) {
                // ExpenseListBloc might not be available, that's okay
              }

              // Close bottom sheet
              Navigator.of(context).pop(true);

              // Only show message if context is still mounted
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Expense added successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else if (state.errorMessage != null) {
              // Skip errors about closed blocs
              if (state.errorMessage!.contains('after calling close')) {
                return;
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${state.errorMessage}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
        BlocListener<AddIncomeBloc, AddIncomeState>(
          listenWhen: (previous, current) =>
              previous.formStatus != current.formStatus,
          listener: (context, state) {
            // Update loading state based on formStatus
            final isLoading =
                state.formStatus == FormSubmissionStatus.inProgress;
            if (isLoading != _isSubmitting) {
              setState(() {
                _isSubmitting = isLoading;
              });
            }

            if (state.formStatus == FormSubmissionStatus.success) {
              // Refresh income list to show new income in real-time
              try {
                context.read<IncomeListBloc>().add(const LoadIncomes());
              } catch (e) {
                // IncomeListBloc might not be available, that's okay
              }

              Navigator.of(context).pop(true);

              // Only show message if context is still mounted
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Income added successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else if (state.formStatus == FormSubmissionStatus.failure) {
              // Skip errors about closed blocs
              if (state.errorMessage.contains('after calling close')) {
                return;
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${state.errorMessage}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ],
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .shadow
                        .withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
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
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAmountField(),
                          const SizedBox(height: 16),
                          _buildTitleField(),
                          const SizedBox(height: 16),
                          _buildDateAndCategoryRow(),
                          const SizedBox(height: 16),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _transactionType == TransactionType.income
                                ? _buildSourceField()
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 12),
                          _buildNotesField(),
                          const SizedBox(height: 24),
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
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final isExpense = _transactionType == TransactionType.expense;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Title and close button
          Row(
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color.lerp(
                              colorScheme.error
                                  .withValues(alpha: 0.7)
                                  .withValues(alpha: 0.1),
                              Colors.green.withValues(alpha: 0.1),
                              _animation.value),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                          color: Color.lerp(
                              colorScheme.error.withValues(alpha: 0.85),
                              Colors.green,
                              _animation.value),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Add ${isExpense ? 'Expense' : 'Income'}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Color.lerp(
                              colorScheme.error.withValues(alpha: 0.85),
                              Colors.green,
                              _animation.value),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
                style: IconButton.styleFrom(
                  foregroundColor: colorScheme.onSurface,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Transaction type selector
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // Animated selection indicator
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Positioned(
                      left: _animation.value *
                          (MediaQuery.of(context).size.width - 64) /
                          2,
                      top: 4,
                      bottom: 4,
                      width: (MediaQuery.of(context).size.width - 64) / 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Tab buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeTab(
                        TransactionType.expense,
                        'Expense',
                        Icons.arrow_upward,
                        colorScheme.error.withValues(alpha: 0.85),
                      ),
                    ),
                    Expanded(
                      child: _buildTypeTab(
                        TransactionType.income,
                        'Income',
                        Icons.arrow_downward,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildTypeTab(
    TransactionType type,
    String label,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isSelected = _transactionType == type;
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => _switchTransactionType(type),
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? color
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isSelected
                      ? color
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    final theme = Theme.of(context);
    final accentColor = _transactionType == TransactionType.expense
        ? Colors.redAccent
        : Colors.green;

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
    final isExpense = _transactionType == TransactionType.expense;
    final colorScheme = theme.colorScheme;
    final iconColor =
        isExpense ? colorScheme.error.withValues(alpha: 0.85) : Colors.green;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Title',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              hintText: isExpense
                  ? 'Title (e.g., Lunch at Restaurant)'
                  : 'Title (e.g., Monthly Salary)',
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              prefixIcon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  isExpense
                      ? Icons.shopping_bag_outlined
                      : Icons.payments_outlined,
                  color: iconColor,
                  size: 20,
                  key: ValueKey(isExpense),
                ),
              ),
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
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
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: _buildCompactCategorySelector(),
        ),
      ],
    );
  }

  Widget _buildCompactDatePicker() {
    final theme = Theme.of(context);
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;
    final formattedDate =
        isToday ? 'Today' : DateFormat('MMM d, yyyy').format(_selectedDate);

    final isExpense = _transactionType == TransactionType.expense;
    final colorScheme = theme.colorScheme;
    final iconColor =
        isExpense ? colorScheme.error.withValues(alpha: 0.85) : Colors.green;

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
        const SizedBox(height: 6),
        InkWell(
          onTap: _showDatePicker,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: iconColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    formattedDate,
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isToday) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.access_time,
                    color: theme.colorScheme.primary,
                    size: 16,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactCategorySelector() {
    final theme = Theme.of(context);
    final isExpense = _transactionType == TransactionType.expense;

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
        const SizedBox(height: 6),
        AnimatedCrossFade(
          firstChild: _buildCompactExpenseCategorySelector(),
          secondChild: _buildCompactIncomeCategorySelector(),
          crossFadeState:
              isExpense ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  Widget _buildCompactExpenseCategorySelector() {
    final theme = Theme.of(context);
    final color = _selectedCustomExpenseCategory != null
        ? _selectedCustomExpenseCategory!.color
        : _getCategoryColor(_selectedExpenseCategory);

    return InkWell(
      onTap: _showExpenseCategoriesSheet,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _selectedCustomExpenseCategory?.icon ??
                    _selectedExpenseCategory.icon,
                color: color,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedCustomExpenseCategory?.name ??
                    _selectedExpenseCategory.displayName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.expand_more,
              color: theme.colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactIncomeCategorySelector() {
    final theme = Theme.of(context);

    return InkWell(
      onTap: _showIncomeCategoriesSheet,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Text(
                context.currencySymbol,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedIncomeCategory.displayName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.expand_more,
              color: theme.colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceField() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      key: const ValueKey('source_field'),
      children: [
        Text(
          'Source (Optional)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _sourceController,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: 'e.g., ABC Company, Freelance Client (Optional)',
              prefixIcon: Icon(
                Icons.business,
                color: Colors.green,
                size: 20,
              ),
            ),
            textCapitalization: TextCapitalization.words,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    final theme = Theme.of(context);
    final isExpense = _transactionType == TransactionType.expense;
    final iconColor = isExpense
        ? theme.colorScheme.error.withValues(alpha: 0.85)
        : Colors.green;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (Optional)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
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
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: 'Add any additional notes here...',
              prefixIcon: Icon(
                Icons.note_alt_outlined,
                color: iconColor,
                size: 20,
              ),
            ),
            maxLines: null, // Allow unlimited lines for invoice content
            minLines: 6, // Show at least 3 lines
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final theme = Theme.of(context);
    final isExpense = _transactionType == TransactionType.expense;
    final color = isExpense
        ? theme.colorScheme.error.withValues(alpha: 0.85)
        : Colors.green;

    return FilledButton(
      onPressed: _submitTransaction,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 56),
      ),
      child: Text(
        'Add ${isExpense ? 'Expense' : 'Income'}',
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _submitTransaction() {
    // Prevent multiple submissions
    if (_isSubmitting) return;

    // Validate inputs
    if (_titleController.text.trim().isEmpty) {
      _showValidationError('Please enter a title');
      return;
    }

    double? amount;
    try {
      amount = double.parse(_amountController.text);
      if (amount <= 0) throw const FormatException();
    } catch (e) {
      _showValidationError('Please enter a valid amount');
      return;
    }

    // Show loading state
    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_transactionType == TransactionType.expense) {
        // Submit expense
        final expenseBloc = context.read<AddExpenseBloc>();
        expenseBloc.add(UpdateNotes(
            '${_titleController.text.trim()}\n${_notesController.text.trim()}'));
        expenseBloc.add(UpdateAmount(amount));
        expenseBloc.add(UpdateDate(_selectedDate));
        if (_selectedCustomExpenseCategory != null) {
          expenseBloc.add(const UpdateCategory(ExpenseCategory.other));
        } else {
          expenseBloc.add(UpdateCategory(_selectedExpenseCategory));
        }
        expenseBloc.add(const SubmitExpense());
      } else {
        // Submit income
        final incomeBloc = context.read<AddIncomeBloc>();
        incomeBloc.add(UpdateIncomeTitle(_titleController.text.trim()));
        incomeBloc.add(UpdateIncomeAmount(amount.toString()));
        incomeBloc.add(UpdateIncomeDate(_selectedDate));
        incomeBloc.add(UpdateIncomeCategory(_selectedIncomeCategory));
        incomeBloc.add(UpdateIncomeNotes(_notesController.text.trim()));

        // Source is now optional - use empty string if not provided
        final source = _sourceController.text.trim();
        incomeBloc.add(UpdateIncomeSource(source));

        incomeBloc.add(const SubmitIncomeForm());
      }
    } catch (e) {
      // Reset loading state if there's an error
      setState(() {
        _isSubmitting = false;
      });

      // Handle any unexpected errors during submission
      if (!e.toString().contains('after calling close')) {
        _showValidationError('Error: ${e.toString()}');
      }
    }
  }

  void _showValidationError(String message) {
    // Instead of using ScaffoldMessenger, show an overlay that remains visible on top of the bottom sheet
    final overlay = Overlay.of(context);
    final theme = Theme.of(context);

    // Create a OverlayEntry with the error message
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 20.0,
        left: 20.0,
        right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Insert the overlay
    overlay.insert(overlayEntry);

    // Remove after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  Color _getCategoryColor(ExpenseCategory category) {
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
  }

  Future<void> _showDatePicker() async {
    final theme = Theme.of(context);
    final isExpense = _transactionType == TransactionType.expense;
    final accentColor = isExpense ? Colors.redAccent : Colors.green;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: accentColor,
              brightness: theme.brightness,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (picked != _selectedDate) {
        // If the selected date is not today, show time picker
        if (picked.year != DateTime.now().year ||
            picked.month != DateTime.now().month ||
            picked.day != DateTime.now().day) {
          final TimeOfDay? timePicked = await showTimePicker(
            // ignore: use_build_context_synchronously
            context: context,
            initialTime: TimeOfDay.fromDateTime(_selectedDate),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: accentColor,
                    brightness: theme.brightness,
                  ),
                ),
                child: child!,
              );
            },
          );

          if (timePicked != null) {
            setState(() {
              _selectedDate = DateTime(
                picked.year,
                picked.month,
                picked.day,
                timePicked.hour,
                timePicked.minute,
              );
            });
          } else {
            // If time picker was cancelled, keep the previous time
            setState(() {
              _selectedDate = DateTime(
                picked.year,
                picked.month,
                picked.day,
                _selectedDate.hour,
                _selectedDate.minute,
              );
            });
          }
        } else {
          // If selected date is today, use current time
          setState(() {
            _selectedDate = DateTime.now();
          });
        }
      }
    }
  }

  void _showExpenseCategoriesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final repo = context.read<CategoryRepository?>();
        return _ExpenseCategoryPicker(
          systemCategories: ExpenseCategory.values,
          selectedSystem: _selectedExpenseCategory,
          selectedCustom: _selectedCustomExpenseCategory,
          onSelectSystem: (c) {
            setState(() {
              _selectedExpenseCategory = c;
              _selectedCustomExpenseCategory = null;
            });
          },
          onSelectCustom: (uc) {
            setState(() {
              _selectedCustomExpenseCategory = uc;
            });
          },
          repository: repo,
        );
      },
    );
  }

  void _showIncomeCategoriesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategorySelectionBottomSheet(
        title: 'Select Income Source',
        categories: IncomeCategory.values,
        selectedCategory: _selectedIncomeCategory,
        accentColor: Colors.green,
        getIcon: (category) => (category as IncomeCategory).icon,
        getDisplayName: (category) => (category as IncomeCategory).displayName,
        getCategoryColor: (category) => Colors.green,
        onSelect: (category) {
          setState(() {
            _selectedIncomeCategory = category as IncomeCategory;
          });
        },
      ),
    );
  }
}

class CategorySelectionBottomSheet extends StatelessWidget {
  final String title;
  final List<dynamic> categories;
  final dynamic selectedCategory;
  final Color accentColor;
  final IconData Function(dynamic) getIcon;
  final String Function(dynamic) getDisplayName;
  final Color Function(dynamic) getCategoryColor;
  final Function(dynamic) onSelect;

  const CategorySelectionBottomSheet({
    super.key,
    required this.title,
    required this.categories,
    required this.selectedCategory,
    required this.accentColor,
    required this.getIcon,
    required this.getDisplayName,
    required this.getCategoryColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: screenSize.height * 0.5,
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // Drag handle and title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Categories grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = category == selectedCategory;
                  final categoryColor = getCategoryColor(category);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        onSelect(category);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? categoryColor
                                  : categoryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: categoryColor, width: 2)
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: categoryColor.withValues(
                                            alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              getIcon(category),
                              color: isSelected ? Colors.white : categoryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                getDisplayName(category),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? categoryColor
                                      : theme.colorScheme.onSurface,
                                  fontSize: 11,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ExpenseCategoryPicker extends StatelessWidget {
  final List<ExpenseCategory> systemCategories;
  final ExpenseCategory selectedSystem;
  final UserCategory? selectedCustom;
  final ValueChanged<ExpenseCategory> onSelectSystem;
  final ValueChanged<UserCategory> onSelectCustom;
  final CategoryRepository? repository;

  const _ExpenseCategoryPicker({
    required this.systemCategories,
    required this.selectedSystem,
    required this.selectedCustom,
    required this.onSelectSystem,
    required this.onSelectCustom,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    'Select Category',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      context.pushNamed(AppRoutes.manageCategories);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  )
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<UserCategory>>(
                future:
                    repository?.getAllCategories(type: CategoryType.expense),
                builder: (context, snapshot) {
                  final custom = snapshot.data ?? const <UserCategory>[];

                  return ListView(
                    children: [
                      if (custom.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          child: Text(
                            'Your Categories',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ...custom.map((c) => ListTile(
                            leading: CircleAvatar(
                              backgroundColor: c.color.withValues(alpha: 0.15),
                              child: Icon(c.icon ?? Icons.category,
                                  color: c.color),
                            ),
                            title: Text(c.name),
                            onTap: () {
                              onSelectCustom(c);
                              Navigator.pop(context);
                            },
                          )),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: Text(
                          'Default Categories',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...systemCategories.map((category) {
                        final color = _getStaticCategoryColor(category);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.15),
                            child: Icon(category.icon, color: color),
                          ),
                          trailing: category == selectedSystem
                              ? const Icon(Icons.check)
                              : null,
                          title: Text(category.displayName),
                          onTap: () {
                            onSelectSystem(category);
                            Navigator.pop(context);
                          },
                        );
                      })
                    ],
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  static Color _getStaticCategoryColor(ExpenseCategory category) {
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
        return Colors.greenAccent;
      case ExpenseCategory.health:
        return Colors.pinkAccent;
      case ExpenseCategory.education:
        return Colors.tealAccent;
      case ExpenseCategory.travel:
        return Colors.amberAccent;
      case ExpenseCategory.other:
        return Colors.blueGrey;
    }
  }
}
