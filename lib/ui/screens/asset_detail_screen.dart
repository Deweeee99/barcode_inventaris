import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:io'; 
import 'package:image_picker/image_picker.dart'; 
import 'package:dio/dio.dart'; 

import 'bash_form_screen.dart';
import '../../models/barang_model.dart'; 
import '../../services/api_services.dart'; 

class AssetDetailScreen extends StatefulWidget {
  final BarangModel asset;

  const AssetDetailScreen({
    super.key, 
    required this.asset,
  });

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  
  // --- STATE DATA DARI API ---
  bool _isFetchingDetail = true; 
  late BarangModel _currentAsset; 

  final List<String> conditionItems = ['Baik', 'Rusak Ringan', 'Rusak Berat', 'Dalam Perbaikan'];
  String? selectedCondition;
  String? _initialCondition; 

  // --- CONTROLLER CATATAN & KAMERA ---
  final TextEditingController _catatanCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _fotoKondisi;

  @override
  void initState() {
    super.initState();
    // Gunakan data awal dari list terlebih dahulu biar layar gak kosong
    _currentAsset = widget.asset; 
    _mapConditionFromDatabase();
    
    // Ambil data lengkap (Kontrak + Kondisi Terakhir) dari server
    _fetchDetailDariServer();
  }

  @override
  void dispose() {
    _catatanCtrl.dispose();
    super.dispose();
  }

  // Fungsi buat narik data barang secara komplit berdasarkan barcode
  Future<void> _fetchDetailDariServer() async {
    if (!mounted) return;
    setState(() => _isFetchingDetail = true);
    
    try {
      final response = await _apiService.getDetailBarang(_currentAsset.kodeBarcode);
      var data = response.data;
      if (data is String) data = jsonDecode(data);
      
      // Ambil data barang dari bungkusan JSON sesuai struktur backend Laravel
      var jsonData = data['data'] ?? data['barang'] ?? data;

      if (jsonData != null && mounted) {
        setState(() {
          _currentAsset = BarangModel.fromJson(jsonData);
          _mapConditionFromDatabase(); 
          _isFetchingDetail = false;
        });
      }
    } catch (e) {
      debugPrint("Error refresh detail: $e");
      if (mounted) setState(() => _isFetchingDetail = false); 
    }
  }

  // Menyelaraskan teks kondisi dari database ke item dropdown agar tidak error
  void _mapConditionFromDatabase() {
    String dbKondisi = _currentAsset.kondisi; 
    String dbKondisiLower = dbKondisi.toLowerCase();
    
    if (dbKondisiLower.contains('baik')) {
      _initialCondition = conditionItems[0];
    } else if (dbKondisiLower.contains('ringan')) {
      _initialCondition = conditionItems[1];
    } else if (dbKondisiLower.contains('berat')) {
      _initialCondition = conditionItems[2];
    } else if (dbKondisiLower.contains('perbaikan')) {
      _initialCondition = conditionItems[3];
    } else {
      if (!conditionItems.contains(dbKondisi)) {
        conditionItems.add(dbKondisi);
      }
      _initialCondition = dbKondisi;
    }
    // FIX: Hapus pengisian selectedCondition di sini!
    // Biar selectedCondition tetep null dan otomatis nampilin "Pilih kondisi..."
  }

