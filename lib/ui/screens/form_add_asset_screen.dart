import 'package:flutter/material.dart';
import 'package:dio/dio.dart'; 
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../services/api_services.dart'; 

class AssetRegistrationPage extends StatefulWidget {
  const AssetRegistrationPage({super.key});

  @override
  State<AssetRegistrationPage> createState() => _AssetRegistrationPageState();
}

class _AssetRegistrationPageState extends State<AssetRegistrationPage> {
  final ApiService _apiService = ApiService();

  bool _isLoading = false; 
  bool _isLoadingKontrak = true; 

  // --- CONTROLLER ---
  final TextEditingController _namaBarangCtrl = TextEditingController();
  final TextEditingController _jumlahBarangCtrl = TextEditingController(text: "1"); 
  final TextEditingController _spekCtrl = TextEditingController();

  // Kategori disesuaikan persis dengan in: di Laravel
  String _selectedKategori = "Elektronik";
  final List<String> _listKategori = [
    'Elektronik', 'Furnitur', 'Jaringan', 'Kendaraan', 'Peralatan Kantor', 'Lainnya'
  ];
  
  String? _selectedKontrakId; 
  List<dynamic> _listKontrak = []; 

  // --- JURUS MULTI FOTO ---
  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchKontrak(); 
  }

  Future<void> _fetchKontrak() async {
    try {
      final response = await _apiService.getKontrak();
      var data = response.data;
      
      List<dynamic> listRaw = [];
      if (data is Map) {
        if (data['data'] is List) {
          listRaw = data['data'];
        } else if (data['kontrak'] is List) {
          listRaw = data['kontrak'];
        } else if (data['kontrak'] != null && data['kontrak']['data'] is List) {
          listRaw = data['kontrak']['data'];
        }
      } else if (data is List) {
        listRaw = data;
      }

      if (mounted) {
        setState(() {
          _listKontrak = listRaw;
          _isLoadingKontrak = false;
        });
      }
    } catch (e) {
      debugPrint("Error tarik kontrak: $e");
      if (mounted) setState(() => _isLoadingKontrak = false);
    }
  }

  @override
  void dispose() {
    _namaBarangCtrl.dispose();
    _jumlahBarangCtrl.dispose();
    _spekCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMultiImage() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 70);
      if (images.isNotEmpty) {
        setState(() => _selectedImages.addAll(images));
      }
    } catch (e) {
      debugPrint("Gagal buka galeri: $e");
    }
  }

  Future<void> _simpanData() async {
    if (_namaBarangCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama barang wajib diisi bos!'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedKontrakId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih dulu Nomor Kontrak-nya Tuan!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      int jumlah = int.tryParse(_jumlahBarangCtrl.text.trim()) ?? 1;
      int idKontrakDikirim = int.tryParse(_selectedKontrakId!) ?? 1;

      // --- PERBAIKAN: Payload disamain persis sama Laravel temen lu ---
      // Kaga ada lagi kirim status_penguasaan, lokasi_fisik, atau NIP!
      Map<String, dynamic> dataKirim = {
        "id_kontrak": idKontrakDikirim, 
        "kategori": _selectedKategori, 
        "nama_barang": _namaBarangCtrl.text,
        "spesifikasi": _spekCtrl.text.isEmpty ? "-" : _spekCtrl.text,
        "jumlah_barang": jumlah, 
      };

      await _apiService.tambahBarang(dataKirim, multiFoto: _selectedImages);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cihuy! Aset berhasil didaftarkan dan menunggu proses BAST!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = "Gagal nyimpen data Tuan.";
        if (e is DioException) {
          if (e.response?.data != null && e.response?.data.toString().isNotEmpty == true) {
             errorMessage = "Ditolak Server: ${e.response?.data}";
          } else if (e.error != null) {
             errorMessage = e.error.toString();
          } else {
             errorMessage = "Terjadi kesalahan di server (422) atau koneksi putus.";
          }
        } else {
          errorMessage = e.toString();
        }

        errorMessage = errorMessage.replaceAll("Exception: ", "");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: const TextStyle(fontSize: 12)), 
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Registrasi Aset Baru',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // INFO BOX WORKFLOW BARU
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Aset yang diregistrasi akan otomatis berstatus 'Menunggu Serah Terima'. Lakukan serah terima di menu Mutasi/BAST.",
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            // Bagian Upload Foto
            Container(
              width: double.infinity,
              color: const Color(0xFFF5F6F8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.image_outlined, size: 20, color: Colors.black87),
                      SizedBox(width: 8),
                      Text("Foto Fisik Aset (Bisa Lebih Dari 1)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: [
                      GestureDetector(
                        onTap: _pickMultiImage,
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1), 
                            borderRadius: BorderRadius.circular(10), 
                            border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 1.5)
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: Colors.blue),
                              SizedBox(height: 5),
                              Text("Tambah", style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold))
                            ],
                          ),
                        ),
                      ),
                      ..._selectedImages.asMap().entries.map((entry) {
                        int idx = entry.key;
                        XFile img = entry.value;
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10), 
                              child: Image.file(File(img.path), width: 80, height: 80, fit: BoxFit.cover)
                            ),
                            Positioned(
                              right: -5, top: -5, 
                              child: IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 20), 
                                onPressed: () => setState(() => _selectedImages.removeAt(idx))
                              )
                            )
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("NOMOR KONTRAK / PO"),
                  _isLoadingKontrak 
                    ? const Center(child: CircularProgressIndicator())
                    : _listKontrak.isEmpty 
                        ? TextFormField(
                            enabled: false,
                            decoration: _buildInputDeco(hint: "Tidak ada data kontrak dari server", icon: Icons.warning_amber_rounded),
                          )
                        : DropdownButtonFormField<String>(
                            initialValue: _selectedKontrakId,
                            decoration: _buildInputDeco(hint: "-- Pilih Kontrak Aktif --", icon: Icons.description_outlined),
                            items: _listKontrak.map((k) {
                              String namaKontrak = k['no_kontrak']?.toString() ?? k['nama_kontrak']?.toString() ?? 'Kontrak ${k['id_kontrak']}';
                              return DropdownMenuItem<String>(
                                value: k['id_kontrak'].toString(), 
                                child: Text(namaKontrak, style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (v) { setState(() => _selectedKontrakId = v); },
                          ),
                  
                  const SizedBox(height: 16),
                  _buildLabel("NAMA BARANG"),
                  TextField(controller: _namaBarangCtrl, decoration: _buildInputDeco(hint: "Contoh: Laptop Asus ROG")),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("JUMLAH"),
                            TextField(
                              controller: _jumlahBarangCtrl, 
                              keyboardType: TextInputType.number,
                              decoration: _buildInputDeco(hint: "1"),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("KATEGORI"),
                            DropdownButtonFormField<String>(
                              value: _selectedKategori,
                              decoration: _buildInputDeco(),
                              items: _listKategori.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                              onChanged: (v) { setState(() => _selectedKategori = v!); },
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildLabel("SPESIFIKASI"),
                  TextField(
                    controller: _spekCtrl, 
                    maxLines: 2,
                    decoration: _buildInputDeco(hint: "Contoh: RAM 16GB, Core i7...", icon: Icons.memory_outlined),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      
      bottomNavigationBar: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
        child: SizedBox(
          height: 55,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _simpanData, 
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0087FF), 
              foregroundColor: Colors.white, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Icon(Icons.save),
            label: Text(_isLoading ? "Menyimpan..." : "Simpan Data Aset", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  InputDecoration _buildInputDeco({String? hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
      filled: true,
      fillColor: const Color(0xFFEEEEEE),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 1.5)),
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
    );
  }
}