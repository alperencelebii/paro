import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
part 'send_message_state.dart';

/// Cubit to manage Send Message screen state and actions
class SendMessageCubit extends Cubit<SendMessageState> {
  Timer? _successTimer;

  /// Creates a new instance of [SendMessageCubit]
  SendMessageCubit() : super(SendMessageState.initial());

  @override
  Future<void> close() {
    state.messageController.dispose();
    state.subjectController.dispose();
    _successTimer?.cancel();
    return super.close();
  }

  /// Validates and submits the support form
  Future<void> submitForm() async {
    if (state.formKey.currentState!.validate()) {
      emit(state.copyWith(
          isSending: true, errorMessage: null, clearErrorMessage: true));

      try {
        // Format message with proper greeting and signature
        final formattedMessage = 'Dear Support Team,\n\n'
            '${state.messageController.text}\n\n'
            'Thank you for your assistance.\n\n'
            'Best regards,\n'
            'Expense App User';

        // Launch email with form data
        final String subject = Uri.encodeComponent(
            'Support Request: ${state.subjectController.text}');
        final String body = Uri.encodeComponent(formattedMessage);

        final String emailUrl =
            'mailto:oveshdevwala@gmail.com?subject=$subject&body=$body';
        final Uri emailUri = Uri.parse(emailUrl);

        final bool launched = await launchUrl(
          emailUri,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          emit(state.copyWith(isSending: false, isSuccess: true));
          state.messageController.clear();
          state.subjectController.clear();

          _successTimer?.cancel();
          _successTimer = Timer(const Duration(seconds: 3), () {
            emit(state.copyWith(isSuccess: false));
          });
        } else {
          throw Exception('Could not launch email client');
        }
      } catch (e) {
        emit(state.copyWith(
          isSending: false,
          errorMessage:
              'Failed to open email client. Please try again or contact us directly at oveshdevwala@gmail.com',
        ));
      }
    }
  }
}














