import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Teks raksasa berjalan horizontal tanpa henti (marquee) ala LED ticker / display tape-deck.
/// Terpotong di tepi dan menghormati setting aksesibilitas reduce-motion.
class MarqueeText extends StatefulWidget {
  final String text;
  final double fontSize;
  final Color color;
  final double speed; // piksel per detik
  final double spacing;

  const MarqueeText({
    super.key,
    required this.text,
    this.fontSize = 42,
    this.color = AppColors.ink,
    this.speed = 35.0,
    this.spacing = 30.0,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 1));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startMarquee();
    });
  }

  void _startMarquee() {
    if (!mounted) return;
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    final durationSeconds = (maxScroll / widget.speed).clamp(2.0, 60.0);
    _animController.duration = Duration(milliseconds: (durationSeconds * 1000).toInt());

    _animController.addListener(() {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_animController.value * maxScroll);
      }
    });

    _animController.repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.display(
      fontSize: widget.fontSize,
      fontWeight: FontWeight.w900,
      color: widget.color,
      letterSpacing: -1.0,
    );

    return IgnorePointer(
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: List.generate(4, (index) {
            return Padding(
              padding: EdgeInsets.only(right: widget.spacing),
              child: Text(widget.text.toUpperCase(), style: style),
            );
          }),
        ),
      ),
    );
  }
}
