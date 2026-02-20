import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'asset_detail_screen.dart';
import '../../models/barang_model.dart';
import '../../services/api_services.dart';
import 'dart:convert';

class AssetListScreen extends StatefulWidget {
  const AssetListScreen({super.key});

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<BarangModel>> _futureBarang;

  @override
  void initState() {
    super.initState();
    // Panggil API pas halaman pertama kali dibuka
    _futureBarang = fetchBarang();
  }

  Future<List<BarangModel>> fetchBarang() async {
    try {
      final response = await _apiService.getBarang();
      dynamic responseData = response.data;

       print("=== HASIL RAW DARI API ===");
       print(response.data);
       print("=== TIPE DATANYA ===");
       print(response.data.runtimeType);   

      if(responseData is String) {
        responseData = jsonDecode(responseData);
      }

      List<dynamic> dataList;

      if(responseData is List) {
        dataList = responseData;
      } else {
        dataList =responseData['data'];
      }
       return dataList.map((json) => BarangModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal nyedot data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Items",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black, size: 28),
            onPressed: () {},
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: FutureBuilder<List<BarangModel>>(
        future: _futureBarang,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error bos: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Data kosong melompong.'));
          }

          final listBarang = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: listBarang.length,
            itemBuilder: (context, index) {
              // Sekarang item tipe datanya BarangModel
              final item = listBarang[index]; 

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssetDetailScreen(
                          asset: item,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Gambar Produk (Sementara pake errorBuilder / dummy, karena di ERD lu kaga ada field foto barang)
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.grey[100],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.asset(
                              'assets/images/placeholder.png', // Ganti kalo lu punya gambar default
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.image_not_supported, color: Colors.grey, size: 40);
                              },
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 15),

                        // Text Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.namaBarang, // DARI API
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                item.kodeBarcode, // DARI API
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Jumlah Stock
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              item.jumlahBarang.toString(), // DARI API (dijadiin string)
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0D47A1),
                              ),
                            ),
                            const SizedBox(height: 20), 
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}