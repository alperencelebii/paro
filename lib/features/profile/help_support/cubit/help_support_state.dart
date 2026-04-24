part of 'help_support_cubit.dart';
/// The state for the HelpSupportBloc
class HelpSupportState {
  final TextEditingController messageController;
  final TextEditingController subjectController;
  final GlobalKey<FormState> formKey;
  final bool isSending;
  final String? errorMessage;
  final bool isSuccess;

  /// Create an instance of [HelpSupportState]
  const HelpSupportState({
    required this.messageController,
    required this.subjectController,
    required this.formKey,
    this.isSending = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  /// Creates an initial state for [HelpSupportBloc]
  factory HelpSupportState.initial() {
    return HelpSupportState(
      messageController: TextEditingController(),
      subjectController: TextEditingController(),
      formKey: GlobalKey<FormState>(),
    );
  }

  /// Creates a copy of the current state with specified fields replaced
  HelpSupportState copyWith({
    TextEditingController? messageController,
    TextEditingController? subjectController,
    GlobalKey<FormState>? formKey,
    bool? isSending,
    String? errorMessage,
    bool? isSuccess,
    bool clearErrorMessage = false,
  }) {
    return HelpSupportState(
      messageController: messageController ?? this.messageController,
      subjectController: subjectController ?? this.subjectController,
      formKey: formKey ?? this.formKey,
      isSending: isSending ?? this.isSending,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}
