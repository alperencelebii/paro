enum TransactionDeleteStatus {
  initial,
  confirmingDelete,
  deleting,
  deleted,
  error,
  restarting
}

/// Transaction deletion progress stages
enum DeletionStage {
  initializing,
  deletingLocalExpenses,
  deletingLocalIncomes,
  connectingToCloud,
  deletingCloudExpenses,
  deletingCloudIncomes,
  finalizing,
  complete
}

/// State for transaction deletion
class TransactionDeleteState {
  /// Current status of transaction deletion
  final TransactionDeleteStatus status;

  /// Current stage of deletion process
  final DeletionStage stage;

  /// Detailed progress message
  final String progressMessage;

  /// Error message if deletion failed
  final String? errorMessage;

  /// Deletion progress percentage (0-100)
  final int progressPercentage;

  /// Whether local transactions have been deleted
  final bool localDeleted;

  /// Whether cloud transactions have been deleted
  final bool cloudDeleted;

  /// Constructor
  const TransactionDeleteState({
    this.status = TransactionDeleteStatus.initial,
    this.stage = DeletionStage.initializing,
    this.progressMessage = 'Initializing...',
    this.errorMessage,
    this.progressPercentage = 0,
    this.localDeleted = false,
    this.cloudDeleted = false,
  });

  /// Create a copy of this state with the given values replaced
  TransactionDeleteState copyWith({
    TransactionDeleteStatus? status,
    DeletionStage? stage,
    String? progressMessage,
    String? errorMessage,
    int? progressPercentage,
    bool? localDeleted,
    bool? cloudDeleted,
  }) {
    return TransactionDeleteState(
      status: status ?? this.status,
      stage: stage ?? this.stage,
      progressMessage: progressMessage ?? this.progressMessage,
      errorMessage: errorMessage,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      localDeleted: localDeleted ?? this.localDeleted,
      cloudDeleted: cloudDeleted ?? this.cloudDeleted,
    );
  }

  /// Factory method to create a state for confirmation dialog
  factory TransactionDeleteState.confirming() {
    return const TransactionDeleteState(
      status: TransactionDeleteStatus.confirmingDelete,
    );
  }

  /// Factory method to create a state for deletion in progress
  factory TransactionDeleteState.deleting() {
    return const TransactionDeleteState(
      status: TransactionDeleteStatus.deleting,
      progressMessage: 'Starting deletion process...',
    );
  }

  /// Factory method to create a state for successful deletion
  factory TransactionDeleteState.deleted() {
    return const TransactionDeleteState(
      status: TransactionDeleteStatus.deleted,
      stage: DeletionStage.complete,
      progressMessage: 'All transactions deleted successfully',
      progressPercentage: 100,
      localDeleted: true,
      cloudDeleted: true,
    );
  }

  /// Factory method to create a state for error
  factory TransactionDeleteState.error(String message) {
    return TransactionDeleteState(
      status: TransactionDeleteStatus.error,
      errorMessage: message,
    );
  }

  /// Factory method to create a state for app restarting
  factory TransactionDeleteState.restarting() {
    return const TransactionDeleteState(
      status: TransactionDeleteStatus.restarting,
      stage: DeletionStage.complete,
      progressMessage: 'Restarting application...',
      progressPercentage: 100,
      localDeleted: true,
      cloudDeleted: true,
    );
  }
}
