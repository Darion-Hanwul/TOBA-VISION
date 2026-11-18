import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'reel_loader.dart';

/// Tombol CTA oranye retro berbentuk trapesium (sisi miring ala tab produk retro),
/// dengan teks monospace tebal bertanda hubung "----TEKS----", efek tekan tactile (translate),
/// dan bayangan offset keras warna ink.
class TrapezoidTabButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final double height;
  final double slantWidth;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;

  const TrapezoidTabButton({
    super.key,
    required this.label,
    VoidCallback? onPressed,
    VoidCallback? onTap,
    Color? backgroundColor,
    Color? color,
    this.textColor = AppColors.paper,
    this.borderColor = AppColors.ink,
    this.height = 48,
    this.slantWidth = 14,
    this.isLoading = false,
    this.isExpanded = true,
    this.icon,
  })  : onPressed = onPressed ?? onTap,
        backgroundColor = backgroundColor ?? color ?? AppColors.orange;

  @override
  State<TrapezoidTabButton> createState() => _TrapezoidTabButtonState();
}

class _TrapezoidTabButtonState extends State<TrapezoidTabButton> {
  bool _isPressed = false;

  String _formatLabel(String raw) {
    if (raw.startsWith('--') && raw.endsWith('--')) return raw.toUpperCase();
    return '-- ${raw.toUpperCase()} --';
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final displayOffset = _isPressed ? const Offset(2, 2) : Offset.zero;
    final shadowOffset = _isPressed ? const Offset(2, 2) : const Offset(4, 4);

    Widget buttonContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (widget.isLoading) ...[
          const ReelLoader(size: 20, color: Colors.white),
          const SizedBox(width: 8),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: widget.textColor),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatLabel(widget.label),
              maxLines: 1,
              style: AppTypography.mono(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: enabled ? widget.textColor : AppColors.muted,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ],
    );

    Widget trapezoidBody = ClipPath(
      clipper: _TrapezoidClipper(slantWidth: widget.slantWidth),
      child: Container(
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: enabled ? widget.backgroundColor : const Color(0xFFC4BAA9),
          border: Border.all(color: widget.borderColor, width: 2),
        ),
        alignment: Alignment.center,
        child: buttonContent,
      ),
    );

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
      child: Stack(
        children: [
          // Hard shadow layer di belakang
          Positioned(
            left: shadowOffset.dx,
            top: shadowOffset.dy,
            right: -shadowOffset.dx,
            bottom: -shadowOffset.dy,
            child: ClipPath(
              clipper: _TrapezoidClipper(slantWidth: widget.slantWidth),
              child: Container(
                height: widget.height,
                color: enabled ? AppColors.ink : Colors.transparent,
              ),
            ),
          ),
          // Tombol utama dengan tactile translation
          Transform.translate(
            offset: displayOffset,
            child: trapezoidBody,
          ),
        ],
      ),
    );
  }
}

class _TrapezoidClipper extends CustomClipper<Path> {
  final double slantWidth;

  const _TrapezoidClipper({required this.slantWidth});

  @override
  Path getClip(Size size) {
    final path = Path();
    // Trapesium: atas lebih pendek atau bersisi miring (kiri miring masuk, kanan miring keluar)
    path.moveTo(slantWidth, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width - slantWidth, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _TrapezoidClipper oldClipper) =>
      oldClipper.slantWidth != slantWidth;
}
