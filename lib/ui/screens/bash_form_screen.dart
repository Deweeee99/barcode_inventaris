import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:signature/signature.dart';

import '../../services/api_services.dart';
import '../../models/barang_model.dart';
import 'scan_screen.dart';

class BastFormScreen extends StatefulWidget {
  final BarangModel? initialAsset;
  
  const BastFormScreen({super.key, this.initialAsset});

  @override
  State<BastFormScreen> createState() => _BastFormScreenState();
}

class _BastFormScreenState extends State<BastFormScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  String _namaUser = "Memuat...";
  
  // Karena backend sekarang support Array, kita bikin list. Walau cuma 1 barang.
  List<BarangModel> _selectedAssets = [];
  
  String _jenisMutasi = "karyawan"; // Sesuai backend: 'karyawan' atau 'lokasi'
  
  final TextEditingController _penerimaCtrl = TextEditingController();

  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    if (widget.initialAsset != null) {
      _selectedAssets.add(widget.initialAsset!);
    }
  }

  @override
  void dispose() {
    _penerimaCtrl.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _namaUser = prefs.getString('nama_user') ?? "Petugas TSI";
    });
  }

  Future<void> _handleScanAsset() async {
    final barcodeResult = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanScreen()),
    );

    if (barcodeResult != null && barcodeResult is String) {
      // Cek kalo barangnya udah ada di list
      if (_selectedAssets.any((asset) => asset.kodeBarcode == barcodeResult)) {
        _showError("Barang ini udah ada di dalam daftar BAST Tuan!");
        return;
      }

      setState(() => _isLoading = true);
      try {
        final response = await _apiService.getDetailBarang(barcodeResult);
        var data = response.data;
        if (data is String) data = jsonDecode(data);
        
        // Sesuaikan dengan response getDetailBarang
        var jsonData = data['data'] ?? data['barang'] ?? data;

        if (jsonData != null) {
          setState(() {
            _selectedAssets.add(BarangModel.fromJson(jsonData));
          });
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Aset $barcodeResult berhasil ditambahkan!'), backgroundColor: Colors.green),
            );
          }
        } else {
          _showError("Aset dengan kode $barcodeResult kaga nemu di database!");
        }
      } catch (e) {
        _showError("Gagal narik data aset: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // JURUS POP-UP ERROR MANUSIAWI
  void _showError(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 50),
            const SizedBox(height: 15),
            Text(
              "Ups, Ada Masalah Tuan!", 
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)
            ),
          ],
        ),
        content: Text(
          msg, 
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87)
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0087FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text("SIAP TUAN, SAYA CEK LAGI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _konfirmasiSerahTerima() async {
    if (_selectedAssets.isEmpty) {
      _showError("Tambahin barangnya dulu lewat Scan!");
      return;
    }

    String inputTujuan = _penerimaCtrl.text.trim();
    if (inputTujuan.isEmpty) {
      _showError(_jenisMutasi == "karyawan" ? "NIP Penerima wajib diisi!" : "Lokasi tujuan wajib diisi!");
      return;
    }

    // --- JURUS KEMBALIKAN VALIDASI LOKAL (ANTI MUTASI KE ORANG/TEMPAT YG SAMA) ---
    for (var asset in _selectedAssets) {
      if (_jenisMutasi == "karyawan") {
        // FIX DEWA: Cek langsung ke nipPemegang, bukan ke nama!
        if (asset.nipPemegang == inputTujuan) {
          _showError("Aset ${asset.namaBarang} saat ini udah dipegang sama NIP $inputTujuan, barang tidak bisa di mutasi oleh NIP yang sama.");
          return;
        }
      } else {
        // Cek apakah lokasi fisik saat ini sama dengan lokasi yang diketik
        if (asset.lokasiFisik.toLowerCase() == inputTujuan.toLowerCase()) {
          _showError("Aset ${asset.namaBarang} saat ini udah ada di $inputTujuan, lokasi tidak bisa dipindah ke ruangan yang sama.");
          return;
        }
      }
    }
    // --------------------------------------------------------------------------

    if (_signatureController.isEmpty) {
      _showError("Tanda tangan penerima wajib diisi!");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final Uint8List? signatureBytes = await _signatureController.toPngBytes();

      // --- SESUAIKAN SAMA PAYLOAD LARAVEL BARU ---
      Map<String, dynamic> dataUpdate = {
        // Ambil ID dari semua barang yang disekam jadi List
        "id_barang": _selectedAssets.map((e) => e.id).toList(), 
        "jenis_transaksi": _jenisMutasi, // 'karyawan' atau 'lokasi'
      };

      if (_jenisMutasi == "karyawan") {
        dataUpdate["nip_penerima"] = inputTujuan;
      } else {
        dataUpdate["lokasi_tujuan"] = inputTujuan;
      }

      if (signatureBytes != null) {
        dataUpdate["bukti_serah_terima"] = await MultipartFile.fromBytes(
          signatureBytes,
          filename: 'ttd_bast_${DateTime.now().millisecondsSinceEpoch}.png',
        );
      }

      await _apiService.submitMutasiBarang(dataUpdate);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('BAST Mutasi Berhasil! Data aset telah diperbarui.'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); 
      }
    } catch (e) {
      String msg = "Gagal simpan BAST!!";
      
      if (e is DioException) {
        if (e.error != null) {
          msg = e.error.toString();
        }

        if (msg.contains("RequestOptions") || msg.contains("validateStatus") || msg.contains("status code 422")) {
          msg = "Ada kesalahan data. Mohon periksa kembali isian form.";
        }
        
        String responseBody = e.response?.data?.toString().toLowerCase() ?? "";
        if (responseBody.contains("penerima") && responseBody.contains("sama") || 
            responseBody.contains("already assigned")) { 
           msg = "Maaf tidak bisa nginput NIP/Lokasi yang sama dengan posisi sebelumnya!";
        } else if (responseBody.isNotEmpty) {
           msg = "Ditolak Server: $responseBody";
        }
      }
      
      _showError(msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "BAST Digital",
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Pastikan barang fisik telah diperiksa oleh penerima sebelum tanda tangan. Anda bisa scan beberapa barang sekaligus.",
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
          
              // TOMBOL SCAN BARANG
              GestureDetector(
                onTap: _isLoading ? null : _handleScanAsset,
                child: Container(
                  height: 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_scanner, color: Colors.blue),
                      const SizedBox(width: 15),
                      Text("Scan Tambah Barang", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue)),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 15),

              // LIST BARANG YANG MAU DI-BAST
              if (_selectedAssets.isNotEmpty)
                Column(
                  children: _selectedAssets.asMap().entries.map((entry) {
                    int idx = entry.key;
                    BarangModel asset = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(12), 
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2, color: Colors.grey, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(asset.namaBarang, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text("BC: ${asset.kodeBarcode}", style: GoogleFonts.sourceCodePro(fontSize: 10, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          // Jangan kasih hapus kalo ini inisial aset dari layar detail
                          if (widget.initialAsset == null || widget.initialAsset!.id != asset.id)
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 20), 
                              onPressed: () => setState(() {
                                _selectedAssets.removeAt(idx);
                              })
                            )
                        ],
                      ),
                    );
                  }).toList(),
                ),
              
              const SizedBox(height: 25),
              Text("DETAIL MUTASI", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11)),
              const SizedBox(height: 10),
              
              Container(
                height: 45,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildToggleItem("Pindah Tangan", Icons.person_outline, "karyawan"),
                    _buildToggleItem("Pindah Lokasi", Icons.location_on_outlined, "lokasi"),
                  ],
                ),
              ),
          
              const SizedBox(height: 25),
              _buildLabel("Pihak Pemberi (Sistem)"),
              TextField(
                readOnly: true,
                decoration: _buildInputDeco(hint: "$_namaUser (Saya)", icon: Icons.person_pin_circle_outlined),
              ),
          
              const SizedBox(height: 20),
              _buildLabel(_jenisMutasi == "karyawan" ? "NIP Penerima Baru" : "Lokasi Tujuan Baru"),
              TextField(
                key: ValueKey(_jenisMutasi), 
                controller: _penerimaCtrl,
                keyboardType: _jenisMutasi == "karyawan" ? TextInputType.number : TextInputType.text,
                decoration: _buildInputDeco(
                  hint: _jenisMutasi == "karyawan" ? "Masukkan NIP Penerima" : "Masukkan Lokasi Baru",
                  icon: _jenisMutasi == "karyawan" ? Icons.badge_outlined : Icons.map_outlined,
                ),
              ),
          
              const SizedBox(height: 25),
              _buildLabel("Tanda Tangan Penerima"),
              Container(
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Signature(controller: _signatureController, height: 180, backgroundColor: const Color(0xFFF8F9FA)),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _signatureController.clear(),
                  icon: const Icon(Icons.refresh, size: 14, color: Colors.redAccent),
                  label: const Text("Hapus Ulang", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: (_isLoading || _selectedAssets.isEmpty) ? null : _konfirmasiSerahTerima,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedAssets.isEmpty ? const Color(0xFFF1F1F1) : const Color(0xFF0087FF),
              foregroundColor: _selectedAssets.isEmpty ? Colors.black38 : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isLoading 
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_circle_outline, size: 20),
            label: Text(_isLoading ? "Memproses..." : "Konfirmasi Serah Terima"),
          ),
        ),
      ),
    );
  }

  // Parameter ke-3 disesuaikan sama kebutuhan backend (karyawan/lokasi)
  Widget _buildToggleItem(String label, IconData icon, String valueBackend) {
    bool isSelected = _jenisMutasi == valueBackend;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _jenisMutasi = valueBackend;
            _penerimaCtrl.clear();
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.blue : Colors.grey),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isSelected ? Colors.blue : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)));
  InputDecoration _buildInputDeco({String? hint, IconData? icon}) => InputDecoration(
    hintText: hint, prefixIcon: icon != null ? Icon(icon, size: 20) : null, filled: true, fillColor: const Color(0xFFEEEEEE),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}