import 'package:equatable/equatable.dart';

import '../../../data/models/income_model.dart';

/// Status of income list loading
enum IncomeListStatus {
  initial,
  loading,
  loaded,
  error,
}

/// State for the income list
class IncomeListState extends Equatable {
  final IncomeListStatus status;
  final List<Income> incomes;
  final String errorMessage;
  final IncomeCategory? selectedCategory;

  const IncomeListState({
    this.status = IncomeListStatus.initial,
    this.incomes = const [],
    this.errorMessage = '',
    this.selectedCategory,
  });

  /// Create a copy with updated parameters
  IncomeListState copyWith({
    IncomeListStatus? status,
    List<Income>? incomes,
    String? errorMessage,
    IncomeCategory? selectedCategory,
    bool clearSelectedCategory = false,
  }) {
    return IncomeListState(
      status: status ?? this.status,
      incomes: incomes ?? this.incomes,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedCategory: clearSelectedCategory ? null : selectedCategory ?? this.selectedCategory,
    );
  }

  /// Get filtered incomes based on selected category
  List<Income> get filteredIncomes {
    if (selectedCategory == null) {
      return incomes;
    }
    return incomes.where((income) => income.category == selectedCategory).toList();
  }

  /// Get total income amount
  double get totalIncome {
    return incomes.fold(0, (sum, income) => sum + income.amount);
  }

  /// Get total income amount for the filtered list
  double get totalFilteredIncome {
    return filteredIncomes.fold(0, (sum, income) => sum + income.amount);
  }

  @override
  List<Object?> get props => [status, incomes, errorMessage, selectedCategory];
} 