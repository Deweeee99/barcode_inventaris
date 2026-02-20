import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

import '../../services/api_services.dart';
import '../../models/barang_model.dart'; 
import 'asset_detail_screen.dart';

class AssetListScreen extends StatefulWidget {
  const AssetListScreen({super.key});

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<BarangModel>> _futureAset;

  @override
  void initState() {
    super.initState();
    _futureAset = fetchDaftarAset();
  }

  // Fungsi buat bersihin JSON kotor (biasanya ada sampah teks di awal/akhir)
  dynamic _cleanAndDecode(dynamic data) {
    if (data == null) return null;
    if (data is Map || data is List) return data;
    try {
      String raw = data.toString().trim();
      int lastBrace = raw.lastIndexOf('}');
      int lastBracket = raw.lastIndexOf(']');
      int cutIndex = (lastBrace > lastBracket) ? lastBrace : lastBracket;
      if (cutIndex != -1) raw = raw.substring(0, cutIndex + 1);
      return jsonDecode(raw);
    } catch (e) {
      return null;
    }
  }

  Future<List<BarangModel>> fetchDaftarAset() async {
    try {
      final response = await _apiService.getBarang();
      dynamic responseData = _cleanAndDecode(response.data);

      List<BarangModel> tempItems = [];

      if (responseData != null && responseData is Map) {
        var barangData = responseData['barang'];
        List<dynamic> listRaw = [];
        
        if (barangData != null && barangData['data'] is List) {
          listRaw = barangData['data'];
        } else if (responseData['data'] is List) {
          listRaw = responseData['data'];
        }

        // Convert raw JSON ke Model biar logikanya seragam
        tempItems = listRaw.map((e) => BarangModel.fromJson(e)).toList();
      }
      return tempItems;
    } catch (e) {
      print("Error list: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Warna background abu soft biar card keliatan
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Daftar Aset", 
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search, color: Colors.black)),
        ],
      ),
      body: FutureBuilder<List<BarangModel>>(
        future: _futureAset,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0087FF)));
          }
          
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("Belum ada aset terdaftar Tuan.", style: GoogleFonts.poppins(color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() { _futureAset = fetchDaftarAset(); });
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                bool isLokasi = item.statusPenguasaan == 'lokasi';

                return GestureDetector(
                  onTap: () async {
                    final res = await Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => AssetDetailScreen(asset: item))
                    );
                    if (res == true) setState(() { _futureAset = fetchDaftarAset(); });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      children: [
                        // Kotak Icon Biru (Sesuai Screenshot)
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF5FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF0087FF), size: 24),
                        ),
                        const SizedBox(width: 15),
                        
                        // Info Barang
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.namaBarang.toUpperCase(), 
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.qr_code, size: 12, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.kodeBarcode, 
                                    style: GoogleFonts.sourceCodePro(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Badges (Kondisi & Tipe Aset)
                              Row(
                                children: [
                                  // Badge Kondisi (Greenish)
                                  _buildBadge(
                                    item.kondisi, 
                                    item.kondisi.toLowerCase().contains('baik') ? Colors.green : Colors.orange
                                  ),
                                  const SizedBox(width: 8),
                                  
                                  // Badge Tipe Aset (Dinamis: LOKASI vs PERSONAL)
                                  _buildBadge(
                                    item.statusPenguasaan.toUpperCase(), 
                                    isLokasi ? const Color(0xFF0087FF) : Colors.grey[600]!
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        backgroundColor: const Color(0xFF0087FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text, 
        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: color)
      ),
    );
  }
}