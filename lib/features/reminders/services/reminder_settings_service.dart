import 'package:shared_preferences/shared_preferences.dart';

class ReminderSettings {
  const ReminderSettings({
    required this.dailyCheckInEnabled,
    required this.budgetWarningEnabled,
    required this.subscriptionReminderEnabled,
    required this.dailyHour,
    required this.dailyMinute,
    required this.calmToneEnabled,
    required this.positiveProgressEnabled,
    required this.maxDailyNotifications,
  });

  final bool dailyCheckInEnabled;
  final bool budgetWarningEnabled;
  final bool subscriptionReminderEnabled;
  final int dailyHour;
  final int dailyMinute;
  final bool calmToneEnabled;
  final bool positiveProgressEnabled;
  final int maxDailyNotifications;

  ReminderSettings copyWith({
    bool? dailyCheckInEnabled,
    bool? budgetWarningEnabled,
    bool? subscriptionReminderEnabled,
    int? dailyHour,
    int? dailyMinute,
    bool? calmToneEnabled,
    bool? positiveProgressEnabled,
    int? maxDailyNotifications,
  }) {
    return ReminderSettings(
      dailyCheckInEnabled: dailyCheckInEnabled ?? this.dailyCheckInEnabled,
      budgetWarningEnabled: budgetWarningEnabled ?? this.budgetWarningEnabled,
      subscriptionReminderEnabled:
          subscriptionReminderEnabled ?? this.subscriptionReminderEnabled,
      dailyHour: dailyHour ?? this.dailyHour,
      dailyMinute: dailyMinute ?? this.dailyMinute,
      calmToneEnabled: calmToneEnabled ?? this.calmToneEnabled,
      positiveProgressEnabled:
          positiveProgressEnabled ?? this.positiveProgressEnabled,
      maxDailyNotifications:
          maxDailyNotifications ?? this.maxDailyNotifications,
    );
  }
}

class ReminderSettingsService {
  static const String _dailyKey = 'paro_reminder_daily_enabled';
  static const String _budgetKey = 'paro_reminder_budget_enabled';
  static const String _subscriptionKey = 'paro_reminder_subscription_enabled';
  static const String _hourKey = 'paro_reminder_daily_hour';
  static const String _minuteKey = 'paro_reminder_daily_minute';
  static const String _calmToneKey = 'paro_reminder_calm_tone_enabled';
  static const String _positiveProgressKey = 'paro_reminder_positive_progress';
  static const String _maxDailyKey = 'paro_reminder_max_daily_count';

  Future<ReminderSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return ReminderSettings(
      dailyCheckInEnabled: prefs.getBool(_dailyKey) ?? true,
      budgetWarningEnabled: prefs.getBool(_budgetKey) ?? true,
      subscriptionReminderEnabled: prefs.getBool(_subscriptionKey) ?? true,
      dailyHour: prefs.getInt(_hourKey) ?? 20,
      dailyMinute: prefs.getInt(_minuteKey) ?? 0,
      calmToneEnabled: prefs.getBool(_calmToneKey) ?? true,
      positiveProgressEnabled: prefs.getBool(_positiveProgressKey) ?? true,
      maxDailyNotifications: prefs.getInt(_maxDailyKey) ?? 2,
    );
  }

  Future<void> saveSettings(ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyKey, settings.dailyCheckInEnabled);
    await prefs.setBool(_budgetKey, settings.budgetWarningEnabled);
    await prefs.setBool(_subscriptionKey, settings.subscriptionReminderEnabled);
    await prefs.setInt(_hourKey, settings.dailyHour);
    await prefs.setInt(_minuteKey, settings.dailyMinute);
    await prefs.setBool(_calmToneKey, settings.calmToneEnabled);
    await prefs.setBool(_positiveProgressKey, settings.positiveProgressEnabled);
    await prefs.setInt(_maxDailyKey, settings.maxDailyNotifications);
  }
}
