import 'package:finance_track/core/localization/localization.dart';
import 'package:intl/intl.dart';

String formatTransactionDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = DateTime(now.year, now.month, now.day - 1);

  final transactionDate = DateTime(date.year, date.month, date.day);

  if (transactionDate == today) {
    return AppLocalizations.tr('Today');
  } else if (transactionDate == yesterday) {
    return AppLocalizations.tr('Yesterday');
  } else if (AppLocalizations.currentLanguageCode == 'tr') {
    const weekdays = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  } else {
    return '${DateFormat('EEEE').format(date)}, ${DateFormat('MMMM').format(date)} ${date.day}';
  }
}
