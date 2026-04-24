part of 'budget_bloc.dart';
abstract class BudgetState extends Equatable {
  const BudgetState();

  @override
  List<Object?> get props => [];
}

class BudgetInitial extends BudgetState {}

class BudgetLoading extends BudgetState {}

class BudgetLoaded extends BudgetState {
  final Budget? activeBudget;
  final List<Budget> allBudgets;
  final double spent;
  final double remaining;
  final double dailyBudget;
  final int daysRemaining;
  final double percentUsed;

  const BudgetLoaded({
    this.activeBudget,
    this.allBudgets = const [],
    this.spent = 0.0,
    this.remaining = 0.0,
    this.dailyBudget = 0.0,
    this.daysRemaining = 0,
    this.percentUsed = 0.0,
  });

  @override
  List<Object?> get props => [
        activeBudget,
        allBudgets,
        spent,
        remaining,
        dailyBudget,
        daysRemaining,
        percentUsed,
      ];

  BudgetLoaded copyWith({
    Budget? activeBudget,
    List<Budget>? allBudgets,
    double? spent,
    double? remaining,
    double? dailyBudget,
    int? daysRemaining,
    double? percentUsed,
  }) {
    return BudgetLoaded(
      activeBudget: activeBudget ?? this.activeBudget,
      allBudgets: allBudgets ?? this.allBudgets,
      spent: spent ?? this.spent,
      remaining: remaining ?? this.remaining,
      dailyBudget: dailyBudget ?? this.dailyBudget,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      percentUsed: percentUsed ?? this.percentUsed,
    );
  }
}

class BudgetError extends BudgetState {
  final String message;

  const BudgetError(this.message);

  @override
  List<Object?> get props => [message];
}
