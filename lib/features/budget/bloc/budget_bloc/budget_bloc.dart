import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:finance_track/data/repositories/composite_budget_repository.dart';

import '../../../../data/models/budget_model.dart';
import '../../../../data/models/expense_model.dart';

// Events
part 'budget_event.dart';
// States
part 'budget_state.dart';

// Bloc
class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final CompositeBudgetRepository _budgetRepository;

  BudgetBloc({required CompositeBudgetRepository budgetRepository})
      : _budgetRepository = budgetRepository,
        super(BudgetInitial()) {
    on<LoadBudget>(_onLoadBudget);
    on<CreateBudget>(_onCreateBudget);
    on<UpdateBudget>(_onUpdateBudget);
    on<DeleteBudget>(_onDeleteBudget);
    on<SetActiveBudget>(_onSetActiveBudget);
    on<CalculateBudgetStats>(_onCalculateBudgetStats);
  }

  /// Exposes the budget repository for use in other blocs
  CompositeBudgetRepository get repository => _budgetRepository;

  void _onLoadBudget(LoadBudget event, Emitter<BudgetState> emit) {
    emit(BudgetLoading());
    try {
      final activeBudget = _budgetRepository.getActiveBudget();
      final allBudgets = _budgetRepository.getAllBudgets();

      if (activeBudget != null) {
        emit(BudgetLoaded(
          activeBudget: activeBudget,
          allBudgets: allBudgets,
          daysRemaining: activeBudget.daysRemaining,
          dailyBudget: activeBudget.dailyBudget,
        ));
      } else {
        emit(const BudgetLoaded());
      }
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  void _onCreateBudget(CreateBudget event, Emitter<BudgetState> emit) {
    emit(BudgetLoading());
    try {
      final budget = _budgetRepository.createBudget(
        amount: event.amount,
        period: event.period,
        startDate: event.startDate,
        endDate: event.endDate,
        title: event.title,
      );

      final allBudgets = _budgetRepository.getAllBudgets();

      emit(BudgetLoaded(
        activeBudget: budget,
        allBudgets: allBudgets,
        remaining: budget.amount,
        daysRemaining: budget.daysRemaining,
        dailyBudget: budget.dailyBudget,
      ));
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  void _onUpdateBudget(UpdateBudget event, Emitter<BudgetState> emit) {
    emit(BudgetLoading());
    try {
      final updatedBudget = _budgetRepository.updateBudget(event.budget);
      final allBudgets = _budgetRepository.getAllBudgets();

      if (state is BudgetLoaded) {
        final currentState = state as BudgetLoaded;
        emit(currentState.copyWith(
          activeBudget: updatedBudget.isActive
              ? updatedBudget
              : currentState.activeBudget,
          allBudgets: allBudgets,
        ));
      } else {
        emit(BudgetLoaded(
          activeBudget: updatedBudget.isActive ? updatedBudget : null,
          allBudgets: allBudgets,
        ));
      }
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  void _onDeleteBudget(DeleteBudget event, Emitter<BudgetState> emit) {
    emit(BudgetLoading());
    try {
      final success = _budgetRepository.deleteBudget(event.budgetId);
      if (success) {
        final activeBudget = _budgetRepository.getActiveBudget();
        final allBudgets = _budgetRepository.getAllBudgets();

        emit(BudgetLoaded(
          activeBudget: activeBudget,
          allBudgets: allBudgets,
          daysRemaining: activeBudget?.daysRemaining ?? 0,
          dailyBudget: activeBudget?.dailyBudget ?? 0.0,
        ));
      } else {
        emit(const BudgetError('Failed to delete budget'));
      }
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  void _onSetActiveBudget(SetActiveBudget event, Emitter<BudgetState> emit) {
    emit(BudgetLoading());
    try {
      final activeBudget = _budgetRepository.setActiveBudget(event.budgetId);
      final allBudgets = _budgetRepository.getAllBudgets();

      // When setting a new active budget, we need to recalculate stats
      // but we don't have expenses here, so we'll set initial values
      emit(BudgetLoaded(
        activeBudget: activeBudget,
        allBudgets: allBudgets,
        daysRemaining: activeBudget.daysRemaining,
        dailyBudget: activeBudget.dailyBudget,
        remaining: activeBudget.amount, // Initial remaining is full amount
        spent: 0.0, // Reset spent amount
        percentUsed: 0.0, // Reset percentage
      ));
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  void _onCalculateBudgetStats(
      CalculateBudgetStats event, Emitter<BudgetState> emit) {
    if (state is BudgetLoaded) {
      final currentState = state as BudgetLoaded;
      final activeBudget = currentState.activeBudget;

      if (activeBudget != null) {
        // Filter expenses that fall within the budget period
        final periodExpenses = event.expenses.where((expense) {
          // Include expenses from the start date to the end date (inclusive)
          return expense.date.isAfter(
                  activeBudget.startDate.subtract(const Duration(days: 1))) &&
              expense.date
                  .isBefore(activeBudget.endDate.add(const Duration(days: 1)));
        }).toList();

        // Calculate total spent
        final totalSpent = periodExpenses.fold<double>(
            0.0, (sum, expense) => sum + expense.amount);

        // Calculate remaining budget
        final remaining = activeBudget.amount - totalSpent;

        // Calculate percentage used
        final percentUsed = activeBudget.amount > 0
            ? (totalSpent / activeBudget.amount).clamp(0.0, 1.0)
            : 0.0;

        // Calculate daily budget based on remaining amount and days
        final adjustedDailyBudget = activeBudget.daysRemaining > 0
            ? remaining / activeBudget.daysRemaining
            : 0.0;

        emit(currentState.copyWith(
          spent: totalSpent,
          remaining: remaining,
          percentUsed: percentUsed,
          dailyBudget: adjustedDailyBudget,
        ));
      }
    }
  }
}
