# PARO Cüzdan

PARO Cüzdan; gelir, gider, bütçe ve kategori takibi için hazırlanmış Flutter tabanlı kişisel finans uygulamasıdır.

## Paket bilgisi

- Android applicationId / namespace: `com.glowuply.paro`
- Görünen uygulama adı: `PARO Cüzdan`
- Ana renk: `#1D4ED8`
- Accent: `#22C55E`

## Build

Debug APK:

```bash
flutter clean
flutter pub get
flutter build apk --debug
```

Release APK için gerçek yayın anahtarı kullanmanız önerilir. Bu projede `android/key.properties` yoksa release build yerel test için debug keystore ile imzalanır.
