# HidoVPN Android — Geliştirme Günlüğü

**Versiyon:** 2.3.0 (Derleme 6)
**Platform:** Android
**Framework:** Flutter 3.29.3 / Dart 3.7.2
**Son Güncelleme:** 14 Mayıs 2026

---

## Derleme Komutu

```bash
flutter pub get
flutter build apk --release --no-tree-shake-icons
```

> **NOT:** `lib/flutter_gen/gen_l10n/` dizinindeki dosyalar elle düzenlenmiştir. `flutter gen-l10n` çalıştırılırsa bu değişiklikler silinir. Yeni çeviri anahtarı eklenecekse hem ARB hem de gen_l10n dosyaları birlikte güncellenmelidir.

---

## ✅ YAPILAN DEĞİŞİKLİKLER (v1.0 → v2.3.0)

### Faz 1 — Temel Stabilite

| # | Sorun | Dosya | Durum |
|---|-------|-------|-------|
| B1 | Giriş ekranı alt kısım boş (Samsung dahil tüm cihazlar) | `login_screen.dart` | ✅ |
| B2 | Çıkış yapılınca VPN açık kalıyor | `auth_provider.dart`, `vpn_provider.dart` | ✅ |
| B3 | Hız göstergesi sürekli 0 KB/s | `vpn_provider.dart` | ✅ |
| B4 | Hysteria2 protokolü çöküyor | `api_service.dart`, `node_model.dart` | ✅ Filtrelendi |

### Faz 2 — Güvenlik ve Bağlantı

| # | Özellik | Dosya | Durum |
|---|---------|-------|-------|
| F2-1 | Kill Switch — Sahte toggle kaldırıldı, "Yakında" uyarısı eklendi | `settings_screen.dart` | ✅ |
| F2-2 | Otomatik Yeniden Bağlanma (3 deneme, artan bekleme süresi) | `vpn_provider.dart` | ✅ Gerçek |
| F2-3 | Token güvenli saklama (flutter_secure_storage, şifreli keystore) | `auth_provider.dart` | ✅ |
| F2-4 | Türkçe hata mesajları (API hatalarını lokalize et) | `auth_provider.dart` | ✅ |

### Faz 3 — UI/UX Modernizasyonu

| # | Özellik | Dosya | Durum |
|---|---------|-------|-------|
| M1 | Üst menü: Profil ikonu + Ayarlar ikonu + Dil değiştirme | `home_screen.dart` | ✅ |
| M2 | Sunucu bağlantı durumu: "Sunucuya Bağlı / Bağlı Değil" | `home_screen.dart` | ✅ Gerçek |
| M3 | Gerçek ağ tipi algılama: WiFi / Mobil Veri / İnternet Yok | `home_screen.dart` | ✅ connectivity_plus |
| M4 | Hızlı dil değiştirme (bayrak ikonu üst menüde) | `home_screen.dart` | ✅ |
| A1 | Ping gizleme (varsayılan kapalı, sadece renk noktası) | `servers_screen.dart` | ✅ |
| F3-1 | Animasyonlu floating navigasyon çubuğu | `main_nav_screen.dart` | ✅ |
| F3-2 | Açık tema renk uyumu (tüm metinler görünür) | `app_theme.dart` | ✅ |

### Faz 4 — Sunucu ve Profil

| # | Özellik | Dosya | Durum |
|---|---------|-------|-------|
| S1 | hidovpn.xyz adresi kaldırıldı | `servers_screen.dart`, `settings_screen.dart` | ✅ |
| S2 | Sunucu Bağlı 🟢 / Offline 🔴 durumu | `servers_screen.dart` | ✅ |
| P1 | Büyük avatar + durum rozeti (Aktif/Pasif) | `profile_screen.dart` | ✅ |
| P2 | Abonelik zaman çizelgesi + yüzde çubuğu | `profile_screen.dart` | ✅ |
| P3 | Veri kullanımı yüzde çubuğu | `profile_screen.dart` | ✅ |
| P4 | Cihaz kullanım çubuğu | `profile_screen.dart` | ✅ |

### Faz 5 — Hız Testi (Gerçek)

