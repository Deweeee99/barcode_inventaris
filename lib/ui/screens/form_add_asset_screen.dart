import 'package:flutter/material.dart';
import 'package:dio/dio.dart'; 
import '../../services/api_services.dart'; 

class AssetRegistrationPage extends StatefulWidget {
  const AssetRegistrationPage({super.key});

  @override
  State<AssetRegistrationPage> createState() => _AssetRegistrationPageState();
}

class _AssetRegistrationPageState extends State<AssetRegistrationPage> {
  final ApiService _apiService = ApiService();

  bool isLocationAsset = true;
  bool _isLoading = false; 
  bool _isLoadingKontrak = true; 

  // --- CONTROLLER ---
  final TextEditingController _barcodeCtrl = TextEditingController();
  final TextEditingController _namaBarangCtrl = TextEditingController();
  final TextEditingController _jumlahBarangCtrl = TextEditingController(text: "1"); 
  final TextEditingController _spekCtrl = TextEditingController();
  final TextEditingController _lokasiPenerimaCtrl = TextEditingController();

  String _selectedKategori = "Elektronik";
  
  // --- PERBAIKAN: Ubah jadi String biar kaga bentrok sama data JSON Backend ---
  String? _selectedKontrakId; 
  List<dynamic> _listKontrak = []; 

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
      print("Error tarik kontrak: $e");
      if (mounted) setState(() => _isLoadingKontrak = false);
    }
  }

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _namaBarangCtrl.dispose();
    _jumlahBarangCtrl.dispose();
    _spekCtrl.dispose();
    _lokasiPenerimaCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpanData() async {
    if (_namaBarangCtrl.text.isEmpty || _barcodeCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama barang sama barcode wajib diisi bos!'), backgroundColor: Colors.red),
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
      String inputPenerima = _lokasiPenerimaCtrl.text.trim();
      int jumlah = int.tryParse(_jumlahBarangCtrl.text.trim()) ?? 1;
      
      // Kembalikan ID Kontrak ke Integer pas mau dikirim
      int idKontrakDikirim = int.tryParse(_selectedKontrakId!) ?? 1;

      Map<String, dynamic> dataKirim = {
        "id_kontrak": idKontrakDikirim, 
        "id_kategori": _selectedKategori == "Elektronik" ? 1 : 2,
        "kode_barcode": _barcodeCtrl.text,
        "nama_barang": _namaBarangCtrl.text,
        "spesifikasi": _spekCtrl.text.isEmpty ? "-" : _spekCtrl.text,
        "jumlah_barang": jumlah, 
        "status_penguasaan": isLocationAsset ? "lokasi" : "personal",
        "kondisi": "Baik", 
        "status_kondisi": "Baik", 
      };

      if (isLocationAsset) {
        if (inputPenerima.isEmpty) throw Exception("Lokasi fisik wajib diisi!");
        dataKirim["lokasi_fisik"] = inputPenerima;
        dataKirim["id_karyawan_pemegang"] = null;
        dataKirim["nip"] = null;
      } else {
        if (inputPenerima.isEmpty) throw Exception("NIP Penerima kaga boleh kosong!");
        dataKirim["id_karyawan_pemegang"] = int.tryParse(inputPenerima) ?? inputPenerima; 
        dataKirim["nip"] = inputPenerima; 
        dataKirim["lokasi_fisik"] = null;
      }

      await _apiService.tambahBarang(dataKirim);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cihuy! Aset baru udah kedaftar Tuan!'), backgroundColor: Colors.green),
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
            // Bagian Foto (Dummy)
            Container(
              width: double.infinity,
              color: const Color(0xFFF5F6F8),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.image_outlined, size: 20, color: Colors.black87),
                      SizedBox(width: 8),
                      Text("Foto Fisik Aset", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 1.5),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined, color: Colors.blue),
                            SizedBox(height: 8),
                            Text("Ambil Foto", style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold))
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text("Belum ada foto", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
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
                  // --- DROPDOWN KONTRAK (UDAH DI-UPGRADE) ---
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
                              String namaKontrak = k['no_kontrak']?.toString() ?? k['nama_kontrak']?.toString() ?? 'Kontrak ${k['id']}';
                              // ID-nya kita paksa jadi String biar kaga bikin error Dropdown
                              return DropdownMenuItem<String>(
                                value: k['id'].toString(), 
                                child: Text(namaKontrak, style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (v) { setState(() => _selectedKontrakId = v); },
                          ),
                  const SizedBox(height: 16),

                  _buildLabel("ID / TAG BARCODE"),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _barcodeCtrl, 
                          decoration: _buildInputDeco(hint: "Scan ID Barcode...", icon: Icons.label_outline),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2F66D6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                          onPressed: () {
                            _barcodeCtrl.text = "BRC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
                          },
                        ),
                      ),
                    ],
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
                              items: ["Elektronik", "Furniture"].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
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
                  const SizedBox(height: 24),

                  const Text("Tipe Alokasi Aset", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildToggle(label: "Aset Lokasi", icon: Icons.business, isSelected: isLocationAsset, onTap: () => setState(() => isLocationAsset = true)),
                        _buildToggle(label: "Aset Personal", icon: Icons.person_outline, isSelected: !isLocationAsset, onTap: () => setState(() => isLocationAsset = false)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (isLocationAsset) ...[
                    _buildLabel("LOKASI PENEMPATAN FISIK"),
                    TextField(
                      controller: _lokasiPenerimaCtrl, 
                      decoration: _buildInputDeco(hint: "Contoh: Ruang Rapat Lt. 2", icon: Icons.location_on_outlined),
                    ),
                  ] else ...[
                    _buildLabel("NIP PENERIMA ASET"),
                    TextField(
                      controller: _lokasiPenerimaCtrl, 
                      keyboardType: TextInputType.number, 
                      decoration: _buildInputDeco(hint: "Masukin NIP (Contoh: 160108)", icon: Icons.badge_outlined),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      
      bottomSheet: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _simpanData, 
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0087FF), 
            foregroundColor: Colors.white, 
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
              : const Icon(Icons.save),
          label: Text(_isLoading ? "Menyimpan..." : "Simpan & Cetak Label", style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildToggle({required String label, required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.blue : Colors.grey, size: 18),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isSelected ? Colors.blue : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
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