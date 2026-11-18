import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'retro/reel_loader.dart';
import 'retro/retro_card.dart';
import 'retro/trapezoid_tab_button.dart';

/// Menangani loading (memakai ReelLoader kaset tape-deck) / error / pull-to-refresh
/// untuk semua layar yang mengambil data asinkron.
class AsyncView<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;

  const AsyncView({super.key, required this.load, required this.builder});

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  Future<void> _reload() async {
    final f = widget.load();
    setState(() => _future = f);
    try {
      await f;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: ReelLoader(
                size: 44,
                color: AppColors.ink,
                label: 'MEMUAT DATA SISTEM...',
              ),
            ),
          );
        }

        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: RetroCard(
                tapeTag: 'SYSTEM ERROR // TAPE READ FAIL',
                rightTag: 'ERR-500',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 48, color: AppColors.orange),
                    const SizedBox(height: 12),
                    Text(
                      'DATA BELUM BISA DIMUAT',
                      style: AppTypography.display(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${snap.error}',
                      textAlign: TextAlign.center,
                      style: AppTypography.mono(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TrapezoidTabButton(
                      label: 'COBA LAGI',
                      height: 40,
                      isExpanded: false,
                      onPressed: _reload,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.lime,
          backgroundColor: AppColors.ink,
          onRefresh: _reload,
          child: widget.builder(context, snap.data as T),
        );
      },
    );
  }
}
