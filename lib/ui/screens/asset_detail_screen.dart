import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bash_form_screen.dart';
import '../../models/barang_model.dart'; // <--- IMPORT MODEL LU DISINI

class AssetDetailScreen extends StatefulWidget {
  // Kita terima data OBJECT UTUH dari halaman sebelumnya
  final BarangModel asset;

  const AssetDetailScreen({
    super.key, 
    required this.asset,
  });

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  // Variabel untuk Dropdown Kondisi
  final List<String> conditionItems = [
    'Baik (Layak Operasi)',
    'Rusak Ringan',
    'Rusak Berat',
    'Dalam Perbaikan',
  ];
  String? selectedCondition;

  @override
  void initState() {
    super.initState();
    selectedCondition = conditionItems[0]; // Default: Baik
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0056D2), // Biru Tua Header
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Detail Aset",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      // BODY
      body: SingleChildScrollView(
        child: Column(
          children: [
            // BAGIAN ATAS (HEADER BIRU)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              decoration: const BoxDecoration(
                color: Color(0xFF0056D2),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.asset.namaBarang, // <--- NAMA ASET DINAMIS DARI API
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.qr_code, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          widget.asset.kodeBarcode, // <--- BARCODE DINAMIS DARI API
                          style: GoogleFonts.sourceCodePro(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // CONTENT KARTU-KARTU
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // 1. KARTU DATA INVENTARIS
                  _buildCard(
                    title: "Data Inventaris",
                    icon: Icons.description_outlined,
                    child: Column(
                      children: [
                        _buildInfoRow("Lokasi Fisik", widget.asset.lokasiFisik), // <--- DARI API
                        _buildInfoRow("Tgl. Labeling", widget.asset.tglLabeling), // <--- DARI API
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text("Spesifikasi", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                            ),
                            Expanded(
                              child: Text(
                                widget.asset.spesifikasi, // <--- SPESIFIKASI DARI API
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        const Divider(),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(0xFFFFE0B2),
                              child: Icon(Icons.person, color: Colors.orange, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Karyawan Pemegang", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                                // Ini masih hardcode karena di ERD lu kaga ada field relasi karyawan di tabel m_barang
                                Text("Andiro Rizky Dwitama (IT Support)", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)), 
                              ],
                            )
                          ],
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. KARTU UPDATE KONDISI
                  _buildCard(
                    title: "Update Kondisi Fisik",
                    icon: Icons.camera_alt_outlined,
                    iconColor: Colors.orange,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Kondisi Saat Ini", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 8),
                        // DROPDOWN
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCondition,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down),
                              items: conditionItems.map((String item) {
                                return DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(item, style: GoogleFonts.poppins(fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedCondition = newValue;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        // TOMBOL FOTO (DASHED BORDER)
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.camera_alt, size: 18, color: Colors.grey),
                            label: Text("Ambil Foto Bukti", style: GoogleFonts.poppins(color: Colors.grey)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.grey, style: BorderStyle.solid), // Harusnya dashed, pake package dotted_border kalau mau persis
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. KARTU MOBILISASI (BAST)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD), // Biru Muda
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBBDEFB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.swap_horiz, color: Color(0xFF0087FF)),
                            const SizedBox(width: 10),
                            Text(
                              "Update Mobilisasi",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: const Color(0xFF0087FF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Pindah tanggung jawab atau lokasi aset ini ke karyawan lain melalui BAST Digital",
                          style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF1565C0)),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Aksi ke Halaman BAST
                                 Navigator.push(
                                 context,
                                 MaterialPageRoute(builder: (context) => const BastFormScreen()),
      );
                            },
                            icon: const Icon(Icons.description_outlined, size: 18, color: Colors.white),
                            label: Text("Buat BAST Mutasi", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0087FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  
                  // TOMBOL SIMPAN PALING BAWAH
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.save, color: Color(0xFF0087FF)),
                      label: Text("Simpan Update Kondisi", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0087FF))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF0087FF), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET HELPER: Membuat Baris Info
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // WIDGET HELPER: Membuat Card Putih
  Widget _buildCard({required String title, required IconData icon, Color iconColor = Colors.blue, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const Divider(height: 25),
          child,
        ],
      ),
    );
  }
}