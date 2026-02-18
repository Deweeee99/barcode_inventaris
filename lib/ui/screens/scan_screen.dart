import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Library Kamera
import 'package:google_fonts/google_fonts.dart';
import 'asset_detail_screen.dart'; // Import Detail Screen

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isScanning = true; // Status biar gak scan berkali-kali dalam 1 detik
  MobileScannerController cameraController = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // APP BAR TRANSPARAN
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text("Scan Aset", style: GoogleFonts.poppins(color: Colors.white)),
        actions: [
          // TOMBOL SENTER / FLASH
          ValueListenableBuilder(
            valueListenable: cameraController, 
            builder: (context, state, child) {
              // Menangani perbedaan versi: Cek apakah torchState ada di state
              // Jika error di versi lama, biasanya cameraController.torchState terpisah
              return IconButton(
                icon: Icon(
                  state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                  color: state.torchState == TorchState.on ? Colors.yellow : Colors.grey,
                ),
                onPressed: () => cameraController.toggleTorch(),
              );
            },
          ),
          // TOMBOL GANTI KAMERA (DEPAN/BELAKANG)
          ValueListenableBuilder(
            valueListenable: cameraController, 
            builder: (context, state, child) {
              return IconButton(
                icon: Icon(
                  // PERBAIKAN: Menggunakan CameraFacing untuk kompatibilitas
                  state.cameraDirection == CameraFacing.front 
                      ? Icons.camera_front 
                      : Icons.camera_rear,
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
          // 1. KAMERA SCANNER
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (!_isScanning) return; // Kalau lagi loading, jangan scan dulu
              
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  // KETEMU! Proses kodenya
                  _handleBarcodeFound(barcode.rawValue!); 
                  break; 
                }
              }
            },
          ),

          // 2. OVERLAY KOTAK FOKUS (Visual Only)
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

  // WIDGET POJOKAN KOTAK (Hiasan)
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

  // --- LOGIKA UTAMA DISINI ---
  void _handleBarcodeFound(String code) async {
    // 1. Stop scanning biar gak manggil fungsi ini berkali-kali
    setState(() {
      _isScanning = false;
    });

    // 2. Munculkan Loading
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator())
    );
 if (mounted) {
       Navigator.pop(context); // Tutup Loading
       
       // Pindah ke Halaman Detail
       // Pakai pushReplacement biar kalau di-back gak balik ke kamera
       Navigator.pushReplacement(
         context,
         MaterialPageRoute(
           builder: (context) => AssetDetailScreen(
             assetName: "Aset Hasil Scan", // Nanti ini diganti data.name
             assetId: code,                // Ini kode yg discan tadi
           ),
         ),
       ).then((value) {
         // Kalau user balik lagi ke sini, nyalakan scanner lagi
         if (mounted) {
            setState(() {
                _isScanning = true;
            });
         }
       });
    }
  }
}