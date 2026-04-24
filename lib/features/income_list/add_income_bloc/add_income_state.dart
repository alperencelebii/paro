import 'package:equatable/equatable.dart';

import '../../../data/models/income_model.dart';

/// Status of form submission
enum FormSubmissionStatus {
  initial,
  inProgress,
  success,
  failure,
}

/// State for the add income form
class AddIncomeState extends Equatable {
  final String id;
  final String title;
  final String amount;
  final DateTime date;
  final IncomeCategory category;
  final String? notes;
  final String source;
  final FormSubmissionStatus formStatus;
  final String errorMessage;
  final bool isEditing;

  AddIncomeState({
    this.id = '',
    this.title = '',
    this.amount = '',
    DateTime? date,
    this.category = IncomeCategory.salary,
    this.notes,
    this.source = '',
    this.formStatus = FormSubmissionStatus.initial,
    this.errorMessage = '',
    this.isEditing = false,
  }) : date = date ?? DateTime.now();

  /// Create a copy with updated parameters
  AddIncomeState copyWith({
    String? id,
    String? title,
    String? amount,
    DateTime? date,
    IncomeCategory? category,
    String? notes,
    bool clearNotes = false,
    String? source,
    FormSubmissionStatus? formStatus,
    String? errorMessage,
    bool? isEditing,
  }) {
    return AddIncomeState(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      notes: clearNotes ? null : notes ?? this.notes,
      source: source ?? this.source,
      formStatus: formStatus ?? this.formStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      isEditing: isEditing ?? this.isEditing,
    );
  }

  /// Check if the form is valid
  bool get isFormValid {
    return title.isNotEmpty &&
        amount.isNotEmpty &&
        double.tryParse(amount) != null &&
        double.parse(amount) > 0;
  }

  /// Get the amount as a double
  double get amountAsDouble {
    return double.tryParse(amount) ?? 0.0;
  }

  /// Create an Income object from the state
  Income toIncome() {
    return Income.create(
      uuid: id,
      title: title,
      amount: amountAsDouble,
      date: date,
      category: category,
      notes: notes,
      source: source,
    );
  }

  /// Create a state from an Income object
  factory AddIncomeState.fromIncome(Income income) {
    return AddIncomeState(
      id: income.uuid,
      title: income.title,
      amount: income.amount.toString(),
      date: income.date,
      category: income.category,
      notes: income.notes,
      source: income.source,
      isEditing: true,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        amount,
        date,
        category,
        notes,
        source,
        formStatus,
        errorMessage,
        isEditing,
      ];
}
