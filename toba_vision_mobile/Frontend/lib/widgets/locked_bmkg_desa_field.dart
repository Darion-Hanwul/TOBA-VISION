import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Kolom Desa/Kelurahan dalam status terkunci ketika BMKG belum menyediakan daftar desa.
class LockedBmkgDesaField extends StatelessWidget {
  final Key fieldKey;

  const LockedBmkgDesaField({
    super.key,
    this.fieldKey = const ValueKey('locked-desa-field'),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1EB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.muted.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: TextField(
        key: fieldKey,
        enabled: false,
        readOnly: true,
        canRequestFocus: false,
        style: AppTypography.body(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Desa belum tersedia di BMKG (terkunci)',
          hintStyle: AppTypography.body(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.muted,
            size: 18,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
