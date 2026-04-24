import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/budget_model.dart';
import '../../../../data/repositories/composite_budget_repository.dart';

part 'budget_form_event.dart';
part 'budget_form_state.dart';

class BudgetFormBloc extends Bloc<BudgetFormEvent, BudgetFormState> {
  final CompositeBudgetRepository _budgetRepository;

  BudgetFormBloc({
    required CompositeBudgetRepository budgetRepository,
    Budget? budget,
  })  : _budgetRepository = budgetRepository,
        super(budget != null
            ? BudgetFormState.fromBudget(budget)
            : BudgetFormState.initial()) {
    on<BudgetFormInitialized>(_onInitialized);
    on<BudgetFormPeriodChanged>(_onPeriodChanged);
    on<BudgetFormStartDateChanged>(_onStartDateChanged);
    on<BudgetFormSubmitted>(_onSubmitted);
    on<BudgetFormValidated>(_onValidated);
    on<BudgetFormDeleted>(_onDeleted);
    on<BudgetFormReset>(_onReset);
  }

  void _onInitialized(
    BudgetFormInitialized event,
    Emitter<BudgetFormState> emit,
  ) {
    if (event.budget != null) {
      emit(BudgetFormState.fromBudget(event.budget!));
    } else {
      emit(BudgetFormState.initial());
    }
  }

  void _onPeriodChanged(
    BudgetFormPeriodChanged event,
    Emitter<BudgetFormState> emit,
  ) {
    final normalizedStart = _normalizeStartDate(state.startDate, event.period);
    final endDate = _calculateEndDate(normalizedStart, event.period);

    // Update title based on period if it's still the default format or empty
    final currentTitle = state.titleController.text;
    final periodNames = BudgetPeriod.values.map((p) => p.displayName).toList();

    bool isDefaultTitle = false;
    for (final name in periodNames) {
      if (currentTitle == '$name Budget') {
        isDefaultTitle = true;
        break;
      }
    }

    if (isDefaultTitle || currentTitle.isEmpty) {
      state.titleController.text = '${event.period.displayName} Budget';
    }

    emit(state.copyWith(
      selectedPeriod: event.period,
      startDate: normalizedStart,
      endDate: endDate,
    ));
  }

  void _onStartDateChanged(
    BudgetFormStartDateChanged event,
    Emitter<BudgetFormState> emit,
  ) {
    final normalizedStart =
        _normalizeStartDate(event.startDate, state.selectedPeriod);
    final endDate = _calculateEndDate(normalizedStart, state.selectedPeriod);
    emit(state.copyWith(
      startDate: normalizedStart,
      endDate: endDate,
    ));
  }

  void _onValidated(
    BudgetFormValidated event,
    Emitter<BudgetFormState> emit,
  ) {
    emit(state.copyWith(formValid: event.valid));
  }

  void _onSubmitted(
    BudgetFormSubmitted event,
    Emitter<BudgetFormState> emit,
  ) {
    emit(state.copyWith(submitted: true));

    if (!validateForm()) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Please fill all fields correctly',
      ));
      return;
    }

    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final amount = double.tryParse(state.amountController.text.trim()) ?? 0.0;

      if (amount <= 0) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Please enter a valid amount greater than zero',
        ));
        return;
      }

      // Get the title
      final title = state.titleController.text.trim();
      if (title.isEmpty) {
        state.titleController.text =
            '${state.selectedPeriod.displayName} Budget';
      }

      // Perform the budget operation
      Budget? result;

      if (state.isEditing) {
        // Update existing budget
        final updatedBudget = state.budget!.copyWith(
          title: state.titleController.text,
          amount: amount,
          period: state.selectedPeriod,
          startDate: state.startDate,
          endDate: state.endDate,
          updatedAt: DateTime.now(),
        );

        result = _budgetRepository.updateBudget(updatedBudget);
      } else {
        // Create new budget
        result = _budgetRepository.createBudget(
          title: state.titleController.text,
          amount: amount,
          period: state.selectedPeriod,
          startDate: state.startDate,
          endDate: state.endDate,
        );
      }

      // Set loading to false on success or failure
      if (result.id != null) {
        emit(state.copyWith(
          isLoading: false,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage:
              'Failed to ${state.isEditing ? 'update' : 'create'} budget',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error: ${e.toString()}',
      ));
    }
  }

  void _onDeleted(
    BudgetFormDeleted event,
    Emitter<BudgetFormState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final success = _budgetRepository.deleteBudget(event.budgetId);

      if (!success) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to delete budget',
        ));
      } else {
        // Reset loading state after successful deletion
        emit(state.copyWith(
          isLoading: false,
          clearError: true,
          // Mark as not editing anymore so UI listeners can react
          budget: null,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error: ${e.toString()}',
      ));
    }
  }

  void _onReset(
    BudgetFormReset event,
    Emitter<BudgetFormState> emit,
  ) {
    emit(BudgetFormState.initial());
  }

  DateTime _calculateEndDate(DateTime startDate, BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        return DateTime(startDate.year, startDate.month, startDate.day)
            .add(const Duration(days: 6)); // Monday..Sunday (7 days)
      case BudgetPeriod.monthly:
        // Last day of the month
        final nextMonth = startDate.month < 12
            ? DateTime(startDate.year, startDate.month + 1, 1)
            : DateTime(startDate.year + 1, 1, 1);
        return nextMonth.subtract(const Duration(days: 1));
      case BudgetPeriod.yearly:
        return DateTime(startDate.year + 1, startDate.month, startDate.day)
            .subtract(const Duration(days: 1));
    }
  }

  DateTime _normalizeStartDate(DateTime date, BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        // align to Monday
        final weekday = date.weekday; // Monday=1
        final delta = weekday - DateTime.monday; // 0 for Monday
        return DateTime(date.year, date.month, date.day)
            .subtract(Duration(days: delta));
      case BudgetPeriod.monthly:
        return DateTime(date.year, date.month, 1);
      case BudgetPeriod.yearly:
        return DateTime(date.year, 1, 1);
    }
  }

  bool validateForm() {
    // Check if amount is valid
    final amountText = state.amountController.text.trim();
    if (amountText.isEmpty) {
      return false;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      return false;
    }

    // Check if title is valid
    final title = state.titleController.text.trim();
    if (title.isEmpty) {
      return false;
    }

    return true;
  }

  @override
  Future<void> close() {
    // Clean up controllers to prevent memory leaks
    state.dispose();
    return super.close();
  }
}
