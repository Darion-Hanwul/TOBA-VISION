import 'package:toba_vision_mobile/services/offline_service.dart';
import 'api_service.dart';

class PanenService {
  // ==========================================
  // 1. SIMPAN PETIKAN PANEN (P1 - P7)
  // ==========================================
  static Future<void> simpanPetikan({
    required String idSiklus,
    required int petikanKe,
    required double beratKg,
    required double totalPendapatan,
    bool isOnline = true,
  }) async {
    final dataPanen = {
      'id_siklus': idSiklus,
      'petikan_ke': petikanKe,
      'berat_kg': beratKg,
      'total_pendapatan': totalPendapatan,
      'created_at': DateTime.now().toIso8601String(),
    };

    if (isOnline) {
      try {
        await ApiService.simpanPetikanPanen(
          idSiklus: idSiklus,
          petikanKe: petikanKe,
          beratKg: beratKg,
          totalPendapatan: totalPendapatan,
        );
        return;
      } catch (e) {
        // Fallback ke offline jika jaringan gagal
        await OfflineService.savePanenOffline(dataPanen);
      }
    } else {
      // Simpan langsung ke Hive jika mode offline
      await OfflineService.savePanenOffline(dataPanen);
    }
  }

  // ==========================================
  // 2. SIMPAN BIAYA OPERASIONAL
  // ==========================================
  static Future<void> tambahBiaya({
    required String idSiklus,
    required String namaPengeluaran,
    required String kategori,
    required double jumlahBiaya,
    String keterangan = "",
    bool isOnline = true,
  }) async {
    final dataBiaya = {
      'id_siklus': idSiklus,
      'nama_pengeluaran': namaPengeluaran,
      'kategori': kategori,
      'jumlah_biaya': jumlahBiaya,
      'keterangan': keterangan,
      'created_at': DateTime.now().toIso8601String(),
    };

    if (isOnline) {
      try {
        await ApiService.tambahBiayaOperasional(
          idSiklus: idSiklus,
          namaPengeluaran: namaPengeluaran,
          kategori: kategori,
          jumlahBiaya: jumlahBiaya,
          keterangan: keterangan,
        );
        return;
      } catch (e) {
        await OfflineService.saveBiayaOffline(dataBiaya);
      }
    } else {
      await OfflineService.saveBiayaOffline(dataBiaya);
    }
  }

  // ==========================================
  // 3. SYNC AUTOMATIS ANTREAN OFFLINE KE FASTAPI
  // ==========================================
  static Future<dynamic> syncPendingData(String idSiklus) async {
    final pendingPanen = OfflineService.getOfflinePanenList();
    final pendingBiaya = OfflineService.getOfflineBiayaList();

    if (pendingPanen.isEmpty && pendingBiaya.isEmpty) {
      return false; // Tidak ada antrean data
    }

    try {
      await ApiService.syncOfflineData(
        idSiklus: idSiklus,
        listPetikan: pendingPanen,
        listBiaya: pendingBiaya,
      );

      // Bersihkan antrean Hive setelah berhasil dikirim ke Cloud
      await OfflineService.clearPanenQueue();
      await OfflineService.clearBiayaQueue();
      return true;
    } catch (e) {
      throw Exception("Gagal melakukan enkripsi batch sync: $e");
    }
  }

  static Future<void> tambahPanen({required String idSiklus, required int petikanKe, required double beratKg, required double totalPendapatan, required bool isOnline, required String keterangan}) async {}
}