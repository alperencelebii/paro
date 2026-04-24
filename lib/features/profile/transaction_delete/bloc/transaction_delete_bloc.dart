import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finance_track/core/services/transaction_service.dart';
import 'package:finance_track/data/repositories/objectbox_expense_repository.dart';
import 'package:finance_track/data/repositories/objectbox_income_repository.dart';
import 'package:flutter/material.dart';

import 'transaction_delete_event.dart';
import 'transaction_delete_state.dart';

/// BLoC for managing transaction deletion process
class TransactionDeleteBloc
    extends Bloc<TransactionDeleteEvent, TransactionDeleteState> {
  final TransactionService _transactionService;
  final ObjectBoxExpenseRepository _expenseRepository;
  final ObjectBoxIncomeRepository _incomeRepository;
  final BuildContext _context;

  /// Constructor
  TransactionDeleteBloc({
    required TransactionService transactionService,
    required ObjectBoxExpenseRepository expenseRepository,
    required ObjectBoxIncomeRepository incomeRepository,
    required BuildContext context,
  })  : _transactionService = transactionService,
        _expenseRepository = expenseRepository,
        _incomeRepository = incomeRepository,
        _context = context,
        super(const TransactionDeleteState()) {
    on<ShowDeleteConfirmation>(_onShowDeleteConfirmation);
    on<CancelDeletion>(_onCancelDeletion);
    on<ConfirmDeletion>(_onConfirmDeletion);
    on<UpdateDeletionProgress>(_onUpdateDeletionProgress);
    on<DeletionCompleted>(_onDeletionCompleted);
    on<DeletionFailed>(_onDeletionFailed);
    on<RestartApp>(_onRestartApp);
    on<AcknowledgeError>(_onAcknowledgeError);
    on<ContinueWithoutRestart>(_onContinueWithoutRestart);
  }

  /// Handle the ShowDeleteConfirmation event
  FutureOr<void> _onShowDeleteConfirmation(
    ShowDeleteConfirmation event,
    Emitter<TransactionDeleteState> emit,
  ) {
    emit(TransactionDeleteState.confirming());
  }

  /// Handle the CancelDeletion event
  FutureOr<void> _onCancelDeletion(
    CancelDeletion event,
    Emitter<TransactionDeleteState> emit,
  ) {
    emit(const TransactionDeleteState());
  }

  /// Handle the ConfirmDeletion event
  FutureOr<void> _onConfirmDeletion(
    ConfirmDeletion event,
    Emitter<TransactionDeleteState> emit,
  ) async {
    // Change state to deleting
    emit(TransactionDeleteState.deleting());

    try {
      await _transactionService.deleteAllTransactionsEverywhere(
        _context,
        expenseRepository: _expenseRepository,
        incomeRepository: _incomeRepository,
        updateProgress: (progress) {
          // Update progress via event
          add(UpdateDeletionProgress(
            message: progress,
            progressPercentage: _calculateProgressPercentage(progress),
          ));
        },
      );

      // Deletion completed successfully
      add(const DeletionCompleted());
    } catch (e) {
      dev.log('Error deleting transactions: $e');

      // Make sure operation isn't stuck
      _transactionService.resetOperationFlag();

      // Emit failure
      add(DeletionFailed(e.toString()));
    }
  }

  /// Handle the UpdateDeletionProgress event
  FutureOr<void> _onUpdateDeletionProgress(
    UpdateDeletionProgress event,
    Emitter<TransactionDeleteState> emit,
  ) {
    // Update the state with the new progress message and percentage
    final stage = _determineDeletionStage(event.message);

    emit(state.copyWith(
      progressMessage: event.message,
      progressPercentage: event.progressPercentage > 0
          ? event.progressPercentage
          : _getProgressPercentageForStage(stage),
      stage: stage,
      localDeleted: _isLocalDeleted(stage),
      cloudDeleted: _isCloudDeleted(stage),
    ));
  }

  /// Handle the DeletionCompleted event
  FutureOr<void> _onDeletionCompleted(
    DeletionCompleted event,
    Emitter<TransactionDeleteState> emit,
  ) {
    emit(TransactionDeleteState.deleted());
  }

  /// Handle the DeletionFailed event
  FutureOr<void> _onDeletionFailed(
    DeletionFailed event,
    Emitter<TransactionDeleteState> emit,
  ) {
    final errorMessage = event.errorMessage.split(':').first.trim();
    emit(TransactionDeleteState.error(errorMessage));
  }

  /// Handle the RestartApp event
  FutureOr<void> _onRestartApp(
    RestartApp event,
    Emitter<TransactionDeleteState> emit,
  ) {
    emit(TransactionDeleteState.restarting());
  }

  /// Handle the AcknowledgeError event
  FutureOr<void> _onAcknowledgeError(
    AcknowledgeError event,
    Emitter<TransactionDeleteState> emit,
  ) {
    emit(const TransactionDeleteState());
  }

  /// Handle the ContinueWithoutRestart event
  FutureOr<void> _onContinueWithoutRestart(
    ContinueWithoutRestart event,
    Emitter<TransactionDeleteState> emit,
  ) {
    emit(const TransactionDeleteState());
  }

  /// Calculate progress percentage based on the stage
  int _calculateProgressPercentage(String progressMessage) {
    final stage = _determineDeletionStage(progressMessage);
    return _getProgressPercentageForStage(stage);
  }

  /// Determine the current deletion stage from the progress message
  DeletionStage _determineDeletionStage(String progressMessage) {
    final lowerMessage = progressMessage.toLowerCase();

    if (lowerMessage.contains('initializing')) {
      return DeletionStage.initializing;
    } else if (lowerMessage.contains('local expense')) {
      return DeletionStage.deletingLocalExpenses;
    } else if (lowerMessage.contains('local income')) {
      return DeletionStage.deletingLocalIncomes;
    } else if (lowerMessage.contains('connect')) {
      return DeletionStage.connectingToCloud;
    } else if (lowerMessage.contains('cloud expense')) {
      return DeletionStage.deletingCloudExpenses;
    } else if (lowerMessage.contains('cloud income')) {
      return DeletionStage.deletingCloudIncomes;
    } else if (lowerMessage.contains('finaliz')) {
      return DeletionStage.finalizing;
    } else if (lowerMessage.contains('success') ||
        lowerMessage.contains('complet') ||
        lowerMessage.contains('delet')) {
      return DeletionStage.complete;
    }

    return DeletionStage.initializing;
  }

  /// Get progress percentage based on the stage
  int _getProgressPercentageForStage(DeletionStage stage) {
    switch (stage) {
      case DeletionStage.initializing:
        return 5;
      case DeletionStage.deletingLocalExpenses:
        return 20;
      case DeletionStage.deletingLocalIncomes:
        return 35;
      case DeletionStage.connectingToCloud:
        return 50;
      case DeletionStage.deletingCloudExpenses:
        return 65;
      case DeletionStage.deletingCloudIncomes:
        return 80;
      case DeletionStage.finalizing:
        return 95;
      case DeletionStage.complete:
        return 100;
    }
  }

  /// Check if local data is deleted based on stage
  bool _isLocalDeleted(DeletionStage stage) {
    return stage.index >= DeletionStage.connectingToCloud.index;
  }

  /// Check if cloud data is deleted based on stage
  bool _isCloudDeleted(DeletionStage stage) {
    return stage == DeletionStage.finalizing || stage == DeletionStage.complete;
  }
}
