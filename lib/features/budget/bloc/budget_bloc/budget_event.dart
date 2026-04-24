part of 'budget_bloc.dart';

abstract class BudgetEvent extends Equatable {
  const BudgetEvent();

  @override
  List<Object?> get props => [];
}

class LoadBudget extends BudgetEvent {
  const LoadBudget();
}

class CreateBudget extends BudgetEvent {
  final double amount;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime? endDate;
  final String title;

  const CreateBudget({
    required this.amount,
    required this.period,
    required this.startDate,
    this.endDate,
    this.title = '',
  });

  @override
  List<Object?> get props => [amount, period, startDate, endDate, title];
}

class UpdateBudget extends BudgetEvent {
  final Budget budget;

  const UpdateBudget(this.budget);

  @override
  List<Object?> get props => [budget];
}

class DeleteBudget extends BudgetEvent {
  final int budgetId;

  const DeleteBudget(this.budgetId);

  @override
  List<Object?> get props => [budgetId];
}

class SetActiveBudget extends BudgetEvent {
  final int budgetId;

  const SetActiveBudget(this.budgetId);

  @override
  List<Object?> get props => [budgetId];
}

class CalculateBudgetStats extends BudgetEvent {
  final List<Expense> expenses;

  const CalculateBudgetStats(this.expenses);

  @override
  List<Object?> get props => [expenses];
}
