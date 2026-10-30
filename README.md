# DosyaX

**Android dosya yöneticisi** — Flutter + Material 3.

Telefon için debug APK, GitHub Actions ile otomatik üretilir.

![Flutter](https://img.shields.io/badge/Flutter-stable-02569B?logo=flutter)
![CI](https://img.shields.io/badge/CI-debug%20APK-success)

---

## Debug APK (GitHub Actions)

1. `main` branch’e push veya **Actions → Build Debug APK → Run workflow**
2. Workflow bitince **Artifacts** → `dosyax-debug-apk`
3. `app-debug.apk` indir, telefona yükle (bilinmeyen kaynaklar açık olsun)

Workflow dosyası: [`.github/workflows/build-debug-apk.yml`](.github/workflows/build-debug-apk.yml)

```bash
# Yerel build
flutter pub get
flutter build apk --debug
# Çıktı: build/app/outputs/flutter-apk/app-debug.apk
```

---

## Özellikler (v0.1)

- Material 3 açık / koyu tema
- Grid + liste görünümü
- Dosya tipi ikonları (klasör, resim, video, PDF, arşiv, kod…)
- Arama kutusu
- Yükle FAB (yakında gerçek storage)

---

## Stack

| Katman | Teknoloji |
|--------|-----------|
| UI | Flutter / Material 3 |
| Dil | Dart |
| CI | GitHub Actions → debug APK artifact |
| Platform | Android (`com.dosyax.app`) |

---

## Proje yapısı

```
lib/
  main.dart
  models/file_item.dart
  screens/home_screen.dart
  widgets/file_tile.dart
android/          # native Android
.github/workflows/build-debug-apk.yml
```

> Eski `src/` (Next.js denemesi) duruyor; asıl uygulama **Flutter**. İstersen sonra temizleriz.

---

## Yerel geliştirme

```bash
git clone https://github.com/Lionapp1/DosyaX.git
cd DosyaX
flutter pub get
flutter run
```

Gereksinim: Flutter SDK (stable), Android SDK, cihaz veya emülatör.

---

**DosyaX** — dosyalarını telefonda yönet.
