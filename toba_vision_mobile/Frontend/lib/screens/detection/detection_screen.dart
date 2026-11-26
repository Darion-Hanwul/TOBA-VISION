import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/services.dart';
import '../../widgets/detection_result_sheet.dart';
import '../../widgets/retro/micro_text.dart';
import '../../widgets/retro/trapezoid_tab_button.dart';

class DetectionScreen extends StatefulWidget {
  final VoidCallback onBack;
  const DetectionScreen({super.key, required this.onBack});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraReady = false;
  bool _isAnalyzing = false;
  bool _flashOn = false;
  TobaccoDetectionMode _selectedMode = TobaccoDetectionMode.grade;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        final backCamera = _cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first,
        );

        final controller = CameraController(
          backCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await controller.initialize();
        if (mounted) {
          setState(() {
            _cameraController = controller;
            _isCameraReady = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Kamera tidak tersedia atau akses ditolak: $e');
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      setState(() => _flashOn = !_flashOn);
      return;
    }

    try {
      if (_flashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
        setState(() => _flashOn = false);
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
        setState(() => _flashOn = true);
      }
    } catch (e) {
      debugPrint('Gagal mengubah mode flash: $e');
      setState(() => _flashOn = !_flashOn);
    }
  }

  void _selectMode(TobaccoDetectionMode mode) {
    if (_isAnalyzing || _selectedMode == mode) return;
    setState(() => _selectedMode = mode);
  }

  Future<void> _analyzeImagePath(String photoPath) async {
    if (!mounted) return;
    final activeMode = _selectedMode;
    setState(() => _isAnalyzing = true);

    try {
      final result = await Services.detection.analyze(
        imagePath: photoPath,
        mode: activeMode,
      );
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      await showDetectionResultSheet(context, result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.rust,
          content: Text(
            'Gagal memindai daun: $e',
            style: AppTypography.mono(fontSize: 11, color: Colors.white),
          ),
        ),
      );
    }
  }

  Future<void> _capturePhoto() async {
    if (_isAnalyzing) return;

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          content: Text(
            'KAMERA BELUM AKTIF • GUNAKAN TOMBOL GALERI DI KIRI BAWAH',
            style: AppTypography.mono(fontSize: 10.5, color: AppColors.lime),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      final xFile = await _cameraController!.takePicture();
      await _analyzeImagePath(xFile.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil gambar: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isAnalyzing) return;

    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(source: ImageSource.gallery);
      if (xFile != null && mounted) {
        await _analyzeImagePath(xFile.path);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka galeri: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview atau Fallback Gradient Gelap
          if (_isCameraReady && _cameraController != null)
            CameraPreview(_cameraController!)
          else
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [Color(0xFF1E2818), Color(0xFF0D120B)],
                ),
              ),
            ),

          // 2. Vignette Dark Overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xEE141414), Colors.transparent, Color(0xAA141414)],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // 3. HUD & Kontrol Kamera Responsif (Header + Pilih Fitur + Viewfinder + Tombol Aksi)
          SafeArea(
            child: Column(
              children: [
                _buildRetroHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildModeSelector(),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildRetroViewfinder(),
                            const SizedBox(height: 14),
                            _buildInstructionPill(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                  child: _buildBottomActions(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetroHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tombol Kembali Fisik Tape-Deck
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.lime, width: 1.5),
                boxShadow: const [
                  BoxShadow(color: AppColors.lime, offset: Offset(1.5, 1.5)),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: AppColors.lime, size: 20),
            ),
          ),

          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'PINDAI DAUN TEMBAKAU',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.display(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.paper,
                ),
              ),
            ),
          ),

          // Tombol Senter Fisik Bertepi Lime
          GestureDetector(
            onTap: _toggleFlash,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _flashOn ? AppColors.lime : AppColors.ink,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.lime, width: 1.5),
                boxShadow: const [
                  BoxShadow(color: AppColors.lime, offset: Offset(1.5, 1.5)),
                ],
              ),
              child: Icon(
                _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: _flashOn ? AppColors.ink : AppColors.lime,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Switcher 2 fitur deteksi AI offline agar petani mudah berganti antara Grade & Siap Panen.
  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lime, width: 1.5),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(2, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _modeTabItem(
              mode: TobaccoDetectionMode.grade,
              title: 'GRADE TEMBAKAU',
              subtitle: 'GRADE A • B • C',
              icon: Icons.workspace_premium_rounded,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _modeTabItem(
              mode: TobaccoDetectionMode.maturity,
              title: 'SIAP PANEN',
              subtitle: 'KEMATANGAN DAUN',
              icon: Icons.eco_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeTabItem({
    required TobaccoDetectionMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final bool active = _selectedMode == mode;
    final Color fg = active ? AppColors.ink : AppColors.paper;
    final Color subFg = active ? AppColors.ink.withValues(alpha: 0.78) : AppColors.lime;

    return GestureDetector(
      onTap: () => _selectMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.lime : const Color(0xFF1F241B),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: active ? AppColors.ink : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: fg),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.mono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: fg,
                      letterSpacing: 0.4,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.mono(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w700,
                      color: subFg,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetroViewfinder() {
    final bool isMaturity = _selectedMode == TobaccoDetectionMode.maturity;
    final Color hudColor = isMaturity ? AppColors.orange : AppColors.lime;

    return Container(
      width: 256,
      height: 272,
      decoration: BoxDecoration(
        color: hudColor.withValues(alpha: 0.10),
        border: Border.all(color: hudColor.withValues(alpha: 0.35), width: 1),
      ),
      child: Stack(
        children: [
          // Garis pemindaian naik-turun
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Positioned(
                top: _animController.value * (272 - 4),
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: hudColor,
                    boxShadow: [
                      BoxShadow(
                        color: hudColor.withValues(alpha: 0.8),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Sudut siku tebal warna aktif
          Positioned.fill(
            child: CustomPaint(
              painter: _HudCornerBracketsPainter(color: hudColor),
            ),
          ),

          // Teks HUD di dalam viewfinder sesuai fitur yang dipilih
          Positioned(
            top: 8,
            left: 10,
            child: MicroText(
              isMaturity
                  ? 'MODE KEMATANGAN // SIAP PANEN'
                  : 'MODE GRADE // MUTU DAUN A•B•C',
              fontSize: 8,
              color: hudColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionPill() {
    final String text = _selectedMode == TobaccoDetectionMode.maturity
        ? 'CEK SIAP PANEN: BELUM MATANG • MATANG • TERLALU MATANG'
        : 'DETEKSI GRADE: FOTO 1–2 DAUN TERANG & FOKUS';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.ink, width: 1.5),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(2, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.ink),
          const SizedBox(width: 6),
          MicroText(text, fontSize: 8.5),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final bool isMaturity = _selectedMode == TobaccoDetectionMode.maturity;
    final String ctaLabel;
    if (_isAnalyzing) {
      ctaLabel = isMaturity ? 'CEK KEMATANGAN...' : 'MEMINDAI GRADE...';
    } else {
      ctaLabel = isMaturity ? 'CEK KEMATANGAN' : 'PINDAI GRADE';
    }

    return Row(
      children: [
        // Tombol Galeri (Kotak Tape-Deck)
        GestureDetector(
          onTap: _pickFromGallery,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.ink, width: 2),
              boxShadow: const [
                BoxShadow(color: AppColors.ink, offset: Offset(2.5, 2.5)),
              ],
            ),
            child: const Icon(Icons.photo_library_outlined, color: AppColors.ink, size: 22),
          ),
        ),
        const SizedBox(width: 12),

        // Tombol Utama Pindai AI (Trapesium Oranye)
        Expanded(
          child: TrapezoidTabButton(
            label: ctaLabel,
            isLoading: _isAnalyzing,
            onPressed: _capturePhoto,
          ),
        ),
      ],
    );
  }
}

class _HudCornerBracketsPainter extends CustomPainter {
  final Color color;

  const _HudCornerBracketsPainter({this.color = AppColors.lime});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    const len = 20.0;

    // Top-left
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, len), paint);

    // Top-right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);

    // Bottom-left
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - len), paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - len, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - len), paint);
  }

  @override
  bool shouldRepaint(covariant _HudCornerBracketsPainter oldDelegate) =>
      oldDelegate.color != color;
}
