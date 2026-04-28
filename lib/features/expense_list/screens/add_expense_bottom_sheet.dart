import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finance_track/core/localization/localization.dart';

import '../../../data/models/expense_model.dart';
import '../add_expense_bloc/add_expense_bloc.dart';
import '../add_expense_bloc/add_expense_event.dart';
import '../add_expense_bloc/add_expense_state.dart';

/// A modern bottom sheet for adding expenses
class AddExpenseBottomSheet extends StatelessWidget {
  const AddExpenseBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // Use the existing bloc from the parent context
    return BlocListener<AddExpenseBloc, AddExpenseState>(
      listenWhen: (previous, current) =>
          previous.isSuccess != current.isSuccess,
      listener: (context, state) {
        if (state.isSuccess) {
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      },
      child: const _AddExpenseBottomSheetContent(),
    );
  }

  /// Show the add expense bottom sheet
  static Future<bool?> show(BuildContext context) {
    // Create a dedicated BlocProvider for this bottom sheet session
    final bloc = AddExpenseBloc(context.read());

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) => BlocProvider<AddExpenseBloc>.value(
        // Use .value constructor to share the same bloc instance
        value: bloc,
        child: const AddExpenseBottomSheet(),
      ),
    ).then((result) {
      // Clean up the bloc when done
      bloc.close();
      return result;
    });
  }
}

class _AddExpenseBottomSheetContent extends StatelessWidget {
  const _AddExpenseBottomSheetContent();

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    // Simplified bottom sheet with just the necessary components
    return Container(
      height: mediaQuery.size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Category selector
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: _CategorySelector(),
          ),

          // Expense label
          const LocalizedText('Expenses',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),

          // Amount display
          const _AmountDisplay(),

