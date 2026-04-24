import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/income_repository.dart';
import 'income_list_event.dart';
import 'income_list_state.dart';

/// BLoC for managing the income list
class IncomeListBloc extends Bloc<IncomeListEvent, IncomeListState> {
  final IncomeRepository _incomeRepository;
  StreamSubscription? _incomeSubscription;

  /// Constructor taking an income repository
  IncomeListBloc(this._incomeRepository) : super(const IncomeListState()) {
    on<LoadIncomes>(_onLoadIncomes);
    on<IncomesLoaded>(_onIncomesLoaded);
    on<FilterIncomesByCategory>(_onFilterIncomesByCategory);
    on<DeleteIncome>(_onDeleteIncome);
    on<IncomeDeleted>(_onIncomeDeleted);
    on<UpdateIncome>(_onUpdateIncome);
  }

  /// Handle the LoadIncomes event
  Future<void> _onLoadIncomes(
    LoadIncomes event,
    Emitter<IncomeListState> emit,
  ) async {
    emit(state.copyWith(status: IncomeListStatus.loading));

    try {
      // Cancel any previous subscriptions
      await _incomeSubscription?.cancel();

      // Subscribe to the income stream
      _incomeSubscription = _incomeRepository.getIncomesStream().listen(
        (incomes) {
          add(IncomesLoaded(incomes));
        },
        onError: (error) {
          emit(state.copyWith(
            status: IncomeListStatus.error,
            errorMessage: error.toString(),
          ));
        },
      );
    } catch (error) {
      emit(state.copyWith(
        status: IncomeListStatus.error,
        errorMessage: 'Failed to load incomes: ${error.toString()}',
      ));
    }
  }

  /// Handle the IncomesLoaded event
  void _onIncomesLoaded(
    IncomesLoaded event,
    Emitter<IncomeListState> emit,
  ) {
    emit(state.copyWith(
      status: IncomeListStatus.loaded,
      incomes: event.incomes,
    ));
  }

  /// Handle the FilterIncomesByCategory event
  void _onFilterIncomesByCategory(
    FilterIncomesByCategory event,
    Emitter<IncomeListState> emit,
  ) {
    emit(state.copyWith(selectedCategory: event.category));
  }

  /// Handle the DeleteIncome event
  Future<void> _onDeleteIncome(
    DeleteIncome event,
    Emitter<IncomeListState> emit,
  ) async {
    try {
      await _incomeRepository.deleteIncome(event.incomeId);
      add(IncomeDeleted(event.incomeId));
    } catch (error) {
      emit(state.copyWith(
        status: IncomeListStatus.error,
        errorMessage: 'Failed to delete income: ${error.toString()}',
      ));
    }
  }

  /// Handle the IncomeDeleted event
  void _onIncomeDeleted(
    IncomeDeleted event,
    Emitter<IncomeListState> emit,
  ) {
    // No need to update state as we're using a stream
    // which will push the updated list via IncomesLoaded
  }

  /// Handle the UpdateIncome event
  Future<void> _onUpdateIncome(
    UpdateIncome event,
    Emitter<IncomeListState> emit,
  ) async {
    try {
      await _incomeRepository.updateIncome(event.income);
      // The updated item will be delivered through the stream
    } catch (error) {
      emit(state.copyWith(
        status: IncomeListStatus.error,
        errorMessage: 'Failed to update income: ${error.toString()}',
      ));
    }
  }

  @override
  Future<void> close() {
    _incomeSubscription?.cancel();
    return super.close();
  }
}
