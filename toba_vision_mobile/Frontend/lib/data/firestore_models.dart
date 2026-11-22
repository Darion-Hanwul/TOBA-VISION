import 'package:cloud_firestore/cloud_firestore.dart';

/// 1. Model Data Petani (Users)
class PetaniModel {
  final String idPetani;
  final String? noTelepon;
  final String? username;
  final String? password;
  final String nama;
  final String lokasiLahan;
  final double luasLahanM2;
  final String kelompokTani;
  final String? idMusimAktif;
  final DateTime createdAt;

  const PetaniModel({
    required this.idPetani,
    this.noTelepon,
    this.username,
    this.password,
    required this.nama,
    required this.lokasiLahan,
    required this.luasLahanM2,
    this.kelompokTani = '',
    this.idMusimAktif,
    required this.createdAt,
  });

  factory PetaniModel.fromMap(Map<String, dynamic> map, String id) {
    return PetaniModel(
      idPetani: id,
      noTelepon: map['no_telepon'],
      username: map['username'],
      password: map['password'],
      nama: map['nama'] ?? 'Petani Toba',
      lokasiLahan: map['lokasi_lahan'] ?? 'Temanggung',
      luasLahanM2: (map['luas_lahan_m2'] as num?)?.toDouble() ?? 0.0,
      kelompokTani: map['kelompok_tani'] ?? '',
      idMusimAktif: map['id_musim_aktif'],
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (noTelepon != null) 'no_telepon': noTelepon,
      'username': username,
      'password': (password != null && password!.trim().isNotEmpty) ? password!.trim() : '123456',
      'nama': nama,
      'lokasi_lahan': lokasiLahan,
      'luas_lahan_m2': luasLahanM2,
      'kelompok_tani': kelompokTani,
      'id_musim_aktif': idMusimAktif,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  PetaniModel copyWith({
    String? idPetani,
    String? noTelepon,
    String? username,
    String? password,
    String? nama,
    String? lokasiLahan,
    double? luasLahanM2,
    String? kelompokTani,
    String? idMusimAktif,
    DateTime? createdAt,
  }) {
    return PetaniModel(
      idPetani: idPetani ?? this.idPetani,
      noTelepon: noTelepon ?? this.noTelepon,
      username: username ?? this.username,
      password: password ?? this.password,
      nama: nama ?? this.nama,
      lokasiLahan: lokasiLahan ?? this.lokasiLahan,
      luasLahanM2: luasLahanM2 ?? this.luasLahanM2,
      kelompokTani: kelompokTani ?? this.kelompokTani,
      idMusimAktif: idMusimAktif ?? this.idMusimAktif,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// 2. Model Musim Tanam (Season Anchor)
class MusimTanamModel {
  final String idMusim;
  final String idPetani;
  final int nomorMusim;
  final String judulMusim;
  final String lokasiBlok;
  final String status; // 'AKTIF' atau 'SELESAI'
  final DateTime tanggalMulai;
  final DateTime? tanggalTutup;
  final double targetPendapatan;
  final double totalPengeluaranCache;
  final double totalPendapatanCache;
  final double totalBobotPanenCache;
  final bool isDeleted;

  const MusimTanamModel({
    required this.idMusim,
    required this.idPetani,
    required this.nomorMusim,
    required this.judulMusim,
    this.lokasiBlok = 'Lahan Utama',
    this.status = 'AKTIF',
    required this.tanggalMulai,
    this.tanggalTutup,
    this.targetPendapatan = 40000000.0,
    this.totalPengeluaranCache = 0.0,
    this.totalPendapatanCache = 0.0,
    this.totalBobotPanenCache = 0.0,
    this.isDeleted = false,
  });

  bool get isAktif => status == 'AKTIF';
  double get labaBersih => totalPendapatanCache - totalPengeluaranCache;

  factory MusimTanamModel.fromMap(Map<String, dynamic> map, String id) {
    return MusimTanamModel(
      idMusim: id,
      idPetani: map['id_petani'] ?? '',
      nomorMusim: (map['nomor_musim'] as num?)?.toInt() ?? 1,
      judulMusim: map['judul_musim'] ?? 'Musim Tanam',
      lokasiBlok: map['lokasi_blok'] ?? 'Lahan Utama',
      status: map['status'] ?? 'AKTIF',
      tanggalMulai: (map['tanggal_mulai'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tanggalTutup: (map['tanggal_tutup'] as Timestamp?)?.toDate(),
      targetPendapatan: (map['target_pendapatan'] as num?)?.toDouble() ?? 40000000.0,
      totalPengeluaranCache: (map['total_pengeluaran_cache'] as num?)?.toDouble() ?? 0.0,
      totalPendapatanCache: (map['total_pendapatan_cache'] as num?)?.toDouble() ?? 0.0,
      totalBobotPanenCache: (map['total_bobot_panen_cache'] as num?)?.toDouble() ?? 0.0,
      isDeleted: map['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_petani': idPetani,
      'nomor_musim': nomorMusim,
      'judul_musim': judulMusim,
      'lokasi_blok': lokasiBlok,
      'status': status,
      'tanggal_mulai': Timestamp.fromDate(tanggalMulai),
      'tanggal_tutup': tanggalTutup != null ? Timestamp.fromDate(tanggalTutup!) : null,
      'target_pendapatan': targetPendapatan,
      'total_pengeluaran_cache': totalPengeluaranCache,
      'total_pendapatan_cache': totalPendapatanCache,
      'total_bobot_panen_cache': totalBobotPanenCache,
      'is_deleted': isDeleted,
    };
  }
}

/// 3. Model Biaya Operasional (4 Kategori Baku)
class BiayaOperasionalModel {
  final String idBiaya;
  final String idMusim;
  final String kodeKategori; // 'BURUH', 'PUPUK', 'BIBIT', 'LAINNYA'
  final String namaPengeluaran;
  final double jumlahBiaya;
  final DateTime tanggal;
  final String? catatan;
  final bool isDeleted;

  const BiayaOperasionalModel({
    required this.idBiaya,
    required this.idMusim,
    required this.kodeKategori,
    required this.namaPengeluaran,
    required this.jumlahBiaya,
    required this.tanggal,
    this.catatan,
    this.isDeleted = false,
  });

  String get namaKategoriDisplay {
    switch (kodeKategori) {
      case 'BURUH':
        return 'Buruh Tani / Upah Kerja';
      case 'PUPUK':
        return 'Pupuk & Nutrisi';
      case 'BIBIT':
        return 'Bibit & Olah Lahan';
      case 'LAINNYA':
      default:
        return 'Lainnya / Tambahan';
    }
  }

  factory BiayaOperasionalModel.fromMap(Map<String, dynamic> map, String id) {
    return BiayaOperasionalModel(
      idBiaya: id,
      idMusim: map['id_musim'] ?? '',
      kodeKategori: map['kode_kategori'] ?? 'LAINNYA',
      namaPengeluaran: map['nama_pengeluaran'] ?? 'Pengeluaran',
      jumlahBiaya: (map['jumlah_biaya'] as num?)?.toDouble() ?? 0.0,
      tanggal: (map['tanggal'] as Timestamp?)?.toDate() ?? DateTime.now(),
      catatan: map['catatan'],
      isDeleted: map['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_musim': idMusim,
      'kode_kategori': kodeKategori,
      'nama_pengeluaran': namaPengeluaran,
      'jumlah_biaya': jumlahBiaya,
      'tanggal': Timestamp.fromDate(tanggal),
      'catatan': catatan,
      'is_deleted': isDeleted,
    };
  }
}

/// 4. Model Petikan Panen (P1 s.d P7)
class PetikanPanenModel {
  final String idPetikan;
  final String idMusim;
  final String kodeSiklus; // 'P1' .. 'P7'
  final int petikanKe; // 1 .. 7
  final double beratKg;
  final double estimasiPendapatan;
  final DateTime tanggalPetik;
  final String? kondisiDaun;
  final bool isDeleted;

  const PetikanPanenModel({
    required this.idPetikan,
    required this.idMusim,
    required this.kodeSiklus,
    required this.petikanKe,
    required this.beratKg,
    required this.estimasiPendapatan,
    required this.tanggalPetik,
    this.kondisiDaun,
    this.isDeleted = false,
  });

  static const Map<String, String> labelSiklusMap = {
    'P1': 'Daun Pasir (Bawah 1)',
    'P2': 'Daun Bawah 2',
    'P3': 'Daun Tengah Utama (Prima)',
    'P4': 'Daun Tengah 2',
    'P5': 'Daun Atas',
    'P6': 'Pucuk Daun',
    'P7': 'Pemetikan Akhir / Pembersihan',
  };

  String get labelDaun => labelSiklusMap[kodeSiklus] ?? 'Petikan Daun Tembakau';

  factory PetikanPanenModel.fromMap(Map<String, dynamic> map, String id) {
    return PetikanPanenModel(
      idPetikan: id,
      idMusim: map['id_musim'] ?? '',
      kodeSiklus: map['kode_siklus'] ?? 'P1',
      petikanKe: (map['petikan_ke'] as num?)?.toInt() ?? 1,
      beratKg: (map['berat_kg'] as num?)?.toDouble() ?? 0.0,
      estimasiPendapatan: (map['estimasi_pendapatan'] as num?)?.toDouble() ?? 0.0,
      tanggalPetik: (map['tanggal_petik'] as Timestamp?)?.toDate() ?? DateTime.now(),
      kondisiDaun: map['kondisi_daun'],
      isDeleted: map['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_musim': idMusim,
      'kode_siklus': kodeSiklus,
      'petikan_ke': petikanKe,
      'berat_kg': beratKg,
      'estimasi_pendapatan': estimasiPendapatan,
      'tanggal_petik': Timestamp.fromDate(tanggalPetik),
      'kondisi_daun': kondisiDaun,
      'is_deleted': isDeleted,
    };
  }
}
