part of 'budget_form_bloc.dart';

/// Represents the state of the budget form
class BudgetFormState {
  final TextEditingController amountController;
  final TextEditingController titleController;
  final BudgetPeriod selectedPeriod;
  final DateTime startDate;
  final DateTime endDate;
  final bool isLoading;
  final String? errorMessage;
  final bool submitted;
  final bool formValid;
  final Budget? budget;

  const BudgetFormState({
    required this.amountController,
    required this.titleController,
    required this.selectedPeriod,
    required this.startDate,
    required this.endDate,
    this.isLoading = false,
    this.errorMessage,
    this.submitted = false,
    this.formValid = false,
    this.budget,
  });

  /// Creates an initial state for the budget form
  factory BudgetFormState.initial() {
    final now = DateTime.now();
    const defaultPeriod = BudgetPeriod.monthly;

    // Normalize to start of current month
    final startOfMonth = DateTime(now.year, now.month, 1);
    // Calculate default end date based on monthly period
    final nextMonth = now.month < 12
        ? DateTime(now.year, now.month + 1, 1)
        : DateTime(now.year + 1, 1, 1);
    final endDate = nextMonth.subtract(const Duration(days: 1));

    return BudgetFormState(
      amountController: TextEditingController(),
      titleController:
          TextEditingController(text: '${defaultPeriod.displayName} Budget'),
      selectedPeriod: defaultPeriod,
      startDate: startOfMonth,
      endDate: endDate,
    );
  }

  /// Creates a state from an existing budget for editing
  factory BudgetFormState.fromBudget(Budget budget) {
    return BudgetFormState(
      amountController:
          TextEditingController(text: budget.amount.toStringAsFixed(2)),
      titleController: TextEditingController(
        text: budget.title.isNotEmpty
            ? budget.title
            : '${budget.period.displayName} Budget',
      ),
      selectedPeriod: budget.period,
      startDate: budget.startDate,
      endDate: budget.endDate,
      budget: budget,
    );
  }

  /// Creates a copy of the current state with specified values changed
  BudgetFormState copyWith({
    TextEditingController? amountController,
    TextEditingController? titleController,
    BudgetPeriod? selectedPeriod,
    DateTime? startDate,
    DateTime? endDate,
    bool? isLoading,
    String? errorMessage,
    bool? submitted,
    bool? formValid,
    Budget? budget,
    bool clearError = false,
  }) {
    return BudgetFormState(
      amountController: amountController ?? this.amountController,
      titleController: titleController ?? this.titleController,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      submitted: submitted ?? this.submitted,
      formValid: formValid ?? this.formValid,
      budget: budget ?? this.budget,
    );
  }

  /// Creates a new state with disposed controllers (to prevent memory leaks)
  BudgetFormState dispose() {
    amountController.dispose();
    titleController.dispose();
    return this;
  }

  /// Whether the form is in edit mode
  bool get isEditing => budget != null;

  @override
  String toString() =>
      'BudgetFormState(period: $selectedPeriod, isLoading: $isLoading, submitted: $submitted)';
}
