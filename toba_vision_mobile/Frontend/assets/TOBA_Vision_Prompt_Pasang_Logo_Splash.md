# PROMPT: Pasang Logo & Splash Screen "TOBA Vision" ke Proyek APK

> Salin seluruh isi file ini sebagai prompt ke model AI. Lampirkan juga 3 file aset (lihat bagian 2) dan, kalau bisa, struktur folder proyek atau isi file konfigurasi utama (`pubspec.yaml`, `build.gradle`, `AndroidManifest.xml`, atau `app.json`).

---

## 1. PERAN & TUJUAN

Kamu adalah engineer mobile senior. Tugasmu: memasang **logo aplikasi (launcher icon)** dan **splash screen** ke proyek aplikasi Android bernama **TOBA Vision** (aplikasi deteksi tembakau berbasis kamera/AI), lalu memastikan keduanya tampil benar di build APK.

Bekerjalah teliti dan bertahap. Jangan mengubah hal di luar tugas ini.

## 2. ASET YANG DISEDIAKAN

| File | Ukuran | Fungsi |
|---|---|---|
| `icon_1024.png` | 1024x1024, background penuh | Ikon utama (legacy / Play Store / iOS) |
| `icon_foreground.png` | 1024x1024, **transparan** | Layer depan adaptive icon Android |
| `splash_1080x1920.png` | 1080x1920 portrait | Gambar splash screen penuh |

**Warna brand (pakai persis):**
- Background sage: `#A3AB8E`
- Hitam: `#0E0F0C`
- Hijau neon: `#9BE000`
- Oranye aksen: `#FF5A1F`

Letakkan aset asli di `assets/branding/` (atau folder aset yang sudah dipakai proyek). Jangan edit atau kompres ulang file aslinya.

## 3. LANGKAH 0: DETEKSI PROYEK DULU (WAJIB)

Sebelum menulis kode apa pun:

1. Cari tahu framework proyek dengan memeriksa file yang ada:
   - `pubspec.yaml` → **Flutter**
   - `app.json` / `app.config.js` + `package.json` → **React Native / Expo**
   - `build.gradle` + `app/src/main` tanpa dua di atas → **Android Native (Kotlin/Java)**
   - `capacitor.config.*` → **Capacitor/Ionic**
2. Baca versi `minSdk`, `targetSdk`, dan nama package.
3. Laporkan temuanmu dalam 3-5 baris, lalu lanjut ke jalur yang sesuai di bawah. **Jika framework tidak bisa dipastikan, tanyakan dulu, jangan menebak.**

## 4. JALUR A: FLUTTER

### 4.1 Launcher icon
Tambahkan di `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.0

flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/branding/icon_1024.png"
  adaptive_icon_background: "#A3AB8E"
  adaptive_icon_foreground: "assets/branding/icon_foreground.png"
  min_sdk_android: 21
```

Jalankan:
```bash
flutter pub get
dart run flutter_launcher_icons
```

### 4.2 Splash screen (dua lapis)
**Lapis 1: splash native** (muncul sangat singkat saat app dibuka; wajib sederhana karena Android 12+ hanya menampilkan ikon di tengah):

```yaml
dev_dependencies:
  flutter_native_splash: ^2.4.0

flutter_native_splash:
  color: "#A3AB8E"
  image: "assets/branding/icon_foreground.png"
  android_12:
    color: "#A3AB8E"
    icon_background_color: "#A3AB8E"
    image: "assets/branding/icon_foreground.png"
```

```bash
dart run flutter_native_splash:create
```

**Lapis 2: splash Flutter (gambar desain penuh)**: buat `lib/screens/splash_screen.dart` yang menampilkan `splash_1080x1920.png` memenuhi layar (`BoxFit.cover`, `alignment: Alignment.center`) di atas background `#A3AB8E`, tahan 2-3 detik (atau sampai model AI selesai dimuat), lalu pindah ke halaman utama dengan `pushReplacement` + fade transition. Daftarkan aset di `pubspec.yaml` bagian `flutter: assets:`.

## 5. JALUR B: ANDROID NATIVE

### 5.1 Launcher icon
1. Di Android Studio: *Right-click `res` → New → Image Asset* → pilih **Launcher Icons (Adaptive and Legacy)**.
   - Foreground layer: `icon_foreground.png`, Scaling: pastikan objek utama (daun) berada **di dalam safe zone 66% tengah**.
   - Background layer: Color `#A3AB8E`.
