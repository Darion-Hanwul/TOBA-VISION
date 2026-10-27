import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
        // Ambil kamera belakang
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
      // Jika di web/desktop atau simulator tanpa sensor kamera, tetap tampil fallback gradient
      debugPrint('Kamera tidak tersedia atau akses ditolak: $e');
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  // Toggle Senter (Flashlight fisik)
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

  // Ambil Foto Nyata via Kamera
  Future<void> _capturePhoto() async {
    if (_isAnalyzing) return;

    setState(() => _isAnalyzing = true);

    try {
      String? photoPath;
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final xFile = await _cameraController!.takePicture();
        photoPath = xFile.path;
      }

      await Future.delayed(const Duration(milliseconds: 1200));

      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(photoPath != null
                ? 'Foto berhasil diambil: ${photoPath.split(r'\').last.split('/').last}'
                : 'Pemindaian daun tembakau selesai!'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF047857),
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

  // Pilih dari Galeri
  Future<void> _pickFromGallery() async {
    if (_isAnalyzing) return;

    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(source: ImageSource.gallery);
      if (xFile != null && mounted) {
        setState(() => _isAnalyzing = true);
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) {
          setState(() => _isAnalyzing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gambar terpilih: ${xFile.name}'),
              duration: const Duration(seconds: 2),
              backgroundColor: const Color(0xFF047857),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Gagal memilih gambar dari galeri: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF7F9FB),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Camera Preview atau Fallback Simulated Background
          if (_isCameraReady && _cameraController != null)
            CameraPreview(_cameraController!)
          else ...[
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF022C22), Color(0xFF0F172A), Color(0xFF022C22)],
                ),
              ),
            ),
            Opacity(
              opacity: 0.15,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.75,
                    colors: [Color(0xFF86EFAC), Colors.transparent],
                  ),
                ),
              ),
            ),
          ],

          // 2. Vignette Dark Overlay (Top & Bottom)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xCC000000), Colors.transparent, Color(0x66000000)],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // 3. Header & Floating Info Card
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildAiStatusCard(),
              ],
            ),
          ),

          // 4. Central Scanner Viewfinder Area (256x288 px)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewfinderBox(),
                const SizedBox(height: 20),
                _buildInstructionPill(),
              ],
            ),
          ),

          // 5. Bottom Action Buttons (Galeri, Ambil Foto, Tips)
          Positioned(
            left: 20,
            right: 20,
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

  // --- Sub-Widgets ---

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pindai Daun Tembakau',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Deteksi Otomatis AI Toba Vision',
                style: TextStyle(
                  color: const Color(0xFFA7F3D0).withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: _toggleFlash,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _flashOn
                    ? const Color(0xFFFCD34D).withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(
                  color: _flashOn ? const Color(0xFFFCD34D) : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Icon(
                _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: _flashOn ? const Color(0xFFFCD34D) : Colors.white70,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiStatusCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD1FAE5)),
          boxShadow: const [
            BoxShadow(color: Color(0x1A000000), blurRadius: 15, offset: Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 35,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF059669), Color(0xFF15803D)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.psychology_outlined, color: Color(0xFFD1FAE5), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'AI ACTIVE SCAN',
                        style: TextStyle(
                          color: Color(0xFF047857),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Arahkan kamera ke daun tembakau',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Siap',
                    style: TextStyle(
                      color: Color(0xFF065F46),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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

  Widget _buildViewfinderBox() {
    return Container(
      width: 256,
      height: 288,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 50, offset: Offset(0, 25)),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          _buildCornerBracket(top: 1, left: 1, isTop: true, isLeft: true),
          _buildCornerBracket(top: 1, right: 1, isTop: true, isLeft: false),
          _buildCornerBracket(bottom: 1, left: 1, isTop: false, isLeft: true),
          _buildCornerBracket(bottom: 1, right: 1, isTop: false, isLeft: false),

          // Laser Scanner
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Positioned(
                top: 14 + (_animController.value * (288 - 32)),
                left: 13,
                right: 13,
                child: child!,
              );
            },
            child: Container(
              height: 2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xFF34D399), Colors.transparent],
                ),
                boxShadow: [
                  BoxShadow(color: Color(0xFF34D399), blurRadius: 14, spreadRadius: 2),
                ],
              ),
            ),
          ),

          // Simbol Daun di Tengah jika kamera belum ready
          if (!_isCameraReady)
            Center(
              child: Opacity(
                opacity: 0.45,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.eco_rounded, size: 68, color: Color(0xFF34D399)),
                    SizedBox(height: 8),
                    Text(
                      'POSISIKAN DAUN',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                        color: Color(0xFFA7F3D0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstructionPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 15, offset: Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFF34D399),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0xFF34D399), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Posisikan daun di dalam bingkai',
            style: TextStyle(color: Color(0xFFD1FAE5), fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // Button Galeri
            Expanded(
              child: GestureDetector(
                onTap: _pickFromGallery,
                child: Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD1FAE5)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x1A000000), blurRadius: 15, offset: Offset(0, 10)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD1FAE5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.photo_library_rounded, color: Color(0xFF047857), size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Galeri',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                          Text(
                            'Unggah foto',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Button Ambil Foto (Nyata via Sensor Kamera)
            Expanded(
              child: GestureDetector(
                onTap: _capturePhoto,
                child: Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF047857),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF059669)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x1A000000), blurRadius: 15, offset: Offset(0, 10)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF065F46).withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                        child: _isAnalyzing
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(color: Color(0xFFA7F3D0), strokeWidth: 2),
                              )
                            : const Icon(Icons.camera_alt_rounded, color: Color(0xFFA7F3D0), size: 16),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isAnalyzing ? 'Memindai' : 'Ambil Foto',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                          const Text(
                            'Pindai AI',
                            style: TextStyle(
                              color: Color(0xFFA7F3D0),
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Tips Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF065F46).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF047857).withValues(alpha: 0.6)),
              ),
              child: const Text(
                'TIPS',
                style: TextStyle(
                  color: Color(0xFFA7F3D0),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Pastikan pencahayaan cukup terang',
              style: TextStyle(
                color: const Color(0xFFD1FAE5).withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCornerBracket({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required bool isTop,
    required bool isLeft,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(16) : Radius.zero,
            topRight: isTop && !isLeft ? const Radius.circular(16) : Radius.zero,
            bottomLeft: !isTop && isLeft ? const Radius.circular(16) : Radius.zero,
            bottomRight: !isTop && !isLeft ? const Radius.circular(16) : Radius.zero,
          ),
          border: Border(
            top: isTop ? const BorderSide(color: Color(0xFF34D399), width: 4) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: Color(0xFF34D399), width: 4) : BorderSide.none,
            left: isLeft ? const BorderSide(color: Color(0xFF34D399), width: 4) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: Color(0xFF34D399), width: 4) : BorderSide.none,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF34D399).withValues(alpha: 0.5),
              blurRadius: 10,
            ),
          ],
        ),
      ),
    );
  }
}
