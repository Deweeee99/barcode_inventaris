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
  BarangModel? _selectedAsset;
  String _jenisMutasi = "Pindah Tangan"; 
  
  final TextEditingController _penerimaCtrl = TextEditingController();
  final TextEditingController _catatanCtrl = TextEditingController(); 

  final List<String> conditionItems = ['Baik', 'Rusak Ringan', 'Rusak Berat', 'Dalam Perbaikan'];
  String _selectedCondition = 'Baik';

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
      _selectedAsset = widget.initialAsset;
      _selectedCondition = _selectedAsset!.kondisi;
      if (!conditionItems.contains(_selectedCondition)) {
        _selectedCondition = 'Baik';
      }

      if (_jenisMutasi == "Pindah Lokasi") {
        _catatanCtrl.text = "Mutasi dari lokasi lama: ${_selectedAsset!.lokasiFisik}";
      }
    }
  }

  @override
  void dispose() {
    _penerimaCtrl.dispose();
    _catatanCtrl.dispose();
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
      setState(() => _isLoading = true);
      try {
        final response = await _apiService.getBarang();
        var data = response.data;
        if (data is String) data = jsonDecode(data);
        
        List<dynamic> listRaw = data['barang']?['data'] ?? data['data'] ?? [];
        
        var found = listRaw.firstWhere(
          (element) => element['kode_barcode'] == barcodeResult,
          orElse: () => null,
        );

        if (found != null) {
          setState(() {
            _selectedAsset = BarangModel.fromJson(found);
            _selectedCondition = _selectedAsset!.kondisi;
            if (!conditionItems.contains(_selectedCondition)) _selectedCondition = 'Baik';

            if (_jenisMutasi == "Pindah Lokasi") {
              _catatanCtrl.text = "Mutasi dari lokasi lama: ${_selectedAsset!.lokasiFisik}";
            }
          });
        } else {
          _showError("Aset dengan kode $barcodeResult kaga nemu di database Tuan!");
        }
      } catch (e) {
        _showError("Gagal narik data aset: $e");
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // JURUS POP-UP ERROR YANG BERSIH & MANUSIAWI
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
    if (_selectedAsset == null) {
      _showError("Tambahin barangnya dulu lewat Scan Tuan!");
      return;
    }

    String inputTujuan = _penerimaCtrl.text.trim();
    if (inputTujuan.isEmpty) {
      _showError(_jenisMutasi == "Pindah Tangan" ? "NIP Penerima wajib diisi!" : "Lokasi tujuan wajib diisi!");
      return;
    }

    if (_signatureController.isEmpty) {
      _showError("Tanda tangan penerima wajib diisi bos!");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final Uint8List? signatureBytes = await _signatureController.toPngBytes();

      Map<String, dynamic> dataUpdate = {
        "kode_barcode": _selectedAsset!.kodeBarcode,
        "status_kondisi": _selectedCondition,
        "catatan": _catatanCtrl.text.isEmpty ? "Mutasi Aset" : _catatanCtrl.text,
      };

      if (_jenisMutasi == "Pindah Tangan") {
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
      // JURUS SAKTI FIX ERROR RED SCREEN / TECHNICAL JARGON
      String msg = "Gagal simpan BAST Tuan.";
      
      if (e is DioException) {
        // Ambil error dari interceptor (pesanError yang kita buat di api_services)
        if (e.error != null) {
          msg = e.error.toString();
        }

        // Kalau isinya teks teknis Dio atau 'validateStatus', kita paksa ganti
        if (msg.contains("RequestOptions") || msg.contains("validateStatus") || msg.contains("status code 422")) {
          msg = "Ada kesalahan data Tuan. Mohon periksa kembali isian form.";
        }
        
        // Logika Deteksi NIP SAMA:
        // Biasanya kalau NIP sama, backend ngirim info di response data atau error message
        String responseBody = e.response?.data?.toString().toLowerCase() ?? "";
        if (responseBody.contains("penerima") && responseBody.contains("sama") || 
            responseBody.contains("already assigned") ||
            inputTujuan == _selectedAsset?.karyawanPemegang) { // Cek lokal juga biar aman
           msg = "Maaf tidak bisa nginput NIP yang sama dengan orang sebelumnya Tuan!";
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
                        "Pastikan barang fisik telah diperiksa oleh penerima sebelum tanda tangan.",
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
          
              if (_selectedAsset == null)
                GestureDetector(
                  onTap: _isLoading ? null : _handleScanAsset,
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_scanner, color: Colors.blue),
                        const SizedBox(width: 15),
                        Text("Scan Barcode Barang", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(15), 
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2, color: Colors.blue, size: 30),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedAsset!.namaBarang, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text("Barcode: ${_selectedAsset!.kodeBarcode}", style: GoogleFonts.sourceCodePro(fontSize: 11, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      if (widget.initialAsset == null)
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent), 
                          onPressed: () => setState(() {
                            _selectedAsset = null;
                            _catatanCtrl.clear();
                            _penerimaCtrl.clear();
                          })
                        )
                    ],
                  ),
                ),
              
              const SizedBox(height: 25),
              Text("DETAIL MUTASI & KONDISI", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11)),
              const SizedBox(height: 10),
              
              Container(
                height: 45,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildToggleItem("Pindah Tangan", Icons.person_outline),
                    _buildToggleItem("Pindah Lokasi", Icons.location_on_outlined),
                  ],
                ),
              ),
          
              const SizedBox(height: 25),
              _buildLabel("Pihak Pemberi"),
              TextField(
                readOnly: true,
                decoration: _buildInputDeco(hint: "$_namaUser (Saya)", icon: Icons.person_pin_circle_outlined),
              ),
          
              const SizedBox(height: 20),
              _buildLabel(_jenisMutasi == "Pindah Tangan" ? "NIP Penerima Baru" : "Lokasi Tujuan Baru"),
              TextField(
                key: ValueKey(_jenisMutasi), 
                controller: _penerimaCtrl,
                keyboardType: _jenisMutasi == "Pindah Tangan" ? TextInputType.number : TextInputType.text,
                decoration: _buildInputDeco(
                  hint: _jenisMutasi == "Pindah Tangan" ? "Masukkan NIP" : "Masukkan Lokasi Baru",
                  icon: _jenisMutasi == "Pindah Tangan" ? Icons.badge_outlined : Icons.map_outlined,
                ),
              ),

              const SizedBox(height: 20),
              _buildLabel("Kondisi Fisik Saat Serah Terima"),
              DropdownButtonFormField<String>(
                value: _selectedCondition,
                decoration: _buildInputDeco(icon: Icons.offline_bolt_outlined),
                items: conditionItems.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setState(() => _selectedCondition = v!),
              ),
          
              const SizedBox(height: 20),
              _buildLabel("Catatan"),
              TextField(
                controller: _catatanCtrl, 
                maxLines: 2,
                decoration: _buildInputDeco(hint: "Alasan mutasi...", icon: Icons.edit_note_outlined),
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
            onPressed: (_isLoading || _selectedAsset == null) ? null : _konfirmasiSerahTerima,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedAsset == null ? const Color(0xFFF1F1F1) : const Color(0xFF0087FF),
              foregroundColor: _selectedAsset == null ? Colors.black38 : Colors.white,
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

  Widget _buildToggleItem(String label, IconData icon) {
    bool isSelected = _jenisMutasi == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _jenisMutasi = label;
            _penerimaCtrl.clear();
            if (_jenisMutasi == "Pindah Lokasi" && _selectedAsset != null) {
              _catatanCtrl.text = "Mutasi dari lokasi lama: ${_selectedAsset!.lokasiFisik}";
            } else {
              _catatanCtrl.clear();
            }
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