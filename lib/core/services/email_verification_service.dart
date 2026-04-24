import 'dart:async';
import 'dart:developer' as dev;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage sending and throttling of email verification links
class EmailVerificationService {
  EmailVerificationService._internal();
  static final EmailVerificationService instance =
      EmailVerificationService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Minimum duration between verification email sends
  /// Increase in production to reduce spam further if needed
  static const Duration resendCooldown = Duration(seconds: 60);

  String _keyLastSent(String uid) => 'email_verify_last_sent_$uid';
  String _keyWindowStart(String uid) => 'email_verify_window_start_$uid';
  String _keyWindowCount(String uid) => 'email_verify_window_count_$uid';

  /// Sliding window for per-hour send limits
  static const Duration windowDuration = Duration(hours: 1);
  static const int windowMaxSends = 5;

  /// Returns the DateTime at which the user can resend again
  Future<DateTime?> getNextAllowedSendTime(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSentMillis = prefs.getInt(_keyLastSent(uid));
    if (lastSentMillis == null) return null;
    final lastSent = DateTime.fromMillisecondsSinceEpoch(lastSentMillis);
    final next = lastSent.add(resendCooldown);
    return next.isAfter(DateTime.now()) ? next : null;
  }

  /// Returns number of sends in the current window and the window start time
  Future<(int count, DateTime windowStart)> _getWindowInfo(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final startMillis = prefs.getInt(_keyWindowStart(uid));
    final count = prefs.getInt(_keyWindowCount(uid)) ?? 0;
    final now = DateTime.now();
    final start = startMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(startMillis)
        : now;
    // Reset window if expired
    if (now.difference(start) >= windowDuration) {
      await prefs.setInt(_keyWindowStart(uid), now.millisecondsSinceEpoch);
      await prefs.setInt(_keyWindowCount(uid), 0);
      return (0, now);
    }
    return (count, start);
  }

  /// Attempts to send a verification email with throttling and per-hour limits
  /// Returns the DateTime when the next send is allowed if throttled
  Future<DateTime?> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user');
    }

    final uid = user.uid;
    final prefs = await SharedPreferences.getInstance();

    // Cooldown check
    final nextAllowed = await getNextAllowedSendTime(uid);
    if (nextAllowed != null) {
      dev.log('Verification email throttled until $nextAllowed');
      return nextAllowed;
    }

    // Window check
    final (count, windowStart) = await _getWindowInfo(uid);
    if (count >= windowMaxSends) {
      final resetAt = windowStart.add(windowDuration);
      dev.log('Verification email hourly limit reached. Resets at $resetAt');
      return resetAt;
    }

    try {
      await user.sendEmailVerification();

      // Record send
      await prefs.setInt(
          _keyLastSent(uid), DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt(_keyWindowCount(uid), count + 1);
      if (count == 0) {
        await prefs.setInt(
            _keyWindowStart(uid), windowStart.millisecondsSinceEpoch);
      }
      return null; // Sent successfully, no throttle info
    } catch (e, st) {
      dev.log('Failed to send verification email: $e', stackTrace: st);
      rethrow;
    }
  }
}

