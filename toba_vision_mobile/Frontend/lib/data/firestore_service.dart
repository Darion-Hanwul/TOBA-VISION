import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_models.dart';

/// Service Utama Pengelola Data Cloud Firestore sesuai ERD v2.0
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Koleksi Root: users
  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _db.collection('users');

  // Sub-koleksi: musim_tanam
  CollectionReference<Map<String, dynamic>> _musimCol(String idPetani) =>
      _usersCol.doc(idPetani).collection('musim_tanam');

  // Sub-koleksi: biaya_operasional
  CollectionReference<Map<String, dynamic>> _biayaCol(
          String idPetani, String idMusim) =>
      _musimCol(idPetani).doc(idMusim).collection('biaya_operasional');

  // Sub-koleksi: petikan_panen
  CollectionReference<Map<String, dynamic>> _panenCol(
          String idPetani, String idMusim) =>
      _musimCol(idPetani).doc(idMusim).collection('petikan_panen');

  // ====================================================================
  // 1. MANAJEMEN AKUN PETANI (USERS)
  // ====================================================================

  /// Login petani via Nama Lengkap atau Username
  Future<PetaniModel?> loginPetani({
    required String identifier,
    required String password,
  }) async {
    final cleanId = identifier.trim();

    // 1. Cari berdasarkan nama lengkap
    var query = await _usersCol.where('nama', isEqualTo: cleanId).limit(1).get();
    if (query.docs.isEmpty) {
      // 2. Coba cari berdasarkan username
      query = await _usersCol.where('username', isEqualTo: cleanId).limit(1).get();
    }
    if (query.docs.isEmpty) {
      // 3. Fallback jika masih ada akun lama dengan no_telepon
      query = await _usersCol.where('no_telepon', isEqualTo: cleanId).limit(1).get();
    }

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final data = doc.data();
      final dbPassword = data['password'] as String?;

      // Validasi kata sandi jika akun memiliki kata sandi di database
      if (dbPassword != null && dbPassword.isNotEmpty) {
        if (password.trim() != dbPassword.trim()) {
          throw Exception('KATA_SANDI_SALAH');
        }
      }
      return PetaniModel.fromMap(data, doc.id);
    }
    return null;
  }

  /// Pendaftaran Petani Baru (Validasi Keunikan Nama Petani)
  Future<PetaniModel> daftarPetaniBaru({
    required String nama,
    required String lokasiLahan,
    required double luasLahanM2,
    String? password,
    String? noTelepon,
  }) async {
    final cleanName = nama.trim();

    // Cek duplikasi Nama Petani unik
    final existing = await _usersCol.where('nama', isEqualTo: cleanName).limit(1).get();
    if (existing.docs.isNotEmpty) {
      throw Exception('NAMA_SUDAH_TERPAKAI');
    }

    final newDoc = _usersCol.doc();
    return await simpanProfilPetani(
      idPetani: newDoc.id,
      nama: cleanName,
      password: password,
      noTelepon: noTelepon,
      lokasiLahan: lokasiLahan.trim(),
      luasLahanM2: luasLahanM2,
    );
  }

  /// Simpan atau perbarui profil petani di Firestore
  Future<PetaniModel> simpanProfilPetani({
    required String idPetani,
    required String nama,
    String? noTelepon,
    String? username,
    String? password,
    required String lokasiLahan,
    required double luasLahanM2,
    String kelompokTani = '',
  }) async {
    final docRef = _usersCol.doc(idPetani);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      // Inisialisasi musim tanam pertama secara otomatis
      final musimBaruRef = _musimCol(idPetani).doc();
      final batch = _db.batch();

      final petaniBaru = PetaniModel(
        idPetani: idPetani,
        noTelepon: noTelepon,
        username: username,
        password: password,
        nama: nama,
        lokasiLahan: lokasiLahan,
        luasLahanM2: luasLahanM2,
        kelompokTani: kelompokTani,
        idMusimAktif: musimBaruRef.id,
        createdAt: DateTime.now(),
      );

      final musimPertama = MusimTanamModel(
        idMusim: musimBaruRef.id,
        idPetani: idPetani,
        nomorMusim: 1,
        judulMusim: 'Musim Tanam 1 (${DateTime.now().year})',
        lokasiBlok: 'Lahan Blok A',
        status: 'AKTIF',
        tanggalMulai: DateTime.now(),
        targetPendapatan: 40000000.0,
      );

      batch.set(docRef, petaniBaru.toMap());
      batch.set(musimBaruRef, musimPertama.toMap());
      await batch.commit();

      return petaniBaru;
    } else {
      await docRef.update({
        'nama': nama,
        'lokasi_lahan': lokasiLahan,
        'luas_lahan_m2': luasLahanM2,
        'kelompok_tani': kelompokTani,
      });
      return PetaniModel.fromMap(snapshot.data()!, idPetani);
    }
  }

  /// Ambil profil petani berdasarkan idPetani
  Future<PetaniModel?> getProfilPetani(String idPetani) async {
    final doc = await _usersCol.doc(idPetani).get();
    if (!doc.exists || doc.data() == null) return null;
    return PetaniModel.fromMap(doc.data()!, idPetani);
  }

  // ====================================================================
  // 2. MANAJEMEN MUSIM TANAM (SEASON ANCHOR)
  // ====================================================================

  /// Dapatkan musim tanam yang saat ini berstatus 'AKTIF'
  Future<MusimTanamModel?> getMusimAktif(String idPetani) async {
    if (idPetani.isEmpty) return null;

    try {
      // 1. Cek dari profil petani (id_musim_aktif)
      final petDoc = await _usersCol.doc(idPetani).get();
      if (petDoc.exists && petDoc.data() != null) {
        final idMusimAktif = petDoc.data()!['id_musim_aktif'] as String?;
        if (idMusimAktif != null && idMusimAktif.isNotEmpty) {
          final mDoc = await _musimCol(idPetani).doc(idMusimAktif).get();
          if (mDoc.exists && mDoc.data() != null) {
            final m = MusimTanamModel.fromMap(mDoc.data()!, mDoc.id);
            if (!m.isDeleted) return m;
          }
        }
      }

      // 2. Fallback query musim berstatus 'AKTIF'
      final snap = await _musimCol(idPetani)
          .where('status', isEqualTo: 'AKTIF')
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;
      final m = MusimTanamModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
      if (m.isDeleted) return null;
      return m;
    } catch (_) {
      return null;
    }
  }

  /// Dapatkan atau buatkan musim aktif jika belum ada
  Future<MusimTanamModel> getOrCreateMusimAktif(String idPetani) async {
    final existing = await getMusimAktif(idPetani);
    if (existing != null) return existing;

    final docRef = _musimCol(idPetani).doc();
    final musimBaru = MusimTanamModel(
      idMusim: docRef.id,
      idPetani: idPetani,
      nomorMusim: 1,
      judulMusim: 'Musim Tanam 1 (${DateTime.now().year})',
      lokasiBlok: 'Lahan Utama',
      status: 'AKTIF',
      tanggalMulai: DateTime.now(),
      targetPendapatan: 40000000.0,
    );

    await docRef.set(musimBaru.toMap());
    await _usersCol.doc(idPetani).set({
      'id_musim_aktif': docRef.id,
    }, SetOptions(merge: true));

    return musimBaru;
  }

  /// Dapatkan seluruh riwayat musim tanam (untuk layar Semua Musim)
  Future<List<MusimTanamModel>> getSemuaMusim(String idPetani) async {
    if (idPetani.isEmpty) return [];
    try {
      final snap = await _musimCol(idPetani).get();
      final list = snap.docs
          .map((doc) => MusimTanamModel.fromMap(doc.data(), doc.id))
          .where((m) => !m.isDeleted)
          .toList();
      list.sort((a, b) => b.nomorMusim.compareTo(a.nomorMusim));
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Hapus musim tanam secara permanen & menyeluruh (menghapus dokumen musim serta seluruh sub-koleksi biaya dan panen)
  Future<MusimTanamModel?> hapusMusimTanam({
    required String idPetani,
    required String idMusim,
  }) async {
    if (idPetani.isEmpty || idMusim.isEmpty) return null;

    try {
      // 1. Hapus seluruh data di sub-koleksi biaya_operasional
      final biayaSnap = await _biayaCol(idPetani, idMusim).get();
      final batch = _db.batch();
      for (final doc in biayaSnap.docs) {
        batch.delete(doc.reference);
      }

      // 2. Hapus seluruh data di sub-koleksi petikan_panen
      final panenSnap = await _panenCol(idPetani, idMusim).get();
      for (final doc in panenSnap.docs) {
        batch.delete(doc.reference);
      }

      // 3. Hapus dokumen musim_tanam itu sendiri
      batch.delete(_musimCol(idPetani).doc(idMusim));
      await batch.commit();
    } catch (_) {
      // Fallback soft-delete jika batch delete terkendala izin atau offline
      await _musimCol(idPetani).doc(idMusim).set({
        'is_deleted': true,
        'deleted_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // 4. Periksa apakah musim yang dihapus merupakan musim aktif petani
    MusimTanamModel? musimBaruAktif;
    try {
      final petDoc = await _usersCol.doc(idPetani).get();
      final activeId = petDoc.data()?['id_musim_aktif'] as String?;
      if (activeId == idMusim) {
        final sisaMusim = await getSemuaMusim(idPetani);
        if (sisaMusim.isNotEmpty) {
          musimBaruAktif = sisaMusim.first;
        } else {
          musimBaruAktif = await getOrCreateMusimAktif(idPetani);
        }
        await _usersCol.doc(idPetani).set({
          'id_musim_aktif': musimBaruAktif.idMusim,
        }, SetOptions(merge: true));
      }
    } catch (_) {}
    return musimBaruAktif;
  }

  // ====================================================================
  // 3. OPERASIONAL KEUANGAN (BIAYA OPERASIONAL)
  // ====================================================================

  /// Stream daftar biaya operasional musim aktif (Real-time updates, no composite index needed)
  Stream<List<BiayaOperasionalModel>> streamDaftarBiaya(
      String idPetani, String idMusim) {
    if (idPetani.isEmpty || idMusim.isEmpty) {
      return Stream.value(<BiayaOperasionalModel>[]);
    }
    return _biayaCol(idPetani, idMusim)
        .snapshots()
        .map((snap) {
          final items = snap.docs
              .map((doc) => BiayaOperasionalModel.fromMap(doc.data(), doc.id))
              .where((item) => !item.isDeleted)
              .toList();
          items.sort((a, b) => b.tanggal.compareTo(a.tanggal));
          return items;
        });
  }

  /// Dapatkan daftar biaya operasional musim (One-time fetch data riil)
  Future<List<BiayaOperasionalModel>> getDaftarBiaya(
      String idPetani, String idMusim) async {
    if (idPetani.isEmpty || idMusim.isEmpty) return [];
    try {
      final snap = await _biayaCol(idPetani, idMusim).get();
      final items = snap.docs
          .map((doc) => BiayaOperasionalModel.fromMap(doc.data(), doc.id))
          .where((item) => !item.isDeleted)
          .toList();
      items.sort((a, b) => b.tanggal.compareTo(a.tanggal));
      return items;
    } catch (_) {
      return [];
    }
  }

  /// Simpan catatan biaya baru atau perbarui catatan biaya yang sudah ada
  Future<void> simpanBiayaOperasional({
    required String idPetani,
    required String idMusim,
    String? idBiaya,
    required String kodeKategori,
    required String namaPengeluaran,
    required double jumlahBiaya,
    required DateTime tanggal,
    String? catatan,
  }) async {
    if (idPetani.isEmpty) throw Exception('ID Petani tidak boleh kosong');

    String resolvedMusimId = idMusim;
    if (resolvedMusimId.isEmpty) {
      final m = await getOrCreateMusimAktif(idPetani);
      resolvedMusimId = m.idMusim;
    }

    final docRef = idBiaya != null
        ? _biayaCol(idPetani, resolvedMusimId).doc(idBiaya)
        : _biayaCol(idPetani, resolvedMusimId).doc();

    final model = BiayaOperasionalModel(
      idBiaya: docRef.id,
      idMusim: resolvedMusimId,
      kodeKategori: kodeKategori,
      namaPengeluaran: namaPengeluaran,
      jumlahBiaya: jumlahBiaya,
      tanggal: tanggal,
      catatan: catatan,
      isDeleted: false,
    );

    // Simpan dokumen biaya
    await docRef.set(model.toMap(), SetOptions(merge: true));

    // Sinkronisasi otomatis total_pengeluaran_cache pada dokumen induk musim
    await _syncTotalBiayaMusim(idPetani, resolvedMusimId);
  }

  /// Soft delete pengeluaran (tidak menghapus fisik untuk menjaga jejak audit)
  Future<void> hapusBiayaSoft({
    required String idPetani,
    required String idMusim,
    required String idBiaya,
  }) async {
    String resolvedMusimId = idMusim;
    if (resolvedMusimId.isEmpty) {
      final m = await getOrCreateMusimAktif(idPetani);
      resolvedMusimId = m.idMusim;
    }

    await _biayaCol(idPetani, resolvedMusimId).doc(idBiaya).update({
      'is_deleted': true,
      'deleted_at': FieldValue.serverTimestamp(),
    });

    await _syncTotalBiayaMusim(idPetani, resolvedMusimId);
  }

  /// Hitung ulang total biaya dan update cache musim tanam
  Future<void> _syncTotalBiayaMusim(String idPetani, String idMusim) async {
    final snap = await _biayaCol(idPetani, idMusim).get();

    double total = 0.0;
    for (var doc in snap.docs) {
      final data = doc.data();
      if (data['is_deleted'] != true) {
        total += (data['jumlah_biaya'] as num?)?.toDouble() ?? 0.0;
      }
    }

    await _musimCol(idPetani).doc(idMusim).set({
      'total_pengeluaran_cache': total,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ====================================================================
  // 4. OPERASIONAL PANEN (PETIKAN PANEN P1 s.d P7)
  // ====================================================================

  /// Stream daftar petikan panen riil pada musim aktif (Real-time updates, no composite index needed)
  Stream<List<PetikanPanenModel>> streamDaftarPetikan(
      String idPetani, String idMusim) {
    if (idPetani.isEmpty || idMusim.isEmpty) {
      return Stream.value(<PetikanPanenModel>[]);
    }
    return _panenCol(idPetani, idMusim)
        .snapshots()
        .map((snap) {
          final items = snap.docs
              .map((doc) => PetikanPanenModel.fromMap(doc.data(), doc.id))
              .where((item) => !item.isDeleted)
              .toList();
          items.sort((a, b) => a.petikanKe.compareTo(b.petikanKe));
          return items;
        });
  }

  /// Dapatkan daftar petikan panen musim (One-time fetch data riil)
  Future<List<PetikanPanenModel>> getDaftarPetikan(
      String idPetani, String idMusim) async {
    if (idPetani.isEmpty || idMusim.isEmpty) return [];
    try {
      final snap = await _panenCol(idPetani, idMusim).get();
      final items = snap.docs
          .map((doc) => PetikanPanenModel.fromMap(doc.data(), doc.id))
          .where((item) => !item.isDeleted)
          .toList();
      items.sort((a, b) => a.petikanKe.compareTo(b.petikanKe));
      return items;
    } catch (_) {
      return [];
    }
  }

  /// Simpan catatan hasil petikan (timbangan kg dan estimasi pendapatan kotor)
  Future<void> simpanPetikanPanen({
    required String idPetani,
    required String idMusim,
    required String kodeSiklus, // P1 .. P7
    required int petikanKe,
    required double beratKg,
    required double estimasiPendapatan,
    required DateTime tanggalPetik,
    String? kondisiDaun,
  }) async {
    if (idPetani.isEmpty) throw Exception('ID Petani tidak boleh kosong');

    String resolvedMusimId = idMusim;
    if (resolvedMusimId.isEmpty) {
      final m = await getOrCreateMusimAktif(idPetani);
      resolvedMusimId = m.idMusim;
    }

    final docRef = _panenCol(idPetani, resolvedMusimId).doc(kodeSiklus);

    final model = PetikanPanenModel(
      idPetikan: docRef.id,
      idMusim: resolvedMusimId,
      kodeSiklus: kodeSiklus,
      petikanKe: petikanKe,
      beratKg: beratKg,
      estimasiPendapatan: estimasiPendapatan,
      tanggalPetik: tanggalPetik,
      kondisiDaun: kondisiDaun,
      isDeleted: false,
    );

    await docRef.set(model.toMap(), SetOptions(merge: true));

    // Sinkronisasi otomatis total pendapatan dan bobot kg pada musim
    await _syncTotalPanenMusim(idPetani, resolvedMusimId);
  }

  /// Hitung ulang total kg dan omzet panen lalu perbarui cache musim
  Future<void> _syncTotalPanenMusim(String idPetani, String idMusim) async {
    final snap = await _panenCol(idPetani, idMusim).get();

    double totalOmzet = 0.0;
    double totalKg = 0.0;

    for (var doc in snap.docs) {
      final data = doc.data();
      if (data['is_deleted'] != true) {
        totalOmzet += (data['estimasi_pendapatan'] as num?)?.toDouble() ?? 0.0;
        totalKg += (data['berat_kg'] as num?)?.toDouble() ?? 0.0;
      }
    }

    await _musimCol(idPetani).doc(idMusim).set({
      'total_pendapatan_cache': totalOmzet,
      'total_bobot_panen_cache': totalKg,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ====================================================================
  // 5. TRANSAKSI TUTUP BUKU SECARA ATOMIK (ATOMIC SEASON CLOSURE)
  // ====================================================================

  /// Perbarui referensi id_musim_aktif di Firestore
  Future<void> setMusimAktif(String idPetani, String idMusim) async {
    if (idPetani.isEmpty || idMusim.isEmpty) return;
    await _usersCol.doc(idPetani).set({
      'id_musim_aktif': idMusim,
    }, SetOptions(merge: true));
  }

  /// Buat musim tanam baru (misal: Musim Tanam 2, Musim Tanam 3) dan jadikan musim aktif
  Future<MusimTanamModel> buatMusimBaru({
    required String idPetani,
    String? judulMusim,
    String lokasiBlok = 'Lahan Utama',
    double targetPendapatan = 40000000.0,
  }) async {
    final existing = await getSemuaMusim(idPetani);
    int nextNomor = 1;
    if (existing.isNotEmpty) {
      final highest = existing.map((m) => m.nomorMusim).reduce((a, b) => a > b ? a : b);
      nextNomor = highest + 1;
    }

    final String finalTitle = judulMusim != null && judulMusim.trim().isNotEmpty
        ? judulMusim.trim()
        : 'Musim Tanam $nextNomor (${DateTime.now().year})';

    final docRef = _musimCol(idPetani).doc();
    final musimBaru = MusimTanamModel(
      idMusim: docRef.id,
      idPetani: idPetani,
      nomorMusim: nextNomor,
      judulMusim: finalTitle,
      lokasiBlok: lokasiBlok,
      status: 'AKTIF',
      tanggalMulai: DateTime.now(),
      targetPendapatan: targetPendapatan,
    );

    await docRef.set(musimBaru.toMap());
    await _usersCol.doc(idPetani).set({
      'id_musim_aktif': docRef.id,
    }, SetOptions(merge: true));

    return musimBaru;
  }

  /// Menutup buku musim tanam aktif dan secara serempak membuka musim baru
  Future<MusimTanamModel> tutupBukuMusimAtomik({
    required String idPetani,
    required String idMusimLama,
    required String judulMusimBaru,
    double targetOmzetBaru = 40000000.0,
  }) async {
    final batch = _db.batch();

    // 1. Ambil data musim lama untuk mengetahui nomor musimnya
    int nomorLama = 1;
    String lokasi = 'Lahan Utama';
    try {
      final musimLamaDoc = await _musimCol(idPetani).doc(idMusimLama).get();
      if (musimLamaDoc.exists && musimLamaDoc.data() != null) {
        final dataLama = musimLamaDoc.data()!;
        nomorLama = (dataLama['nomor_musim'] as num?)?.toInt() ?? 1;
        lokasi = (dataLama['lokasi_blok'] as String?) ?? 'Lahan Utama';
      }
    } catch (_) {}

    final nomorBaru = nomorLama + 1;
    final finalJudul = judulMusimBaru.isNotEmpty && !judulMusimBaru.startsWith('Musim Tanam Baru')
        ? judulMusimBaru
        : 'Musim Tanam $nomorBaru (${DateTime.now().year})';

    // 2. Kunci musim lama menjadi 'SELESAI'
    final refMusimLama = _musimCol(idPetani).doc(idMusimLama);
    batch.set(refMusimLama, {
      'status': 'SELESAI',
      'tanggal_tutup': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 3. Buat dokumen musim baru dengan status 'AKTIF'
    final refMusimBaru = _musimCol(idPetani).doc();
    final musimBaru = MusimTanamModel(
      idMusim: refMusimBaru.id,
      idPetani: idPetani,
      nomorMusim: nomorBaru,
      judulMusim: finalJudul,
      lokasiBlok: lokasi,
      status: 'AKTIF',
      tanggalMulai: DateTime.now(),
      targetPendapatan: targetOmzetBaru,
    );
    batch.set(refMusimBaru, musimBaru.toMap());

    // 4. Perbarui pointer id_musim_aktif di dokumen petani
    batch.set(_usersCol.doc(idPetani), {
      'id_musim_aktif': refMusimBaru.id,
    }, SetOptions(merge: true));

    // Eksekusi atomik: semua berhasil atau semua gagal (rollback)
    await batch.commit();

    return musimBaru;
  }

  // ====================================================================
  // 6. SEEDER DATA SAMPLE INISIALISASI (DEMO SEEDING)
  // ====================================================================

  /// Inisialisasi data sampel awal ke Firestore agar tabel langsung terisi
  Future<void> inisialisasiDataAwalDemo({String idPetani = 'petani_slamet_01'}) async {
    final petaniRef = _usersCol.doc(idPetani);
    final petSnap = await petaniRef.get();

    if (!petSnap.exists) {
      final batch = _db.batch();

      // Buat akun petani
      final petani = PetaniModel(
        idPetani: idPetani,
        noTelepon: '081234567890',
        username: 'slamet_raharjo',
        password: '123456',
        nama: 'Slamet Raharjo',
        lokasiLahan: 'Desa Bansari, Parakan, Temanggung',
        luasLahanM2: 2500.0,
        kelompokTani: 'Sindoro Makmur',
        idMusimAktif: 'musim_03',
        createdAt: DateTime.now(),
      );
      batch.set(petaniRef, petani.toMap());

      // Musim 3 (Aktif)
      final msm3Ref = _musimCol(idPetani).doc('musim_03');
      final msm3 = MusimTanamModel(
        idMusim: 'musim_03',
        idPetani: idPetani,
        nomorMusim: 3,
        judulMusim: 'Musim Ketiga (2024)',
        lokasiBlok: 'Lahan Blok A & B',
        status: 'AKTIF',
        tanggalMulai: DateTime(2024, 5, 10),
        targetPendapatan: 40000000.0,
        totalPengeluaranCache: 14250000.0,
        totalPendapatanCache: 68600000.0,
        totalBobotPanenCache: 1850.0,
      );
      batch.set(msm3Ref, msm3.toMap());

      // Biaya Operasional Musim 3
      final b1Ref = _biayaCol(idPetani, 'musim_03').doc('b1');
      batch.set(b1Ref, {
        'id_musim': 'musim_03',
        'kode_kategori': 'BURUH',
        'nama_pengeluaran': 'Upah Petik & Angkut 5 Orang',
        'jumlah_biaya': 6840000.0,
        'tanggal': Timestamp.fromDate(DateTime(2024, 6, 12)),
        'catatan': 'Tenaga harian petik daun pasir',
        'is_deleted': false,
      });

      final b2Ref = _biayaCol(idPetani, 'musim_03').doc('b2');
      batch.set(b2Ref, {
        'id_musim': 'musim_03',
        'kode_kategori': 'PUPUK',
        'nama_pengeluaran': 'Pupuk NPK & ZA Kujang',
        'jumlah_biaya': 3847500.0,
        'tanggal': Timestamp.fromDate(DateTime(2024, 5, 20)),
        'catatan': 'Pemupukan dasar 5 sak',
        'is_deleted': false,
      });

      final b3Ref = _biayaCol(idPetani, 'musim_03').doc('b3');
      batch.set(b3Ref, {
        'id_musim': 'musim_03',
        'kode_kategori': 'BIBIT',
        'nama_pengeluaran': 'Benih Kemloko Unggul & Bajak',
        'jumlah_biaya': 2422500.0,
        'tanggal': Timestamp.fromDate(DateTime(2024, 5, 10)),
        'catatan': 'Sewa traktor dan semai benih',
        'is_deleted': false,
      });

      final b4Ref = _biayaCol(idPetani, 'musim_03').doc('b4');
      batch.set(b4Ref, {
        'id_musim': 'musim_03',
        'kode_kategori': 'LAINNYA',
        'nama_pengeluaran': 'Terpal Jemur & Tali Rafia',
        'jumlah_biaya': 1140000.0,
        'tanggal': Timestamp.fromDate(DateTime(2024, 6, 1)),
        'catatan': 'Peralatan penjemuran daun',
        'is_deleted': false,
      });

      // Petikan Panen P1, P2, P3
      final p1Ref = _panenCol(idPetani, 'musim_03').doc('P1');
      batch.set(p1Ref, {
        'id_musim': 'musim_03',
        'kode_siklus': 'P1',
        'petikan_ke': 1,
        'berat_kg': 480.0,
        'estimasi_pendapatan': 11250000.0,
        'tanggal_petik': Timestamp.fromDate(DateTime(2024, 6, 15)),
        'kondisi_daun': 'Petikan daun pasir pertama, tipis dan kering cepat',
        'is_deleted': false,
      });

      final p2Ref = _panenCol(idPetani, 'musim_03').doc('P2');
      batch.set(p2Ref, {
        'id_musim': 'musim_03',
        'kode_siklus': 'P2',
        'petikan_ke': 2,
        'berat_kg': 520.0,
        'estimasi_pendapatan': 12750000.0,
        'tanggal_petik': Timestamp.fromDate(DateTime(2024, 6, 25)),
        'kondisi_daun': 'Petikan daun bawah kedua, aroma mulai mantap',
        'is_deleted': false,
      });

      final p3Ref = _panenCol(idPetani, 'musim_03').doc('P3');
      batch.set(p3Ref, {
        'id_musim': 'musim_03',
        'kode_siklus': 'P3',
        'petikan_ke': 3,
        'berat_kg': 850.0,
        'estimasi_pendapatan': 68600000.0,
        'tanggal_petik': Timestamp.fromDate(DateTime(2024, 7, 5)),
        'kondisi_daun': 'Petikan daun tengah utama, kualitas prima bobot maksimal',
        'is_deleted': false,
      });

      await batch.commit();
    } else {
      if (petSnap.data()?['password'] == null) {
        await petaniRef.update({'password': '123456'});
      }
    }
  }
}
