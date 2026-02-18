import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'asset_detail_screen.dart';


class AssetListScreen extends StatelessWidget {
  const AssetListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // DUMMY DATA (Data Palsu sementara biar mirip desain)
    // Nanti ini diganti sama data asli dari Database/API
    final List<Map<String, dynamic>> assets = [
      {
        "name": "Asus Rog Strix",
        "id": "2341254634235",
        "stock": 35,
        "image": "assets/images/laptop_rog.png", // Pastikan punya gambar dummy
      },
      {
        "name": "Meja Meeting",
        "id": "53454534",
        "stock": 12,
        "image": "assets/images/meja.png",
      },
      {
        "name": "Acer Aspire",
        "id": "53454534",
        "stock": 35,
        "image": "assets/images/laptop_acer.png",
      },
      {
        "name": "Asus Vivobook s14",
        "id": "53454534",
        "stock": 35,
        "image": "assets/images/laptop_vivo.png",
      },
      {
        "name": "HP Victus 15",
        "id": "53454534",
        "stock": 35,
        "image": "assets/images/laptop_hp.png",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        centerTitle: false, // Judul di kiri sesuai desain Android/iOS modern
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
            onPressed: () {
              // Aksi pencarian
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: assets.length,
        itemBuilder: (context, index) {
          final item = assets[index];
          return Container(
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
                  // 1. GAMBAR PRODUK
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
                        item['image'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Tampilan kalau gambar tidak ketemu
                          return const Icon(Icons.image_not_supported, color: Colors.grey);
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 15),

                  // 2. TEXT INFO (Tengah)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'],
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
                          item['id'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. JUMLAH STOCK (Kanan Atas)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        item['stock'].toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0D47A1), // Biru Tua
                        ),
                      ),
                      // Spacer biar angkanya agak ke atas (optional layout hack)
                      const SizedBox(height: 20), 
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}