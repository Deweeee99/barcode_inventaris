import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Library Kamera
import 'package:google_fonts/google_fonts.dart';
import 'asset_detail_screen.dart'; // Pastikan file ini ada

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  // Variabel penanda apakah kamera sedang boleh memproses barcode atau tidak
  bool _isScanning = true; 
  
  // Remote Control untuk Kamera
  final MobileScannerController cameraController = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      
      // APP BAR (Transparan)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Scan Aset", 
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)
        ),
        actions: [
          // TOMBOL FLASH (Senter)
          ValueListenableBuilder(
            valueListenable: cameraController,
            builder: (context, state, child) {
              // Cek status senter
              final isTorchOn = state.torchState == TorchState.on;
              return IconButton(
                icon: Icon(
                  isTorchOn ? Icons.flash_on : Icons.flash_off,
                  color: isTorchOn ? Colors.yellow : Colors.grey,
                ),
                onPressed: () => cameraController.toggleTorch(),
              );
            },
          ),
          // TOMBOL GANTI KAMERA (Depan/Belakang)
          ValueListenableBuilder(
            valueListenable: cameraController,
            builder: (context, state, child) {
              // PERBAIKAN DISINI: Menggunakan CameraFacing agar kompatibel
              final isFrontCamera = state.cameraDirection == CameraFacing.front;
              return IconButton(
                icon: Icon(
                  isFrontCamera ? Icons.camera_front : Icons.camera_rear,
                  color: Colors.white,
                ),
                onPressed: () => cameraController.switchCamera(),
              );
            },
          ),
        ],
      ),
      
      body: Stack(
        children: [
          // 1. LAYAR KAMERA UTAMA
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (!_isScanning) return; 
              
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _showResultDialog(barcode.rawValue!); 
                  break; 
                }
              }
            },
          ),
          
          // 2. OVERLAY KOTAK FOKUS
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF0087FF), width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_corner(), _corner(rot: 90)]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_corner(rot: 270), _corner(rot: 180)]),
                ],
              ),
            ),
          ),
          
          // 3. TEKS PETUNJUK
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Arahkan kamera ke Barcode / QR Code",
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _corner({int rot = 0}) {
    return RotatedBox(
      quarterTurns: rot ~/ 90,
      child: Container(
        width: 30, height: 30,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white, width: 4),
            left: BorderSide(color: Colors.white, width: 4),
          ),
        ),
      ),
    );
  }

  void _showResultDialog(String code) {
    setState(() {
      _isScanning = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              const Icon(Icons.qr_code, color: Color(0xFF0087FF)),
              const SizedBox(width: 10),
              Text("Barcode Ditemukan", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Isi Barcode:", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 5),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText( 
                  code, 
                  style: GoogleFonts.sourceCodePro(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); 
                setState(() {
                  _isScanning = true; 
                });
              },
              child: Text("Scan Lagi", style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            // ElevatedButton(
            //   onPressed: () {
            //     Navigator.pop(context); 
            //     Navigator.pushReplacement(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => AssetDetailScreen(
            //           assetName: "Aset Hasil Scan", 
            //           assetId: code,                
            //         ),
            //       ),
            //     );
            //   },
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: const Color(0xFF0087FF),
            //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            //   ),
            //   child: Text("Lihat Detail", style: GoogleFonts.poppins(color: Colors.white)),
            // ),
          ],
        );
      },
    );
  }
}