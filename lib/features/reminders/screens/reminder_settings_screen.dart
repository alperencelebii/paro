
import 'package:finance_track/core/colors/app_colors.dart';
import 'package:finance_track/core/localization/localization.dart';
import 'package:finance_track/features/reminders/services/reminder_settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  final ReminderSettingsService _service = ReminderSettingsService();
  ReminderSettings? _settings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _service.getSettings();
    if (mounted) {
      setState(() => _settings = settings);
    }
  }

  Future<void> _save(ReminderSettings settings) async {
    await _service.saveSettings(settings);
    if (mounted) {
      setState(() => _settings = settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;

    return Scaffold(
      appBar: AppBar(
        title: const LocalizedText('Akıllı Hatırlatıcılar'),
      ),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16.r),
              children: [
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_active_rounded,
                          color: Colors.white,
                          size: 28.r,
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LocalizedText(
                              'PARO seni takipte tutar',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            SizedBox(height: 6.h),
                            LocalizedText(
                              'Bütçe, abonelik ve günlük kontrol hatırlatıcılarını yönet.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.86),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                _ReminderSwitchTile(
                  icon: Icons.today_rounded,
                  title: 'Günlük kontrol',
                  subtitle: 'Her gün gelir/gider girişi için hatırlat.',
                  value: settings.dailyCheckInEnabled,
                  onChanged: (value) => _save(
                    settings.copyWith(dailyCheckInEnabled: value),
                  ),
                ),
                _ReminderSwitchTile(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Bütçe uyarıları',
                  subtitle: 'Kategori veya toplam bütçe %80 seviyesine yaklaşınca uyar.',
                  value: settings.budgetWarningEnabled,
                  onChanged: (value) => _save(
                    settings.copyWith(budgetWarningEnabled: value),
                  ),
                ),
                _ReminderSwitchTile(
                  icon: Icons.subscriptions_rounded,
                  title: 'Abonelik hatırlatıcıları',
                  subtitle: 'Yaklaşan tekrar eden ödemeleri önceden göster.',
                  value: settings.subscriptionReminderEnabled,
                  onChanged: (value) => _save(
                    settings.copyWith(subscriptionReminderEnabled: value),
                  ),
                ),
                _ReminderSwitchTile(
                  icon: Icons.spa_rounded,
                  title: 'Rahat ton',
                  subtitle: 'Uyarıları yargılamayan, sakin ve destekleyici dille göster.',
                  value: settings.calmToneEnabled,
                  onChanged: (value) => _save(
                    settings.copyWith(calmToneEnabled: value),
                  ),
                ),
                _ReminderSwitchTile(
                  icon: Icons.celebration_rounded,
                  title: 'Pozitif ilerleme',
                  subtitle: 'Daha az harcadığında veya düzenli kayıt yaptığında motive edici bildirim göster.',
                  value: settings.positiveProgressEnabled,
                  onChanged: (value) => _save(
                    settings.copyWith(positiveProgressEnabled: value),
                  ),
                ),
                _NotificationLimitTile(
                  value: settings.maxDailyNotifications,
                  onChanged: (value) => _save(
                    settings.copyWith(maxDailyNotifications: value),
                  ),
                ),
                SizedBox(height: 8.h),
                _TimeTile(
                  hour: settings.dailyHour,
                  minute: settings.dailyMinute,
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: settings.dailyHour,
                        minute: settings.dailyMinute,
                      ),
                    );
                    if (picked != null) {
                      await _save(
                        settings.copyWith(
                          dailyHour: picked.hour,
                          dailyMinute: picked.minute,
                        ),
                      );
                    }
                  },
                ),
                SizedBox(height: 14.h),
                Text(
                  'PARO bildirim mantığı: az, faydalı ve sakin. Gereksiz tekrar yok; önemli durumlar ve pozitif ilerleme öne çıkar.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.56),
                      ),
                ),
              ],
            ),
    );
  }
}

class _ReminderSwitchTile extends StatelessWidget {
  const _ReminderSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        secondary: Container(
          width: 44.r,
          height: 44.r,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: LocalizedText(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: LocalizedText(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
          ),
        ),
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.hour,
    required this.minute,
    required this.onTap,
  });

  final int hour;
  final int minute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay(hour: hour, minute: minute).format(context);
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: const Icon(
                Icons.schedule_rounded,
                color: AppColors.accent,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    'Günlük saat',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    time,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.40),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationLimitTile extends StatelessWidget {
  const _NotificationLimitTile({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: AppColors.warning,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedText(
                  'Günlük bildirim sınırı',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Günde en fazla $value nazik hatırlatma',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          DropdownButton<int>(
            value: value,
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(14.r),
            items: const [1, 2, 3]
                .map((item) => DropdownMenuItem<int>(
                      value: item,
                      child: Text('$item'),
                    ))
                .toList(),
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ],
      ),
    );
  }
}
