import 'package:equatable/equatable.dart';
import '../../../data/models/expense_model.dart';

/// State for the AddExpenseBloc
class AddExpenseState extends Equatable {
  final double amount;
  final ExpenseCategory category;
  final String paymentMethod;
  final DateTime date;
  final String? notes;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;

  /// Default values for a new expense
  const AddExpenseState({
    this.amount = 0.0,
    this.category = ExpenseCategory.food,
    this.paymentMethod = 'Cash',
    required this.date,
    this.notes,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  /// Initial state factory
  factory AddExpenseState.initial() {
    return AddExpenseState(
      date: DateTime.now(),
    );
  }

  /// Check if the form is valid
  bool get isValid => amount > 0;

  @override
  List<Object?> get props => [
        amount,
        category,
        paymentMethod,
        date,
        notes,
        isSubmitting,
        isSuccess,
        errorMessage,
      ];

  /// Create a copy with updated parameters
  AddExpenseState copyWith({
    double? amount,
    ExpenseCategory? category,
    String? paymentMethod,
    DateTime? date,
    String? notes,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return AddExpenseState(
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
