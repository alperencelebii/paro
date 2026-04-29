import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  AppLocalizations(this.locale) {
    currentLanguageCode = locale.languageCode;
    Intl.defaultLocale = locale.languageCode;
  }

  final Locale locale;

  static String currentLanguageCode = 'en';

  static const supportedLocales = [
    Locale('en'),
    Locale('tr'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static String tr(String text) {
    if (currentLanguageCode != 'tr') return text;
    return _tr[text] ?? _dynamicTr(text) ?? text;
  }

  String translate(String text) => tr(text);

  static String? _dynamicTr(String text) {
    if (text.trim().isEmpty) return text;

    final exact = _tr[text];
    if (exact != null) return exact;

    if (text.startsWith('Error: ')) {
      return text.replaceFirst('Error: ', 'Hata: ');
    }
    if (text.startsWith('Error loading data: ')) {
      return text.replaceFirst('Error loading data: ', 'Veri yüklenirken hata: ');
    }
    if (text.startsWith('Error refreshing data: ')) {
      return text.replaceFirst('Error refreshing data: ', 'Veri yenilenirken hata: ');
    }
    if (text.startsWith('Error loading budget: ')) {
      return text.replaceFirst('Error loading budget: ', 'Bütçe yüklenirken hata: ');
    }
    if (text.startsWith('Error loading category data: ')) {
      return text.replaceFirst('Error loading category data: ', 'Kategori verisi yüklenirken hata: ');
    }
    if (text.startsWith('Error navigating to category detail: ')) {
      return text.replaceFirst('Error navigating to category detail: ', 'Kategori detayına giderken hata: ');
    }
    if (text.startsWith('Failed to process image: ')) {
      return text.replaceFirst('Failed to process image: ', 'Görsel işlenemedi: ');
    }
    if (text.startsWith('Failed to parse invoice: ')) {
      return text.replaceFirst('Failed to parse invoice: ', 'Fatura okunamadı: ');
    }
    if (text.startsWith('Failed to pick image: ')) {
      return text.replaceFirst('Failed to pick image: ', 'Görsel seçilemedi: ');
    }
    if (text.startsWith('Failed to take picture: ')) {
      return text.replaceFirst('Failed to take picture: ', 'Fotoğraf çekilemedi: ');
    }
    if (text.startsWith('Failed to initialize camera: ')) {
      return text.replaceFirst('Failed to initialize camera: ', 'Kamera başlatılamadı: ');
    }
    if (text.startsWith('Failed to save: ')) {
      return text.replaceFirst('Failed to save: ', 'Kaydedilemedi: ');
    }
    if (text.startsWith('Found ') && text.endsWith(' items to fetch...')) {
      return text.replaceFirst('Found ', '').replaceFirst(' items to fetch...', ' öğe alınacak...');
    }
    if (text.startsWith('Last ') && text.endsWith(' Days')) {
      return text.replaceFirst('Last ', 'Son ').replaceFirst(' Days', ' Gün');
    }
    if (text.startsWith('Last ') && text.endsWith(' days')) {
      return text.replaceFirst('Last ', 'Son ').replaceFirst(' days', ' gün');
    }
    if (text.endsWith(' days left')) {
      return text.replaceFirst(' days left', ' gün kaldı');
    }
    if (text.endsWith(' days remaining')) {
      return text.replaceFirst(' days remaining', ' gün kaldı');
    }
    if (text.endsWith(' day left')) {
      return text.replaceFirst(' day left', ' gün kaldı');
    }
    if (text.endsWith(' transactions')) {
      return text.replaceFirst(' transactions', ' işlem');
    }
    final expenseCountMatch = RegExp(r'^(\d+) expenses?$').firstMatch(text);
    if (expenseCountMatch != null) {
      return '${expenseCountMatch.group(1)} gider';
    }
    final incomeCountMatch = RegExp(r'^(\d+) incomes?$').firstMatch(text);
    if (incomeCountMatch != null) {
      return '${incomeCountMatch.group(1)} gelir';
    }
    if (text.endsWith(' Transactions')) {
      return text.replaceFirst(' Transactions', ' İşlem');
    }
    if (text.endsWith(' Categories')) {
      return text.replaceFirst(' Categories', ' Kategori');
    }
    if (text.endsWith(' active')) {
      return text.replaceFirst(' active', ' aktif');
    }
    if (text.startsWith('Currency: ')) {
      return text.replaceFirst('Currency: ', 'Para birimi: ');
    }
    if (text.startsWith('Date: ')) {
      return text.replaceFirst('Date: ', 'Tarih: ');
    }
    if (text.startsWith('Transaction ID: ')) {
      return text.replaceFirst('Transaction ID: ', 'İşlem ID: ');
    }
    if (text.startsWith('Updated ')) {
      return text.replaceFirst('Updated ', 'Güncellendi: ');
    }
    if (text.startsWith('Used ')) {
      return text.replaceFirst('Used ', 'Kullanılan ');
    }
    if (text.startsWith('Total ')) {
      return text.replaceFirst('Total ', 'Toplam ');
    }
    if (text.startsWith('Over ')) {
      return text.replaceFirst('Over ', '') + ' üzeri';
    }
    if (text.startsWith('Under ')) {
      return text.replaceFirst('Under ', '') + ' altı';
    }
    if (text.startsWith('No expenses found for ')) {
      return text.replaceFirst('No expenses found for ', 'Gider bulunamadı: ');
    }
    if (text.startsWith('No results found for ')) {
      return text.replaceFirst('No results found for ', 'Sonuç bulunamadı: ');
    }
    if (text.startsWith('No transactions for ')) {
      return text.replaceFirst('No transactions for ', 'İşlem yok: ');
    }
    if (text.startsWith('From ') && text.contains(' to ')) {
      return text.replaceFirst('From ', '').replaceFirst(' to ', ' → ');
    }
    if (text.startsWith('vs ')) {
      return text.replaceFirst('vs ', 'Karşılaştırma: ');
    }
    if (text.startsWith('Day ')) {
      return text.replaceFirst('Day ', 'Gün ');
    }
    if (text.startsWith('7-Day Trend:')) {
      return text.replaceFirst('7-Day Trend:', '7 Günlük Trend:');
    }
    if (text.startsWith('Monthly Avg:')) {
      return text.replaceFirst('Monthly Avg:', 'Aylık Ortalama:');
    }
    if (text.contains(' of ') && text.endsWith(' days')) {
      return text.replaceAll(' of ', ' / ').replaceFirst(' days', ' gün');
    }

    String translateWord(String value) => _tr[value] ?? value;

    if (text.contains(' • ')) {
      final parts = text.split(' • ');
      if (parts.isNotEmpty) {
        parts[0] = translateWord(parts[0]);
        return parts.join(' • ');
      }
    }

    final budgetTitleMatch = RegExp(r'^(Monthly|Weekly|Yearly) Budget$').firstMatch(text);
    if (budgetTitleMatch != null) {
      return '${translateWord(budgetTitleMatch.group(1)!)} Bütçe';
    }

    final summaryTitleMatch = RegExp(r'^([A-Za-z]+) Summary$').firstMatch(text);
    if (summaryTitleMatch != null) {
      return '${translateWord(summaryTitleMatch.group(1)!)} Özeti';
    }

    final monthYearMatch = RegExp(r'^(January|February|March|April|May|June|July|August|September|October|November|December) (\d{4})$').firstMatch(text);
    if (monthYearMatch != null) {
      return '${translateWord(monthYearMatch.group(1)!)} ${monthYearMatch.group(2)}';
    }

    final editTypeMatch = RegExp(r'^Edit (Expense|Income|Amount)$').firstMatch(text);
    if (editTypeMatch != null) {
      final value = editTypeMatch.group(1)!;
      if (value == 'Amount') return 'Tutarı Düzenle';
      return '${translateWord(value)} Düzenle';
    }

    final updateTypeMatch = RegExp(r'^Update (Expense|Income)$').firstMatch(text);
    if (updateTypeMatch != null) {
      return '${translateWord(updateTypeMatch.group(1)!)} Güncelle';
    }

    final deleteTypeMatch = RegExp(r'^Delete (Expense|Income|expense|income)$').firstMatch(text);
    if (deleteTypeMatch != null) {
      final value = deleteTypeMatch.group(1)!;
      return '${translateWord(value[0].toUpperCase() + value.substring(1))} Sil';
    }

    final selectCategoryMatch = RegExp(r'^Select (Expense|Income) Category$').firstMatch(text);
    if (selectCategoryMatch != null) {
      return '${translateWord(selectCategoryMatch.group(1)!)} Kategorisi Seç';
    }

    final selectSourceMatch = RegExp(r'^Select (Income) Source$').firstMatch(text);
    if (selectSourceMatch != null) {
      return '${translateWord(selectSourceMatch.group(1)!)} Kaynağı Seç';
    }

    final noCategoryIncomeMatch = RegExp(r'^No (.+) incomes found$').firstMatch(text);
    if (noCategoryIncomeMatch != null) {
      return '${translateWord(noCategoryIncomeMatch.group(1)!)} için gelir bulunamadı';
    }

    final noIncomeDataMatch = RegExp(r'^No income data available for (.+)$').firstMatch(text);
    if (noIncomeDataMatch != null) {
      return '${noIncomeDataMatch.group(1)} için gelir verisi yok';
    }

    final exportTransactionsMatch = RegExp(r'^Export (\d+) Transactions$').firstMatch(text);
    if (exportTransactionsMatch != null) {
      return '${exportTransactionsMatch.group(1)} İşlemi Dışa Aktar';
    }

    final restoredPurchasesMatch = RegExp(r'^Purchases restored! Found (\d+) active subscription\(s\)$').firstMatch(text);
    if (restoredPurchasesMatch != null) {
      return 'Satın almalar geri yüklendi! ${restoredPurchasesMatch.group(1)} aktif abonelik bulundu';
    }

    final loadingCategoryMatch = RegExp(r'^Loading (.+) data\.\.\.$').firstMatch(text);
    if (loadingCategoryMatch != null) {
      return '${translateWord(loadingCategoryMatch.group(1)!)} verileri yükleniyor...';
    }

    final deleteBudgetMatch = RegExp(r'^Are you sure you want to delete this (.+) budget\?$').firstMatch(text);
    if (deleteBudgetMatch != null) {
      return 'Bu ${translateWord(deleteBudgetMatch.group(1)!)} bütçeyi silmek istediğine emin misin?';
    }

    if (text.endsWith('% Used')) {
      return text.replaceFirst('% Used', '% Kullanıldı');
    }
    if (text.endsWith('% of total')) {
      return text.replaceFirst('% of total', '% toplam');
    }
    if (text.endsWith(' saved')) {
      return text.replaceFirst(' saved', ' birikti');
    }
    if (text.startsWith('vs ') && text.endsWith(' last month')) {
      return text.replaceFirst('vs ', '').replaceFirst(' last month', ' geçen aya göre');
    }
    if (text.startsWith('Last updated: ')) {
      return text.replaceFirst('Last updated: ', 'Son güncelleme: ');
    }
    if (text.startsWith('Effective: ')) {
      return text.replaceFirst('Effective: ', 'Geçerli tarih: ');
    }
    if (text.startsWith('Your transactions have been exported to: ')) {
      return text.replaceFirst('Your transactions have been exported to: ', 'İşlemlerin şuraya aktarıldı: ');
    }
    if (text.startsWith('Total: ')) {
      return text.replaceFirst('Total: ', 'Toplam: ');
    }
    if (text.startsWith('Error exporting data: ')) {
      return text.replaceFirst('Error exporting data: ', 'Veri dışa aktarılırken hata: ');
    }
    if (text.startsWith('Error loading transaction details: ')) {
      return text.replaceFirst('Error loading transaction details: ', 'İşlem detayları yüklenirken hata: ');
    }
    if (text.startsWith('Error cropping image: ')) {
      return text.replaceFirst('Error cropping image: ', 'Görsel kırpılırken hata: ');
    }
    if (text.startsWith('Failed to verify OTP: ')) {
      return text.replaceFirst('Failed to verify OTP: ', 'OTP doğrulanamadı: ');
    }
    if (text.startsWith('Failed to resend verification email: ')) {
      return text.replaceFirst('Failed to resend verification email: ', 'Doğrulama e-postası yeniden gönderilemedi: ');
    }
    if (text.startsWith('Failed to load incomes: ')) {
      return text.replaceFirst('Failed to load incomes: ', 'Gelirler yüklenemedi: ');
    }
    if (text.startsWith('Failed to delete income: ')) {
      return text.replaceFirst('Failed to delete income: ', 'Gelir silinemedi: ');
    }
    if (text.startsWith('Failed to update income: ')) {
      return text.replaceFirst('Failed to update income: ', 'Gelir güncellenemedi: ');
    }

    final addTypeMatch = RegExp(r'^Add (Expense|Income)$').firstMatch(text);
    if (addTypeMatch != null) {
      return '${translateWord(addTypeMatch.group(1)!)} Ekle';
    }

    final totalTypeMatch = RegExp(r'^Total (Expense|Expenses|Income|Incomes)$').firstMatch(text);
    if (totalTypeMatch != null) {
      final value = totalTypeMatch.group(1)!;
      final normalized = value.startsWith('Expense') ? 'Expense' : 'Income';
      return 'Toplam ${translateWord(normalized)}';
    }

    final selectCategoriesMatch = RegExp(r'^Select (expense|income|Expense|Income) categories$').firstMatch(text);
    if (selectCategoriesMatch != null) {
      final value = selectCategoriesMatch.group(1)!;
      final normalized = value[0].toUpperCase() + value.substring(1).toLowerCase();
      return '${translateWord(normalized)} kategorilerini seç';
    }

    final adjustBudgetForMatch = RegExp(r'^Adjust Budget for (.+)$').firstMatch(text);
    if (adjustBudgetForMatch != null) {
      return '${translateWord(adjustBudgetForMatch.group(1)!)} için bütçeyi ayarla';
    }

    final deleteNamedTransactionMatch = RegExp(r'^Are you sure you want to delete (.+)\?$').firstMatch(text);
    if (deleteNamedTransactionMatch != null) {
      return '${deleteNamedTransactionMatch.group(1)} öğesini silmek istediğine emin misin?';
    }

    if (text.startsWith("We've sent a verification link to ")) {
      return text.replaceFirst("We've sent a verification link to ", '') + ' adresine doğrulama bağlantısı gönderdik';
    }
    if (text.contains(' at ') && RegExp(r'^\d').hasMatch(text)) {
      return text.replaceFirst(' at ', ' saat ');
    }
    return null;
  }

  static final Map<String, String> _tr = {
    // App / navigation
    'Finance Track': 'PARO Cüzdan',
    'PARO Cüzdan': 'PARO Cüzdan',
    'Finance Tracker': 'PARO Cüzdan',
    'Expense Manager Pro': 'PARO Cüzdan',
    'Home': 'Ana Sayfa',
    'Dashboard': 'Panel',
    'Analytics': 'Analizler',
    'Transactions': 'İşlemler',
    'Transaction': 'İşlem',
    'Transaction History': 'İşlem Geçmişi',
    'Profile': 'Profil',
    'Quick Access': 'Hızlı Erişim',
    'Recent Transactions': 'Son İşlemler',
    'Financial Overview': 'Finansal Genel Bakış',

    // Common actions
    'Add': 'Ekle',
    'Edit': 'Düzenle',
    'Delete': 'Sil',
    'Save': 'Kaydet',
    'Update': 'Güncelle',
    'Cancel': 'İptal',
    'OK': 'Tamam',
    'Ok': 'Tamam',
    'Close': 'Kapat',
    'Back': 'Geri',
    'Next': 'İleri',
    'Done': 'Bitti',
    'Continue': 'Devam Et',
    'Retry': 'Tekrar Dene',
    'Try Again': 'Tekrar Dene',
    'Try again': 'Tekrar dene',
    'Refresh': 'Yenile',
    'Reset': 'Sıfırla',
    'Clear': 'Temizle',
    'Apply': 'Uygula',
    'Dismiss': 'Kapat',
    'Submit': 'Gönder',
    'Verify': 'Doğrula',
    'Maybe later': 'Belki sonra',
    'Got it': 'Anladım',
    'Share File': 'Dosyayı Paylaş',
    'Open Settings': 'Ayarları Aç',
    'Open App Settings': 'Uygulama Ayarlarını Aç',
    'Grant Permission': 'İzin Ver',
    'Grant Permissions': 'İzin Ver',

    // Generic labels
    'Title': 'Başlık',
    'Name': 'Ad',
    'Description': 'Açıklama',
    'Amount': 'Tutar',
    'Date': 'Tarih',
    'Time': 'Saat',
    'Date & Time': 'Tarih ve Saat',
    'Category': 'Kategori',
    'Categories': 'Kategoriler',
    'Type': 'Tür',
    'Source': 'Kaynak',
    'Source (Optional)': 'Kaynak (İsteğe Bağlı)',
    'Source (e.g., Company Name)': 'Kaynak (örn. Şirket Adı)',
    'Payment Method': 'Ödeme Yöntemi',
    'Payment Method (e.g., Credit Card)': 'Ödeme Yöntemi (örn. Kredi Kartı)',
    'Payment Methods': 'Ödeme Yöntemleri',
    'Notes': 'Notlar',
    'Notes (Optional)': 'Notlar (İsteğe Bağlı)',
    'Notes (optional)': 'Notlar (İsteğe Bağlı)',
    'Color': 'Renk',
    'Icon': 'İkon',
    'Search': 'Ara',
    'Filter': 'Filtrele',
    'Sort': 'Sırala',
    'From': 'Başlangıç',
    'To': 'Bitiş',
    'All': 'Tümü',
    'Any': 'Herhangi biri',
    'None': 'Yok',
    'All time': 'Tüm zamanlar',
    'Overview': 'Genel Bakış',
    'Summary': 'Özet',
    'Details': 'Detaylar',
    'Important Information': 'Önemli Bilgi',
    'Tips:': 'İpuçları:',

    // Auth / account
    'Account': 'Hesap',
    'Account Information': 'Hesap Bilgileri',
    'Email': 'E-posta',
    'Email Address': 'E-posta Adresi',
    'Password': 'Şifre',
    'Username': 'Kullanıcı adı',
    'Login': 'Giriş Yap',
    'Log In': 'Giriş Yap',
    'Sign In': 'Giriş Yap',
    'Sign Up': 'Kayıt Ol',
    'Create Account': 'Hesap Oluştur',
    'Forgot Password?': 'Şifreni mi unuttun?',
    'Remember me': 'Beni hatırla',
    'Logout': 'Çıkış Yap',
    'Sign out from your account': 'Hesabından çıkış yap',
    'Are you sure you want to log out?': 'Çıkış yapmak istediğine emin misin?',
    'Guest User': 'Misafir Kullanıcı',
    'Not logged in': 'Giriş yapılmadı',
    'No user logged in': 'Giriş yapan kullanıcı yok',
    'Verify your email': 'E-postanı doğrula',
    'Verify Your Email': 'E-postanı Doğrula',
    'Verify Email': 'E-postayı Doğrula',
    'Verification Code': 'Doğrulama Kodu',
    'I have verified, continue': 'Doğruladım, devam et',
    'Resend Verification Link': 'Doğrulama Bağlantısını Tekrar Gönder',
    'Continue to your account': 'Hesabına devam et',
    'Email verification successful': 'E-posta doğrulaması başarılı',
    'Display Name': 'Görünen Ad',
    'Change Password': 'Şifreyi Değiştir',
    'Current Password': 'Mevcut Şifre',
    'New Password': 'Yeni Şifre',
    'Confirm Password': 'Şifreyi Onayla',
    'Update Password': 'Şifreyi Güncelle',
    'Update Email': 'E-postayı Güncelle',
    'Update Email Address': 'E-posta Adresini Güncelle',
    'Update Name': 'Adı Güncelle',
    'Update Display Name': 'Görünen Adı Güncelle',
    'Enter your current password': 'Mevcut şifreni gir',
    'Enter your new password': 'Yeni şifreni gir',
    'Confirm your new password': 'Yeni şifreni onayla',
    'Enter your display name': 'Görünen adını gir',
    'Enter your new email address': 'Yeni e-posta adresini gir',
    'Enter 6-digit code': '6 haneli kodu gir',
    'Name updated successfully': 'Ad başarıyla güncellendi',
    'Password updated successfully': 'Şifre başarıyla güncellendi',
    'No changes were made to your name': 'Adında değişiklik yapılmadı',
    'You will receive a verification link at your new email address.': 'Yeni e-posta adresine bir doğrulama bağlantısı gönderilecek.',
    'You\'re signed in with a social account. Password changes are managed through your social account provider.': 'Sosyal hesapla giriş yaptın. Şifre değişiklikleri sosyal hesap sağlayıcın üzerinden yönetilir.',
    'Social Account Sign In': 'Sosyal Hesapla Giriş',
    'Google': 'Google',
    'Googles': 'Google',
    'Or': 'Veya',

    // Profile / settings
    'Preferences': 'Tercihler',
    'Support': 'Destek',
    'Data Management': 'Veri Yönetimi',
    'Edit Profile': 'Profili Düzenle',
    'Change your name and password': 'Adını ve şifreni değiştir',
    'Subscription Management': 'Abonelik Yönetimi',
    'View and manage your subscription details': 'Abonelik detaylarını görüntüle ve yönet',
    'Active': 'Aktif',
    'Privacy & Security': 'Gizlilik ve Güvenlik',
    'Privacy': 'Gizlilik',
    'Security': 'Güvenlik',
    'Manage your privacy settings and account security': 'Gizlilik ayarlarını ve hesap güvenliğini yönet',
    'Biometric Authentication': 'Biyometrik Kimlik Doğrulama',
    'Secure your app with fingerprint or face recognition': 'Uygulamayı parmak izi veya yüz tanıma ile güvene al',
    'Use fingerprint or face recognition to access the app': 'Uygulamaya erişmek için parmak izi veya yüz tanıma kullan',
    'Biometric authentication coming soon!': 'Biyometrik kimlik doğrulama yakında!',
    'Export Data': 'Verileri Dışa Aktar',
    'Export your transactions to CSV': 'İşlemlerini CSV olarak dışa aktar',
    'Delete Account': 'Hesabı Sil',
    'Permanently delete your account and all data': 'Hesabını ve tüm verilerini kalıcı olarak sil',
    'Currency': 'Para Birimi',
    'Select your preferred currency for transactions': 'İşlemler için tercih ettiğin para birimini seç',
    'Language': 'Dil',
    'Change app language': 'Uygulama dilini değiştir',
    'System Default': 'Sistem Varsayılanı',
    'English': 'İngilizce',
    'Turkish': 'Türkçe',
    'My Categories': 'Kategorilerim',
    'Add, edit, or delete your custom categories': 'Özel kategorilerini ekle, düzenle veya sil',
    'Help & Support': 'Yardım ve Destek',
    'Get help with using the app': 'Uygulamayı kullanırken yardım al',
    'Send Feedback': 'Geri Bildirim Gönder',
    'Share your thoughts and suggestions': 'Düşüncelerini ve önerilerini paylaş',
    'About': 'Hakkında',
    'Learn more about this app': 'Bu uygulama hakkında daha fazla bilgi edin',
    'FAQ': 'SSS',
    'Frequently Asked Questions': 'Sık Sorulan Sorular',
    'Send Message': 'Mesaj Gönder',
    'Send Us a Message': 'Bize Mesaj Gönder',
    'Message': 'Mesaj',
    'Subject': 'Konu',
    'Contact Us': 'Bize Ulaşın',
    'How can we help you?': 'Nasıl yardımcı olabiliriz?',
    'Have an idea?': 'Bir fikrin mi var?',
    'Share Your Ideas': 'Fikirlerini Paylaş',
    'Feature Suggestions': 'Özellik Önerileri',
    'Message sent successfully!': 'Mesaj başarıyla gönderildi!',
    'Email Support': 'E-posta Desteği',
    'Collaborate with us': 'Bizimle iş birliği yap',
    'Submit feature requests': 'Özellik isteği gönder',
    'Join beta testing': 'Beta testine katıl',

    // Finance basics
    'Expense': 'Gider',
    'Income': 'Gelir',
    'Expenses': 'Giderler',
    'Incomes': 'Gelirler',
    'Expense History': 'Gider Geçmişi',
    'Income History': 'Gelir Geçmişi',
    'Income List': 'Gelir Listesi',
    'Expense Details': 'Gider Detayları',
    'Income & Expenses': 'Gelir ve Giderler',
    'Income vs Expense': 'Gelir - Gider',
    'Balance': 'Bakiye',
    'Total Balance': 'Toplam Bakiye',
    'Current Balance': 'Güncel Bakiye',
    'Projected Balance': 'Tahmini Bakiye',
    'Total Income': 'Toplam Gelir',
    'Total Expense': 'Toplam Gider',
    'Net Cashflow': 'Net Nakit Akışı',
    'Expense ratio': 'Gider oranı',
    'Expense to Income Ratio': 'Gider / Gelir Oranı',
    'Monthly spending ratio': 'Aylık harcama oranı',
    'Remaining': 'Kalan',
    'Spent': 'Harcanan',
    'Used': 'Kullanılan',
    'Available to spend today': 'Bugün harcanabilir',
    'Bank': 'Banka',
    'Cash': 'Nakit',
    'Card': 'Kart',
    'Transport': 'Ulaşım',
    'Entertainment': 'Eğlence',
    'Food & Groceries': 'Yemek ve Market',

    // Transactions
    'All Transactions': 'Tüm İşlemler',
    'Add Transaction': 'İşlem Ekle',
    'Add Expense': 'Gider Ekle',
    'Add Income': 'Gelir Ekle',
    'Edit Transaction': 'İşlemi Düzenle',
    'Edit Expense': 'Gideri Düzenle',
    'Edit Income': 'Geliri Düzenle',
    'Delete Transaction': 'İşlemi Sil',
    'Delete Expense': 'Gideri Sil',
    'Delete Income': 'Geliri Sil',
    'Update Expense': 'Gideri Güncelle',
    'Update Income': 'Geliri Güncelle',
    'Select Expense Category': 'Gider Kategorisi Seç',
    'Select Income Category': 'Gelir Kategorisi Seç',
    'Select Category': 'Kategori Seç',
    'Select Currency': 'Para Birimi Seç',
    'Select Date Range': 'Tarih Aralığı Seç',
    'Select Time Period': 'Zaman Aralığı Seç',
    'Quick Select': 'Hızlı Seçim',
    'Add comment...': 'Yorum ekle...',
    '0.00': '0.00',
    'e.g., ABC Company, Freelance Client (Optional)': 'örn. ABC Şirketi, Freelance Müşteri (İsteğe Bağlı)',
    'Add any additional notes here...': 'Ek notlarını buraya yaz...',
    'Please enter a title': 'Lütfen bir başlık gir',
    'Please enter a valid amount': 'Lütfen geçerli bir tutar gir',
    'Expense added successfully': 'Gider başarıyla eklendi',
    'Income added successfully': 'Gelir başarıyla eklendi',
    'Expense updated successfully': 'Gider başarıyla güncellendi',
    'Income updated successfully': 'Gelir başarıyla güncellendi',
    'Expense saved successfully!': 'Gider başarıyla kaydedildi!',
    'No transactions found': 'İşlem bulunamadı',
    'No transactions found in the cloud.': 'Bulutta işlem bulunamadı.',
    'No transactions found. Start by adding your first transaction!': 'İşlem bulunamadı. İlk işlemini ekleyerek başla!',
    'No transactions found with the current filters': 'Geçerli filtrelerle işlem bulunamadı',
    'No transactions found for the selected period': 'Seçili dönem için işlem bulunamadı',
    'No transactions in this period': 'Bu dönemde işlem yok',
    'No transactions yet': 'Henüz işlem yok',
    'No transactions': 'İşlem yok',
    'No expenses found': 'Gider bulunamadı',
    'No expenses yet': 'Henüz gider yok',
    'No income yet': 'Henüz gelir yok',
    'Tap the + button to add a new income': 'Yeni gelir eklemek için + butonuna dokun',
    'Add some expenses or income to see them here': 'Burada görmek için gelir veya gider ekle',
    'Add expenses or income for this date': 'Bu tarih için gelir veya gider ekle',
    'Transaction data unavailable': 'İşlem verisi yok',
    'Transaction not found': 'İşlem bulunamadı',
    'Delete All Transactions?': 'Tüm İşlemler Silinsin mi?',
    'Delete All': 'Tümünü Sil',
    'Deleting Transactions': 'İşlemler Siliniyor',
    'Successfully Deleted': 'Başarıyla Silindi',
    'All transactions deleted successfully': 'Tüm işlemler başarıyla silindi',
    'All your transactions have been permanently deleted from both local storage and cloud.': 'Tüm işlemlerin hem yerel depolamadan hem de buluttan kalıcı olarak silindi.',

    // Search / filter / sort
    'Search transactions': 'İşlemlerde ara',
    'Search expenses': 'Giderlerde ara',
    'Search incomes': 'Gelirlerde ara',
    'Search categories': 'Kategorilerde ara',
    'Search features...': 'Özelliklerde ara...',
    'Search FAQs...': 'SSS içinde ara...',
    'Search for incomes by title, category, source, or notes': 'Gelirleri başlık, kategori, kaynak veya notlara göre ara',
    'Filter Transactions': 'İşlemleri Filtrele',
    'Filter Expenses': 'Giderleri Filtrele',
    'Filter by Category': 'Kategoriye Göre Filtrele',
    'Filter expenses': 'Giderleri filtrele',
    'Filter incomes': 'Gelirleri filtrele',
    'Sort Transactions': 'İşlemleri Sırala',
    'Sort by': 'Sıralama',
    'Direction': 'Yön',
    'Amount Range': 'Tutar Aralığı',
    'Applied Filters': 'Uygulanan Filtreler',
    'Apply Filters': 'Filtreleri Uygula',
    'Apply Sort': 'Sıralamayı Uygula',
    'Clear Filter': 'Filtreyi Temizle',
    'Clear Filters': 'Filtreleri Temizle',
    'Clear Search': 'Aramayı Temizle',
    'Clear search': 'Aramayı temizle',
    'Reset Filters': 'Filtreleri Sıfırla',
    'Reset all': 'Tümünü sıfırla',
    'No results found': 'Sonuç bulunamadı',
    'Try a different search term': 'Farklı bir arama dene',
    'Try using different keywords or filters': 'Farklı anahtar kelimeler veya filtreler dene',
    'Try using different keywords or check for spelling errors': 'Farklı anahtar kelimeler dene veya yazımı kontrol et',
    'Try selecting a different date range': 'Farklı bir tarih aralığı seçmeyi dene',
    'Try selecting a different time period': 'Farklı bir zaman aralığı seçmeyi dene',

    // Dates / periods
    'Today': 'Bugün',
    'Yesterday': 'Dün',
    'This Week': 'Bu Hafta',
    'This Month': 'Bu Ay',
    'This Year': 'Bu Yıl',
    'This month': 'Bu ay',
    'This year': 'Bu yıl',
    'Last Month': 'Geçen Ay',
    'Last month': 'Geçen ay',
    'Last 7 days': 'Son 7 gün',
    'Last 30 days': 'Son 30 gün',
    'Last 3 months': 'Son 3 ay',
    'Last year': 'Geçen yıl',
    'Monthly': 'Aylık',
    'Weekly': 'Haftalık',
    'Monthly (Auto)': 'Aylık (Otomatik)',
    'Custom': 'Özel',
    'Selected Period': 'Seçili Dönem',
    'Reset to current month': 'Geçerli aya sıfırla',
    'Date Wise': 'Tarihe Göre',
    'Date-wise Expenses': 'Tarihe Göre Giderler',

    // Dashboard / analytics / reports
    'Monthly Summary': 'Aylık Özet',
    'Monthly Dashboard': 'Aylık Panel',
    'Monthly Analytics': 'Aylık Analizler',
    'Monthly Average': 'Aylık Ortalama',
    'Month End Forecast': 'Ay Sonu Tahmini',
    'Month-over-Month': 'Aydan Aya',
    'Month-to-Month Analysis': 'Aydan Aya Analiz',
    'Period Comparison': 'Dönem Karşılaştırması',
    'Selected image file not found': 'Seçilen görsel dosyası bulunamadı',
    'Income vs Expenses': 'Gelir ve Giderler',
    'Expense Breakdown': 'Gider Dağılımı',
    'Expense Breakdown by Category': 'Kategoriye Göre Gider Dağılımı',
    'Expense Categories': 'Gider Kategorileri',
    'Income Categories': 'Gelir Kategorileri',
    'Category Details': 'Kategori Detayları',
    'All Categories': 'Tüm Kategoriler',
    'Manage Categories': 'Kategorileri Yönet',
    'Add Category': 'Kategori Ekle',
    'Edit Category': 'Kategoriyi Düzenle',
    'Category Name': 'Kategori Adı',
    'Default Categories': 'Varsayılan Kategoriler',
    'Your Categories': 'Kategorilerin',
    'No categories': 'Kategori yok',
    'No categories match your filters': 'Filtrelerine uyan kategori yok',
    'Analyze Categories': 'Kategorileri Analiz Et',
    'Top Categories': 'En İyi Kategoriler',
    'Top Spending Categories': 'En Çok Harcama Kategorileri',
    'Top Sources': 'En İyi Kaynaklar',
    'Top Changes by Category': 'Kategoriye Göre En Büyük Değişimler',
    'Start adding expenses to see your category breakdown': 'Kategori dağılımını görmek için gider eklemeye başla',
    'No significant category changes found': 'Kayda değer kategori değişimi bulunamadı',
    'Expense Categories': 'Gider Kategorileri',
    'Income Categories': 'Gelir Kategorileri',
    'Daily Spending': 'Günlük Harcama',
    'Daily Expenses': 'Günlük Giderler',
    'Daily Spending Trend': 'Günlük Harcama Trendi',
    'Daily Transactions': 'Günlük İşlemler',
    '7-Day Trend': '7 Günlük Trend',
    '7-Day Average': '7 Günlük Ortalama',
    '7-day Average': '7 günlük ortalama',
    'Spending Trend': 'Harcama Trendi',
    'Trend': 'Trend',
    'Actual Spending': 'Gerçek Harcama',
    'Projected Spending': 'Tahmini Harcama',
    'Savings Rate': 'Tasarruf Oranı',
    'Overspending Alert': 'Aşırı Harcama Uyarısı',
    'Expense Ratio': 'Gider Oranı',
    'Daily Average': 'Günlük Ortalama',
    'Key Insight': 'Önemli İçgörü',
    'Key Insights': 'Önemli İçgörüler',
    'Advanced Analytics': 'Gelişmiş Analizler',
    'Advanced Trend Examples': 'Gelişmiş Trend Örnekleri',
    'Finance Visualization Examples': 'Finans Görselleştirme Örnekleri',
    'Insufficient data for comparison': 'Karşılaştırma için yeterli veri yok',
    'No comparison data available': 'Karşılaştırma verisi yok',
    'No data available': 'Veri yok',
    'No data available for selected period': 'Seçili dönem için veri yok',
    'No data to display': 'Gösterilecek veri yok',
    'No daily spending data available': 'Günlük harcama verisi yok',
    'No daily transaction data': 'Günlük işlem verisi yok',
    'No income data available for \$period': 'Bu dönem için gelir verisi yok',
    'No income recorded this month': 'Bu ay gelir kaydı yok',
    'We need at least two months of data to show comparison': 'Karşılaştırma göstermek için en az iki aylık veri gerekli',

    // Budgets
    'Budget': 'Bütçe',
    'Budgets': 'Bütçeler',
    'Your Budgets': 'Bütçelerin',
    'Budget Details': 'Bütçe Detayları',
    'Add Budget': 'Bütçe Ekle',
    'Edit Budget': 'Bütçeyi Düzenle',
    'Delete Budget': 'Bütçeyi Sil',
    'Create Budget': 'Bütçe Oluştur',
    'Create New Budget': 'Yeni Bütçe Oluştur',
    'Budget Name': 'Bütçe Adı',
    'Budget Title': 'Bütçe Başlığı',
    'Budget Amount': 'Bütçe Tutarı',
    'Budget Settings': 'Bütçe Ayarları',
    'Budget Status': 'Bütçe Durumu',
    'Budget Usage': 'Bütçe Kullanımı',
    'Budget Plan': 'Bütçe Planı',
    'Budget Planning': 'Bütçe Planlama',
    'Monthly Budget': 'Aylık Bütçe',
    'Daily Budget': 'Günlük Bütçe',
    'Active Budget': 'Aktif Bütçe',
    'No active budget': 'Aktif bütçe yok',
    'No Active Budget': 'Aktif Bütçe Yok',
    'No Budget Set': 'Bütçe Belirlenmedi',
    'No Budgets Found': 'Bütçe Bulunamadı',
    'Set Budget': 'Bütçe Belirle',
    'Set Active': 'Aktif Yap',
    'All Budgets': 'Tüm Bütçeler',
    'Total Budget': 'Toplam Bütçe',
    'Create a budget to track your spending and save money': 'Harcamalarını takip etmek ve tasarruf etmek için bütçe oluştur',
    'Create a monthly budget to track your spending and save money': 'Harcamalarını takip etmek ve tasarruf etmek için aylık bütçe oluştur',
    'Upgrade to Premium Budgeting': 'Premium Bütçeye Geç',
    'Unlock Premium Insights': 'Premium İçgörüleri Aç',
    'Adjust Budget for \$_categoryName': '\$_categoryName için bütçeyi ayarla',
    'Setting budget as active...': 'Bütçe aktif yapılıyor...',
    'Deleting budget...': 'Bütçe siliniyor...',
    'Budget deleted successfully': 'Bütçe başarıyla silindi',
    'Are you sure you want to delete this budget? This action cannot be undone.': 'Bu bütçeyi silmek istediğine emin misin? Bu işlem geri alınamaz.',

    // Scanner / invoice
    'Camera': 'Kamera',
    'Scan': 'Tara',
    'Scanner': 'Tarayıcı',
    'Invoice Scanner': 'Fatura Tarayıcı',
    'Scan Receipt': 'Fiş Tara',
    'Scan Receipt / Invoice': 'Fiş / Fatura Tara',
    'Scan Receipt or Invoice': 'Fiş veya Fatura Tara',
    'Review Invoice': 'Faturayı İncele',
    'Review & Save': 'İncele ve Kaydet',
    'Parsed Information': 'Okunan Bilgiler',
    'Preview': 'Önizleme',
    'Crop': 'Kırp',
    'Crop Receipt': 'Fişi Kırp',
    'Retake': 'Yeniden Çek',
    'Use Photo': 'Fotoğrafı Kullan',
    'Take Photo': 'Fotoğraf Çek',
    'Gallery': 'Galeri',
    'Select Photo': 'Fotoğraf Seç',
    'Merchant': 'Satıcı',
    'Tax': 'Vergi',
    'Invoice #': 'Fatura No',
    'Total': 'Toplam',
    'Camera Permission Required': 'Kamera İzni Gerekli',
    'Permission Required': 'İzin Gerekli',
    'Permissions Required': 'İzinler Gerekli',
    'Camera Not Available': 'Kamera Kullanılamıyor',
    'Unable to access camera. Please try again.': 'Kameraya erişilemiyor. Lütfen tekrar dene.',
    'Please grant camera permission to scan receipts': 'Fiş taramak için kamera izni ver',
    'Please grant camera permission in app settings': 'Lütfen uygulama ayarlarından kamera izni ver',
    'Camera and storage permissions are required to scan receipts. Please grant permissions in app settings.': 'Fiş taramak için kamera ve depolama izinleri gerekli. Lütfen uygulama ayarlarından izin ver.',
    'Storage permission is required to select photos': 'Fotoğraf seçmek için depolama izni gerekli',
    'Storage permission is required to select photos. Please grant permission in app settings.': 'Fotoğraf seçmek için depolama izni gerekli. Lütfen uygulama ayarlarından izin ver.',
    'Requesting permissions...': 'İzinler isteniyor...',
    'Processing image...': 'Görsel işleniyor...',
    'Extracting data...': 'Veriler çıkarılıyor...',
    'Saving expense...': 'Gider kaydediliyor...',
    'Invalid total amount': 'Geçersiz toplam tutar',
    'No invoice data to save': 'Kaydedilecek fatura verisi yok',
    'No image provided': 'Görsel sağlanmadı',
    'Take a photo or choose from gallery': 'Fotoğraf çek veya galeriden seç',
    'Some fields have low confidence. Please verify before saving.': 'Bazı alanların güveni düşük. Kaydetmeden önce kontrol et.',

    // Subscription
    'Unlock Premium': 'Premium Kilidini Aç',
    'Go Premium': 'Premium’a Geç',
    'View Plans': 'Planları Gör',
    'Refresh plans': 'Planları yenile',
    'Plans are getting ready': 'Planlar hazırlanıyor',
    'Fetching premium plans…': 'Premium planlar alınıyor…',
    'Hang tight while we prepare the best offers for you.': 'En iyi teklifleri hazırlarken lütfen bekle.',
    'What you’ll get': 'Neler kazanacaksın',
    'Unlock unlimited budget planning, smart insights, and more ways to stay on top of your finances.': 'Sınırsız bütçe planlama, akıllı içgörüler ve finansını kontrol altında tutmak için daha fazlasını aç.',
    'We couldn’t load the purchase options': 'Satın alma seçenekleri yüklenemedi',
    'We couldn’t find any plans right now. Check back in a moment or refresh.': 'Şu anda plan bulunamadı. Biraz sonra tekrar kontrol et veya yenile.',
    'Active Subscription': 'Aktif Abonelik',
    'No Active Subscription': 'Aktif Abonelik Yok',
    'All Active Subscriptions': 'Tüm Aktif Abonelikler',
    'Manage Subscription': 'Aboneliği Yönet',
    'Open Subscription Settings': 'Abonelik Ayarlarını Aç',
    'Refresh Subscription Info': 'Abonelik Bilgisini Yenile',
    'Restore Purchases': 'Satın Almaları Geri Yükle',
    'Restoring purchases...': 'Satın almalar geri yükleniyor...',
    'No purchases found to restore': 'Geri yüklenecek satın alma bulunamadı',
    'Purchases restored! Found \${restoredInfo.entitlements.active.length} active subscription(s)': 'Satın almalar geri yüklendi! \${restoredInfo.entitlements.active.length} aktif abonelik bulundu',
    'Test Subscription Restore': 'Abonelik Geri Yüklemeyi Test Et',
    'Testing subscription restore... Check logs for details': 'Abonelik geri yükleme test ediliyor... Detaylar için logları kontrol et',
    'Could not open management URL': 'Yönetim bağlantısı açılamadı',
    'Sandbox Environment': 'Sandbox Ortamı',
    'You don\'t have an active subscription': 'Aktif aboneliğin yok',

    // Export / data / privacy
    'Export as CSV': 'CSV olarak dışa aktar',
    'Export as JSON': 'JSON olarak dışa aktar',
    'Export Successful': 'Dışa Aktarma Başarılı',
    'Export Information': 'Dışa Aktarma Bilgisi',
    'Export Your Data': 'Verilerini Dışa Aktar',
    'Exporting data, please wait...': 'Veriler dışa aktarılıyor, lütfen bekle...',
    'You can export all your financial data as a CSV or JSON file. This includes all your income and expense transactions, categories, and budget settings.': 'Tüm finansal verilerini CSV veya JSON dosyası olarak dışa aktarabilirsin. Gelir ve gider işlemleri, kategoriler ve bütçe ayarları dahildir.',
    'You can export your transactions to a CSV file. The file will include all transaction details including date, amount, category, and description.': 'İşlemlerini CSV dosyası olarak dışa aktarabilirsin. Dosyada tarih, tutar, kategori ve açıklama dahil tüm işlem detayları bulunur.',
    'Privacy Policy': 'Gizlilik Politikası',
    'Your Privacy Matters': 'Gizliliğin Önemli',
    'Your financial data is important to us. This policy explains how we protect your privacy.': 'Finansal verilerin bizim için önemlidir. Bu politika gizliliğini nasıl koruduğumuzu açıklar.',
    'Data Handling': 'Veri İşleme',
    'Offline Data Storage': 'Çevrimdışı Veri Depolama',
    'Firebase Cloud Storage': 'Firebase Bulut Depolama',
    'Cloud Data Storage': 'Bulut Veri Depolama',
    'Firebase Storage': 'Firebase Depolama',
    'When cloud sync is enabled:': 'Bulut senkronizasyonu etkin olduğunda:',
    'All financial data is stored on your device first': 'Tüm finansal veriler önce cihazında saklanır',
    'Data is synchronized across all your devices': 'Veriler tüm cihazların arasında senkronize edilir',
    'Only you can access your financial data with your account': 'Finansal verilerine yalnızca hesabınla sen erişebilirsin',
    'Your data is securely encrypted in transit': 'Verilerin aktarım sırasında güvenli şekilde şifrelenir',
    'Your data never leaves your device unless cloud sync is enabled': 'Bulut senkronizasyonu etkin değilse verilerin cihazından ayrılmaz',
    'Works offline with no internet connection required': 'İnternet bağlantısı olmadan çevrimdışı çalışır',
    'Fast and efficient with minimal battery usage': 'Minimum pil kullanımıyla hızlı ve verimli',
    'You can disable cloud sync at any time to keep your data local only.': 'Verilerini yalnızca yerelde tutmak için bulut senkronizasyonunu istediğin zaman kapatabilirsin.',
    'Google Firebase security standards protect your information': 'Bilgilerin Google Firebase güvenlik standartlarıyla korunur',
    'Request Data Deletion': 'Veri Silme Talep Et',
    'Delete My Data': 'Verilerimi Sil',
    'Delete Your Data?': 'Verilerin Silinsin mi?',
    'Delete all your data from our servers': 'Tüm verilerini sunucularımızdan sil',
    'This will permanently delete all your data from our servers. Your local data will remain intact. This action cannot be undone.': 'Bu işlem tüm verilerini sunucularımızdan kalıcı olarak siler. Yerel verilerin kalır. Bu işlem geri alınamaz.',
    'This will permanently delete all your expenses and incomes from both your device and the cloud. This action cannot be undone.': 'Bu işlem tüm gider ve gelirlerini hem cihazından hem de buluttan kalıcı olarak siler. Bu işlem geri alınamaz.',
    'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.': 'Hesabını silmek istediğine emin misin? Bu işlem geri alınamaz ve tüm verilerin kalıcı olarak silinir.',

    // Status / errors
    'Loading...': 'Yükleniyor...',
    'Please wait': 'Lütfen bekle',
    'Please wait while the app restarts': 'Uygulama yeniden başlatılırken lütfen bekle',
    'Restarting app...': 'Uygulama yeniden başlatılıyor...',
    'Restart Now': 'Şimdi Yeniden Başlat',
    'Continue Without Restart': 'Yeniden Başlatmadan Devam Et',
    'To ensure all data is properly refreshed, restarting the app is recommended.': 'Tüm verilerin doğru yenilenmesi için uygulamayı yeniden başlatman önerilir.',
    'Data refreshed successfully!': 'Veriler başarıyla yenilendi!',
    'Data will be synced automatically when reconnected': 'Bağlantı geldiğinde veriler otomatik senkronize edilecek',
    'Working offline. Your data is being saved locally.': 'Çevrimdışı çalışıyorsun. Verilerin yerel olarak kaydediliyor.',
    'You are offline': 'Çevrimdışısın',
    'Database Initialization Failed': 'Veritabanı Başlatılamadı',
    'The app database could not be initialized. ': 'Uygulama veritabanı başlatılamadı. ',
    'Error': 'Hata',
    'Success': 'Başarılı',
    'Warning': 'Uyarı',
    'Information': 'Bilgi',
    'Something went wrong': 'Bir şeyler ters gitti',
    'Failed to load statistics': 'İstatistikler yüklenemedi',
    'Error Loading Dashboard': 'Panel Yüklenirken Hata',
    'Error Loading Summary': 'Özet Yüklenirken Hata',
    'Error loading categories': 'Kategoriler yüklenirken hata',
    'Error loading category analysis': 'Kategori analizi yüklenirken hata',
    'Error loading subscription details': 'Abonelik detayları yüklenirken hata',
    'Error loading transaction': 'İşlem yüklenirken hata',
    'Error Deleting Transactions': 'İşlemler Silinirken Hata',
    'We encountered a problem while deleting your transactions:': 'İşlemlerini silerken bir sorunla karşılaştık:',
    'Update Required': 'Güncelleme Gerekli',
    'Update Now': 'Şimdi Güncelle',
    'A newer version of the app is available and is required to continue.': 'Devam etmek için uygulamanın daha yeni bir sürümü gerekli.',
    'The update will start automatically. Please follow the on-screen instructions.': 'Güncelleme otomatik başlayacak. Lütfen ekrandaki talimatları izle.',
    'Unable to access camera. Please try again.': 'Kameraya erişilemiyor. Lütfen tekrar dene.',

    // Landing / about
    'Get Started now': 'Hemen Başla',
    'Track expenses seamlessly': 'Giderlerini kolayca takip et',
    'Your complete solution for expense tracking, budgeting, and financial analytics': 'Gider takibi, bütçeleme ve finansal analiz için eksiksiz çözümün',
    'App Features': 'Uygulama Özellikleri',
    'Feature Suggestions': 'Özellik Önerileri',
    'No features found': 'Özellik bulunamadı',
    'Find answers to common questions about using the app.': 'Uygulamayı kullanmayla ilgili sık sorulan soruların yanıtlarını bul.',
    'We\'re Here to Help': 'Yardım Etmek İçin Buradayız',
    'Have questions or need assistance with the app? Our support team is ready to help you get the most out of your expense tracking experience.': 'Soruların mı var veya yardıma mı ihtiyacın var? Destek ekibimiz gider takip deneyiminden en iyi şekilde yararlanman için hazır.',
    'We\'re constantly improving our app and would love to hear your suggestions for new features or improvements.': 'Uygulamamızı sürekli geliştiriyoruz ve yeni özellik ya da iyileştirme önerilerini duymak isteriz.',
    'Need help? Visit our ': 'Yardıma mı ihtiyacın var? ',
    'support center': 'destek merkezimizi ziyaret et',
    'Home': 'Ana Sayfa',
    'Expense Tracking': 'Gider Takibi',
    'Income Management': 'Gelir Yönetimi',
    'Financial Analytics': 'Finansal Analizler',
    'Budget Planning': 'Bütçe Planlama',
    'Category Management': 'Kategori Yönetimi',
    'User Profile': 'Kullanıcı Profili',
    'Firebase Integration': 'Firebase Entegrasyonu',
    'Key Capabilities': 'Temel Yetenekler',
    'Usage Examples': 'Kullanım Örnekleri',
    'Integration with Other Features': 'Diğer Özelliklerle Entegrasyon',
    'Fast and efficient with minimal battery usage': 'Minimum pil kullanımıyla hızlı ve verimli',

    // FAQ
    'Getting Started': 'Başlangıç',
    'Tracking Expenses': 'Gider Takibi',
    'Budgeting': 'Bütçeleme',
    'Reports & Analytics': 'Raporlar ve Analizler',
    'Account & Settings': 'Hesap ve Ayarlar',
    'Troubleshooting': 'Sorun Giderme',
    'How do I create an account?': 'Nasıl hesap oluştururum?',
    'To create an account, open the app and tap on "Sign Up" on the welcome screen. Enter your email address and create a password. You can also sign up using your Google account for faster access.': 'Hesap oluşturmak için uygulamayı aç ve karşılama ekranında "Kayıt Ol" seçeneğine dokun. E-posta adresini girip bir şifre oluştur. Daha hızlı erişim için Google hesabınla da kayıt olabilirsin.',
    'Is my financial data secure?': 'Finansal verilerim güvende mi?',
    'Yes, your data is securely stored using Firebase authentication and database systems. We employ industry-standard encryption methods and never share your personal financial information with third parties.': 'Evet, verilerin Firebase kimlik doğrulama ve veritabanı sistemleriyle güvenli şekilde saklanır. Sektör standardı şifreleme yöntemleri kullanırız ve kişisel finansal bilgilerini üçüncü taraflarla paylaşmayız.',
    'Can I use the app without creating an account?': 'Hesap oluşturmadan uygulamayı kullanabilir miyim?',
    'No, an account is required to use the app. This ensures your data is securely stored and can be recovered if you change devices.': 'Hayır, uygulamayı kullanmak için hesap gerekir. Bu sayede verilerin güvenle saklanır ve cihaz değiştirdiğinde geri yüklenebilir.',
    'How do I reset my password?': 'Şifremi nasıl sıfırlarım?',
    'If you forgot your password, tap on "Forgot Password" on the login screen. Enter your email address and follow the instructions sent to your email to reset your password.': 'Şifreni unuttuysan giriş ekranında "Şifremi Unuttum" seçeneğine dokun. E-posta adresini gir ve şifreni sıfırlamak için gönderilen yönergeleri takip et.',
    'How do I add a new expense?': 'Nasıl yeni gider eklerim?',
    'To add a new expense, tap the "+" button in the bottom navigation bar, then select "Expense". Fill in details such as amount, category, date, and notes, then tap "Save".': 'Yeni gider eklemek için alt menüdeki "+" butonuna dokun ve "Gider" seç. Tutar, kategori, tarih ve not gibi bilgileri doldurup "Kaydet"e dokun.',
    'How do I add a recurring expense?': 'Nasıl tekrarlayan gider eklerim?',
    'When adding an expense, toggle on the "Recurring" option. You can then set the frequency (daily, weekly, monthly) and the app will automatically track these recurring expenses.': 'Gider eklerken "Tekrarlayan" seçeneğini aç. Ardından sıklığı günlük, haftalık veya aylık olarak ayarlayabilirsin; uygulama bu giderleri otomatik takip eder.',
    'Can I attach receipts to my expenses?': 'Giderlerime fiş ekleyebilir miyim?',
    'Yes, when adding or editing an expense, tap the camera icon to take a photo of your receipt or select an existing image from your gallery.': 'Evet. Gider eklerken veya düzenlerken kamera ikonuna dokunarak fiş fotoğrafı çekebilir ya da galeriden mevcut bir görsel seçebilirsin.',
    'How do I edit or delete an expense?': 'Bir gideri nasıl düzenler veya silerim?',
    'Navigate to the transaction list, find the expense you want to modify, then swipe left to delete or tap to view details. In the details screen, you can edit the expense information or delete it permanently.': 'İşlem listesine git, düzenlemek istediğin gideri bul. Silmek için sola kaydırabilir veya detayları görmek için dokunabilirsin. Detay ekranında gider bilgilerini düzenleyebilir ya da kalıcı olarak silebilirsin.',
    'How do I add income?': 'Nasıl gelir eklerim?',
    'To add income, tap the "+" button in the bottom navigation bar, then select "Income". Enter the amount, source, date, and any notes, then tap "Save".': 'Gelir eklemek için alt menüdeki "+" butonuna dokun ve "Gelir" seç. Tutar, kaynak, tarih ve notları girip "Kaydet"e dokun.',
    'Can I set up recurring income entries?': 'Tekrarlayan gelir kayıtları oluşturabilir miyim?',
    'Yes, similar to expenses, you can toggle on the "Recurring" option when adding income and set the frequency (daily, weekly, monthly).': 'Evet. Giderlerde olduğu gibi gelir eklerken "Tekrarlayan" seçeneğini açıp günlük, haftalık veya aylık sıklık belirleyebilirsin.',
    'How do I view my income history?': 'Gelir geçmişimi nasıl görürüm?',
    'Go to the "Transactions" tab and filter by "Income" to see your income history. You can also view income in the dashboard for different time periods.': 'Gelir geçmişini görmek için "İşlemler" sekmesine git ve "Gelir" filtresini seç. Farklı dönemlerdeki gelirleri panelde de görebilirsin.',
    'How do I create a custom category?': 'Nasıl özel kategori oluştururum?',
    'Go to Settings > Categories > Add New Category. Enter a name for your category, select an icon, and choose a color. You can create categories for both expenses and income.': 'Ayarlar > Kategoriler > Yeni Kategori Ekle yolunu izle. Kategori adını gir, ikon ve renk seç. Hem gider hem gelir için kategori oluşturabilirsin.',
    'Can I edit or delete categories?': 'Kategorileri düzenleyebilir veya silebilir miyim?',
    'Yes, go to Settings > Categories, find the category you want to modify, then tap the edit icon or swipe to delete. Note that deleting a category will not delete transactions - they will be moved to "Uncategorized".': 'Evet. Ayarlar > Kategoriler bölümüne git, düzenlemek istediğin kategoriyi bul ve düzenle ikonuna dokun ya da silmek için kaydır. Kategori silmek işlemleri silmez; işlemler "Kategorisiz"e taşınır.',
    'Is there a limit to how many categories I can create?': 'Oluşturabileceğim kategori sayısında sınır var mı?',
    'No, you can create as many custom categories as you need to organize your finances effectively.': 'Hayır, finanslarını düzenlemek için ihtiyaç duyduğun kadar özel kategori oluşturabilirsin.',
    'How do I set up a budget?': 'Nasıl bütçe oluştururum?',
    'Go to the "Budget" tab and tap "Create Budget". Select a category, set your budget amount, and choose the time period (weekly, monthly). The app will track your spending against this budget.': '"Bütçe" sekmesine git ve "Bütçe Oluştur"a dokun. Kategori seç, bütçe tutarını belirle ve dönemi haftalık veya aylık seç. Uygulama harcamalarını bu bütçeye göre takip eder.',
    'Can I set budgets for multiple categories?': 'Birden fazla kategori için bütçe oluşturabilir miyim?',
    'Yes, you can create separate budgets for different expense categories to track spending across various aspects of your life.': 'Evet, farklı gider kategorileri için ayrı bütçeler oluşturarak harcamalarını daha detaylı takip edebilirsin.',
    'How will I know if I exceed my budget?': 'Bütçemi aşarsam nasıl haberim olur?',
    'The app sends notifications when you reach 50%, 80%, and 100% of your budget. You can also see visual indicators in the Budget section showing your spending progress.': 'Uygulama bütçenin %50, %80 ve %100 seviyelerine ulaştığında bildirim gönderir. Bütçe bölümünde harcama ilerlemeni görsel olarak da takip edebilirsin.',
    'Can I change or delete a budget?': 'Bütçeyi değiştirebilir veya silebilir miyim?',
    'Yes, go to the Budget tab, find the budget you want to modify, then tap to edit or use the menu options to delete it.': 'Evet. Bütçe sekmesine git, değiştirmek istediğin bütçeyi bul; düzenlemek için dokun veya menü seçeneklerinden sil.',
    'What kinds of reports are available?': 'Hangi raporlar mevcut?',
    'The app provides various reports including expense breakdown by category, income vs. expenses, spending trends over time, and monthly summaries.': 'Uygulama kategoriye göre gider dağılımı, gelir-gider karşılaştırması, zaman içindeki harcama trendleri ve aylık özetler gibi çeşitli raporlar sunar.',
    'How do I view my spending trends?': 'Harcama trendlerimi nasıl görürüm?',
    'Go to the "Analytics" tab to see charts and graphs showing your spending patterns over different time periods (weekly, monthly, yearly).': 'Haftalık, aylık veya yıllık harcama alışkanlıklarını gösteren grafikler için "Analizler" sekmesine git.',
    'Can I export my financial data?': 'Finansal verilerimi dışa aktarabilir miyim?',
    'Yes, go to Settings > Data > Export Data. You can export your transactions as a CSV file for use in spreadsheet applications.': 'Evet. Ayarlar > Veri > Verileri Dışa Aktar bölümüne git. İşlemlerini elektronik tablo uygulamalarında kullanmak üzere CSV olarak dışa aktarabilirsin.',
    'How do I view my monthly summary?': 'Aylık özetimi nasıl görürüm?',
    'Navigate to the "Monthly Summary" section to see a comprehensive overview of your income, expenses, savings, and budget status for each month.': 'Her ay için gelir, gider, birikim ve bütçe durumunun kapsamlı özetini görmek için "Aylık Özet" bölümüne git.',
    'How do I change my account email or password?': 'Hesap e-postamı veya şifremi nasıl değiştiririm?',
    'Go to Profile > Account Settings. From there, you can update your email address or change your password by following the verification steps.': 'Profil > Hesap Ayarları bölümüne git. Buradan doğrulama adımlarını takip ederek e-posta adresini veya şifreni değiştirebilirsin.',
    'Can I sync my data across multiple devices?': 'Verilerimi birden fazla cihazda senkronize edebilir miyim?',
    'Yes, your data is automatically synced across all devices where you are signed in with the same account.': 'Evet, aynı hesapla giriş yaptığın tüm cihazlarda verilerin otomatik olarak senkronize edilir.',
    'How do I change the currency settings?': 'Para birimi ayarlarını nasıl değiştiririm?',
    'Go to Settings > General > Currency and select your preferred currency from the list of available options.': 'Ayarlar > Genel > Para Birimi bölümüne git ve listeden tercih ettiğin para birimini seç.',
    'Is there a dark mode available?': 'Karanlık mod var mı?',
    'Yes, go to Settings > Display > Theme and toggle Dark Mode on or off, or select "System Default" to match your device settings.': 'Evet. Ayarlar > Görünüm > Tema bölümünden Karanlık Modu açıp kapatabilir veya cihaz ayarlarınla eşleşmesi için "Sistem Varsayılanı"nı seçebilirsin.',
    'The app is running slowly or crashing': 'Uygulama yavaş çalışıyor veya çöküyor',
    'Try clearing the app cache (Settings > Apps > Expense App > Clear Cache) or reinstalling the app. Make sure you have the latest version installed from the app store.': 'Uygulama önbelleğini temizlemeyi veya uygulamayı yeniden kurmayı dene. Uygulama mağazasındaki en güncel sürümün yüklü olduğundan emin ol.',
    "My transactions aren't syncing across devices": 'İşlemlerim cihazlar arasında senkronize olmuyor',
    "Check your internet connection and ensure you're signed in with the same account on all devices. Go to Settings > Sync > Sync Now to force a manual sync.": 'İnternet bağlantını kontrol et ve tüm cihazlarda aynı hesapla giriş yaptığından emin ol. Manuel senkronizasyon için Ayarlar > Senkronizasyon > Şimdi Senkronize Et yolunu izle.',
    "I'm seeing incorrect totals in my reports": 'Raporlarımda yanlış toplamlar görüyorum',
    'This might happen if you have transactions with future dates included in current reports. Check your date filters and ensure all transactions are correctly categorized.': 'Gelecek tarihli işlemler mevcut raporlara dahil edilirse bu durum yaşanabilir. Tarih filtrelerini kontrol et ve tüm işlemlerin doğru kategorilendirildiğinden emin ol.',
    'How do I report a bug or suggest a feature?': 'Bir hatayı nasıl bildiririm veya özellik öneririm?',
    'Go to Help & Support > Send Us a Message. Describe the issue or feature suggestion in detail, and our team will review it.': 'Yardım ve Destek > Bize Mesaj Gönder bölümüne git. Sorunu veya özellik önerini detaylı anlat; ekibimiz inceleyecektir.',

    // Misc
    'Dark mode is coming soon!': 'Karanlık mod yakında!',
    'Camera and storage permissions are required to scan receipts. Please grant permissions in app settings.': 'Fiş taramak için kamera ve depolama izinleri gerekli. Lütfen ayarlardan izin ver.',
    'Continue to your account': 'Hesabına devam et',
    'Create a new password that is at least 6 characters long.': 'En az 6 karakterli yeni bir şifre oluştur.',
    'This name will be visible to others in the app.': 'Bu ad uygulamadaki diğer kişiler tarafından görülebilir.',
    'Please login to change your name': 'Adını değiştirmek için giriş yap',
    'Please login to change your password': 'Şifreni değiştirmek için giriş yap',
    'Please click the link in the email to verify your new email address.': 'Yeni e-posta adresini doğrulamak için e-postadaki bağlantıya tıkla.',
    'We sent a verification link to:': 'Doğrulama bağlantısı gönderildi:',
    "We've sent a verification link to \${widget.email}": '\${widget.email} adresine doğrulama bağlantısı gönderdik',
    'For testing purposes, please enter the verification code:': 'Test amacıyla lütfen doğrulama kodunu gir:',
    'For testing, any 6-digit code will be accepted.': 'Test için herhangi bir 6 haneli kod kabul edilir.',
    'Firebase normally sends verification links by email which users must click to complete verification. The OTP input here is for demonstration purposes.': 'Firebase normalde doğrulamayı tamamlamak için kullanıcıların tıklaması gereken e-posta bağlantıları gönderir. Buradaki OTP alanı demo amaçlıdır.',
    'Please check your inbox and click the link to verify your account. You can reopen the app after verifying.': 'Lütfen gelen kutunu kontrol et ve hesabını doğrulamak için bağlantıya tıkla. Doğruladıktan sonra uygulamayı yeniden açabilirsin.',
    'Email is required': 'E-posta gerekli',
    'Username is required': 'Kullanıcı adı gerekli',
    'Password is required': 'Şifre gerekli',
    'Please enter a subject': 'Lütfen konu gir',
    'Please enter your message': 'Lütfen mesajını gir',
    'Please enter your name': 'Lütfen adını gir',
    'Please enter your current password': 'Lütfen mevcut şifreni gir',
    'Please enter your new password': 'Lütfen yeni şifreni gir',
    'Please confirm your new password': 'Lütfen yeni şifreni onayla',
    'Please enter verification code': 'Lütfen doğrulama kodunu gir',
    'Code must be 6 digits': 'Kod 6 haneli olmalı',
    'Please enter your email': 'Lütfen e-posta adresini gir',
    'Please enter a valid email': 'Lütfen geçerli bir e-posta gir',
    'Please enter a budget amount': 'Lütfen bütçe tutarı gir',
    'Please enter a valid number': 'Lütfen geçerli bir sayı gir',
    'Budget amount must be greater than zero': 'Bütçe tutarı sıfırdan büyük olmalı',
    'Daily Spending Trends': 'Günlük Harcama Trendleri',
    'Total Amount': 'Toplam Tutar',
    'Average': 'Ortalama',
    'Current Period': 'Geçerli Dönem',
    'Previous Period': 'Önceki Dönem',
    'Ascending': 'Artan',
    'Descending': 'Azalan',
    'A to Z, Low to High': 'A’dan Z’ye, Düşükten Yükseğe',
    'Z to A, High to Low': 'Z’den A’ya, Yüksekten Düşüğe',
    'Days Left': 'Kalan Gün',
    'Spent': 'Harcanan',
    'Savings Rate': 'Birikim Oranı',
    'Overspending Alert': 'Aşırı Harcama Uyarısı',
    'Expense Ratio': 'Gider Oranı',
    'Daily Average': 'Günlük Ortalama',
    'Expense to Income Ratio': 'Gider / Gelir Oranı',
    'No Data Available': 'Veri Yok',
    'Daily Expenses (30-Day View)': 'Günlük Giderler (30 Günlük Görünüm)',
    'Income vs Expenses (Last 12 Months)': 'Gelir ve Giderler (Son 12 Ay)',
    'Category Spending (Last 6 Months)': 'Kategori Harcamaları (Son 6 Ay)',
    'Budget Planning & Projection': 'Bütçe Planlama ve Tahmin',
    'Select Income Source': 'Gelir Kaynağı Seç',
    'All Budgets': 'Tüm Bütçeler',
    'Local': 'Yerel',
    'Cloud': 'Bulut',
    'Unfold Shop 2018': 'Unfold Shop 2018',
    'Food & Dining': 'Yemek ve Restoran',
    'Transportation': 'Ulaşım',
    'Utilities': 'Faturalar',
    'Health': 'Sağlık',
    'Health & Medical': 'Sağlık ve Medikal',
    'Salary': 'Maaş',
    'Freelance': 'Freelance',
    'Business': 'İş',
    'Investment': 'Yatırım',
    'Rental': 'Kira Geliri',
    'Gift': 'Hediye',
    'Refund': 'İade',
    'Unknown Category': 'Bilinmeyen Kategori',
    'Monthly': 'Aylık',
    'Weekly': 'Haftalık',
    'Yearly': 'Yıllık',
    // Final Turkish sweep
    'Finance': 'Finans',
    'Track': 'Takip',
    'Change': 'Değişim',
    'Highest': 'En Yüksek',
    'Lowest': 'En Düşük',
    'Current selection:': 'Mevcut seçim:',
    'DAILY': 'GÜNLÜK',
    'Go Back': 'Geri Dön',
    'View More': 'Daha Fazla Göster',
    'View detailed breakdown': 'Detaylı dökümü görüntüle',
    'View Detailed Analysis': 'Detaylı Analizi Görüntüle',
    'View All Categories': 'Tüm Kategorileri Görüntüle',
    'Refresh Data': 'Verileri Yenile',
    'Save Directly': 'Doğrudan Kaydet',
    'Processing...': 'İşleniyor...',
    'Starting data fetch...': 'Veri alma başlatılıyor...',
    'Fetching income data...': 'Gelir verileri alınıyor...',
    'Fetching expense data...': 'Gider verileri alınıyor...',
    'Fetching budget data...': 'Bütçe verileri alınıyor...',
    'Enter amount': 'Tutar gir',
    'Edit Amount': 'Tutarı Düzenle',
    'Edit expense': 'Gideri düzenle',
    'Error cropping image': 'Görsel kırpılırken hata oluştu',
    'Select custom date range': 'Özel tarih aralığı seç',
    'Password must be at least 6 characters': 'Şifre en az 6 karakter olmalı',
    'Passwords do not match': 'Şifreler eşleşmiyor',
    'Get insights into your spending habits': 'Harcama alışkanlıkların hakkında içgörüler al',
    'Start tracking your expenses by adding your first transaction': 'İlk işlemini ekleyerek giderlerini takip etmeye başla',
    'Add Your First Expense': 'İlk Giderini Ekle',
    'Add expenses and income to see date-wise analysis': 'Tarihe göre analiz görmek için gider ve gelir ekle',
    'Add income and expenses to see the comparison trend': 'Karşılaştırma trendini görmek için gelir ve gider ekle',
    'Add income and expenses to see your summary': 'Özetini görmek için gelir ve gider ekle',
    'Add more transactions to see spending comparisons': 'Harcama karşılaştırmalarını görmek için daha fazla işlem ekle',
    'Add transactions to see daily spending and income trends': 'Günlük gider ve gelir trendlerini görmek için işlem ekle',
    'This action cannot be undone. Are you sure you want to delete this expense?': 'Bu işlem geri alınamaz. Bu gideri silmek istediğine emin misin?',
    'This action cannot be undone. Are you sure you want to delete this income?': 'Bu işlem geri alınamaz. Bu geliri silmek istediğine emin misin?',
    'This app uses ObjectBox for secure local data storage:': 'Bu uygulama güvenli yerel veri depolama için ObjectBox kullanır:',
    'This is your control center for privacy and security settings. ': 'Burası gizlilik ve güvenlik ayarların için kontrol merkezidir. ',
    'vs Last Month': 'Geçen Aya Göre',
    'to': 'ile',
    '100% (Balance)': '%100 (Denge)',
    ' (Balance)': ' (Denge)',
    'Enter your email': 'E-posta adresini gir',
    'Enter your username': 'Kullanıcı adını gir',
    'Enter password': 'Şifre gir',
    'Enter your password': 'Şifreni gir',
    'Expense App Transactions': 'Gider Uygulaması İşlemleri',
    'Transaction Export': 'İşlem Dışa Aktarımı',
    'Your data is primarily stored locally with ObjectBox': 'Verilerin öncelikli olarak ObjectBox ile yerel olarak saklanır',
    'Secure cloud backup of your financial data': 'Finansal verilerinin güvenli bulut yedeği',
    'Download a copy of all your financial data': 'Tüm finansal verilerinin bir kopyasını indir',
    'Data deletion request submitted successfully': 'Veri silme talebi başarıyla gönderildi',
    'Could not launch email client. Please try again later.': 'E-posta uygulaması açılamadı. Lütfen daha sonra tekrar dene.',
    'Find answers to common questions': 'Sık sorulan soruların cevaplarını bul',
    'Error loading expenses': 'Giderler yüklenirken hata oluştu',
    'Error loading incomes': 'Gelirler yüklenirken hata oluştu',
    'Error loading transaction data:': 'İşlem verileri yüklenirken hata oluştu:',
    'Amount must be greater than zero': 'Tutar sıfırdan büyük olmalı',
    'Please fill in all required fields correctly.': 'Lütfen tüm zorunlu alanları doğru şekilde doldur.',
    'Failed to load incomes': 'Gelirler yüklenemedi',
    'Failed to delete income': 'Gelir silinemedi',
    'Failed to update income': 'Gelir güncellenemedi',
    'Start Date': 'Başlangıç Tarihi',
    'End Date': 'Bitiş Tarihi',
    'January': 'Ocak',
    'February': 'Şubat',
    'March': 'Mart',
    'April': 'Nisan',
    'May': 'Mayıs',
    'June': 'Haziran',
    'July': 'Temmuz',
    'August': 'Ağustos',
    'September': 'Eylül',
    'October': 'Ekim',
    'November': 'Kasım',
    'December': 'Aralık',
    'May 2026': 'Mayıs 2026',
    // Final Turkish dynamic keys
    'Total Expenses': 'Toplam Gider',
    'Total Incomes': 'Toplam Gelir',
    'Select expense categories': 'Gider kategorilerini seç',
    'Select income categories': 'Gelir kategorilerini seç',
    // Final property sweep
    'Please fill all fields correctly': 'Lütfen tüm alanları doğru şekilde doldur',
    'Please enter a valid amount greater than zero': 'Lütfen sıfırdan büyük geçerli bir tutar gir',
    'Failed to delete budget': 'Bütçe silinemedi',
    'Transaction Analytics': 'İşlem Analizleri',
    'Failed to initialize connectivity monitoring': 'Bağlantı takibi başlatılamadı',
    // Final newline/error sweep
    'Error loading expenses\n': 'Giderler yüklenirken hata oluştu\n',
    'Error loading incomes\n': 'Gelirler yüklenirken hata oluştu\n',
    'Error loading transaction data:\n': 'İşlem verileri yüklenirken hata oluştu:\n',
    'Error: ': 'Hata: ',

    // Added in full Turkish sweep
    'Indian Rupee': 'Hindistan Rupisi',
    'US Dollar': 'ABD Doları',
    'Euro': 'Euro',
    'British Pound': 'İngiliz Sterlini',
    'Japanese Yen': 'Japon Yeni',
    'Canadian Dollar': 'Kanada Doları',
    'Australian Dollar': 'Avustralya Doları',
    'Chinese Yuan': 'Çin Yuanı',
    'Swiss Franc': 'İsviçre Frangı',
    'Singapore Dollar': 'Singapur Doları',
    'Error loading expenses\\n': 'Giderler yüklenirken hata oluştu\\n',
    'Error loading incomes\\n': 'Gelirler yüklenirken hata oluştu\\n',
    'Error loading transaction data:\\n': 'İşlem verileri yüklenirken hata oluştu:\\n',
    'Rent Payment': 'Kira Ödemesi',
    'Groceries': 'Market Alışverişi',
    'Restaurant Dinner': 'Restoran Yemeği',
    'Fuel': 'Yakıt',
    'Movie Tickets': 'Sinema Biletleri',
    'Previous Rent': 'Önceki Kira',
    'Monthly Salary': 'Aylık Maaş',
    'Performance Bonus': 'Performans Bonusu',
    'Freelance Project': 'Freelance Proje',
    'Previous Salary': 'Önceki Maaş',
    'Dividend': 'Temettü',
    'Shopping': 'Alışveriş',
    'Education': 'Eğitim',
    'Travel': 'Seyahat',
    'Other': 'Diğer',
    'Day': 'Gün',
    'Week': 'Hafta',
    'Month': 'Ay',
    'Last 30 Days': 'Son 30 Gün',
    'Last 3 Months': 'Son 3 Ay',
    'Last 6 Months': 'Son 6 Ay',
    'Last 12 Months': 'Son 12 Ay',
    'All Time': 'Tüm Zamanlar',
    'Custom Range': 'Özel Aralık',
    'Insufficient Data': 'Yetersiz Veri',
    'Increasing': 'Artıyor',
    'Decreasing': 'Azalıyor',
    'Stable': 'Sabit',
    'N/A': 'Yok',
    'New password must be at least 6 characters': 'Yeni şifre en az 6 karakter olmalı',
    'Please enter a valid email address': 'Lütfen geçerli bir e-posta adresi gir',
    'Please enter a valid verification code': 'Lütfen geçerli bir doğrulama kodu gir',
    'Success! Your profile has been updated.': 'Başarılı! Profilin güncellendi.',
    'Incorrect password provided': 'Girilen şifre hatalı',
    'User not found': 'Kullanıcı bulunamadı',
    'This account has been disabled': 'Bu hesap devre dışı bırakılmış',
    'Too many requests. Try again later': 'Çok fazla istek gönderildi. Daha sonra tekrar dene',
    'This operation is not allowed': 'Bu işleme izin verilmiyor',
    'Invalid email format': 'E-posta formatı geçersiz',
    'Email is already in use by another account': 'Bu e-posta başka bir hesap tarafından kullanılıyor',
    'Password is too weak. Please use a stronger password': 'Şifre çok zayıf. Lütfen daha güçlü bir şifre kullan',
    'Please log in again to update your profile': 'Profilini güncellemek için lütfen tekrar giriş yap',
    'Network error. Please check your connection': 'Ağ hatası. Lütfen bağlantını kontrol et',
    'Unknown': 'Bilinmiyor',
    '% of Total': 'Toplamın %',
    '% of total': 'toplamın %',
    'Unknown Merchant': 'Bilinmeyen Satıcı',
    'Highest Spending Category': 'En Yüksek Harcama Kategorisi',
    'Average Daily Spending': 'Ortalama Günlük Harcama',
    'Lowest Spending Category': 'En Düşük Harcama Kategorisi',
    'No significant changes in spending patterns detected.': 'Harcama alışkanlıklarında belirgin bir değişim tespit edilmedi.',
    'Your financial command center with current balance card, quick actions, and recent transactions for immediate financial oversight': 'Güncel bakiye kartı, hızlı işlemler ve son hareketlerle finansını hızlıca kontrol edebileceğin merkez.',
    'Comprehensive financial analytics with balance summary, income vs expense visualization, budget tracking, and category analysis charts': 'Bakiye özeti, gelir-gider görselleştirmesi, bütçe takibi ve kategori analiz grafikleriyle kapsamlı finansal analiz.',
    'Full expense management with categorization, receipt scanning, recurring expenses, location tagging, and detailed search filtering': 'Kategorilendirme, fiş tarama, tekrarlayan giderler, konum etiketleme ve detaylı arama filtreleriyle tam gider yönetimi.',
    'Track multiple income sources with categorization, recurring income setup, tax category assignment, and goal progress tracking': 'Birden çok gelir kaynağını kategorilendirme, tekrarlayan gelir, vergi kategorisi ve hedef ilerlemesiyle takip et.',
    'Advanced spending analytics with interactive charts, yearly comparisons, trend identification, and custom report generation': 'Etkileşimli grafikler, yıllık karşılaştırmalar, trend tespiti ve özel raporlarla gelişmiş harcama analizi.',
    'Detailed month-by-month financial breakdown with month-over-month comparisons, spending patterns, and category highlights': 'Aydan aya karşılaştırmalar, harcama kalıpları ve kategori öne çıkanlarıyla detaylı aylık finansal döküm.',
    'Personalized budget creation with category-specific limits, visual progress tracking, custom timeframes, and spending alerts': 'Kategori bazlı limitler, görsel ilerleme takibi, özel dönemler ve harcama uyarılarıyla kişisel bütçe oluşturma.',
    'Create, customize, and organize expense and income categories with icons, colors, and detailed spending analytics': 'Gelir ve gider kategorilerini ikon, renk ve detaylı harcama analizleriyle oluştur, özelleştir ve düzenle.',
    'Manage personal information, currency preferences, notification settings, and app appearance with customization options': 'Kişisel bilgileri, para birimi tercihlerini, bildirimleri ve uygulama görünümünü özelleştirme seçenekleriyle yönet.',
    'Enhanced security with biometric authentication, data encryption, PIN protection, and privacy controls for sensitive information': 'Hassas bilgiler için biyometrik doğrulama, veri şifreleme, PIN koruması ve gizlilik kontrolleriyle gelişmiş güvenlik.',
    'Comprehensive support with in-app tutorials, searchable FAQ, video guides, email support, and community forum access': 'Uygulama içi rehberler, aranabilir SSS, video kılavuzlar, e-posta desteği ve topluluk erişimiyle kapsamlı destek.',
    'Seamless cloud synchronization with real-time updates, offline mode functionality, secure data backup, and multi-device access': 'Gerçek zamanlı güncellemeler, çevrimdışı kullanım, güvenli yedekleme ve çok cihaz erişimiyle sorunsuz bulut senkronizasyonu.',
    'AI-powered transaction analysis with anomaly detection, spending pattern insights, purchase trend visualization, and smart recommendations': 'Anomali tespiti, harcama kalıbı içgörüleri, satın alma trendleri ve akıllı önerilerle yapay zeka destekli işlem analizi.',
    'Are you a developer or designer? Join our community to contribute directly to the app.': 'Geliştirici veya tasarımcı mısın? Uygulamaya doğrudan katkı vermek için topluluğumuza katıl.',
    'Use the contact form above to suggest new features or improvements.': 'Yeni özellik veya iyileştirme önermek için yukarıdaki iletişim formunu kullan.',
    'Be the first to try new features and provide feedback.': 'Yeni özellikleri ilk deneyenlerden ol ve geri bildirim ver.',
    'Theme': 'Tema',
    'Choose light or dark theme': 'Açık veya koyu tema seç',
    'Avg': 'Ort',
    'Geç': 'Geç',
    'Akıllı Cüzdan Takibi': 'Akıllı Cüzdan Takibi',
    'Tam Kapsamlı Cep Ortağınız': 'Tam Kapsamlı Cep Ortağınız',
    'Başlıca Özellikler': 'Başlıca Özellikler',
    'Kontrol Paneli': 'Kontrol Paneli',
    'Toplam Bakiye': 'Toplam Bakiye',
    'Gelir': 'Gelir',
    'Gider': 'Gider',
    'Akıllı Takip': 'Akıllı Takip',
    'Güçlü ve Analitik': 'Güçlü ve Analitik',
    'Bütçe Belirleme': 'Bütçe Belirleme',
    'Bulut Senkronizasyonu': 'Bulut Senkronizasyonu',
    'Giderleri ve gelirleri otomatik olarak kategorize et.': 'Giderleri ve gelirleri otomatik olarak kategorize et.',
    'İnteraktif grafikler ve analizlerle trendleri görselleştirin.': 'İnteraktif grafikler ve analizlerle trendleri görselleştirin.',
    'Aylık bütçeler oluşturun ve harcama limitlerinizi takip edin.': 'Aylık bütçeler oluşturun ve harcama limitlerinizi takip edin.',
    'Verilerinize tüm cihazlarınızdan güvenli bir şekilde erişin.': 'Verilerinize tüm cihazlarınızdan güvenli bir şekilde erişin.',
    'Akıllı Finans': 'Akıllı Finans',
    'Finansal işlemlerinizi düzenlemek için yapay zeka destekli araçlar.': 'Finansal işlemlerinizi düzenlemek için yapay zeka destekli araçlar.',
    'İşlem Ekle': 'İşlem Ekle',
    'Aylık Özet': 'Aylık Özet',
    'Tasarruf': 'Tasarruf',
    'Bütçeye Genel Bakış': 'Bütçeye Genel Bakış',
    'Gider Takibi': 'Gider Takibi',
    'Akıllı Analitik': 'Akıllı Analitik',
    'İşlemleri kolayca kaydedin ve otomatik olarak kategorize edin.': 'İşlemleri kolayca kaydedin ve otomatik olarak kategorize edin.',
    'Harcama alışkanlıklarınız ve kalıplarınız hakkında bilgi edinin.': 'Harcama alışkanlıklarınız ve kalıplarınız hakkında bilgi edinin.',
    'Farklı gider kategorileri için bütçeler belirleyin ve takip edin.': 'Farklı gider kategorileri için bütçeler belirleyin ve takip edin.',
    'Veri Analizi': 'Veri Analizi',
    'Akıllı analizlerle harcamalarınızı görselleştirin.': 'Akıllı analizlerle harcamalarınızı görselleştirin.',
    'Gelişmiş Özellikler': 'Gelişmiş Özellikler',
    'Gider Analizi': 'Gider Analizi',
    'Kullanılan': 'Kullanılan',
    'Harcama Analizi': 'Harcama Analizi',
    'Bu ay yemek harcamalarınız geçen aya göre %15 daha az oldu.': 'Bu ay yemek harcamalarınız geçen aya göre %15 daha az oldu.',
    'Akıllı Kategorizasyon': 'Akıllı Kategorizasyon',
    'Harcama Analizleri': 'Harcama Analizleri',
    'Dışa Aktarma ve Raporlar': 'Dışa Aktarma ve Raporlar',
    'İşlemleri satıcı ve harcama alışkanlıklarına göre otomatik olarak kategorize edin.': 'İşlemleri satıcı ve harcama alışkanlıklarına göre otomatik olarak kategorize edin.',
    'Finansal durumunuzu optimize etmek için kişiselleştirilmiş bilgiler ve öneriler alın.': 'Finansal durumunuzu optimize etmek için kişiselleştirilmiş bilgiler ve öneriler alın.',
    'Ayrıntılı raporlar oluşturun ve verileri birden fazla formatta dışa aktarın.': 'Ayrıntılı raporlar oluşturun ve verileri birden fazla formatta dışa aktarın.',
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'tr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String tr(String text) => AppLocalizations.tr(text);
}
