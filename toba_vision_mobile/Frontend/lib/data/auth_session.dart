import 'firestore_models.dart';

/// State store untuk judul dan ringkasan musim keuangan yang aktif
class FinanceDataStore {
  static String activeSeasonTitle = 'Biaya & Pengeluaran Musim 1';
  static String activeTotalExpense = 'Rp 0';
  static Map<String, dynamic>? activeSeasonData;

  static void reset() {
    activeSeasonTitle = 'Biaya & Pengeluaran Musim 1';
    activeTotalExpense = 'Rp 0';
    activeSeasonData = null;
  }
}

/// Pengelola sesi login aktif petani di aplikasi
class AuthSession {
  static PetaniModel? currentPetani;
  static String activeMusimId = '';

  static String get currentIdPetani => currentPetani?.idPetani ?? '';

  static String get currentIdMusim {
    if (activeMusimId.isNotEmpty) {
      return activeMusimId;
    }
    final petMusim = currentPetani?.idMusimAktif;
    if (petMusim != null && petMusim.isNotEmpty) {
      return petMusim;
    }
    return '';
  }

  static void setActiveMusim(String idMusim) {
    activeMusimId = idMusim;
    if (currentPetani != null && idMusim.isNotEmpty) {
      currentPetani = currentPetani!.copyWith(idMusimAktif: idMusim);
    }
  }

  static String get currentNama => currentPetani?.nama ?? '';

  static String get currentPhone => currentPetani?.noTelepon ?? '';

  static String get currentLokasi => currentPetani?.lokasiLahan ?? '';

  static void updateCurrentLokasi(String lokasi) {
    if (currentPetani != null) {
      currentPetani = currentPetani!.copyWith(lokasiLahan: lokasi);
    }
  }

  static double get currentLuasM2 => currentPetani?.luasLahanM2 ?? 0.0;

  static String get currentKelompok {
    final k = currentPetani?.kelompokTani;
    if (k == null || k.isEmpty || k == 'Mitra Tani Temanggung') return '';
    return k;
  }

  static void setSession(PetaniModel petani) {
    currentPetani = petani;
    if (petani.idMusimAktif != null && petani.idMusimAktif!.isNotEmpty) {
      activeMusimId = petani.idMusimAktif!;
    }
    FinanceDataStore.reset();
  }

  static void logout() {
    currentPetani = null;
    activeMusimId = '';
    FinanceDataStore.reset();
  }
}
