import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/repositories/expense_repository.dart';
import 'add_expense_event.dart';
import 'add_expense_state.dart';

/// BLoC for managing the add expense form
class AddExpenseBloc extends Bloc<AddExpenseEvent, AddExpenseState> {
  final ExpenseRepository _expenseRepository;
  final Uuid _uuid = const Uuid();

  // Set this to false to disable debug prints
  static const bool enableDebugPrints = false;

  AddExpenseBloc(this._expenseRepository) : super(AddExpenseState.initial()) {
    if (enableDebugPrints) {
      debugPrint(
          'AddExpenseBloc created with initial state: ${state.category.displayName}, ${state.paymentMethod}');
    }

    on<UpdateAmount>(_onUpdateAmount);
    on<UpdateCategory>(_onUpdateCategory);
    on<UpdatePaymentMethod>(_onUpdatePaymentMethod);
    on<UpdateDate>(_onUpdateDate);
    on<UpdateNotes>(_onUpdateNotes);
    on<SubmitExpense>(_onSubmitExpense);
    on<ResetForm>(_onResetForm);
  }

  @override
  Future<void> close() {
    if (enableDebugPrints) {
      debugPrint('AddExpenseBloc closing');
    }
    return super.close();
  }

  void _onUpdateAmount(
    UpdateAmount event,
    Emitter<AddExpenseState> emit,
  ) {
    if (enableDebugPrints) {
      debugPrint('Updating amount to: ${event.amount}');
    }
    emit(state.copyWith(amount: event.amount));
  }

  void _onUpdateCategory(
    UpdateCategory event,
    Emitter<AddExpenseState> emit,
  ) {
    if (enableDebugPrints) {
      debugPrint('Updating category to: ${event.category.displayName}');
    }
    final newState = state.copyWith(category: event.category);
    emit(newState);
    if (enableDebugPrints) {
      debugPrint(
          'New state after category update: ${newState.category.displayName}');
    }
  }

  void _onUpdatePaymentMethod(
    UpdatePaymentMethod event,
    Emitter<AddExpenseState> emit,
  ) {
    if (enableDebugPrints) {
      debugPrint('Updating payment method to: ${event.paymentMethod}');
    }
    final newState = state.copyWith(paymentMethod: event.paymentMethod);
    emit(newState);
    if (enableDebugPrints) {
      debugPrint(
          'New state after payment method update: ${newState.paymentMethod}');
    }
  }

  void _onUpdateDate(
    UpdateDate event,
    Emitter<AddExpenseState> emit,
  ) {
    if (enableDebugPrints) {
      debugPrint('Updating date to: ${event.date}');
    }
    emit(state.copyWith(date: event.date));
  }

  void _onUpdateNotes(
    UpdateNotes event,
    Emitter<AddExpenseState> emit,
  ) {
    emit(state.copyWith(notes: event.notes));
  }

  Future<void> _onSubmitExpense(
    SubmitExpense event,
    Emitter<AddExpenseState> emit,
  ) async {
    if (enableDebugPrints) {
      debugPrint('Attempting to submit expense');
    }
    if (!state.isValid) {
      if (enableDebugPrints) {
        debugPrint('Expense validation failed');
      }
      emit(state.copyWith(
        errorMessage: 'Amount must be greater than zero',
      ));
      return;
    }

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    try {
      // Generate a title based on the category and payment method if notes are empty
      final title = state.notes?.isNotEmpty == true
          ? state.notes!
          : '${state.category.displayName} (${state.paymentMethod})';

      if (enableDebugPrints) {
        debugPrint(
            'Submitting expense with title: $title, category: ${state.category.displayName}, payment: ${state.paymentMethod}');
      }

      final expense = Expense.create(
        uuid: _uuid.v4(),
        title: title,
        amount: state.amount,
        date: state.date,
        category: state.category,
        notes: state.notes,
        paymentMethod: state.paymentMethod,
      );

      await _expenseRepository.addExpense(expense);
      if (enableDebugPrints) {
        debugPrint('Expense added successfully');
      }
      emit(state.copyWith(isSubmitting: false, isSuccess: true));
    } catch (e) {
      if (enableDebugPrints) {
        debugPrint('Error submitting expense: $e');
      }
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onResetForm(
    ResetForm event,
    Emitter<AddExpenseState> emit,
  ) {
    if (enableDebugPrints) {
      debugPrint('Resetting expense form');
    }
    emit(AddExpenseState.initial());
  }
}
