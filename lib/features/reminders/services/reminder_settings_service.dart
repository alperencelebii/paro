
import 'package:shared_preferences/shared_preferences.dart';

class ReminderSettings {
  const ReminderSettings({
    required this.dailyCheckInEnabled,
    required this.budgetWarningEnabled,
    required this.subscriptionReminderEnabled,
    required this.dailyHour,
    required this.dailyMinute,
  });

  final bool dailyCheckInEnabled;
  final bool budgetWarningEnabled;
  final bool subscriptionReminderEnabled;
  final int dailyHour;
  final int dailyMinute;

  ReminderSettings copyWith({
    bool? dailyCheckInEnabled,
    bool? budgetWarningEnabled,
    bool? subscriptionReminderEnabled,
    int? dailyHour,
    int? dailyMinute,
  }) {
    return ReminderSettings(
      dailyCheckInEnabled: dailyCheckInEnabled ?? this.dailyCheckInEnabled,
      budgetWarningEnabled: budgetWarningEnabled ?? this.budgetWarningEnabled,
      subscriptionReminderEnabled:
          subscriptionReminderEnabled ?? this.subscriptionReminderEnabled,
      dailyHour: dailyHour ?? this.dailyHour,
      dailyMinute: dailyMinute ?? this.dailyMinute,
    );
  }
}

class ReminderSettingsService {
  static const String _dailyKey = 'paro_reminder_daily_enabled';
  static const String _budgetKey = 'paro_reminder_budget_enabled';
  static const String _subscriptionKey = 'paro_reminder_subscription_enabled';
  static const String _hourKey = 'paro_reminder_daily_hour';
  static const String _minuteKey = 'paro_reminder_daily_minute';

  Future<ReminderSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return ReminderSettings(
      dailyCheckInEnabled: prefs.getBool(_dailyKey) ?? true,
      budgetWarningEnabled: prefs.getBool(_budgetKey) ?? true,
      subscriptionReminderEnabled: prefs.getBool(_subscriptionKey) ?? true,
      dailyHour: prefs.getInt(_hourKey) ?? 20,
      dailyMinute: prefs.getInt(_minuteKey) ?? 0,
    );
  }

  Future<void> saveSettings(ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyKey, settings.dailyCheckInEnabled);
    await prefs.setBool(_budgetKey, settings.budgetWarningEnabled);
    await prefs.setBool(_subscriptionKey, settings.subscriptionReminderEnabled);
    await prefs.setInt(_hourKey, settings.dailyHour);
    await prefs.setInt(_minuteKey, settings.dailyMinute);
  }
}
