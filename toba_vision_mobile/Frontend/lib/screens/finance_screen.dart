import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/models.dart';
import '../data/services.dart';
import '../widgets/async_view.dart';

/// Layar ini belum ada di desain Figma - versi sederhana agar tab tidak kosong.
class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<FinanceEntry>>(
      load: () => Services.finance.getEntries(),
      builder: (context, list) {
        final income = list.where((e) => e.amount > 0).fold<int>(0, (a, e) => a + e.amount);
        final expense = list.where((e) => e.amount < 0).fold<int>(0, (a, e) => a + e.amount.abs());
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Keuangan',
              style: TextStyle(fontFamily: kSerif, fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.forest)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.forest, borderRadius: BorderRadius.circular(20)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Saldo Kas', style: TextStyle(color: AppColors.mint)),
              const SizedBox(height: 4),
              Text(rupiah(income - expense),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Text('Masuk  ${rupiah(income)}', style: const TextStyle(color: AppColors.mint, fontSize: 12))),
                Expanded(child: Text('Keluar  ${rupiah(expense)}', style: const TextStyle(color: Color(0xFFFFC9C9), fontSize: 12))),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('Transaksi Terakhir',
              style: TextStyle(fontFamily: kSerif, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final e in list)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(14),
              decoration: cardDeco(radius: 16),
              child: Row(children: [
                CircleAvatar(
                  backgroundColor: e.amount > 0 ? AppColors.mint : AppColors.redSoft,
                  child: Icon(e.amount > 0 ? Icons.south_west_rounded : Icons.north_east_rounded,
                      color: e.amount > 0 ? AppColors.green : AppColors.red, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${e.category} • ${e.date}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  ]),
                ),
                Text('${e.amount > 0 ? '+' : '-'}${rupiah(e.amount)}',
                    style: TextStyle(fontWeight: FontWeight.w800, color: e.amount > 0 ? AppColors.green : AppColors.red)),
              ]),
            ),
        ]);
      },
    );
  }
}
