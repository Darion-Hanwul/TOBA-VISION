import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'retro/micro_text.dart';

/// Bottom Navigation Bar bergaya deck tombol fisik tape-deck (Play, Rew, FF, Stop, Rec).
/// Tab aktif ditandai blok trapesium oranye dengan label mono uppercase.
class AppBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const AppBottomNav({super.key, required this.index, required this.onTap});

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'BERANDA'),
    (Icons.document_scanner_outlined, Icons.document_scanner_rounded, 'DETEKSI'),
    (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'KEUANGAN'),
    (Icons.eco_outlined, Icons.eco_rounded, 'PANEN'),
    (Icons.wb_sunny_outlined, Icons.wb_sunny_rounded, 'CUACA'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.ink,
        border: Border(
          top: BorderSide(color: AppColors.ink, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, -3),
            blurRadius: 6,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: _buildTapeDeckButton(i, i == index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTapeDeckButton(int itemIndex, bool isSelected) {
    final item = _items[itemIndex];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.orange : const Color(0xFF22281E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? AppColors.paper : const Color(0xFF3B4434),
          width: 1.5,
        ),
        boxShadow: isSelected
            ? const [
                BoxShadow(color: AppColors.lime, offset: Offset(0, 1.5)),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? item.$2 : item.$1,
            size: 20,
            color: isSelected ? AppColors.paper : AppColors.sage,
          ),
          const SizedBox(height: 3),
          MicroText(
            item.$3,
            fontSize: 8,
            color: isSelected ? AppColors.paper : AppColors.sage,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ],
      ),
    );
  }
}
