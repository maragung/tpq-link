# Sinkronisasi Perubahan: FutuhilHidayahwalNikmah → tpq-link

## Tanggal: 24 Maret 2026

### Perubahan Backend (Next.js) yang Mempengaruhi Flutter App

#### 1. **API `/api/dana` - Perubahan Source Data Pengeluaran**

**File:** `src/app/api/dana/route.js`

**Perubahan:**
- Total pengeluaran sekarang menggunakan data dari tabel `Pengeluaran` (data yang diinput user)
- Sebelumnya menggunakan data dari `JurnalKas` yang termasuk jurnal penyesuaian (ADJ)

**Dampak ke Flutter:**
- Flutter app di `/keuangan` akan otomatis menampilkan data yang benar
- **Tidak perlu update Flutter code** karena perubahan di backend API

**Endpoint yang berubah:**
```
GET /api/dana?tahun=2024
```

**Response sekarang:**
```json
{
  "success": true,
  "data": {
    "total_pengeluaran_tahun": 7178000,
    "jumlah_pengeluaran": 1,
    "ringkasan_bulanan": [
      {
        "bulan": 12,
        "pengeluaran": 7178000
      }
    ]
  }
}
```

---

#### 2. **API `/api/pengeluaran/[id]` - Edit Tanpa Jurnal ADJ**

**File:** `src/app/api/pengeluaran/[id]/route.js`

**Perubahan:**
- Edit pengeluaran TIDAK lagi membuat jurnal penyesuaian (ADJ)
- Hanya update tabel `Pengeluaran`
- Hapus pengeluaran otomatis membersihkan jurnal terkait

**Dampak ke Flutter:**
- Edit pengeluaran di Flutter akan lebih konsisten
- Tidak ada duplikasi jurnal
- **Tidak perlu update Flutter code**

---

#### 3. **Model `Admin` - PIN Encryption**

**File:** `src/lib/models/Admin.js`

**Perubahan:**
- PIN sudah di-hash dengan bcrypt (10 round)
- `toJSON()` method exclude field `pin` dan `password`
- PIN tidak akan pernah ter-expose di API response

**Dampak ke Flutter:**
- Flutter PIN input sudah aman (obscureText: true)
- **Tidak perlu update Flutter code**

---

### File Flutter yang Perlu Diperiksa

#### ✅ **Sudah Aman (No Changes Needed)**

| File | Status | Alasan |
|------|--------|--------|
| `lib/widgets/pin_dialog.dart` | ✅ Aman | PIN sudah masked (`obscureText: true`) |
| `lib/screens/keuangan/keuangan_screen.dart` | ✅ Aman | Menggunakan API yang sudah diperbaiki |
| `lib/screens/pengeluaran/pengeluaran_screen.dart` | ✅ Aman | CRUD menggunakan API yang benar |
| `lib/services/api_service.dart` | ✅ Aman | HTTP client tidak perlu diubah |

---

### Testing Checklist untuk Flutter App

Setelah pull perubahan dari backend:

#### 1. **Test Pengeluaran**
- [ ] Tambah pengeluaran baru → muncul di bulan yang benar
- [ ] Edit tanggal pengeluaran → pindah ke bulan yang benar
- [ ] Edit nominal pengeluaran → update dengan benar
- [ ] Hapus pengeluaran → hilang dari laporan

#### 2. **Test Keuangan**
- [ ] Total pengeluaran = data yang diinput (bukan jurnal)
- [ ] Ringkasan bulanan sesuai dengan tanggal pengeluaran
- [ ] Saldo kas benar

#### 3. **Test PIN**
- [ ] Input PIN masked (titik-titik)
- [ ] PIN tidak terlihat di network log
- [ ] Biometric login berfungsi

---

### Cara Build Flutter App

```bash
cd d:\git\tpq\tpq-link

# Clean build
flutter clean
flutter pub get

# Run di emulator/device
flutter run

# Build APK
flutter build apk --release

# Build App Bundle (Play Store)
flutter build appbundle --release
```

---

### API Endpoints yang Dipengaruhi

| Endpoint | Method | Perubahan | Status |
|----------|--------|-----------|--------|
| `/api/dana` | GET | Source data pengeluaran | ✅ Fixed |
| `/api/pengeluaran` | POST | Tidak ada | ✅ OK |
| `/api/pengeluaran/[id]` | PUT | Tidak buat ADJ journal | ✅ Fixed |
| `/api/pengeluaran/[id]` | DELETE | Cleanup ADJ journals | ✅ Fixed |
| `/api/admin/[id]` | GET | Exclude PIN from response | ✅ Fixed |

---

### Rollback Plan

Jika ada masalah:

1. **Revert backend changes:**
   ```bash
   cd d:\git\tpq\FutuhilHidayahwalNikmah
   git checkout HEAD -- src/app/api/dana/route.js
   git checkout HEAD -- src/app/api/pengeluaran/[id]/route.js
   ```

2. **Revert model changes:**
   ```bash
   git checkout HEAD -- src/lib/models/Admin.js
   ```

3. **Rebuild:**
   ```bash
   npm run build
   ```

---

### Contact

Jika ada pertanyaan atau issue terkait sinkronisasi ini, hubungi developer.
