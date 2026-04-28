import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
part 'help_support_state.dart';
/// Cubit to manage Help & Support screen state and actions
class HelpSupportCubit extends Cubit<HelpSupportState> {
  Timer? _successTimer;

  /// Creates a new instance of [HelpSupportCubit]
  HelpSupportCubit() : super(HelpSupportState.initial());

  @override
  Future<void> close() {
    state.messageController.dispose();
    state.subjectController.dispose();
    _successTimer?.cancel();
    return super.close();
  }

  /// Sets the subject in the form
  void setSubject(String subject) {
    state.subjectController.text = subject;
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
            'mailto:alperencelebiq@gmail.com?subject=$subject&body=$body';
        final Uri emailUri = Uri.parse(emailUrl);

        final bool launched = await launchUrl(emailUri);

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

  /// Launches email client for support
  Future<void> launchEmail() async {
    final String subject = Uri.encodeComponent('Support Request: Expense App');
    final String body = Uri.encodeComponent('Dear Support Team,\n\n'
        'I am contacting you regarding the following issue with the Expense App:\n\n'
        '[Please describe your issue or question in detail]\n\n'
        'App version: [If known]\n'
        'Device model: [Your device]\n'
        'Operating system: [Your OS]\n\n'
        'Steps to reproduce (if applicable):\n'
        '1. \n'
        '2. \n'
        '3. \n\n'
        'Thank you for your assistance.\n\n'
        'Best regards,\n'
        '[Your name]');

    final String emailUrl =
        'mailto:oveshdevwala@gmail.com?subject=$subject&body=$body';
    await _launchUrlHelper(emailUrl);
  }

  /// Launches email client for feature requests
  Future<void> launchFeatureRequestEmail() async {
    final String subject = Uri.encodeComponent('Feature Request: Expense App');
    final String body = Uri.encodeComponent('Dear Expense App Team,\n\n'
        'I would like to suggest the following feature for the Expense App:\n\n'
        '[Please describe your feature idea here in detail]\n\n'
        'This feature would be beneficial because:\n\n'
        '[Please explain the benefits or use cases]\n\n'
        'I believe this would enhance the user experience by:\n\n'
        '[Additional context on how this improves the app]\n\n'
        'Thank you for considering my suggestion.\n\n'
        'Best regards,\n'
        '[Your name]');

    final String emailUrl =
        'mailto:oveshdevwala@gmail.com?subject=$subject&body=$body';
    await _launchUrlHelper(emailUrl);
  }

  /// Launches email client for collaboration inquiries
  Future<void> launchCollaborationEmail() async {
    final String subject =
        Uri.encodeComponent('Collaboration Interest: Expense App');
    final String body = Uri.encodeComponent('Dear Expense App Team,\n\n'
        'I am interested in collaborating on the Expense App project and would like to contribute to its development.\n\n'
        'My skills and experience:\n'
        '[Please describe your skills, experience, and relevant background]\n\n'
        'How I would like to contribute:\n'
        '[Please describe specific ways you would like to contribute - UI/UX, backend, features, etc.]\n\n'
        'My availability and commitment level:\n'
        '[Please indicate your time availability and level of commitment]\n\n'
        'I am excited about the possibility of working with your team and contributing to this project.\n\n'
        'Thank you for your consideration.\n\n'
        'Best regards,\n'
        '[Your name]\n'
        '[Optional: Portfolio/GitHub/LinkedIn]');

    final String emailUrl =
        'mailto:alperencelebiq@gmail.com?subject=$subject&body=$body';
    await _launchUrlHelper(emailUrl);
  }

  /// Launches email client for beta testing applications
  Future<void> launchBetaTestingEmail() async {
    final String subject =
        Uri.encodeComponent('Beta Testing Application: Expense App');
    final String body = Uri.encodeComponent('Dear Expense App Team,\n\n'
        'I would like to apply for the Beta Testing Program for the Expense App.\n\n'
        'My experience with expense tracking apps:\n'
        '[Please describe your experience with expense tracking or similar apps]\n\n'
        'Devices I can test on:\n'
        '[Please list your devices, OS versions, etc.]\n\n'
        'What I can contribute as a beta tester:\n'
        '[Please describe how you can help - bug reporting, usability feedback, feature testing, etc.]\n\n'
        'How much time I can dedicate to testing:\n'
        '[Please indicate how much time you can spend on testing weekly]\n\n'
        'I am excited about the opportunity to help improve the Expense App through beta testing.\n\n'
        'Thank you for your consideration.\n\n'
        'Best regards,\n'
        '[Your name]\n'
        '[Optional: Relevant experience or background]');

    final String emailUrl =
        'mailto:alperencelebiq@gmail.com?subject=$subject&body=$body';
    await _launchUrlHelper(emailUrl);
  }

  Future<void> _launchUrlHelper(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      await launchUrl(uri);
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Could not launch email client. Please try again later.',
      ));
    }
  }
}
