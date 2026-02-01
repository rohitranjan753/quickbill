import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/firestore_service.dart';
import '../models/store_model.dart';

class StoreIdScannerScreen extends StatefulWidget {
  const StoreIdScannerScreen({super.key});

  @override
  State<StoreIdScannerScreen> createState() => _StoreIdScannerScreenState();
}

class _StoreIdScannerScreenState extends State<StoreIdScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isProcessing = false;
  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.2, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final storeId = capture.barcodes.first.rawValue;
    if (storeId == null) return;

    setState(() => _isProcessing = true);

    try {
      // Get store from Firestore
      final store = await _firestoreService.getStore(storeId);
      if (!mounted) return;

      if (store != null) {
        // Store found - return to home screen
        Navigator.pop(context, store);
      } else {
        // Store not found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Store not found')),
              ],
            ),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: ${e.toString()}')),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Scan Store ID',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                _controller.torchEnabled ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
              onPressed: () => _controller.toggleTorch(),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera View
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
          ),

          // Scanning overlay
          AnimatedBuilder(
            animation: _scanLineAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: ScannerOverlay(
                  scanProgress: _scanLineAnimation.value,
                ),
                child: const SizedBox.expand(),
              );
            },
          ),

          // Bottom Instructions Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isProcessing)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 3,
                                ),
                              ),
                              SizedBox(width: 16),
                              Text(
                                'Processing...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.qr_code_scanner_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Scan Store QR Code',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Point camera at the store\'s QR code',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlay extends CustomPainter {
  final double scanProgress;

  ScannerOverlay({this.scanProgress = 0.5});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.75,
      height: size.height * 0.35,
    );

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanArea, const Radius.circular(24)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    final glowPaint = Paint()
      ..color = const Color(0xFF10B981).withOpacity(0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanArea, const Radius.circular(24)),
      glowPaint,
    );

    final cornerPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const cornerLength = 40.0;
    const cornerOffset = 8.0;

    // Draw corners (same as product scanner)
    canvas.drawLine(
      Offset(scanArea.left - cornerOffset, scanArea.top + cornerLength),
      Offset(scanArea.left - cornerOffset, scanArea.top - cornerOffset),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanArea.left - cornerOffset, scanArea.top - cornerOffset),
      Offset(scanArea.left + cornerLength, scanArea.top - cornerOffset),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(scanArea.right - cornerLength, scanArea.top - cornerOffset),
      Offset(scanArea.right + cornerOffset, scanArea.top - cornerOffset),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanArea.right + cornerOffset, scanArea.top - cornerOffset),
      Offset(scanArea.right + cornerOffset, scanArea.top + cornerLength),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(scanArea.left - cornerOffset, scanArea.bottom - cornerLength),
      Offset(scanArea.left - cornerOffset, scanArea.bottom + cornerOffset),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanArea.left - cornerOffset, scanArea.bottom + cornerOffset),
      Offset(scanArea.left + cornerLength, scanArea.bottom + cornerOffset),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(scanArea.right - cornerLength, scanArea.bottom + cornerOffset),
      Offset(scanArea.right + cornerOffset, scanArea.bottom + cornerOffset),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanArea.right + cornerOffset, scanArea.bottom - cornerLength),
      Offset(scanArea.right + cornerOffset, scanArea.bottom + cornerOffset),
      cornerPaint,
    );

    final scanLineY = scanArea.top + (scanArea.height * scanProgress);
    final scanLinePaint = Paint()
      ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFF10B981).withOpacity(0.8),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromLTWH(scanArea.left, scanLineY - 2, scanArea.width, 4),
          )
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(scanArea.left, scanLineY),
      Offset(scanArea.right, scanLineY),
      scanLinePaint,
    );
  }

  @override
  bool shouldRepaint(ScannerOverlay oldDelegate) =>
      oldDelegate.scanProgress != scanProgress;
}