| # | Özellik | Dosya | Durum |
|---|---------|-------|-------|
| ST1 | Gerçek indirme hız testi (Cloudflare 10MB) | `home_screen.dart` | ✅ |
| ST2 | Gerçek yükleme hız testi (Cloudflare 1MB) | `home_screen.dart` | ✅ |
| ST3 | Ping ölçümü (TCP bağlantısı ile) | `home_screen.dart` | ✅ |

### Lokalizasyon

| Dil | Durum |
|-----|-------|
| Türkçe | ✅ Tam |
| Rusça | ✅ Tam |
| Türkmence | ✅ Tam |
| İngilizce | ✅ Tam |

---

## ❌ HENÜZ YAPILMAYANLAR (Sıradaki Fazlar)

### Kritik
- **Kill Switch (Gerçek):** Android sistem seviyesinde `lockdownEnabled=true` ile VPN servisi başlatılması gerekiyor. `flutter_v2ray_plus` paketi bunu desteklemiyor; native Kotlin kodu yazılması gerekiyor.
- **Hysteria2 Protokol Desteği:** `flutter_v2ray_plus` paketi Hysteria2'yi desteklemiyor. Gerçek destek için `hiddify-core` veya `sing-box` native entegrasyonu gerekiyor (büyük iş).
- **Foreground Service Bildirimi:** VPN bağlıyken telefon kilitlendiğinde bildirim gösterilmiyor.

### Önemli
- **DNS Sızıntı Koruması:** Ayarlarda toggle var ama arkasında implementasyon yok.
- **Akıllı Protokol Seçimi:** Otomatik en iyi protokolü seçme özelliği yok.
- **Bağlantı Geçmişi:** Geçmiş bağlantıları gösteren ekran yok.

### İyi Olur
- Unit ve widget testleri
- ProGuard/R8 optimizasyonu
- Production keystore imzalama

---

## Paket Bağımlılıkları

```yaml
dependencies:
  flutter_v2ray_plus: ^1.1.3       # VPN çekirdeği (VLESS/VMess/Trojan/SS)
  connectivity_plus: ^6.1.4        # Gerçek ağ tipi algılama
  flutter_secure_storage: ^9.2.4   # Şifreli token saklama
  provider: ^6.1.5                 # State management
  flutter_animate: ^4.5.2          # Animasyonlar
  shared_preferences: ^2.5.3       # Ayarlar saklama
  http: ^1.4.0                     # API istekleri
  percent_indicator: ^4.2.3        # Yüzde çubukları
  iconsax: ^0.0.8                  # İkonlar
  url_launcher: ^6.3.1             # Link açma
  package_info_plus: ^8.1.3        # Versiyon bilgisi
```

---

## Backend API

**Birincil:** `https://api.hidovpn.xyz`
**Yedek:** `http://94.183.159.227:8000`

| Endpoint | Method | Açıklama |
|----------|--------|---------|
| `/api/v1/auth/login` | POST | Giriş |
| `/api/v1/auth/logout` | POST | Çıkış |
| `/api/v1/auth/refresh` | POST | Token yenile |
| `/api/v1/user/profile` | GET | Profil |
| `/api/v1/user/nodes` | GET | Sunucu listesi |
| `/api/v1/user/connect` | POST | Bağlantı başladı |
| `/api/v1/user/disconnect` | POST | Bağlantı kesildi |
| `/api/v1/user/heartbeat` | POST | 60sn trafik raporu |
| `/api/v1/user/sessions` | GET | Aktif oturumlar |
| `/api/v1/app/version` | GET | Güncelleme kontrolü |

---

## Versiyon Geçmişi

| Versiyon | Tarih | Değişiklikler |
|----------|-------|--------------|
| v2.3.0 | Mayıs 2026 | Gerçek hız testi, güvenli token, Türkçe hatalar, Kill Switch uyarısı |
| v2.1.0 | Mayıs 2026 | Profil yenileme, sunucu durumu, ping gizleme, hidovpn.xyz kaldırıldı |
| v2.0.0 | Mayıs 2026 | Modern navigasyon, auto-reconnect, tema iyileştirme |
| v1.3.0 | Mayıs 2026 | Cihaz yönetimi + güncelleme sistemi |
| v1.2.0 | Mayıs 2026 | İlk Flutter sürümü |
