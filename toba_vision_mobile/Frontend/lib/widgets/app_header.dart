import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'app_logo.dart';
import 'retro/chrome_wordmark.dart';
import 'retro/micro_text.dart';

/// Retro Y2K Walkman / Tape-Deck Top Header untuk TOBA VISION
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? leading;
  final bool useAppLogo;
  final IconData logoIcon;
  final Color? logoBg;
  final Color? logoColor;
  final double logoSize;
  final Widget? trailing;
  final Color? backgroundColor;
  final bool showBottomBorder;
  final EdgeInsetsGeometry? padding;
  final double? height;

  const AppHeader({
    super.key,
    this.title,
    this.subtitle,
    this.showBack = false,
    this.onBack,
    this.leading,
    this.useAppLogo = false,
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
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        border: showBottomBorder
            ? const Border(
                bottom: BorderSide(color: AppColors.ink, width: 2),
              )
            : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: showBack ? _buildBackTitle(context) : _buildBrandTitle(context),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBrandTitle(BuildContext context) {
    return Row(
      children: [
        if (leading != null)
          leading!
        else if (useAppLogo)
          TobaVisionLogo(size: logoSize)
        else
          Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              color: logoBg ?? AppColors.ink,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.ink, width: 1.5),
              boxShadow: const [
                BoxShadow(color: AppColors.ink, offset: Offset(2, 2)),
              ],
            ),
            child: Icon(
              logoIcon,
              size: logoSize * 0.55,
              color: logoColor ?? AppColors.lime,
            ),
          ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null && title!.isNotEmpty)
                Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                )
              else
                const ChromeWordmark(fontSize: 18),
              const SizedBox(height: 2),
              MicroText(
                subtitle ?? 'TEMANGGUNG, JATENG • TB-SYS',
                fontSize: 8.5,
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackTitle(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onBack ?? () => Navigator.maybePop(context),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.ink, width: 1.8),
              boxShadow: const [
                BoxShadow(color: AppColors.ink, offset: Offset(2, 2)),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.ink,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title ?? 'KEMBALI',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.display(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                MicroText(
                  subtitle!,
                  fontSize: 8.5,
                  color: AppColors.muted,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tombol aksi cepat bergaya tombol fisik kaset audio (tactile button)
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
          color: backgroundColor ?? AppColors.paper,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.ink, width: 1.8),
          boxShadow: const [
            BoxShadow(color: AppColors.ink, offset: Offset(2, 2)),
          ],
        ),
        child: Icon(
          icon,
          color: color ?? AppColors.ink,
          size: size * 0.52,
        ),
      ),
    );
  }
}