2. Atau manual, pastikan file berikut ada:
   - `res/mipmap-anydpi-v26/ic_launcher.xml` dan `ic_launcher_round.xml` (adaptive, berisi `<background>` warna `#A3AB8E` dan `<foreground>` ke drawable foreground; tambahkan `<monochrome>` untuk Android 13 jika memungkinkan)
   - PNG legacy di `mipmap-mdpi (48)`, `hdpi (72)`, `xhdpi (96)`, `xxhdpi (144)`, `xxxhdpi (192)` px, dibuat dari `icon_1024.png`
3. Pastikan `AndroidManifest.xml` memakai `android:icon="@mipmap/ic_launcher"` dan `android:roundIcon="@mipmap/ic_launcher_round"`.

### 5.2 Splash screen
- Gunakan **SplashScreen API** (`androidx.core:core-splashscreen`):
  - Theme `Theme.App.Starting` dengan `windowSplashScreenBackground` = `#A3AB8E` dan `windowSplashScreenAnimatedIcon` = foreground icon.
  - Panggil `installSplashScreen()` di `MainActivity.onCreate()` **sebelum** `super.onCreate()`.
- Untuk gambar desain penuh `splash_1080x1920.png`: buat `SplashActivity`/layar Compose berisi `ImageView` `scaleType="centerCrop"`, tahan 2-3 detik, lalu buka `MainActivity`. Taruh gambarnya di `res/drawable-nodpi/`.

## 6. JALUR C: REACT NATIVE / EXPO

```json
{
  "expo": {
    "name": "TOBA Vision",
    "icon": "./assets/branding/icon_1024.png",
    "splash": {
      "image": "./assets/branding/splash_1080x1920.png",
      "resizeMode": "cover",
      "backgroundColor": "#A3AB8E"
    },
    "android": {
      "adaptiveIcon": {
        "foregroundImage": "./assets/branding/icon_foreground.png",
        "backgroundColor": "#A3AB8E"
      }
    }
  }
}
```

Jika bukan Expo (bare RN), ikuti Jalur B untuk sisi native dan gunakan `react-native-bootsplash` untuk splash.

## 7. ATURAN PENTING (JANGAN DILANGGAR)

1. **Jangan ubah** nama package/applicationId, versi, signing config, atau logika deteksi tembakau.
2. **Jangan resize/kompres/edit** file aset asli. Boleh membuat salinan turunan untuk berbagai density.
3. Teks pada splash (`LOADING MODEL 64%`, `START SCAN`, `v1.0`) adalah **hiasan di dalam gambar**. Jangan menimpa dengan komponen UI duplikat. Kalau ingin loading asli, tampilkan indikator kecil di area bawah tanpa menutupi teks desain.
4. Jangan menambah dependency di luar yang disebut di prompt ini tanpa menjelaskan alasannya.
5. Jangan mengarang nama file, path, atau API. Kalau ragu, baca file proyek dulu atau tanya.
6. Ubah **seminimal mungkin** file yang sudah ada, dan tampilkan diff/ringkasan perubahan.

## 8. VERIFIKASI (WAJIB SEBELUM SELESAI)

Jalankan atau jelaskan cara menjalankan:

- [ ] Build berhasil: `flutter build apk --debug` / `./gradlew assembleDebug` / `npx expo prebuild && eas build` (sesuai framework)
- [ ] Ikon launcher tampil di home screen: bentuk bulat, kotak, dan squircle tidak terpotong (daun masih utuh)
- [ ] Ikon monochrome/themed (Android 13+) tidak rusak, jika diaktifkan
- [ ] Splash tampil penuh tanpa gepeng (rasio tidak berubah) di layar 16:9, 19.5:9, dan tablet
- [ ] Tidak ada flash putih/hitam antara splash native dan splash gambar penuh (warna transisi `#A3AB8E`)
- [ ] Android 12+ dan Android di bawah 12 sama-sama berjalan
- [ ] Mode gelap tidak mengubah warna splash/ikon secara tak terduga

Jika ada yang tidak bisa dites langsung, katakan terus terang bagian mana yang belum terverifikasi.

## 9. FORMAT JAWABAN YANG DIMINTA

1. **Hasil deteksi proyek** (framework, minSdk, package)
2. **Daftar file yang dibuat/diubah** (path lengkap)
3. **Kode/konfigurasi lengkap** per file, siap salin
4. **Perintah yang harus dijalankan** (berurutan)
5. **Hasil checklist verifikasi** (centang yang sudah, tandai yang belum)
6. **Catatan risiko** (jika ada), maksimal 5 poin

Mulai dari langkah 0 sekarang.
