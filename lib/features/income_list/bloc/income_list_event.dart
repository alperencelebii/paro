import 'package:equatable/equatable.dart';

import '../../../data/models/income_model.dart';

/// Base event class for IncomeListBloc
abstract class IncomeListEvent extends Equatable {
  const IncomeListEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all incomes
class LoadIncomes extends IncomeListEvent {
  const LoadIncomes();
}

/// Event when incomes are loaded
class IncomesLoaded extends IncomeListEvent {
  final List<Income> incomes;

  const IncomesLoaded(this.incomes);

  @override
  List<Object?> get props => [incomes];
}

/// Event to filter incomes by category
class FilterIncomesByCategory extends IncomeListEvent {
  final IncomeCategory? category;

  const FilterIncomesByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

/// Event to delete an income
class DeleteIncome extends IncomeListEvent {
  final String incomeId;

  const DeleteIncome(this.incomeId);

  @override
  List<Object?> get props => [incomeId];
}

/// Event when an income is successfully deleted
class IncomeDeleted extends IncomeListEvent {
  final String incomeId;

  const IncomeDeleted(this.incomeId);

  @override
  List<Object?> get props => [incomeId];
}

/// Event to update an income
class UpdateIncome extends IncomeListEvent {
  final Income income;

  const UpdateIncome(this.income);

  @override
  List<Object?> get props => [income];
}
