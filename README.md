# TPQ Link

Mobile application built with Flutter for managing **TPQ Futuhil Hidayah Wal Nikmah** — simplifying student management, SPP payments, infak/sedekah, expenses, cash journal, and reporting directly from your phone.

---

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Quick Setup](#quick-setup)
  - [1. Install Dependencies](#1-install-dependencies)
  - [2. Configure Signing Key](#2-configure-signing-key)
  - [3. Build APK / AAB](#3-build-apk--aab)
- [Running for Development](#running-for-development)
- [Project Structure](#project-structure)
- [Scripts Reference](#scripts-reference)
- [API / Server Configuration](#api--server-configuration)
- [Environment & Flavors](#environment--flavors)
- [Security](#security)
- [Troubleshooting](#troubleshooting)
- [Changelog](#changelog)
- [License](#license)

---

## Features

| Feature | Description |
|---|---|
| Login / QR Scan | Admin authentication via username + password or QR scan |
| Dashboard | Balance summary, active students, and recent transactions |
| Students (Santri) | CRUD student data + payment history |
| SPP Payment | Record monthly payments per student |
| Infak / Sedekah | Record non-SPP income |
| Expenses | Record operational expenses |
| Cash Journal | View complete cash inflow/outflow |
| Notifications | Push notifications for important transactions |
| Biometric Lock | Lock the app with fingerprint or Face ID |
| Background Sync | Background data synchronization via WorkManager |

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI Framework | Flutter `^3.x` + Dart `^3.0` |
| State Management | Provider |
| Networking | HTTP + Certificate Pinning |
| Secure Storage | Flutter Secure Storage (encrypted on Android keystore) |
| Background Tasks | WorkManager |
| QR Code | Mobile Scanner |
| Biometrics | Local Auth |
| Backend | [FutuhilHidayahwalNikmah](../FutuhilHidayahwalNikmah) |

---

## Prerequisites

| Requirement | Minimum Version |
|---|---|
| Flutter SDK | 3.10+ (stable channel) |
| Dart SDK | 3.0+ |
| Java JDK | 17+ |
| Android SDK | API 21+ (target API 34) |
| Android Studio / VS Code | Latest |
| Node.js *(optional, for scripts)* | 18+ |

> **Linux / WSL2**: Make sure `curl`, `unzip`, `git`, and `xz-utils` are installed before running the setup script.
>
> **Windows**: Run all PowerShell scripts as **Administrator**. Set execution policy first:
> ```powershell
> Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force
> ```

---

## Quick Setup

### 1. Install Dependencies

This step installs Flutter SDK, Java JDK, Android SDK, and all required packages automatically.

**Linux / macOS:**
```bash
chmod +x scripts/install.sh
./scripts/install.sh
```

**Windows PowerShell (as Administrator):**
```powershell
.\scripts\install.ps1
```

**Windows Command Prompt (as Administrator):**
```bat
scripts\install.bat
```

After installation, verify your setup:
```bash
flutter doctor -v
```

All checkmarks should be green before proceeding.

---

### 2. Configure Signing Key

> **Do this once only.** The keystore is stored at `scripts/keys.jks`.  
> **Never commit this file.** Without it, you cannot publish updates to the Play Store.

**Linux / macOS:**
```bash
chmod +x scripts/sign-apk.sh
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

What this script does:
- Generates `scripts/keys.jks` (RSA 2048-bit keystore)
- Creates `android/app/key.properties` (referenced by Gradle)
- Prompts you to set an alias, keystore password, and key password

> **Back up `scripts/keys.jks` and your passwords** in a password manager or secure storage. If lost, you cannot update the app on the Play Store.

---

### 3. Build APK / AAB

| Target | Linux / macOS | Windows PS | Windows CMD |
|---|---|---|---|
| Universal APK | `./scripts/build-apk.sh` | `.\scripts\build-apk.ps1` | `scripts\build-apk.bat` |
| APK per ABI *(smaller size)* | `./scripts/build-apk.sh --split-per-abi` | `.\scripts\build-apk.ps1 -SplitPerAbi` | `scripts\build-apk.bat --split-per-abi` |
| AAB *(Play Store upload)* | `./scripts/build-apk.sh --aab` | `.\scripts\build-apk.ps1 -Aab` | `scripts\build-apk.bat --aab` |

**Output locations:**

| Type | Path |
|---|---|
| APK (universal) | `build/app/outputs/flutter-apk/app-release.apk` |
| APK per ABI | `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` etc. |
| AAB | `build/app/outputs/bundle/release/app-release.aab` |

**ABI suffixes:**

| File | Device |
|---|---|
| `app-arm64-v8a-release.apk` | Modern 64-bit Android (recommended) |
| `app-armeabi-v7a-release.apk` | Older 32-bit ARM devices |
| `app-x86_64-release.apk` | x86 emulators / Chromebook |

---

## Running for Development

```bash
# Install Flutter dependencies
flutter pub get

# List connected devices
flutter devices

# Run on connected device or emulator
flutter run

# Run on a specific device
flutter run -d <device-id>

# Run in release mode (no debug overhead)
flutter run --release

# Hot reload is active automatically during `flutter run`
# Press: r = hot reload | R = hot restart | q = quit
```

---

## Project Structure

```
tpq-link/
├── android/                    ← Android project files
│   └── app/
│       ├── key.properties      ← Signing config (DO NOT commit)
│       └── build.gradle
├── ios/                        ← iOS project files
├── lib/
│   ├── main.dart               ← App entry point
│   ├── models/                 ← Data models
│   ├── providers/              ← State management (Provider)
│   ├── screens/                ← UI screens
│   │   ├── login/
│   │   ├── dashboard/
│   │   ├── santri/
│   │   ├── pembayaran/
│   │   ├── infak/
│   │   ├── pengeluaran/
│   │   └── jurnal/
│   ├── services/               ← API, auth, background sync
│   ├── utils/                  ← Helpers, constants
│   └── widgets/                ← Reusable UI components
├── assets/
│   ├── images/
│   └── fonts/
├── scripts/
│   ├── keys.jks                ← Keystore (DO NOT commit)
│   ├── install.sh / .ps1 / .bat
│   ├── sign-apk.sh / .ps1 / .bat
│   └── build-apk.sh / .ps1 / .bat
├── test/                       ← Unit & widget tests
├── pubspec.yaml                ← Flutter dependencies
├── .env.example                ← Environment variable template
└── README.md                   ← This file
```

---

## Scripts Reference

```
scripts/
├── keys.jks            ← Keystore for release signing (DO NOT commit!)
│
├── install.sh          ← Install Flutter, Java, Android SDK (Linux/macOS)
├── install.ps1         ← Install Flutter, Java, Android SDK (Windows PS)
├── install.bat         ← Install Flutter, Java, Android SDK (Windows CMD)
│
├── sign-apk.sh         ← Generate keystore + key.properties (Linux/macOS)
├── sign-apk.ps1        ← Generate keystore + key.properties (Windows PS)
├── sign-apk.bat        ← Generate keystore + key.properties (Windows CMD)
│
├── build-apk.sh        ← Build APK/AAB release (Linux/macOS)
├── build-apk.ps1       ← Build APK/AAB release (Windows PS)
└── build-apk.bat       ← Build APK/AAB release (Windows CMD)
```

### Script Flags

| Flag | `build-apk.sh` | `build-apk.ps1` | `build-apk.bat` | Effect |
|---|---|---|---|---|
| Default (no flag) | `./build-apk.sh` | `.\build-apk.ps1` | `build-apk.bat` | Universal APK |
| Split by ABI | `--split-per-abi` | `-SplitPerAbi` | `--split-per-abi` | 3 separate APKs by architecture |
| Play Store bundle | `--aab` | `-Aab` | `--aab` | Android App Bundle (.aab) |

---

## API / Server Configuration

The server URL is configured at login time inside the app — it is **not hardcoded**.

Make sure the backend [FutuhilHidayahwalNikmah](../FutuhilHidayahwalNikmah) is running and accessible from the device before using the app.

**For development**, use your machine's local IP address (not `localhost` or `127.0.0.1` — those won't work from a physical device on the same network):

```
http://192.168.x.x:<port>
```

**For production**, use your domain with HTTPS:
```
https://api.yourdomain.com
```

> Certificate pinning is active. If you change your server's SSL certificate, update the pinned certificate in `lib/services/http_service.dart`.

---

## Environment & Flavors

Copy `.env.example` to `.env` and fill in your values:

```env
# Backend API base URL (set at runtime, but can pre-fill for dev)
API_BASE_URL=http://192.168.1.x:8000

# App flavor: development | staging | production
APP_FLAVOR=development

# Enable debug logging: true | false
DEBUG_LOGGING=true
```

> `.env` is not committed to version control. Add it to `.gitignore`.

---

## Security

| Concern | Implementation |
|---|---|
| Auth tokens | Stored in **Flutter Secure Storage** (Android encrypted keystore, iOS Keychain) |
| Network | **Certificate pinning** — requests to unknown servers are rejected |
| App lock | **Biometric authentication** (fingerprint / Face ID) via Local Auth |
| Signing key | `scripts/keys.jks` — **never commit**, back up securely |
| Key properties | `android/app/key.properties` — **never commit** |

### Required `.gitignore` entries

Make sure your `.gitignore` contains:

```gitignore
# Signing
scripts/keys.jks
android/app/key.properties

# Environment
.env

# Flutter build output
build/
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
```

---

## Troubleshooting

| Problem | Solution |
|---|---|
| `flutter: command not found` | Run `scripts/install.sh` or add `~/flutter/bin` to `PATH` |
| `keytool: command not found` | Install Java JDK 17+ and add `$JAVA_HOME/bin` to `PATH` |
| Build failed: `key.properties not found` | Run `scripts/sign-apk.sh` first |
| `Android license status unknown` | Run `flutter doctor --android-licenses` and accept all |
| Biometric not showing | Ensure the device supports biometrics and has enrolled a fingerprint/face |
| Device not detected | Enable **USB Debugging** in Android Developer Options |
| `CERTIFICATE_VERIFY_FAILED` | Server SSL cert changed — update pinned cert in `lib/services/http_service.dart` |
| APK installs but can't connect to server | Use your machine's LAN IP, not `localhost` or `127.0.0.1` |
| `Gradle build daemon disappeared` | Run `cd android && ./gradlew --stop` then rebuild |
| `MissingPluginException` for biometrics | Run `flutter clean && flutter pub get` then rebuild |
| Hot reload not working | Press `R` for hot restart, or stop and re-run `flutter run` |
| Background sync not triggering | Check battery optimization settings — disable optimization for this app |
| QR scan camera not opening | Grant **Camera** permission in device settings |

---

## Changelog

### v1.0.0 — Initial Release
- Student (santri) CRUD with payment history
- SPP monthly payment recording
- Infak/Sedekah income recording
- Operational expense recording
- Cash journal with full inflow/outflow view
- Dashboard with balance summary and recent transactions
- Admin login with username + password
- QR code scan login
- JWT authentication with Flutter Secure Storage
- Certificate pinning
- Biometric app lock (fingerprint / Face ID)
- Push notifications for important transactions
- Background sync via WorkManager
- Release APK build scripts for Linux, macOS, and Windows

---

## License

Property of TPQ Futuhil Hidayah Wal Nikmah.  
For internal organizational use only.
