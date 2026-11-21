Kamu adalah senior Flutter engineer sekaligus art director mobile. Tugasmu: mendesain ulang (RESTYLE) seluruh layar aplikasi Flutter "TOBA VISION" yang kulampirkan (folder `screens/`, 14 file .dart) dengan GAYA VISUAL dari gambar referensi yang kulampirkan (halaman produk retro bergaya walkman / tape-deck Y2K). Yang berubah hanya tampilan. Logika, alur navigasi, dan struktur data tidak boleh berubah.

==================================================
0. KONTEKS APLIKASI
==================================================
TOBA VISION adalah "Asisten AI Cerdas Petani Tembakau Modern" untuk petani di Temanggung, Jawa Tengah. Fitur utama:
- Deteksi AI: pindai mutu/kematangan daun tembakau lewat kamera atau unggah foto.
- Cuaca: prakiraan cuaca kebun dan status aman/tidak aman untuk menjemur daun.
- Keuangan: buku kas biaya musim tanam (buruh, pupuk, bibit/olah lahan, lainnya), tutup buku musim, arsip semua musim.
- Panen: monitoring siklus petikan daun (P1, P2, P3, dst.), berat (kg), pendapatan, BEP, target laba, tutup buku siklus, arsip semua musim.
Seluruh teks UI dalam Bahasa Indonesia dan tetap Bahasa Indonesia. Target pengguna: petani, jadi teks harus besar, kontras tinggi, dan jelas.

