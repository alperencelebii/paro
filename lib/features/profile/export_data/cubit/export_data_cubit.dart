import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../repository/export_data_repository.dart';

enum ExportPeriod {
  today,
  thisWeek,
  thisMonth,
  last30Days,
  last3Months,
  last6Months,
  last12Months,
  allTime,
  custom,
}

class ExportDataState extends Equatable {
  final ExportPeriod selectedPeriod;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<Map<String, dynamic>> transactions;
  final bool isLoading;
  final String? error;

  const ExportDataState({
    this.selectedPeriod = ExportPeriod.last30Days,
    this.startDate,
    this.endDate,
    this.transactions = const [],
    this.isLoading = false,
    this.error,
  });

  ExportDataState copyWith({
    ExportPeriod? selectedPeriod,
    DateTime? startDate,
    DateTime? endDate,
    List<Map<String, dynamic>>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return ExportDataState(
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        selectedPeriod,
        startDate,
        endDate,
        transactions,
        isLoading,
        error,
      ];
}

class ExportDataCubit extends Cubit<ExportDataState> {
  final ExportDataRepository _repository;

  ExportDataCubit({ExportDataRepository? repository})
      : _repository = repository ?? ExportDataRepository(),
        super(const ExportDataState());

  void setPeriod(ExportPeriod period) {
    final now = DateTime.now();
    // Set the endDate to the end of the current day (23:59:59)
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    DateTime? startDate;
    DateTime? endDate = endOfDay;

    switch (period) {
      case ExportPeriod.today:
        // Start of current day
        startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
        break;
      case ExportPeriod.thisWeek:
        // Start of current week (Monday)
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate =
            DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
        break;
      case ExportPeriod.thisMonth:
        // Start of current month
        startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
        break;
      case ExportPeriod.last30Days:
        // 30 days ago
        startDate = now.subtract(const Duration(days: 30));
        startDate =
            DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
        break;
      case ExportPeriod.last3Months:
        // 3 months ago
        startDate = DateTime(now.year, now.month - 3, now.day, 0, 0, 0);
        break;
      case ExportPeriod.last6Months:
        // 6 months ago
        startDate = DateTime(now.year, now.month - 6, now.day, 0, 0, 0);
        break;
      case ExportPeriod.last12Months:
        // 12 months ago
        startDate = DateTime(now.year - 1, now.month, now.day, 0, 0, 0);
        break;
      case ExportPeriod.allTime:
        // No date restrictions
        startDate = null;
        endDate = null;
        break;
      case ExportPeriod.custom:
        // Custom dates will be set separately
        return;
    }

    emit(state.copyWith(
      selectedPeriod: period,
      startDate: startDate,
      endDate: endDate,
    ));

    _loadTransactions();
  }

  void setCustomDateRange(DateTime startDate, DateTime endDate) {
    // Ensure start date is at beginning of day
    final startOfDay =
        DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);

    // Ensure end date is at end of day
    final endOfDay =
        DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    emit(state.copyWith(
      selectedPeriod: ExportPeriod.custom,
      startDate: startOfDay,
      endDate: endOfDay,
    ));

    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      emit(state.copyWith(isLoading: true, error: null));

      final transactions = await _repository.getTransactions(
        startDate: state.startDate,
        endDate: state.endDate,
      );

      emit(state.copyWith(
        transactions: transactions,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load transactions: ${e.toString()}',
      ));
    }
  }

  Future<void> exportTransactions() async {
    try {
      emit(state.copyWith(isLoading: true, error: null));

      await _repository.exportTransactions(
        transactions: state.transactions,
        startDate: state.startDate,
        endDate: state.endDate,
      );

      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to export transactions: ${e.toString()}',
      ));
    }
  }
}
