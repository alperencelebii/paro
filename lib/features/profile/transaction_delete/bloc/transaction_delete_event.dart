import 'package:equatable/equatable.dart';

/// Base event class for transaction deletion
abstract class TransactionDeleteEvent extends Equatable {
  const TransactionDeleteEvent();

  @override
  List<Object> get props => [];
}

/// Event to request showing the delete confirmation dialog
class ShowDeleteConfirmation extends TransactionDeleteEvent {
  const ShowDeleteConfirmation();
}

/// Event to cancel deletion
class CancelDeletion extends TransactionDeleteEvent {
  const CancelDeletion();
}

/// Event to confirm and start transaction deletion
class ConfirmDeletion extends TransactionDeleteEvent {
  const ConfirmDeletion();
}

/// Event to update the deletion progress
class UpdateDeletionProgress extends TransactionDeleteEvent {
  final String message;
  final int progressPercentage;

  const UpdateDeletionProgress({
    required this.message,
    this.progressPercentage = 0,
  });

  @override
  List<Object> get props => [message, progressPercentage];
}

/// Event when deletion has successfully completed
class DeletionCompleted extends TransactionDeleteEvent {
  const DeletionCompleted();
}

/// Event when deletion fails with an error
class DeletionFailed extends TransactionDeleteEvent {
  final String errorMessage;

  const DeletionFailed(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

/// Event to request app restart after deletion
class RestartApp extends TransactionDeleteEvent {
  const RestartApp();
}

/// Event to acknowledge error and go back to initial state
class AcknowledgeError extends TransactionDeleteEvent {
  const AcknowledgeError();
}

/// Event to continue without restart after deletion
class ContinueWithoutRestart extends TransactionDeleteEvent {
  const ContinueWithoutRestart();
}