Saat ini tampilan aplikasi: hijau tua (#004C22, #064E3B), latar #F7F9FB, kartu putih bersudut 16-24, font serif kustom (konstanta `kSerif`) dan `monospace`.

==================================================
1. ATURAN KERAS (JANGAN DILANGGAR)
==================================================
1. JANGAN ubah logika bisnis, state, controller, timer, kamera, image_picker, dialog konfirmasi, snackbar, maupun teks isi data dummy (angka Rp, tanggal, nama petani, dsb.).
2. JANGAN ubah nama class, nama file, constructor, parameter, dan signature publik. Contoh yang harus tetap sama:
   - `SplashScreen({Duration duration})`, `LoginScreen`, `RegisterScreen`, `Shell`, `HomeScreen({required onNavigate})`
   - `DetectionScreen({onBack})`, `FinanceScreen`, `FinanceScreenEditUpload`, `FinanceEndScreen`, `FinanceAllMusimScreen`
   - `HarvestScreen`, `HarvestEditScreen`, `HarvestAllMusimScreen`, `WeatherScreen`
3. JANGAN ubah alur navigasi: Splash -> Login -> (Register) -> Shell (5 tab: 0 Beranda, 1 Deteksi, 2 Keuangan, 3 Panen, 4 Cuaca) beserta semua `Navigator.push/pop/pushReplacement/pushAndRemoveUntil` yang ada.
4. JANGAN ubah pemanggilan data: `Services.user.getProfile()`, `Services.weather.getWeather()`, model `UserProfile`, `WeatherData`, `WeatherSlot`, `WeatherKind`, serta `AsyncView<T>`.
5. Jangan menghapus fitur atau elemen interaktif apa pun. Boleh mengganti bentuk visualnya.
6. Pertahankan CustomPainter yang sudah ada (`_RingProgressPainter`, `_AllSeasonsRingProgressPainter`), tetapi boleh diubah warna/gayanya.
7. Warna SEMANTIK status tetap bermakna: aman/sukses = hijau, bahaya/hapus/error = merah, peringatan = amber. Boleh disesuaikan nuansanya dengan palet baru, tetapi jangan dibuat ambigu.
8. Kompatibel dengan Flutter stable terbaru (kode saat ini memakai `Color.withValues(alpha:)`). Null-safety penuh, tanpa error analyzer, tanpa warning deprecated.

==================================================
2. ARAH VISUAL (DARI GAMBAR REFERENSI)
==================================================
Ambil dari gambar: gaya retro-futuristik / Y2K tape-deck / walkman product page.
- Latar hijau sage pudar berbutir (grain film), semua konten berada di dalam "frame" kartu besar bersudut membulat kecil.
- Tipografi hitam raksasa, wide dan heavy, yang terpotong di tepi layar.
- Banyak microtext teknis uppercase monospace (kode seri, nomor ID, label "TYPE 1 NORMAL POSITION", "IDENTIFICATION NUMBER").
- Ornamen runcing hitam (blade/swoosh) dan garis divider dengan segmen tebal-tipis dan segitiga yang mengecil.
- Satu tombol CTA oranye berbentuk trapesium (sisi miring) yang menempel di tepi bawah, bertuliskan "----TEKS----".
- Objek hero transparan bergaya clear-shell plastik dengan tint hijau lime dan stiker label kertas gading.
Jangan menyalin merek, logo, atau teks persis dari gambar. Ambil gaya, komposisi, palet, dan tipografinya saja.

OBJEK HERO PENGGANTI: ganti objek di tengah (kaset/walkman di referensi) dengan SMARTPHONE clear-shell (bodi plastik transparan, tint lime, sedikit miring ~10 derajat) yang layarnya menampilkan bingkai pemindai (viewfinder) dengan siluet daun tembakau. Buat dengan widget Flutter (Container + CustomPainter + gradient), TANPA aset gambar eksternal. Siapkan juga parameter opsional `imageProvider` agar nanti bisa diganti dengan PNG transparan render sendiri.

==================================================
3. DESIGN TOKENS
==================================================
Warna dasar baru (perkiraan dari gambar):
- sage (latar utama)      : #9CA882
- sageDeep (latar kedua)  : #8A9770
- ink (hitam)             : #141414
- lime (aksen/tint kaca)  : #86D12A
- limeDeep                : #4C7A12
- orange (CTA, harga, highlight) : #F2590F
- paper (stiker/kartu)    : #E9E6D8
- glass                   : rgba(235,245,225,0.35)
Warna semantik (disesuaikan agar serasi di atas sage/paper):
- success #2F7D32 / bahaya #C62828 (soft #F6D5CF) / amber #E08A00 (soft #F5E3B8)

Efek global:
- Grain: overlay noise (CustomPainter dengan titik acak ber-seed, atau shader/ImageFilter ringan) opacity 0.12-0.20, `IgnorePointer`, di atas semua konten. Wajib ringan untuk HP kelas menengah: render sekali lalu cache dengan `RepaintBoundary`, jangan repaint tiap frame.
- Frame: kartu utama bersudut radius 10-12, margin 8-12 dari tepi layar, latar putih bersih di luar frame (seperti referensi).

Tipografi (gunakan paket `google_fonts` ATAU bundel font di assets, pilih yang paling aman dan jelaskan di langkah setup):
- Display raksasa: "Anybody" (wdth lebar, wght 900) atau fallback "Dela Gothic One".
- Microtext/label/angka teknis: "Space Mono" (uppercase, letterSpacing ~0.5).
- Teks isi: "Space Grotesk" atau "DM Sans", minimal 14sp supaya terbaca petani.
- Wordmark TOBA VISION: gaya chrome/outlined graffiti-blackletter dibuat dengan `Text` + `Paint..style = PaintingStyle.stroke` + gradient metalik (ShaderMask), atau CustomPainter.
Ganti seluruh pemakaian `kSerif` dan `'monospace'` dengan font baru lewat TextTheme/konstanta di theme (jangan hardcode di tiap layar).

==================================================
4. KOMPONEN REUSABLE YANG HARUS DIBUAT (file baru: `lib/widgets/retro/`)
==================================================
1. `RetroFrame` : frame sage bersudut membulat + grain overlay + child.
2. `GrainOverlay` : noise ringan ter-cache.
3. `MicroText` : teks mono kecil uppercase dengan variasi (label, kode seri).
4. `BladeOrnament` / `TaperedDivider` : ornamen runcing & garis divider ala referensi (CustomPainter). Di tengah divider boleh ada microtext.
5. `RetroCard` : kartu gaya J-card / label kaset: latar paper, border ink 2px, radius kecil, bayangan keras offset (6,6) warna ink, tanpa blur.
6. `TrapezoidTabButton` : tombol CTA oranye trapesium (ClipPath/CustomClipper) teks "----LABEL----", efek tekan (translate 2px), dukungan state disabled & loading.
7. `StatusChip` : label hitam kecil / outline untuk status (P3 AKTIF, BEP TERCAPAI, dsb.).
8. `VuMeterBar` : progress bar bergaya equalizer/VU meter dengan 12-20 segmen (lime -> orange -> merah di ujung). Dipakai untuk persentase.
9. `ReelLoader` : dua reel kaset berputar sebagai loading state (CustomPainter + AnimationController).
10. `MarqueeText` : teks raksasa berjalan horizontal, tak berujung, terpotong di tepi (SingleTickerProviderStateMixin; hormati reduce-motion).
11. `GlassPhone` : objek hero smartphone clear-shell dengan stiker label.
12. `ChromeWordmark` : logo teks TOBA VISION bergaya krom.

==================================================
5. FILE PENDUKUNG YANG TIDAK KULAMPIRKAN
==================================================
File berikut dipakai oleh layar tetapi TIDAK ada di zip: `core/theme.dart`, `widgets/app_header.dart`, `widgets/bottom_nav.dart`, `widgets/async_view.dart`, `widgets/app_logo.dart`, `data/models.dart`, `data/services.dart`.
Buatkan versi BARU untuk `core/theme.dart`, `app_header.dart`, `bottom_nav.dart`, `async_view.dart`, `app_logo.dart` dengan API yang KOMPATIBEL dengan pemakaian di layar, yaitu:
- `AppColors`: forest, green, ink, muted, line, mint, peach, amber, amberSoft, red, redSoft (pertahankan SEMUA nama ini, ganti nilainya ke palet baru; tambahkan sage, lime, orange, paper, dst.).
- `cardDeco({double radius})` mengembalikan BoxDecoration (ubah jadi gaya RetroCard tetapi tetap bisa dipakai `Container(decoration: cardDeco(radius: 24))`).
- `kSerif` (pertahankan nama konstanta, arahkan ke font display/teks baru agar layar lama tidak error) dan `greeting()` (Selamat pagi/siang/sore/malam + logika yang sama).
- `AppHeader({subtitle, padding, height, logoSize, logoIcon, logoBg, logoColor, useAppLogo, trailing})` dan `AppHeaderActionButton({icon, onTap})`.
- `AppBottomNav({index, onTap})` dengan 5 tab: Beranda, Deteksi, Keuangan, Panen, Cuaca (ikon sama dengan fitur di Home: local_florist, payments, agriculture, wb_sunny).
- `AsyncView<T>({load, builder})` dengan loading memakai `ReelLoader`, error state yang ramah, dan tombol coba lagi.
- `TobaVisionLogo({size, elevation})`.
Untuk `data/models.dart` dan `data/services.dart`: JANGAN dibuat ulang. Anggap tetap ada dan tidak berubah.

==================================================
6. SPESIFIKASI PER LAYAR
==================================================
Gunakan lebar acuan 360-430dp, dukung layar kecil (320dp) tanpa overflow, dan semua konten bisa discroll jika perlu.

6.1 `splash_screen.dart`
- Latar sage + grain. Wordmark TOBA VISION krom di tengah atas, dengan GlassPhone miring di tengah dan teks raksasa hitam "TOBA VISION" bergerak (marquee) di belakangnya, terpotong di tepi.
- Microtext bawah: "TOBA-VISION v2.4 AI", "TEMANGGUNG, JATENG", "IDENTIFICATION NUMBER - TB-2026-088".
- Pertahankan: timer 2,5 dtk, tap untuk lewati, transisi fade 600ms, SystemUiOverlayStyle transparan (sesuaikan brightness ikon status bar dengan latar baru: ikon gelap), dan fallback jika aset `assets/splash screen.png` ada/tidak (jika aset ada boleh tetap jadi layer paling bawah dengan opacity rendah).

6.2 `login_screen.dart`
- Header ala referensi: kiri microtext "PETANI MITRA / TB-LOGIN", tengah wordmark krom, kanan "TYPE 1 NORMAL POSITION".
- Hero: GlassPhone kecil + teks raksasa "MASUK" di belakang.
- Kartu hero brand (logo + "TOBA VISION" + badge "v2.4 AI" + "Asisten AI Cerdas Petani Tembakau Modern") menjadi RetroCard bergaya stiker.
- Form "Nomor HP / Username Petani (ID Unik)" dan "Kata Sandi" dalam RetroCard: field kotak dengan border ink 2px, label mono uppercase, ikon phone/lock, toggle lihat sandi. Default identifier '081234567890' (menjamin tidak ada konflik nama yang sama dan kompatibel dengan Firebase Auth).
- Tombol "Masuk ke Kebun" menjadi TrapezoidTabButton oranye di bawah ("----MASUK KE KEBUN----"). Link "Belum punya akun? Daftar Akun Baru" tetap, berbentuk teks mono bergaris bawah.

6.3 `register_screen.dart`
- Struktur dan gaya sama dengan Login. Field: Nama Lengkap, Nomor WhatsApp / HP (ID Unik Akun - untuk login & kontak darurat BMKG), Alamat Lahan / Lokasi Kebun (+ helper "Alamat digunakan untuk integrasi cuaca & data lahan"), Luas Lahan Kebun (satuan baku: Meter Persegi / m²), Kata Sandi, Konfirmasi Kata Sandi.
- Kartu info keamanan "Data akun tersimpan aman dan terenkripsi di perangkat untuk akses tanpa sinyal." menjadi strip label dengan ikon shield.
- Validasi sandi cocok/tidak (ikon check) tetap, dengan styling baru.
- CTA: "----DAFTAR AKUN SEKARANG----"; link "Sudah punya akun? Masuk Sekarang".

6.4 `shell.dart` + bottom nav
- Scaffold tetap, `SafeArea(bottom: false)`, `AppBottomNav` baru: bar hitam/sage bergaya tombol fisik tape-deck (play/stop/rewind feel), tab aktif ditandai blok oranye trapesium kecil dan label mono. Ikon + label selalu tampil.
- Latar semua tab: sage + grain, konten di dalam RetroFrame.

6.5 `home_screen.dart`
- Header: kiri logo + "TEMANGGUNG, JATENG" (mono), kanan tombol profil (ikon person) membuka bottom sheet.
- Sapaan `${greeting()}, ${p.name}` dalam tipografi display besar. Baris kelompok/region (`${p.group} • ${p.region}`) sebagai microtext dengan ikon groups.
- Judul "Fitur Utama Lapangan" + "Akses Cepat" (mono kecil di kanan) dengan TaperedDivider.
- Grid 2x2 fitur (Deteksi AI, Cuaca, Keuangan, Panen) menjadi 4 RetroCard bergaya kaset: nomor seri "01-04" mono kecil, ikon dalam kotak, judul + subjudul. Tap -> `onNavigate(tabIndex)` sama seperti sekarang.
- Banner AI ("AI Vision Standar SNI", "Pindai Mutu Daun Tembakau", deskripsi, tombol "Buka Kamera AI") menjadi blok hero: kartu hijau lime gelap dengan GlassPhone miring menimpa teks display raksasa, dan CTA trapesium oranye "----BUKA KAMERA AI----" yang memanggil `onTap` (pindah ke tab 1).
- Bottom sheet profil: gaya kartu paper bersudut atas membulat; tetap ada: handle, "Profil Petani", kartu avatar + verified + "ID: TB-2026-088 • Petani Mitra Aktif", baris Nama Lengkap dan Alamat/Domisili Lahan, tombol log out merah dengan dialog konfirmasi "Konfirmasi Keluar" + snackbar + `pushAndRemoveUntil` ke LoginScreen. Semua logika tetap.

6.6 `detection/detection_screen.dart` (layar paling penting)
- Pertahankan semua logika kamera (CameraController, ResolutionPreset.high, flash, switch fallback jika kamera belum siap), `image_picker` dari galeri, AnimationController garis pindai, dan snackbar "Pemindaian daun tembakau selesai!" / error.
- Lapisan: preview kamera (atau fallback gradien gelap bernoise), vignette, header, kartu status AI, viewfinder 256x288 di tengah, pill instruksi, aksi bawah.
- Header: tombol kembali (`widget.onBack`) dan tombol flash dalam bentuk tombol fisik hitam bulat bertepi lime; judul "Pindai Daun Tembakau" + "Deteksi Otomatis AI Toba Vision" dalam mono.
- Kartu status AI ("AI ACTIVE SCAN", "Arahkan kamera ke daun tembakau") menjadi label paper bergaya stiker dengan titik REC berkedip.
- Viewfinder: sudut siku tebal warna lime (CustomPainter), garis pindai lime bergerak naik-turun (ikuti animasi yang sudah ada), tick marks/skala di tepi seperti layar alat ukur, label "POSISIKAN DAUN". Tampilkan hasil/penanda ala HUD (microtext kode seri) tanpa mengubah logika.
- Pill instruksi: "Posisikan daun di dalam bingkai" / "Pastikan pencahayaan cukup terang".
- Aksi bawah (tetap 3 aksi): "Unggah foto" (galeri), "Ambil Foto"/"Pindai AI" (tombol utama), "Memindai" (state saat proses). Tombol utama = TrapezoidTabButton oranye "----PINDAI AI----", tombol sekunder = tombol fisik kotak bergaya tape-deck. State loading memakai ReelLoader kecil.

6.7 `weather/weather_screen.dart`
- Header "TEMANGGUNG, JATENG" + tombol sync (snackbar "Prakiraan cuaca kebun berhasil diperbarui!").
- Sapaan display besar.
- Kartu kondisi kebun: suhu `${w.temp}°C` dengan angka raksasa (font display), kondisi + subkondisi, ikon matahari/petir dalam lingkaran. Kotak status `safeToDry`: aman = strip hijau dengan ikon check; tidak aman = strip merah-oranye bergaris diagonal (hazard) dengan ikon warning. Logika `ok` tetap.
- Kartu "Prakiraan Siang & Sore": daftar slot cuaca bergaya jadwal/tracklist kaset (waktu mono, ikon, judul, catatan, suhu); slot `highlight` ditandai blok amber/oranye. Ikon per `WeatherKind` tetap (sunny, cloudy, overcast, rain).
- Kartu tips: label "Tips Si Daun Toba" / "Darurat Si Daun Toba" dengan titik status, kutipan `"${w.tip}"` sebagai stiker paper miring sedikit.

6.8 `finance/finance_screen.dart`
- Header + tombol sync (snackbar sinkronisasi). Judul "Biaya & Pengeluaran Kebun" + deskripsi.
- Kartu total: "TOTAL BIAYA", "Estimasi Musim Tanam", "Rp 14.250.000", dan "Tercatat dari 4 kategori pengeluaran operasional". Angka dalam font display raksasa di atas MarqueeText/ornamen. Pertahankan `_RingProgressPainter` (donat per kategori) dengan warna palet baru, 4 Kategori baku: Buruh Tani / Upah (`BURUH`), Pupuk & Nutrisi (`PUPUK`), Bibit & Olah Lahan (`BIBIT`), Lainnya / Tambahan (`LAINNYA`) (ikon: groups, science, spa, category/inventory).
- "Rincian Biaya" (4 Pos Biaya) dalam daftar RetroCard dengan VuMeterBar persen.
- "Riwayat Pengeluaran": daftar item (judul, tanggal • keterangan, nominal merah "-Rp ...") bergaya struk/tiket mono. Dukungan soft delete (`is_deleted` tidak menghapus data permanen melainkan menandai arsip). Aksi per item: Edit (menuju `FinanceScreenEditUpload`) dan Hapus (dialog "Hapus Pengeluaran" / "Tindakan ini tidak dapat dibatalkan." / "Ya, Hapus" + snackbar). Tombol "Tambah Catatan Biaya" = TrapezoidTabButton oranye.
- Bagian "Tutup Buku Musim / Akhir Musim" + tombol "Tutup Buku & Simpan Rekap" (menuju `FinanceEndScreen`); tombol arsip/semua musim menuju `FinanceAllMusimScreen`. Pertahankan chip "Musim Ini".

6.9 `finance/finance_screen_edit_upload.dart`
- Form tambah/edit pengeluaran: "Pilih Kategori Pembayaran" (grid pilihan 4 kategori baku: BURUH, PUPUK, BIBIT, LAINNYA, tampil sebagai tombol fisik/stiker terpilih = border oranye + check), "Rincian & Tanggal" (field judul dengan hint 'Misal: Upah tenaga petik harian', pemilih tanggal, nominal, catatan 'Tuliskan catatan atau rincian tambahan di sini...'). Semua controller dan logika simpan tetap. CTA simpan = trapesium oranye.

6.10 `finance/finance_end_screen.dart`
- "Rekap Tutup Buku Musim": gaya dokumen/struk mono di atas latar sage; "Musim Tanam 2026 • Lahan Blok A - Timur", "Total Pengeluaran Tercatat Rp 14.250.000", rincian 4 baris (Buruh Tani / Upah Kerja Rp 6.800.000, Pupuk & Nutrisi Rp 3.800.000, Bibit & Olah Lahan Rp 2.400.000, Lainnya / Operasional Rp 1.250.000), teks peringatan arsip.
- Tombol "Konfirmasi & Simpan Arsip" (trapesium oranye) dan "Batal & Kembali" (tombol hitam outline). Transaksi tutup buku bersifat atomik: mengunci musim berjalan dan membuka musim baru secara serempak.

6.11 `finance/finance_all_musim_screen.dart`
- "Rekap Semua Musim": daftar arsip musim sebagai kartu J-card, `_AllSeasonsRingProgressPainter` dipertahankan, filter kategori dengan chip bergaya tombol fisik (Bibit & Olah Lahan, Buruh & Petik, Pupuk & Nutrisi, Logistik & Lain). Aksi per kartu: Detail (dialog "Tutup"), Edit (membuka kembali `FinanceScreen` dengan dataset musim tersebut), Hapus (dialog Batal / Ya, Hapus + snackbar `Arsip "..." berhasil dihapus!`), tombol sync.

6.12 `harvest/harvest_screen.dart`
- Header "Lahan Blok A • Temanggung" + sync. Judul "Monitoring Siklus Panen" + deskripsi. Chip periode ("PILIH PERIODE", "Musim Ini").
- "Siklus Petikan Daun": chip/stepper tahap petikan (P1..P7, "P3 Aktif" ditandai blok oranye) bergaya jejeran tombol tape-deck. Tahap aktif diturunkan secara dinamis (*derived state*: `jumlah_petikan_selesai + 1`, tanpa perlu menyimpan baris kosong status MENUNGGU).
- "Target Keuntungan" ("TARGET 40 JT"), "Pencapaian Modal & Profit Bersih": angka "Rp 32,6 jt" display raksasa, VuMeterBar "81,6% Tercapai", "Modal: Rp 25.000.000", "Untung: +Rp 7.660.000", "Modal Rp 25 jt Lunas", badge "BEP TERCAPAI", "ESTIMASI LABA BERSIH +Rp 7.660.000".
- "Distribusi Hasil Petikan / Per Tahapan (kg)": bar chart gaya equalizer; nilai 48, 52, 68, 20, 18, 15, 12 tetap.
- Form "Timbangan Petikan": field "Berat Tembakau (kg)", "Total Pendapatan (Rp)", "Tanggal Penimbangan / Petikan", dan textarea "Keterangan / Kondisi Daun" (hint 'Misal: Petikan pucuk daun, warna kuning merata'). Tombol "Simpan Catatan Petikan" = trapesium oranye.
- "Tutup Buku Siklus Panen": Tombol "Tutup Buku & Simpan Rekap" dengan dialog konfirmasi ("Ya, Tutup Buku", "Batal") yang mengeksekusi penutupan musim secara atomik (menutup buku panen & keuangan sekaligus, serta membuka lembaran musim tanam baru).

6.13 `harvest/harvest_edit_screen.dart`
- "Pilih Tahapan yang Ingin Diedit": 7 tahap (Petikan daun pasir / bawah pertama, daun bawah kedua, daun tengah utama (kualitas prima), daun tengah kedua, daun atas, pucuk daun, petikan akhir / pembersihan) sebagai pilihan kartu bergaya kaset. Form mencakup: "Berat Bersih Tembakau (kg)", "Total Penerimaan / Pendapatan (Rp)", "Tanggal Penimbangan / Petikan", dan textarea "Keterangan / Kondisi Daun" (hint 'Misal: Petikan pucuk daun, warna kuning merata'). Tombol Simpan (trapesium oranye) dan Batal; snackbar `Data petikan $stageLabel berhasil diperbarui!` tetap.

6.14 `harvest/harvest_all_musim_screen.dart`
- "Rekap Semua Musim Panen": daftar kartu J-card riwayat panen seluruh musim dengan aksi Detail, Edit (membuka kembali `HarvestScreen` dengan dataset musim lampau yang dipilih), dan Hapus (soft delete). Snackbar tetap, tombol sync.

==================================================
7. ANIMASI, AKSESIBILITAS, PERFORMA
==================================================
- Animasi: marquee teks raksasa pelan, GlassPhone floating (naik-turun 6dp, 6 dtk), titik REC berkedip, kursor field berkedip (opsional), kartu muncul berurutan (slide-up + fade, jeda 40ms), tombol trapesium efek tekan, transisi antarlayar tetap.
- Hormati `MediaQuery.disableAnimations` / reduce motion: matikan semua animasi non-esensial.
- Teks isi minimal 14sp, target sentuh minimal 48x48dp, kontras WCAG AA, `Semantics` untuk tombol ikon dan elemen penting, ornamen dekoratif dibungkus `ExcludeSemantics`.
- Performa: grain dan ornamen statis di-cache dengan `RepaintBoundary`, hindari `saveLayer` berlebihan (blur/opacity bertumpuk), gunakan `const` sebisa mungkin, ListView.builder untuk daftar panjang.
- Tidak ada overflow RenderFlex pada lebar 320-430dp dan pada skala font sistem hingga 1.3x.

==================================================
8. FORMAT OUTPUT
==================================================
1. Mulai dengan ringkasan 6-10 poin keputusan desain (font, struktur frame, cara membuat GlassPhone, cara membuat grain yang ringan, perubahan pada tema).
2. Berikan dependensi tambahan untuk `pubspec.yaml` (mis. `google_fonts`) dan langkah setup font, jika ada.
3. Berikan KODE LENGKAP dan siap jalan untuk SETIAP file, satu per satu, dengan path jelas sebagai judul (contoh: `lib/screens/home_screen.dart`). Tidak boleh ada "..." atau "kode lainnya tetap sama". Urutan: theme dan widget retro dulu, lalu widget pendukung (header, bottom nav, async view, logo), lalu 14 layar.
4. Jika responsmu terpotong, berhenti di batas file yang rapi dan tulis "LANJUT DI: <path file berikutnya>" supaya aku bisa meminta lanjutan.
5. Di akhir, buat daftar periksa singkat: file yang diubah/ditambah, hal yang perlu kuuji manual (kamera, galeri, dialog, navigasi 5 tab), dan cara mengganti GlassPhone dengan PNG render sendiri.
