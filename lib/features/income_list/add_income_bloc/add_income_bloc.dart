import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../data/repositories/income_repository.dart';
import 'add_income_event.dart';
import 'add_income_state.dart';

/// BLoC for managing the add income form
class AddIncomeBloc extends Bloc<AddIncomeEvent, AddIncomeState> {
  final IncomeRepository _incomeRepository;

  /// Constructor taking an income repository
  AddIncomeBloc(this._incomeRepository)
      : super(AddIncomeState(id: const Uuid().v4())) {
    on<InitializeIncomeForm>(_onInitializeIncomeForm);
    on<UpdateIncomeTitle>(_onUpdateIncomeTitle);
    on<UpdateIncomeAmount>(_onUpdateIncomeAmount);
    on<UpdateIncomeDate>(_onUpdateIncomeDate);
    on<UpdateIncomeCategory>(_onUpdateIncomeCategory);
    on<UpdateIncomeNotes>(_onUpdateIncomeNotes);
    on<UpdateIncomeSource>(_onUpdateIncomeSource);
    on<SubmitIncomeForm>(_onSubmitIncomeForm);
    on<FormSubmissionSuccess>(_onFormSubmissionSuccess);
    on<FormSubmissionFailure>(_onFormSubmissionFailure);
  }

  /// Handle the InitializeIncomeForm event
  void _onInitializeIncomeForm(
    InitializeIncomeForm event,
    Emitter<AddIncomeState> emit,
  ) {
    if (event.income != null) {
      emit(AddIncomeState.fromIncome(event.income!));
    } else {
      emit(AddIncomeState(id: const Uuid().v4()));
    }
  }

  /// Handle the UpdateIncomeTitle event
  void _onUpdateIncomeTitle(
    UpdateIncomeTitle event,
    Emitter<AddIncomeState> emit,
  ) {
    emit(state.copyWith(title: event.title));
  }

  /// Handle the UpdateIncomeAmount event
  void _onUpdateIncomeAmount(
    UpdateIncomeAmount event,
    Emitter<AddIncomeState> emit,
  ) {
    emit(state.copyWith(amount: event.amount));
  }

  /// Handle the UpdateIncomeDate event
  void _onUpdateIncomeDate(
    UpdateIncomeDate event,
    Emitter<AddIncomeState> emit,
  ) {
    emit(state.copyWith(date: event.date));
  }

  /// Handle the UpdateIncomeCategory event
  void _onUpdateIncomeCategory(
    UpdateIncomeCategory event,
    Emitter<AddIncomeState> emit,
  ) {
    emit(state.copyWith(category: event.category));
  }

  /// Handle the UpdateIncomeNotes event
  void _onUpdateIncomeNotes(
    UpdateIncomeNotes event,
    Emitter<AddIncomeState> emit,
  ) {
    emit(state.copyWith(
      notes: event.notes,
      clearNotes: event.notes == null || event.notes!.isEmpty,
    ));
  }

  /// Handle the UpdateIncomeSource event
  void _onUpdateIncomeSource(
    UpdateIncomeSource event,
    Emitter<AddIncomeState> emit,
  ) {
    emit(state.copyWith(source: event.source));
  }

  /// Handle the SubmitIncomeForm event
  Future<void> _onSubmitIncomeForm(
    SubmitIncomeForm event,
    Emitter<AddIncomeState> emit,
  ) async {
    if (!state.isFormValid) {
      emit(state.copyWith(
        formStatus: FormSubmissionStatus.failure,
        errorMessage: 'Please fill in all required fields correctly.',
      ));
      return;
    }

    emit(state.copyWith(formStatus: FormSubmissionStatus.inProgress));

    try {
      final income = state.toIncome();

      if (state.isEditing) {
        await _incomeRepository.updateIncome(income);
      } else {
        await _incomeRepository.addIncome(income);
      }

      add(const FormSubmissionSuccess());
    } catch (e) {
      add(FormSubmissionFailure(e.toString()));
    }
  }

  /// Handle the FormSubmissionSuccess event
  void _onFormSubmissionSuccess(
    FormSubmissionSuccess event,
    Emitter<AddIncomeState> emit,
  ) {
    emit(state.copyWith(formStatus: FormSubmissionStatus.success));
  }

  /// Handle the FormSubmissionFailure event
  void _onFormSubmissionFailure(
    FormSubmissionFailure event,
    Emitter<AddIncomeState> emit,
  ) {
    emit(state.copyWith(
      formStatus: FormSubmissionStatus.failure,
      errorMessage: event.errorMessage,
    ));
  }
}