  // Buka kamera HP buat ambil foto kondisi
  Future<void> _ambilFoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (pickedFile != null) setState(() => _fotoKondisi = pickedFile);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kamera tidak dapat dibuka Tuan!'), backgroundColor: Colors.red));
    }
  }

  // Simpan perubahan kondisi aset ke server
  Future<void> _updateKondisiKeServer() async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> dataUpdate = {
        // FIX: Kalo petugas kaga milih dropdown baru (cuma nambah foto/catatan doang), kita kirim kondisi awalnya
        "status_kondisi": selectedCondition ?? _initialCondition,
        "catatan": _catatanCtrl.text.trim().isNotEmpty ? _catatanCtrl.text.trim() : "Update kondisi via mobile",
      };

      if (_fotoKondisi != null) {
        dataUpdate["foto_kondisi"] = await MultipartFile.fromFile(_fotoKondisi!.path, filename: _fotoKondisi!.name);
      }

      await _apiService.updateKondisiBarang(_currentAsset.id, dataUpdate);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kondisi aset berhasil diperbarui!'), backgroundColor: Colors.green)
        );
        
        // --- JURUS SAKTI: Balik ke List Aset sambil ngasih tau buat Refresh ---
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal update: $e", style: GoogleFonts.poppins(fontSize: 12)), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isPersonal = _currentAsset.statusPenguasaan.toLowerCase() == 'personal';
    
    // Logika tombol: Aktif jika kondisi berubah, catatan diisi, atau foto diambil
    // Tapi tombol mati kalau lagi loading simpan
    bool isConditionChanged = selectedCondition != null && selectedCondition != _initialCondition;
    bool isNoteFilled = _catatanCtrl.text.trim().isNotEmpty;
    bool isPhotoTaken = _fotoKondisi != null;
    bool canSave = (isConditionChanged || isNoteFilled || isPhotoTaken) && !_isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0056D2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, false), // Default balik tanpa refresh
        ),
        title: Text("Detail Aset", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER INFO UTAMA ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              decoration: const BoxDecoration(color: Color(0xFF0056D2), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_currentAsset.namaBarang, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.qr_code, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(_currentAsset.kodeBarcode, style: GoogleFonts.sourceCodePro(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // 1. DATA INVENTARIS
                  _buildCard(
                    title: "Data Inventaris",
                    icon: Icons.description_outlined,
                    child: _isFetchingDetail 
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            _buildInfoRow("Tipe Aset", _currentAsset.statusPenguasaan.toUpperCase()),
                            if (isPersonal) _buildInfoRow("Pemegang", _currentAsset.karyawanPemegang)
                            else _buildInfoRow("Lokasi Fisik", _currentAsset.lokasiFisik),
                            _buildInfoRow("Tgl. Labeling", _currentAsset.tglLabeling),
                            _buildInfoRow("Spesifikasi", _currentAsset.spesifikasi),
                            _buildInfoRow("Kondisi Terakhir", _currentAsset.kondisi),
                          ],
                        ),
                  ),
                  const SizedBox(height: 20),

                  // 2. DETAIL KONTRAK / PO
                  _buildCard(
                    title: "Detail Kontrak / PO",
                    icon: Icons.assignment_outlined,
                    iconColor: Colors.purple, 
                    child: _isFetchingDetail 
                      ? const Center(child: CircularProgressIndicator(color: Colors.purple))
                      : Column(
                          children: [
                            _buildInfoRow("No. Kontrak", _currentAsset.noKontrak),
                            _buildInfoRow("Thn. Pengadaan", _currentAsset.tahunPengadaan),
                            _buildInfoRow("Vendor/Supplier", _currentAsset.vendor),
                            _buildInfoRow("Pihak Pengada", _currentAsset.pihakPengada),
                          ],
                        ),
                  ),
                  const SizedBox(height: 20),

                  // 3. UPDATE KONDISI FISIK
                  _buildCard(
                    title: "Update Kondisi Fisik",
                    icon: Icons.camera_alt_outlined,
                    iconColor: Colors.orange,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedCondition,
                          hint: const Text("Pilih kondisi..."), // --- FIX: Tambahin teks hint ini ---
                          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12)),
                          items: conditionItems.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: _isLoading ? null : (v) => setState(() => selectedCondition = v),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _catatanCtrl,
                          maxLines: 2,
                          enabled: !_isLoading,
                          onChanged: (v) => setState(() {}),
                          decoration: InputDecoration(hintText: "Alasan perubahan kondisi (Opsional)...", hintStyle: const TextStyle(fontSize: 12, color: Colors.grey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.all(12)),
                        ),
                        const SizedBox(height: 15),
                        _fotoKondisi == null
                          ? SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _isLoading ? null : _ambilFoto, icon: const Icon(Icons.camera_alt), label: const Text("Ambil Foto Bukti")))
                          : Column(children: [
                              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_fotoKondisi!.path), height: 150, width: double.infinity, fit: BoxFit.cover)),
                              TextButton.icon(onPressed: _isLoading ? null : _ambilFoto, icon: const Icon(Icons.refresh, size: 16), label: const Text("Ganti Foto"), style: TextButton.styleFrom(foregroundColor: Colors.orange))
                            ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 4. MOBILISASI (BAST DIGITAL)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Update Mobilisasi", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0087FF))),
                        const SizedBox(height: 10),
                        const Text("Mutasi aset langsung melalui BAST Digital tanpa scan ulang.", style: TextStyle(fontSize: 11, color: Color(0xFF1565C0))),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : () async {
                              final result = await Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (context) => BastFormScreen(initialAsset: _currentAsset))
                              );
                              if (result == true) {
                                _fetchDetailDariServer();
                              }
                            },
                            icon: const Icon(Icons.description_outlined),
                            label: const Text("Buat BAST Mutasi"),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0087FF), foregroundColor: Colors.white),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 5. TOMBOL SIMPAN SAKTI
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: !canSave ? null : _updateKondisiKeServer,
                      icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                      label: Text(_isLoading ? "Menyimpan..." : "Simpan Update Kondisi", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056D2), foregroundColor: Colors.white, disabledBackgroundColor: Colors.grey[400], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11))), Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))]));
  Widget _buildCard({required String title, required IconData icon, Color iconColor = Colors.blue, required Widget child}) => Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: iconColor, size: 20), const SizedBox(width: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.bold))]), const Divider(height: 25), child]));
}