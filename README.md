# DosyaX

**Telefonun gercek dosyalari** icin modern Android dosya yoneticisi (Flutter).

Hizli tarama, coklu secim, hizli erisim cipileri, tip filtreleri — Material 3.

![Flutter](https://img.shields.io/badge/Flutter-stable-02569B?logo=flutter)
![CI](https://img.shields.io/badge/CI-debug%20APK-success)

---

## Debug APK

1. [Actions](https://github.com/Lionapp1/DosyaX/actions) → **Build Debug APK**
2. Artifacts → `dosyax-debug-apk` → `app-debug.apk`
3. Telefona kur
4. Ilk acilista **Depolama / Dosyalari yonet** iznini ver (Android 11+)

```bash
flutter pub get
flutter run
# veya
flutter build apk --debug
```

---

## Ozellikler (v0.2)

- Gercek depolama: `/storage/emulated/0` ve alt klasorler
- Hizli erisim: Indirilenler, DCIM, Pictures, Movies, Music, Documents
- Izgara / liste, asagi cekerek yenile
- Anlik arama (klasor ici)
- Siralama: ad, boyut, tarih
- Filtre: resim, video, belge, ses
- Uzun bas: detay sayfasi — ac, paylas, yeniden adlandir, yol kopyala, sil
- Coklu secim: sil / paylas / tumunu sec
- Yeni klasor olustur
- Isolate ile klasor listeleme (UI donmaz)
- Izin ekrani (MANAGE_EXTERNAL_STORAGE + medya)

---

## Yapi

```
lib/
  main.dart
  models/file_item.dart
  services/storage_service.dart
  state/browser_controller.dart
  screens/home_screen.dart
  screens/permission_screen.dart
  widgets/file_tile.dart
```

---

**DosyaX** — gercek dosyalar, hizli yonetim.
