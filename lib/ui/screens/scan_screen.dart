import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
// Kalo error di sini, pastiin Tuan udah install: flutter pub add mobile_scanner
import 'package:mobile_scanner/mobile_scanner.dart'; 

import '../../services/api_services.dart';
import '../../models/barang_model.dart';
import 'asset_detail_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ApiService _apiService = ApiService();
  bool _isProcessing = false; // Biar kamera kaga nyepam pop-up berkali-kali

  // JURUS SAKTI NGECEK API DAN PINDAH KE DETAIL
  Future<void> _cekDetailAset(String barcode, BuildContext dialogContext) async {
    // Tunjukin loading puter-puter di dalem dialog
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator(color: Color(0xFF0087FF)))
    );

    try {
      final response = await _apiService.getDetailBarang(barcode);
      var data = response.data;
      if (data is String) data = jsonDecode(data);
      var jsonData = data['data'] ?? data['barang'] ?? data;

      if (jsonData != null && mounted) {
        BarangModel asset = BarangModel.fromJson(jsonData);
        
        Navigator.pop(context); // Tutup Loading
        Navigator.pop(dialogContext); // Tutup Dialog Pop-up Barcode
        
        // Gas pindah ke layar Detail Aset (Pake pushReplacement biar pas di-back kaga balik ke kamera lagi)
        await Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => AssetDetailScreen(asset: asset))
        );
      }
    } catch (e) {
      Navigator.pop(context); // Tutup Loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yah, Aset $barcode kaga ketemu di server!'), backgroundColor: Colors.red),
      );
    }
  }

  // FUNGSI BUAT MUNCULIN POP-UP
  void _showBarcodePopup(String barcode) {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              const Icon(Icons.qr_code_scanner, color: Color(0xFF0087FF), size: 50),
              const SizedBox(height: 10),
              Text("Barcode Ditemukan!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text(
            barcode, 
            textAlign: TextAlign.center, 
            style: GoogleFonts.sourceCodePro(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Column(
              children: [
                // TOMBOL 1: Tombol sakti buat ngecek ke API dan buka Detail Aset!
                ElevatedButton(
                  onPressed: () => _cekDetailAset(barcode, dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0087FF),
                    minimumSize: const Size(double.infinity, 45), // Bikin tombolnya full lebar
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Lihat Detail Aset", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                // TOMBOL 2: Kalo cuma butuh ngambil ID Barcode-nya (misal buat Form BAST)
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext); // Tutup dialog
                    Navigator.pop(context, barcode); // Balik ke layar sebelumnya bawa teks barcode
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Gunakan Barcode"),
                ),
                const SizedBox(height: 8),
                // TOMBOL 3: Cancel
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext); // Cuma tutup dialog
                  }, 
                  child: const Text("Scan Ulang", style: TextStyle(color: Colors.grey)),
                )
              ],
            )
          ],
        );
      }
    ).then((_) {
      // Kalo dialog ditutup (entah dipencet tombol cancel atau area luar), aktifin kamera lagi
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text("Scan Barcode Aset", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Stack(
        children: [
          // WIDGET KAMERA (Mobile Scanner)
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !_isProcessing) {
                final String code = barcodes.first.rawValue ?? "Unknown";
                _showBarcodePopup(code);
              }
            },
          ),

          // EFEK KOTAK SCANNER DI TENGAH LAYAR
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF0087FF), width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          
          // TEKS PANDUAN BAWAH
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20)
                ),
                child: Text(
                  "Arahkan kamera ke barcode aset", 
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}