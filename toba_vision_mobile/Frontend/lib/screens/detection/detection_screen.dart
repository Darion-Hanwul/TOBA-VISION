import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../widgets/retro/micro_text.dart';
import '../../widgets/retro/reel_loader.dart';
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

  Future<void> _capturePhoto() async {
    if (_isAnalyzing) return;
    setState(() => _isAnalyzing = true);

    try {
      String? photoPath;
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final xFile = await _cameraController!.takePicture();
        photoPath = xFile.path;
      }

      await Future.delayed(const Duration(milliseconds: 1400));

      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ink,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.lime, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    photoPath != null
                        ? 'FOTO BERHASIL: ${photoPath.split(r'\').last.split('/').last}'
                        : 'PEMINDAIAN DAUN SELESAI // GRADE A PRIMA',
                    style: AppTypography.mono(fontSize: 11, color: AppColors.paper),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
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
        setState(() => _isAnalyzing = true);
        await Future.delayed(const Duration(milliseconds: 1400));
        if (mounted) {
          setState(() => _isAnalyzing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.ink,
              content: Text(
                'FOTO GALERI DIPINDAI: ${xFile.name} // GRADE A',
                style: AppTypography.mono(fontSize: 11, color: AppColors.paper),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
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
                colors: [Color(0xEE141414), Colors.transparent, Color(0x99141414)],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // 3. Header
          SafeArea(
            child: _buildRetroHeader(),
          ),

          // 4. Central Viewfinder HUD Area (256x288 px)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRetroViewfinder(),
                const SizedBox(height: 16),
                _buildInstructionPill(),
              ],
            ),
          ),

          // 5. Bottom Actions (Unggah Galeri, Tombol Pindai AI, Info Tips)
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: SafeArea(
              top: false,
              child: _buildBottomActions(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetroHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PINDAI DAUN TEMBAKAU',
                style: AppTypography.display(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.paper,
                ),
              ),
              const SizedBox(height: 1),
              
            ],
          ),

          // Tombol Senter Fisik Bulat Bertepi Lime
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

  Widget _buildRetroViewfinder() {
    return Container(
      width: 256,
      height: 288,
      decoration: BoxDecoration(
        color: const Color(0x1A86D12A),
        border: Border.all(color: AppColors.lime.withValues(alpha: 0.35), width: 1),
      ),
      child: Stack(
        children: [
          // Garis pemindaian naik-turun
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Positioned(
                top: _animController.value * (288 - 4),
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lime.withValues(alpha: 0.8),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Sudut siku tebal warna lime
          Positioned.fill(
            child: CustomPaint(
              painter: _HudCornerBracketsPainter(),
            ),
          ),

          // Teks HUD di dalam viewfinder
          Positioned(
            top: 8,
            left: 10,
            child: const MicroText('POSISIKAN DAUN // RETICLE', fontSize: 8, color: AppColors.lime),
          ),
          
        ],
      ),
    );
  }

  Widget _buildInstructionPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
        children: const [
          Icon(Icons.info_outline_rounded, size: 14, color: AppColors.ink),
          SizedBox(width: 6),
          MicroText(
            'PASTIKAN PENCAHAYAAN TERANG & DAUN FOKUS',
            fontSize: 9,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
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
            label: _isAnalyzing ? 'MEMINDAI...' : 'PINDAI AI',
            isLoading: _isAnalyzing,
            onPressed: _capturePhoto,
          ),
        ),
      ],
    );
  }
}

class _HudCornerBracketsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.lime
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
