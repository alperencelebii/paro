# PARO Comfort UX Upgrade

Bu paket kullanıcıyı yormayan, verileri ekrana sığdıran ve sakin finans takibi hissi veren son düzenlemeleri içerir.

## Eklenenler

- Günlük durum kartı: kullanıcının bugünkü harcama durumunu sakin bir dille özetler.
- Rahat öneriler: harcama davranışına göre yargılamayan, uygulanabilir mini öneriler üretir.
- Kullanışlı bildirim kartı: spam hissi vermeyen, pozitif ve kritik uyarıları öne çıkaran dashboard alanı.
- Tek dokunuşla hızlı kayıt alanı: kahve, market ve ulaşım gibi hızlı gider önerileri.
- Finansal rahatlık skoru: gelir-gider dengesini 100 üzerinden sade bir skorla gösterir.
- Bildirim ayarları genişletildi: rahat ton, pozitif ilerleme ve günlük bildirim sınırı eklendi.
- Dashboard overflow güvenliği: metinler FittedBox, ellipsis, Wrap ve responsive grid ile korundu.
- Genel text scale clamp: çok büyük sistem yazı ayarlarında sarı/siyah overflow riskini azaltır.
- Profil istatistikleri overflow güvenliği: bakiye ve işlem sayısı uzun değerlerde taşmaz.

## Tasarım Prensibi

PARO kullanıcıyı suçlayan değil, rahatlatan bir finans asistanı gibi davranır:

- Az bildirim
- Kısa öneri
- Pozitif ton
- Büyük ve okunaklı kartlar
- Sade grafikler
- Taşmayan responsive layout

## Build

```bash
flutter clean
flutter pub get
flutter build apk --debug
```

Release için:

```bash
flutter build apk --release
```

Not: Gerçek cihaz push/local notification için ayrıca native notification paketi kurulabilir. Bu paket, bildirim mantığını ve kullanıcı ayarlarını uygulama içinde hazırlar.
