import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Reusable Top Header / App Bar untuk aplikasi TOBA VISION.
///
/// Mendukung 2 mode penggunaan:
/// 1. Main Screen Header:
///    Logo brand daun/pertanian, nama 'TOBA VISION', lokasi/subtitle opsional,
///    dan tombol aksi kanan (trailing) seperti profil atau sync.
///
/// 2. Sub-Screen / Form Header:
///    Tombol kembali (back), judul halaman, dan aksi kanan (centang/simpan).
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  /// Judul header. Default: 'TOBA VISION' (jika [showBack] = false).
  final String? title;

  /// Subtitle di bawah judul (misal: 'TEMANGGUNG, JATENG').
  final String? subtitle;

  /// Jika true, menampilkan tombol kembali (Back Arrow).
  final bool showBack;

  /// Callback saat tombol back ditekan. Default: Navigator.maybePop(context).
  final VoidCallback? onBack;

  /// Widget logo custom di sebelah kiri (menggantikan logo default).
  final Widget? leading;

  /// Icon untuk logo brand default jika [leading] tidak diset. Default: Icons.spa_rounded.
  final IconData logoIcon;

  /// Warna background logo icon.
  final Color? logoBg;

  /// Warna icon logo.
  final Color? logoColor;

  /// Ukuran container logo. Default: 36.
  final double logoSize;

  /// Widget aksi di sebelah kanan (misal: tombol profil, tombol sync, tombol simpan).
  final Widget? trailing;

  /// Warna background header. Default: transparan.
  final Color? backgroundColor;

  /// Menampilkan garis pemisah halus di bawah header.
  final bool showBottomBorder;

  /// Padding dalam header.
  final EdgeInsetsGeometry? padding;

  /// Tinggi header (default: 64). Jika null, tinggi menyesuaikan konten.
  final double? height;

  const AppHeader({
    super.key,
    this.title,
    this.subtitle,
    this.showBack = false,
    this.onBack,
    this.leading,
    this.logoIcon = Icons.spa_rounded,
    this.logoBg,
    this.logoColor,
    this.logoSize = 36,
    this.trailing,
    this.backgroundColor,
    this.showBottomBorder = false,
    this.padding,
    this.height = 64,
  });

  @override
  Size get preferredSize => Size.fromHeight(height ?? 64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        border: showBottomBorder
            ? const Border(
                bottom: BorderSide(color: Color(0x0D022C22), width: 1),
              )
            : null,
      ),
      child: SafeArea(
        bottom: false,
        left: false,
        right: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Sisi Kiri: Tombol Back ATAU Logo Brand + Judul
            Expanded(
              child: showBack ? _buildBackTitle(context) : _buildBrandTitle(),
            ),

            // Sisi Kanan: Widget Aksi (Profil, Sync, Centang, dll)
            ?trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildBrandTitle() {
    if (leading != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading!,
          const SizedBox(width: 10),
          _buildTitleText(),
        ],
      );
    }

    final bg = logoBg ?? AppColors.forest.withValues(alpha: 0.1);
    final fg = logoColor ?? AppColors.forest;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(logoIcon, color: fg, size: logoSize * 0.52),
        ),
        const SizedBox(width: 10),
        _buildTitleText(),
      ],
    );
  }

  Widget _buildTitleText() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title ?? 'TOBA VISION',
          style: const TextStyle(
            fontFamily: kSerif,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: AppColors.forest,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 12, color: AppColors.amber),
              const SizedBox(width: 2),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontFamily: kSerif,
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBackTitle(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onBack ?? () => Navigator.maybePop(context),
          child: const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.arrow_back_rounded, color: AppColors.ink, size: 24),
          ),
        ),
        Expanded(
          child: Text(
            title ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: kSerif,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tombol aksi cepat di sisi kanan header (misal: icon profile, sync, check, dll).
class AppHeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final Color? backgroundColor;
  final double size;

  const AppHeaderActionButton({
    super.key,
    required this.icon,
    this.onTap,
    this.color,
    this.backgroundColor,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.forest.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: color ?? AppColors.forest,
          size: size * 0.52,
        ),
      ),
    );
  }
}
