# PARO Cüzdan Upgrade Notları

Bu paket içinde eklenen başlıca geliştirmeler:

- Premium Dashboard V2
  - Gradient toplam bakiye kartı
  - Bu ay gelir/gider/net durum
  - Son 7 gün mini harcama grafiği
  - Akıllı içgörü kartı
  - Modern hızlı işlem grid'i
  - Birikim hedefleri ve abonelik önizleme kartları

- Yeni özellikler
  - Birikim hedefleri ekranı
  - Tekrarlayan gider / abonelik takip ekranı
  - Akıllı hatırlatıcı tercihleri ekranı
  - OCR sonucunda tahmini kategori önerisi
  - OCR fişini gider olarak kaydetme akışında kategori prefill

- UI polish
  - Profile item kartları dark mode uyumlu hale getirildi
  - Premium paywall tamamen PARO branding ile yenilendi
  - Reusable empty state component eklendi

Notlar:
- Birikim hedefleri, tekrarlayan giderler ve hatırlatıcı tercihleri SharedPreferences ile lokal tutulur.
- Gerçek cihaz bildirimi göndermek için flutter_local_notifications gibi native notification plugin yapılandırması ayrıca eklenebilir.
- Firebase package ID: com.glowuply.paro
