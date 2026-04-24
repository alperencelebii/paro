part of 'connectivity_cubit.dart';

/// Enum representing connectivity status
enum ConnectivityStatus { initial, connected, disconnected, unknown }

/// State class for the connectivity cubit
class ConnectivityState extends Equatable {
  /// The current connectivity status
  final ConnectivityStatus status;

  /// The type of connection (wifi, mobile, etc.)
  final String? connectionType;

  /// Error message in case of failure
  final String? errorMessage;

  /// Constructor
  const ConnectivityState({
    required this.status,
    this.connectionType,
    this.errorMessage,
  });

  /// Initial state
  const ConnectivityState.loading() : this(status: ConnectivityStatus.initial);

  /// Connected state
  const ConnectivityState.connected({required String connectionType})
      : this(
          status: ConnectivityStatus.connected,
          connectionType: connectionType,
        );

  /// Disconnected state
  const ConnectivityState.disconnected()
      : this(status: ConnectivityStatus.disconnected);

  /// Unknown state with error
  const ConnectivityState.unknown({String? errorMessage})
      : this(
          status: ConnectivityStatus.unknown,
          errorMessage: errorMessage,
        );

  @override
  List<Object?> get props => [status, connectionType, errorMessage];
}
