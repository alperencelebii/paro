import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:finance_track/data/models/user_category_model.dart';
import 'package:finance_track/data/repositories/category_repository.dart';
import 'dart:async';

class ManageCategoriesState extends Equatable {
  final List<UserCategory> expenseCategories;
  final List<UserCategory> incomeCategories;
  final bool isLoading;
  final String? error;

  const ManageCategoriesState({
    this.expenseCategories = const [],
    this.incomeCategories = const [],
    this.isLoading = false,
    this.error,
  });

  ManageCategoriesState copyWith({
    List<UserCategory>? expenseCategories,
    List<UserCategory>? incomeCategories,
    bool? isLoading,
    String? error,
  }) {
    return ManageCategoriesState(
      expenseCategories: expenseCategories ?? this.expenseCategories,
      incomeCategories: incomeCategories ?? this.incomeCategories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [expenseCategories, incomeCategories, isLoading, error];
}

class ManageCategoriesCubit extends Cubit<ManageCategoriesState> {
  final CategoryRepository _repository;
  StreamSubscription<List<UserCategory>>? _expenseSub;
  StreamSubscription<List<UserCategory>>? _incomeSub;

  ManageCategoriesCubit(this._repository)
      : super(const ManageCategoriesState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));
    await _expenseSub?.cancel();
    await _incomeSub?.cancel();
    try {
      // Hydrate local from cloud via composite repo (returns local fast)
      final expense =
          await _repository.getAllCategories(type: CategoryType.expense);
      final income =
          await _repository.getAllCategories(type: CategoryType.income);
      emit(state.copyWith(
        expenseCategories: expense,
        incomeCategories: income,
        isLoading: false,
      ));

      // Watch local for changes so UI stays in sync without extra network calls
      _expenseSub = _repository
          .watchCategories(type: CategoryType.expense)
          .listen((list) => emit(state.copyWith(expenseCategories: list)));
      _incomeSub = _repository
          .watchCategories(type: CategoryType.income)
          .listen((list) => emit(state.copyWith(incomeCategories: list)));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> upsert(UserCategory category) async {
    await _repository.upsert(category);
    await load();
  }

  Future<void> delete(String uuid) async {
    await _repository.softDelete(uuid);
    await load();
  }

  @override
  Future<void> close() async {
    await _expenseSub?.cancel();
    await _incomeSub?.cancel();
    return super.close();
  }
}