          // Comment field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: AppLocalizations.tr('Add comment...'),
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: (value) {
                context.read<AddExpenseBloc>().add(UpdateNotes(value));
              },
            ),
          ),

          // Divider
          Divider(color: Colors.grey.shade300, height: 1),

          // Numeric keypad
          const Expanded(child: _NumericKeypad()),
        ],
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddExpenseBloc, AddExpenseState>(
      buildWhen: (previous, current) =>
          previous.paymentMethod != current.paymentMethod ||
          previous.category != current.category,
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Payment method dropdown
            _buildDropdownButton(
              context: context,
              label: state.paymentMethod,
              icon: _getPaymentMethodIcon(state.paymentMethod),
              isSelected: true,
              backgroundColor: _getPaymentMethodColor(state.paymentMethod),
              onTap: () {
                _showPaymentMethodOptions(context, state.paymentMethod);
              },
            ),

            const SizedBox(width: 12),

            // Categories dropdown
            _buildDropdownButton(
              context: context,
              label: state.category.displayName,
              icon: state.category.icon,
              isSelected: true,
              backgroundColor:
                  _getCategoryColor(state.category).withValues(alpha: 0.2),
              onTap: () {
                _showCategoryOptions(context, state.category);
              },
            ),
          ],
        );
      },
    );
  }

  // Show payment method options in bottom sheet
  void _showPaymentMethodOptions(BuildContext context, String currentMethod) {
    // Store the bloc reference before showing the modal sheet
    final bloc = context.read<AddExpenseBloc>();

    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) => BlocProvider<AddExpenseBloc>.value(
        // Forward the same bloc instance to the inner sheet
        value: bloc,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const LocalizedText('Payment Methods'),
              tileColor: Colors.grey.shade200,
            ),
            ListTile(
              leading: const Icon(Icons.attach_money, color: Colors.green),
              title: const LocalizedText('Cash'),
              trailing:
                  currentMethod == 'Cash' ? const Icon(Icons.check) : null,
              onTap: () {
                // Use the stored bloc instead of looking it up in the bottomSheetContext
                bloc.add(const UpdatePaymentMethod('Cash'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.credit_card, color: Colors.blue),
              title: const LocalizedText('Card'),
              trailing:
                  currentMethod == 'Card' ? const Icon(Icons.check) : null,
              onTap: () {
                bloc.add(const UpdatePaymentMethod('Card'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance, color: Colors.purple),
              title: const LocalizedText('Bank'),
              trailing:
                  currentMethod == 'Bank' ? const Icon(Icons.check) : null,
              onTap: () {
                bloc.add(const UpdatePaymentMethod('Bank'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Show category options in bottom sheet
  void _showCategoryOptions(
      BuildContext context, ExpenseCategory currentCategory) {
    // Store the bloc reference before showing the modal sheet
    final bloc = context.read<AddExpenseBloc>();

    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) => BlocProvider<AddExpenseBloc>.value(
        // Forward the same bloc instance to the inner sheet
        value: bloc,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const LocalizedText('Categories'),
              tileColor: Colors.grey.shade200,
            ),
            SizedBox(
              height: 300, // Limit height for scrolling
              child: ListView(
                children: ExpenseCategory.values.map((category) {
                  final isSelected = category == currentCategory;
                  return ListTile(
                    leading: Icon(
                      category.icon,
                      color: _getCategoryColor(category),
                    ),
                    title: LocalizedText(category.displayName),
                    trailing: isSelected ? const Icon(Icons.check) : null,
                    onTap: () {
                      // Use the stored bloc instead of looking it up in the bottomSheetContext
                      bloc.add(UpdateCategory(category));
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get color for category icon
  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Colors.red;
      case ExpenseCategory.transportation:
        return Colors.blue;
      case ExpenseCategory.entertainment:
        return Colors.purple;
      case ExpenseCategory.utilities:
        return Colors.orange;
      case ExpenseCategory.shopping:
        return Colors.green;
      case ExpenseCategory.health:
        return Colors.pink;
      case ExpenseCategory.education:
        return Colors.teal;
      case ExpenseCategory.travel:
        return Colors.amber;
      case ExpenseCategory.other:
        return Colors.blueGrey;
    }
  }

  // Get icon for payment method
  IconData _getPaymentMethodIcon(String paymentMethod) {
    switch (paymentMethod) {
      case 'Cash':
        return Icons.attach_money;
      case 'Card':
        return Icons.credit_card;
      case 'Bank':
        return Icons.account_balance;
      default:
        return Icons.attach_money;
    }
  }

  // Get color for payment method
  Color _getPaymentMethodColor(String paymentMethod) {
    switch (paymentMethod) {
      case 'Cash':
        return Colors.green.shade100;
      case 'Card':
        return Colors.blue.shade100;
      case 'Bank':
        return Colors.purple.shade100;
      default:
        return Colors.blue.shade100;
    }
  }

  // Build a dropdown button
  Widget _buildDropdownButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.black87),
              const SizedBox(width: 4),
              LocalizedText(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: Colors.black54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddExpenseBloc, AddExpenseState>(
      buildWhen: (previous, current) => previous.amount != current.amount,
      builder: (context, state) {
        // Format amount to two decimal places
        final amount = state.amount.toStringAsFixed(2);

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LocalizedText('\$',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),
              LocalizedText(
                amount,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NumericKeypad extends StatelessWidget {
  const _NumericKeypad();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddExpenseBloc, AddExpenseState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              // Row 1: 1, 2, 3, backspace
              _buildKeypadRow(context, [
                KeypadItem(
                    text: '1', onTap: () => _appendDigit(context, '1', state)),
                KeypadItem(
                    text: '2', onTap: () => _appendDigit(context, '2', state)),
                KeypadItem(
                    text: '3', onTap: () => _appendDigit(context, '3', state)),
                KeypadItem(
                  icon: Icons.backspace_outlined,
                  color: Colors.pink.shade50,
                  onTap: () => _removeLastDigit(context, state),
                ),
              ]),

              // Row 2: 4, 5, 6, calendar
              _buildKeypadRow(context, [
                KeypadItem(
                    text: '4', onTap: () => _appendDigit(context, '4', state)),
                KeypadItem(
                    text: '5', onTap: () => _appendDigit(context, '5', state)),
                KeypadItem(
                    text: '6', onTap: () => _appendDigit(context, '6', state)),
                KeypadItem(
                  icon: Icons.calendar_today,
                  color: Colors.blue.shade50,
                  onTap: () => _selectDate(context, state.date),
                ),
              ]),

              // Row 3: 7, 8, 9, empty
              _buildKeypadRow(context, [
                KeypadItem(
                    text: '7', onTap: () => _appendDigit(context, '7', state)),
                KeypadItem(
                    text: '8', onTap: () => _appendDigit(context, '8', state)),
                KeypadItem(
                    text: '9', onTap: () => _appendDigit(context, '9', state)),
                const KeypadItem(), // Empty placeholder for grid alignment
              ]),

              // Row 4: $, 0, ., confirm
              _buildKeypadRow(context, [
                KeypadItem(
                    text: '\$', onTap: () {}), // Currency button (no action)
                KeypadItem(
                    text: '0', onTap: () => _appendDigit(context, '0', state)),
                KeypadItem(
                    text: ',',
                    onTap: () => _handleDecimalPoint(context, state)),
                KeypadItem(
                  icon: Icons.check,
                  color: Colors.black,
                  textColor: Colors.white,
                  onTap: state.isValid
                      ? () => context
                          .read<AddExpenseBloc>()
                          .add(const SubmitExpense())
                      : null,
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKeypadRow(BuildContext context, List<KeypadItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((item) => Expanded(child: item)).toList(),
      ),
    );
  }

  void _appendDigit(BuildContext context, String digit, AddExpenseState state) {
    String currentInput = state.amount.toStringAsFixed(2);

    // Remove trailing zeros and decimal point if the value is 0.00
    if (state.amount == 0.0) {
      currentInput = '';
    } else {
      // Handle existing decimal places correctly
      final parts = currentInput.split('.');
      if (parts.length == 2) {
        // Already has a decimal point
        if (parts[1] == '00') {
          // If we just have zeros after decimal, start fresh
          currentInput = parts[0];
        }
      }
    }

    // Check if we already have a decimal point
    if (currentInput.contains('.')) {
      // We have a decimal point - make sure we don't add too many decimal places
      final parts = currentInput.split('.');
      if (parts[1].length < 2) {
        // We have room for more decimal places
        currentInput += digit;
      }
    } else {
      // No decimal point yet - just add the digit
      currentInput += digit;
    }

    final newAmount = double.tryParse(currentInput) ?? 0.0;
    context.read<AddExpenseBloc>().add(UpdateAmount(newAmount));
  }

  void _handleDecimalPoint(BuildContext context, AddExpenseState state) {
    String currentInput = state.amount.toString();

    // If we already have a decimal point, don't add another
    if (currentInput.contains('.')) {
      return;
    }

    // Add decimal point
    currentInput += '.';

    final newAmount = double.tryParse(currentInput) ?? 0.0;
    context.read<AddExpenseBloc>().add(UpdateAmount(newAmount));
  }

  void _removeLastDigit(BuildContext context, AddExpenseState state) {
    // Convert to string and remove trailing zeros if it's an integer value
    String currentInput = state.amount.toString();
    if (currentInput.endsWith('.0')) {
      currentInput = currentInput.substring(0, currentInput.length - 2);
    }

    if (currentInput.isEmpty || currentInput == '0') {
      // If already 0, do nothing
      return;
    }

    // Remove last character
    String newInput = currentInput.substring(0, currentInput.length - 1);

    // If we removed the last digit, set to 0
    if (newInput.isEmpty || newInput == '.') {
      newInput = '0';
    }

    final newAmount = double.tryParse(newInput) ?? 0.0;
    context.read<AddExpenseBloc>().add(UpdateAmount(newAmount));
  }

  Future<void> _selectDate(BuildContext context, DateTime initialDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != initialDate && context.mounted) {
      context.read<AddExpenseBloc>().add(UpdateDate(picked));
    }
  }
}

/// A simple model class for keypad items
class KeypadItem extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final VoidCallback? onTap;

  const KeypadItem({
    super.key,
    this.text,
    this.icon,
    this.color,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Empty placeholder item
    if (text == null && icon == null) {
      return const SizedBox(width: 50, height: 50);
    }

    return Padding(
      padding: const EdgeInsets.all(4),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Material(
          color: color ?? Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: icon != null
                  ? Icon(
                      icon,
                      color: textColor,
                      size: 20,
                    )
                  : LocalizedText(
                      text!,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
