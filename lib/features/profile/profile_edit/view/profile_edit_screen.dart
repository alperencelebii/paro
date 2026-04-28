import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finance_track/core/app_bloc/app_bloc.dart';
import 'package:finance_track/features/profile/profile_edit/bloc/profile_edit_bloc.dart';
import 'package:finance_track/features/profile/widgets/name_change_form.dart';
import 'package:finance_track/features/profile/widgets/password_change_form.dart';
import 'package:user_repository/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:finance_track/core/localization/localization.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isPasswordTabVisible = false;

  @override
  void initState() {
    super.initState();
    // Check if user is using password authentication or social login
    _checkAuthMethod();
  }

  Future<void> _checkAuthMethod() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Check if the user has password provider
      final hasPasswordProvider =
          user.providerData.any((info) => info.providerId == 'password');

      setState(() {
        _isPasswordTabVisible = hasPasswordProvider;
        // Initialize tab controller based on available tabs
        _tabController =
            TabController(length: _isPasswordTabVisible ? 2 : 1, vsync: this);
      });
    } else {
      setState(() {
        _isPasswordTabVisible = false;
        _tabController = TabController(length: 1, vsync: this);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileEditBloc(
        userRepository: context.read<UserRepository>(),
      ),
      child: BlocListener<ProfileEditBloc, ProfileEditState>(
        listener: (context, state) {
          // Success notification
          if (state.status == ProfileEditStatus.success &&
              (_tabController.index == 1)) {
            // Password tab
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: LocalizedText('Password updated successfully'),
                backgroundColor: Colors.green,
              ),
            );

            // Return to profile screen for password updates
            Navigator.of(context).pop();
          }
          // Handle general failures at the parent level
          if (state.status == ProfileEditStatus.failure &&
              !state.errorMessage.contains('PigeonUserInfo')) {
            // PigeonUserInfo errors are handled by the name form
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: LocalizedText(state.errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: AppLocalizations.tr('Dismiss'),
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const LocalizedText('Edit Profile'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            bottom: _isPasswordTabVisible
                ? TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    tabs: const [
                      Tab(child: LocalizedText('Name')),
                      Tab(child: LocalizedText('Password')),
                    ],
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicatorWeight: 3,
                  )
                : null,
          ),
          body: _isPasswordTabVisible
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNameTab(),
                    _buildPasswordTab(),
                  ],
                )
              : _buildNameTab(),
        ),
      ),
    );
  }

  Widget _buildNameTab() {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, appState) {
        if (appState.status == AppStatus.authenticated) {
          return Column(
            children: [
              NameChangeForm(initialName: appState.user.name ?? ''),
              if (!_isPasswordTabVisible) ...[
                const SizedBox(height: 20),
                _buildSocialLoginMessage(),
              ]
            ],
          );
        } else {
          return const Center(
            child: LocalizedText('Please login to change your name'),
          );
        }
      },
    );
  }

  Widget _buildSocialLoginMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              LocalizedText('Social Account Sign In',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const LocalizedText('You\'re signed in with a social account. Password changes are managed through your social account provider.',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordTab() {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, appState) {
        if (appState.status == AppStatus.authenticated) {
          return const SingleChildScrollView(child: PasswordChangeForm());
        } else {
          return const Center(
            child: LocalizedText('Please login to change your password'),
          );
        }
      },
    );
  }
}
