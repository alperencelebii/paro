part of 'budget_form_bloc.dart';
/// Base event class for budget form events
abstract class BudgetFormEvent {}

/// Event to initialize the form with a budget (for editing)
class BudgetFormInitialized extends BudgetFormEvent {
  final Budget? budget;

  BudgetFormInitialized({this.budget});
}

/// Event when the period is changed
class BudgetFormPeriodChanged extends BudgetFormEvent {
  final BudgetPeriod period;

  BudgetFormPeriodChanged(this.period);
}

/// Event when the start date is changed
class BudgetFormStartDateChanged extends BudgetFormEvent {
  final DateTime startDate;

  BudgetFormStartDateChanged(this.startDate);
}

/// Event when the form is submitted
class BudgetFormSubmitted extends BudgetFormEvent {}

/// Event to validate the form
class BudgetFormValidated extends BudgetFormEvent {
  final bool valid;

  BudgetFormValidated(this.valid);
}

/// Event to delete a budget
class BudgetFormDeleted extends BudgetFormEvent {
  final int budgetId;

  BudgetFormDeleted(this.budgetId);
}

/// Event to reset form state
class BudgetFormReset extends BudgetFormEvent {}
