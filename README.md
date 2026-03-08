# TPQ Link

Aplikasi mobile Flutter untuk manajemen **TPQ Futuhil Hidayah Wal Nikmah** — memudahkan pengelolaan santri, pembayaran SPP, infak/sedekah, pengeluaran, jurnal kas, dan pelaporan langsung dari genggaman.

## Fitur Utama

| Fitur | Keterangan |
|---|---|
| Login / QR Scan | Autentikasi admin via username+password atau scan QR |
| Dashboard | Ringkasan saldo, santri aktif, dan transaksi terbaru |
| Santri | CRUD data santri + riwayat pembayaran |
| Pembayaran SPP | Catat pembayaran bulanan per santri |
| Infak/Sedekah | Pencatatan pemasukan non-SPP |
| Pengeluaran | Catat pengeluaran operasional |
| Jurnal Kas | Lihat arus kas masuk/keluar lengkap |
| Notifikasi | Push notification untuk transaksi penting |
| Biometric | Kunci aplikasi dengan fingerprint / Face ID |
| Background Sync | Sinkronisasi data di latar belakang (WorkManager) |

## Stack Teknologi

- Flutter `^3.x` + Dart `^3.0`
- Provider (state management)
- HTTP + Certificate Pinning
- Flutter Secure Storage (token auth)
- WorkManager (background sync)
- Mobile Scanner (QR code)
- Local Auth (biometrics)

---

## Prasyarat

| Kebutuhan | Versi minimal |
|---|---|
| Flutter SDK | 3.10+ (stable) |
| Dart SDK | 3.0+ |
| Java JDK | 17+ |
| Android SDK | API 21+ (target API 34) |
| Android Studio / VS Code | terbaru |

---

## Cara Setup Cepat

### 1. Install semua kebutuhan

**Linux / macOS:**
```bash
chmod +x scripts/install.sh
./scripts/install.sh
```

**Windows (PowerShell sebagai Administrator):**
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force
.\scripts\install.ps1
```

**Windows (Command Prompt sebagai Administrator):**
```bat
scripts\install.bat
```

### 2. Konfigurasi signing key (sekali aja, untuk release build)

**Linux / macOS:**
```bash
./scripts/sign-apk.sh
```

**Windows PowerShell:**
```powershell
.\scripts\sign-apk.ps1
```

**Windows Command Prompt:**
```bat
scripts\sign-apk.bat
```

> Keystore disimpan di `scripts/keys.jks`. **Jangan di-commit & jangan sampai hilang** — tanpa keystore ini kamu tidak bisa update aplikasi di Play Store.

### 3. Build APK Release

| Tujuan | Linux/macOS | Windows PS | Windows CMD |
|---|---|---|---|
| APK universal | `./scripts/build-apk.sh` | `.\scripts\build-apk.ps1` | `scripts\build-apk.bat` |
| APK per ABI | `./scripts/build-apk.sh --split-per-abi` | `.\scripts\build-apk.ps1 -SplitPerAbi` | `scripts\build-apk.bat --split-per-abi` |
| AAB (Play Store) | `./scripts/build-apk.sh --aab` | `.\scripts\build-apk.ps1 -Aab` | `scripts\build-apk.bat --aab` |

Output APK: `build/app/outputs/flutter-apk/`  
Output AAB: `build/app/outputs/bundle/release/`

---

## Struktur Folder `scripts/`

```
scripts/
├── keys.jks           ← Keystore release signing (jangan di-commit!)
│
├── install.sh         ← Install Flutter, Java, Android SDK (Linux/macOS)
├── install.ps1        ← Install Flutter, Java, Android SDK (Windows PowerShell)
├── install.bat        ← Install Flutter, Java, Android SDK (Windows CMD)
│
├── sign-apk.sh        ← Generate keystore & key.properties (Linux/macOS)
├── sign-apk.ps1       ← Generate keystore & key.properties (Windows PS)
├── sign-apk.bat       ← Generate keystore & key.properties (Windows CMD)
│
├── build-apk.sh       ← Build APK/AAB release (Linux/macOS)
├── build-apk.ps1      ← Build APK/AAB release (Windows PS)
└── build-apk.bat      ← Build APK/AAB release (Windows CMD)
```

---

## Menjalankan untuk Development

```bash
# Install dependency
flutter pub get

# Jalankan di emulator / device terhubung
flutter run

# Hot reload aktif otomatis saat run
```

---

## Konfigurasi Server/API

URL server diatur saat login di dalam aplikasi (tidak di-hardcode).  
Pastikan backend [FutuhilHidayahwalNikmah](../FutuhilHidayahwalNikmah) sudah berjalan dan dapat diakses dari device.

---

## Troubleshooting Umum

| Masalah | Solusi |
|---|---|
| `flutter: command not found` | Jalankan `scripts/install.sh` atau tambahkan `~/flutter/bin` ke PATH |
| `keytool not found` | Install Java JDK 17+ dan pastikan `JAVA_HOME/bin` ada di PATH |
| Build gagal: `key.properties not found` | Jalankan `scripts/sign-apk.sh` terlebih dahulu |
| `Android license status unknown` | Jalankan `flutter doctor --android-licenses` |
| Biometric tidak muncul | Pastikan device mendukung biometrik dan sudah di-enroll |

---

## Keamanan

- Token JWT disimpan di **Flutter Secure Storage** (encrypted keystore Android).
- Certificate pinning aktif — request ke server lain akan ditolak.
- Kunci signing (`scripts/keys.jks`) **tidak boleh di-commit** ke version control.
- Tambahkan entri berikut ke `.gitignore` jika belum ada:
  ```
  scripts/keys.jks
  android/app/key.properties
  ```

---

## Lisensi

Milik TPQ Futuhil Hidayah Wal Nikmah. Penggunaan untuk keperluan internal organisasi.
