import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toba_vision_mobile/services/offline_service.dart';
import '../../services/api_service.dart';

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

  // ==========================================
  // PROSES PREDIKSI KE FASTAPI BACKEND (WEB & MOBILE SAFE)
  // ==========================================
  Future<void> _processImageForAi(XFile imageFile) async {
    setState(() => _isAnalyzing = true);

    try {
      // Baca bytes gambar untuk preview lintas platform (Web & Android/iOS)
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Ambil UID Petani dari sesi Hive
      final userData = OfflineService.getUserData();
      final String idPetani = (userData['uid']?.toString().isNotEmpty ?? false)
          ? userData['uid'].toString()
          : "guest_petani";

      // Panggil ApiService ke FastAPI (/api/predict) menggunakan XFile
      final result = await ApiService.predictTobaccoGrade(
        imageFile: imageFile,
        idPetani: idPetani,
      );

      if (!mounted) return;
      setState(() => _isAnalyzing = false);

      // Tampilkan Modal Dialog Hasil Prediksi
      _showResultDialog(result, imageBytes);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal melakukan analisis AI: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Ambil Foto Nyata via Kamera Perangkat (dengan fallback ImagePicker)
  Future<void> _capturePhoto() async {
    if (_isAnalyzing) return;

    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final XFile xFile = await _cameraController!.takePicture();
        if (mounted) {
          await _processImageForAi(xFile);
        }
      } else {
        // Fallback jika dijalankan di Web / emulator tanpa live preview camera
        final picker = ImagePicker();
        final XFile? xFile = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        if (xFile != null && mounted) {
          await _processImageForAi(xFile);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kamera tidak terdeteksi di perangkat ini. Gunakan tombol Galeri untuk mengunggah foto.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil gambar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Pilih Gambar dari Galeri Perangkat
  Future<void> _pickFromGallery() async {
    if (_isAnalyzing) return;

    try {
      final picker = ImagePicker();
      final XFile? xFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (xFile != null && mounted) {
        await _processImageForAi(xFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar dari galeri: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _getSaranByGrade(String grade) {
    final g = grade.toUpperCase();
    if (g.contains('A')) {
      return 'Kualitas prima (Matang Optimal). Segera rajang dan jemur di bawah sinar matahari penuh untuk mempertahankan warna kuning keemasan & nilai jual tinggi.';
    } else if (g.contains('B')) {
      return 'Kualitas baik (Cukup Matang). Lakukan pemeraman singkat 1–2 hari sebelum perajangan agar warna daun lebih merata.';
    } else {
      return 'Daun terdeteksi terlalu matang / lewat panen. Pisahkan dari batch Grade A/B dan keringkan secara bertahap agar tidak mudah hancur.';
    }
  }

  // ==========================================
  // MODAL DIALOG HASIL PREDIKSI AI
  // ==========================================
  void _showResultDialog(Map<String, dynamic> resultData, Uint8List imageBytes) {
    // Membaca response JSON FastAPI (/api/predict)
    final data = resultData['data'] ?? resultData;
    final String grade = (data['predicted_grade'] ?? data['grade'] ?? 'Grade B').toString();

    final rawConf = data['confidence_score'] ?? data['confidence'] ?? 85.0;
    double confidence = (rawConf is num) ? rawConf.toDouble() : double.tryParse(rawConf.toString()) ?? 85.0;
    if (confidence <= 1.0) {
      confidence = confidence * 100;
    }

    final String saran = (data['saran']?.toString().isNotEmpty ?? false)
        ? data['saran'].toString()
        : _getSaranByGrade(grade);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.verified_rounded, color: Color(0xFF047857), size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Hasil Analisis Mutu AI',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Preview Gambar (Image.memory) & Card Grade
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      imageBytes,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PREDIKSI GRADE:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          grade.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF047857),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Akurasi: ${confidence.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Rekomendasi / Saran Panen
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 20, color: Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        saran,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tombol Tutup / Simpan
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF047857),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Selesai & Simpan Hasil', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
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

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildAiStatusCard(),
              ],
            ),
          ),

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
                  Text(
                    _isAnalyzing
                        ? 'Sedang menganalisis daun tembakau...'
                        : 'Arahkan kamera ke daun tembakau',
                    style: const TextStyle(
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
                    decoration: BoxDecoration(
                      color: _isAnalyzing ? Colors.amber : const Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _isAnalyzing ? 'Proses' : 'Siap',
                    style: const TextStyle(
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
            Expanded(
              child: GestureDetector(
                onTap: _isAnalyzing ? null : _pickFromGallery,
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

            Expanded(
              child: GestureDetector(
                onTap: _isAnalyzing ? null : _capturePhoto,
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
                            _isAnalyzing ? 'Memindai...' : 'Ambil Foto',
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