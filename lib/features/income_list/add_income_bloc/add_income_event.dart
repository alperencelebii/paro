import 'package:equatable/equatable.dart';

import '../../../data/models/income_model.dart';

/// Base event class for AddIncomeBloc
abstract class AddIncomeEvent extends Equatable {
  const AddIncomeEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize the income form
class InitializeIncomeForm extends AddIncomeEvent {
  final Income? income;

  const InitializeIncomeForm({this.income});

  @override
  List<Object?> get props => [income];
}

/// Event to update the income title
class UpdateIncomeTitle extends AddIncomeEvent {
  final String title;

  const UpdateIncomeTitle(this.title);

  @override
  List<Object?> get props => [title];
}

/// Event to update the income amount
class UpdateIncomeAmount extends AddIncomeEvent {
  final String amount;

  const UpdateIncomeAmount(this.amount);

  @override
  List<Object?> get props => [amount];
}

/// Event to update the income date
class UpdateIncomeDate extends AddIncomeEvent {
  final DateTime date;

  const UpdateIncomeDate(this.date);

  @override
  List<Object?> get props => [date];
}

/// Event to update the income category
class UpdateIncomeCategory extends AddIncomeEvent {
  final IncomeCategory category;

  const UpdateIncomeCategory(this.category);

  @override
  List<Object?> get props => [category];
}

/// Event to update the income notes
class UpdateIncomeNotes extends AddIncomeEvent {
  final String? notes;

  const UpdateIncomeNotes(this.notes);

  @override
  List<Object?> get props => [notes];
}

/// Event to update the income source
class UpdateIncomeSource extends AddIncomeEvent {
  final String source;

  const UpdateIncomeSource(this.source);

  @override
  List<Object?> get props => [source];
}

/// Event to submit the income form
class SubmitIncomeForm extends AddIncomeEvent {
  const SubmitIncomeForm();
}

/// Event when the form submission is successful
class FormSubmissionSuccess extends AddIncomeEvent {
  const FormSubmissionSuccess();
}

/// Event when the form submission fails
class FormSubmissionFailure extends AddIncomeEvent {
  final String errorMessage;

  const FormSubmissionFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
} 