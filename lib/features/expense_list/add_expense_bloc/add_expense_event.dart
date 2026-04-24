import 'package:equatable/equatable.dart';
import '../../../data/models/expense_model.dart';

/// Events for the AddExpenseBloc
abstract class AddExpenseEvent extends Equatable {
  const AddExpenseEvent();

  @override
  List<Object?> get props => [];
}

/// Event to update amount
class UpdateAmount extends AddExpenseEvent {
  final double amount;

  const UpdateAmount(this.amount);

  @override
  List<Object?> get props => [amount];
}

/// Event to update category
class UpdateCategory extends AddExpenseEvent {
  final ExpenseCategory category;

  const UpdateCategory(this.category);

  @override
  List<Object?> get props => [category];
}

/// Event to update payment method
class UpdatePaymentMethod extends AddExpenseEvent {
  final String paymentMethod;

  const UpdatePaymentMethod(this.paymentMethod);

  @override
  List<Object?> get props => [paymentMethod];
}

/// Event to update date
class UpdateDate extends AddExpenseEvent {
  final DateTime date;

  const UpdateDate(this.date);

  @override
  List<Object?> get props => [date];
}

/// Event to update title/notes
class UpdateNotes extends AddExpenseEvent {
  final String notes;

  const UpdateNotes(this.notes);

  @override
  List<Object?> get props => [notes];
}

/// Event to submit the expense
class SubmitExpense extends AddExpenseEvent {
  const SubmitExpense();
}

/// Event to reset the form
class ResetForm extends AddExpenseEvent {
  const ResetForm();
}
