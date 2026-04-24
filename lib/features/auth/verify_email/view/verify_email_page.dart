import 'dart:async';

import 'package:finance_track/core/router/app_router.dart';
import 'package:finance_track/core/services/email_verification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finance_track/core/app_bloc/app_bloc.dart';
import 'package:finance_track/core/services/auth_service.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  Timer? _pollTimer;
  Timer? _countdownTimer;
  Duration? _timeUntilResend;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _initCooldown();
    _startPolling();
  }

  Future<void> _initCooldown() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final next = await EmailVerificationService.instance
        .getNextAllowedSendTime(user.uid);
    if (!mounted) return;
    if (next != null) {
      _startCountdown(next);
    }
  }

  void _startCountdown(DateTime until) {
    _countdownTimer?.cancel();
    setState(() {
      _timeUntilResend = until.difference(DateTime.now());
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = until.difference(DateTime.now());
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (remaining.isNegative) {
        setState(() {
          _timeUntilResend = null;
        });
        timer.cancel();
      } else {
        setState(() {
          _timeUntilResend = remaining;
        });
      }
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await user.reload();
      final refreshed = FirebaseAuth.instance.currentUser;
      if (refreshed != null && refreshed.emailVerified && mounted) {
        // Persist verification state and latest profile data into Firestore
        try {
          await AuthService.instance.syncUserProfile(markVerified: true);
        } catch (_) {}
        context.go(AppPaths.home);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    setState(() {
      _sending = true;
    });
    try {
      final next =
          await EmailVerificationService.instance.sendVerificationEmail();
      if (!mounted) return;
      if (next != null) {
        _startCountdown(next);
        _showSnack('Please wait before requesting another email.');
      } else {
        final user = FirebaseAuth.instance.currentUser;
        _showSnack('Verification link sent to ${user?.email ?? 'your email'}');
        final uid = user?.uid;
        if (uid != null) {
          final nextAllowed = await EmailVerificationService.instance
              .getNextAllowedSendTime(uid);
          if (nextAllowed != null) {
            _startCountdown(nextAllowed);
          }
        }
      }
    } catch (e) {
      _showSnack('Failed to send verification email');
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _checkNow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await user.reload();
    final refreshed = FirebaseAuth.instance.currentUser;
    if (refreshed != null && refreshed.emailVerified && mounted) {
      try {
        await AuthService.instance.syncUserProfile(markVerified: true);
      } catch (_) {}
      context.go(AppPaths.home);
    } else {
      _showSnack('Not verified yet. Check your inbox or spam folder.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Verify your email'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          actions: [
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout_rounded),
              onPressed: () {
                context.read<AppBloc>().add(const AppLogoutRequested());
              },
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 12.h),
              Text(
                'We sent a verification link to:',
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: 6.h),
              Text(
                email,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Please check your inbox and click the link to verify your account. You can reopen the app after verifying.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.black.withValues(alpha: 0.7),
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed:
                      _sending || _timeUntilResend != null ? null : _resend,
                  child: _sending
                      ? SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _timeUntilResend == null
                              ? 'Resend verification email'
                              : 'Resend in ${_formatDuration(_timeUntilResend!)}',
                        ),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: OutlinedButton(
                  onPressed: _checkNow,
                  child: const Text('I have verified, continue'),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Tips:',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8.h),
              _tip('Check Spam or Promotions folder.'),
              _tip('Add our email to your contacts and request again.'),
              _tip('Open the link on the same device if possible.'),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final total = d.inSeconds;
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _tip(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
          SizedBox(width: 8.w),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
