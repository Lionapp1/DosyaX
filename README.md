# DosyaX

**Modern, hızlı ve güvenli dosya yönetim & paylaşım platformu.**

Kullanıcıların gerçekten seveceği seviyede bir deneyim: temiz arayüz, gerçek ikonlar, akıcı animasyonlar, VIP sistemi, admin paneli, dosya önizleme, arama ve daha fazlası.

![License](https://img.shields.io/badge/license-MIT-blue)
![Stack](https://img.shields.io/badge/stack-Next.js%2015%20%7C%20TypeScript%20%7C%20Tailwind-black)

---

## Özellikler

### Kullanıcı
- Sürükle-bırak + çoklu dosya yükleme (progress + ETA)
- Klasör oluşturma, taşıma, kopyalama, silme, yeniden adlandırma
- Liste / Grid / Galeri görünümleri
- Anlık dosya önizleme (resim, video, PDF, TXT, kod)
- Gelişmiş arama + filtreler (tip, boyut, tarih, etiket)
- Paylaşım linkleri (süre sınırlı, şifreli, indirme limiti)
- Beğeni / şikayet sistemi
- VIP: sınırsız yükleme + tüm public dosyaları görme + öncelikli destek
- Dark / Light / System tema

### Admin
- Kullanıcı yönetimi (ban, VIP verme, limit ayarı)
- Dosya moderasyonu
- İstatistikler (yükleme, depolama, aktif kullanıcı)
- Sistem ayarları

### Teknik
- Modüler mimari (files, auth, sharing, admin, ui)
- Gerçek Lucide ikonları
- Responsive + erişilebilir (a11y)
- Type-safe API
- Hazır UI Kit (Button, Card, Dialog, Dropdown, Toast, Progress…)

---

## Stack

| Katman        | Teknoloji                          |
|---------------|------------------------------------|
| Framework     | Next.js 15 (App Router)            |
| Dil           | TypeScript                         |
| Stil          | Tailwind CSS + CSS Variables       |
| İkonlar       | Lucide React                       |
| UI Kit        | Custom (shadcn tarzı)              |
| State         | Zustand + React Query (planlanan)  |
| Auth          | NextAuth / custom JWT (planlanan)  |
| Storage       | Local / S3 uyumlu (planlanan)      |

---

## Hızlı Başlangıç

```bash
git clone https://github.com/Lionapp1/DosyaX.git
cd DosyaX
npm install
npm run dev
```

Tarayıcıda: [http://localhost:3000](http://localhost:3000)

---

## Proje Yapısı

```
src/
├── app/                    # Next.js App Router sayfaları
│   ├── (auth)/             # login / register
│   ├── (dashboard)/        # ana dosya yöneticisi
│   ├── admin/              # admin paneli
│   └── api/                # route handlers
├── components/
│   ├── ui/                 # UI Kit (Button, Input, Dialog…)
│   ├── files/              # FileGrid, FileList, UploadZone…
│   ├── layout/             # Sidebar, Header, CommandPalette
│   └── shared/             # ortak bileşenler
├── modules/                # domain modülleri
│   ├── files/
│   ├── auth/
│   ├── sharing/
│   └── admin/
├── lib/                    # utils, cn, constants
├── hooks/                  # custom hooks
├── types/                  # TypeScript tipleri
└── styles/                 # global CSS + tema
```

---

## Yol Haritası

- [x] Proje iskeleti + UI Kit + tema
- [ ] Dosya listesi / grid + temel CRUD
- [ ] Upload zone + progress
- [ ] Auth (login/register)
- [ ] Paylaşım linkleri
- [ ] VIP sistemi
- [ ] Admin paneli
- [ ] Önizleme drawer
- [ ] Arama + filtreler
- [ ] Mobil optimizasyon

---

## Katkı

PR’lar ve issue’lar memnuniyetle karşılanır. Önce bir issue açıp konuşalım.

---

**DosyaX** — Dosyalarını yönet, paylaş, kontrol et.
