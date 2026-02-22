import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

import '../../services/api_services.dart';
import '../../models/tugas_model.dart';
import '../../models/barang_model.dart';
import 'asset_detail_screen.dart'; // Import biar bisa buka layar detail aset

class TaskDetailScreen extends StatefulWidget {
  final TugasModel tugas;
  const TaskDetailScreen({super.key, required this.tugas});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  final TextEditingController _catatanCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];

  // Jurus Update Status (Pending -> Proses)
  Future<void> _mulaiKerjakan() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.updateStatusTugas(widget.tugas.idTugas, 'Proses');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status berhasil diubah ke Proses! Tuan sekarang bisa ngerjain tugasnya.'), backgroundColor: Colors.blue));
        Navigator.pop(context, true); // Balik dan refresh list
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // JURUS BARU: Buka Detail Aset pas kotak barang diklik
  Future<void> _bukaDetailAset() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getDetailBarang(widget.tugas.kodeBarcode);
      var data = response.data;
      if (data is String) data = jsonDecode(data);
      
      var jsonData = data['data'] ?? data['barang'] ?? data;

      if (jsonData != null && mounted) {
        BarangModel asset = BarangModel.fromJson(jsonData);
        Navigator.push(context, MaterialPageRoute(builder: (context) => AssetDetailScreen(asset: asset)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yah, data aset kaga ketemu di server!'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal buka aset: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickMultiImage() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 70);
      if (images.isNotEmpty) setState(() => _selectedImages.addAll(images));
    } catch (e) {
      debugPrint("Gagal buka galeri: $e");
    }
  }

  // Jurus Selesaikan Tugas (Catatan + Multi Foto) -> Berubah jadi Selesai
  Future<void> _selesaikanTugas() async {
    if (_catatanCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catatan pengerjaan wajib diisi Tuan!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.completeTugas(widget.tugas.idTugas, _catatanCtrl.text, multiFoto: _selectedImages);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mantap! Tugas berhasil diselesaikan.'), backgroundColor: Colors.green));
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal selesain tugas: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isPending = widget.tugas.status.toLowerCase() == 'pending' || widget.tugas.status.toLowerCase() == 'belum dibaca';
    bool isProses = widget.tugas.status.toLowerCase() == 'proses' || widget.tugas.status.toLowerCase() == 'sudah dibaca';
    bool isSelesai = widget.tugas.status.toLowerCase() == 'selesai';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0056D2),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text("Detail Penugasan", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KOTAK INFO TUGAS
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Status: ${widget.tugas.status}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF0056D2))),
                          const Icon(Icons.assignment, color: Colors.grey),
                        ],
                      ),
                      const Divider(height: 30),
                      _buildInfoRow("Jadwal Mulai", widget.tugas.jadwalMulai),
                      _buildInfoRow("Jadwal Tenggat", widget.tugas.jadwalTenggat),
                      _buildInfoRow("Pemberi Tugas", widget.tugas.namaPemberiTugas),
                      const SizedBox(height: 10),
                      const Text("Deskripsi / Instruksi:", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(widget.tugas.deskripsi, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // KOTAK INFO BARANG (SEKARANG BISA DIKLIK)
                GestureDetector(
                  onTap: _bukaDetailAset,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05), // Dikasih warna dikit biar keliatan bisa diklik
                      borderRadius: BorderRadius.circular(20), 
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(children: [Icon(Icons.inventory_2_outlined, color: Colors.orange), SizedBox(width: 8), Text("Objek Aset", style: TextStyle(fontWeight: FontWeight.bold))]),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                              child: const Text("Klik untuk detail", style: TextStyle(fontSize: 10, color: Colors.blue)),
                            )
                          ],
                        ),
                        const Divider(height: 20),
                        Text(widget.tugas.namaBarang, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("Barcode: ${widget.tugas.kodeBarcode}", style: GoogleFonts.sourceCodePro(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // FORM PENYELESAIAN JIKA STATUS PROSES
                if (isProses) ...[
                  Text("Form Laporan Pengerjaan", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _catatanCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(hintText: "Jelaskan apa saja yang sudah dikerjakan...", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                  ),
                  const SizedBox(height: 15),
                  Text("Foto Bukti Pengerjaan", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: [
                      GestureDetector(
                        onTap: _pickMultiImage,
                        child: Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue)), child: const Icon(Icons.add_a_photo, color: Colors.blue)),
                      ),
                      ..._selectedImages.asMap().entries.map((entry) {
                        int idx = entry.key;
                        return Stack(
                          children: [
                            ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(entry.value.path), width: 80, height: 80, fit: BoxFit.cover)),
                            Positioned(right: -5, top: -5, child: IconButton(icon: const Icon(Icons.cancel, color: Colors.redAccent), onPressed: () => setState(() => _selectedImages.removeAt(idx))))
                          ],
                        );
                      }),
                    ],
                  ),
                ],

                // HASIL PENYELESAIAN JIKA STATUS SELESAI
                if (isSelesai) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.withOpacity(0.3))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text("Laporan Pengerjaan", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))]),
                        const Divider(height: 20),
                        Text(widget.tugas.catatanPetugas, style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 10),
                        Text("Total Bukti Foto: ${widget.tugas.fotoBuktiTugas.length} dilampirkan.", style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  )
                ],

                const SizedBox(height: 100),
              ],
            ),
          ),
          
          // Efek Loading Transparan Biar Keren
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF0087FF)),
              ),
            ),
        ],
      ),
      bottomSheet: isPending || isProses ? Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : (isPending ? _mulaiKerjakan : _selesaikanTugas), 
          style: ElevatedButton.styleFrom(backgroundColor: isPending ? Colors.blue : Colors.green, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Icon(isPending ? Icons.play_arrow : Icons.check_circle),
          label: Text(isPending ? "Terima & Mulai Kerjakan" : "Selesaikan Penugasan", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ) : null,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}