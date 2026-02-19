import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto', // Menggunakan font default yang bersih
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFEEEEEE), // Warna abu-abu muda input
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 1.5),
          ),
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ),
      home: const AssetRegistrationPage(),
    );
  }
}

class AssetRegistrationPage extends StatefulWidget {
  const AssetRegistrationPage({super.key});

  @override
  State<AssetRegistrationPage> createState() => _AssetRegistrationPageState();
}

class _AssetRegistrationPageState extends State<AssetRegistrationPage> {
  // State untuk menentukan tab yang aktif (Lokasi atau Personal)
  bool isLocationAsset = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {},
        ),
        title: const Text(
          'Registrasi Aset Baru',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION: Foto Fisik Aset (Background Abu) ---
            Container(
              width: double.infinity,
              color: const Color(0xFFF5F6F8), // Background abu-abu muda header
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.image_outlined, size: 20, color: Colors.black87),
                      SizedBox(width: 8),
                      Text(
                        "Foto Fisik Aset",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Tombol Ambil Foto
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF), // Biru sangat muda
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blueAccent.withOpacity(0.5),
                            style: BorderStyle.solid, 
                            // Catatan: Flutter native tidak punya dotted border bawaan simple, 
                            // jadi pakai solid border warna biru muda mirip mockup.
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.camera_alt_outlined, color: Colors.blue),
                            SizedBox(height: 8),
                            Text(
                              "Ambil Foto",
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Placeholder Foto Kosong
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            "Belum ada foto",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- SECTION: Form Input (Background Putih) ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // ID / TAG BARCODE
                  _buildLabel("ID / TAG BARCODE"),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: "Scan ID Barcode...",
                            prefixIcon: Icon(Icons.label_outline, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2F66D6), // Warna biru tombol scan
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // INFORMASI BARANG
                  _buildLabel("INFORMASI BARANG"),
                  const TextField(
                    decoration: InputDecoration(
                      hintText: "Nama Barang (Contoh: Laptop Asus ROG STRIX)",
                    ),
                  ),
                  const SizedBox(height: 16),

                  // KATEGORI & KONDISI (ROW)
                  Row(
                    children: [
                      // Kategori
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("KATEGORI"),
                            DropdownButtonFormField<String>(
                              value: "Elektronik",
                              decoration: const InputDecoration(),
                              icon: const Icon(Icons.keyboard_arrow_down),
                              items: ["Elektronik", "Furniture"]
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (v) {},
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Kondisi
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("KONDISI"),
                            DropdownButtonFormField<String>(
                              value: "Baik",
                              decoration: const InputDecoration(),
                              icon: const Icon(Icons.keyboard_arrow_down),
                              items: ["Baik", "Rusak Ringan", "Rusak Berat"]
                                  .map((e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(
                                          e,
                                          style: TextStyle(
                                            color: e == "Baik" ? Colors.green : Colors.black,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (v) {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // DETAIL KONTRAK / PO
                  _buildLabel("DETAIL KONTRAK / PO"),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.description_outlined, color: Colors.grey),
                    ),
                    hint: const Text("-- Pilih Kontrak Aktif --"),
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: const [], // Kosong sesuai mockup
                    onChanged: (v) {},
                  ),
                  const SizedBox(height: 24),

                  const Divider(thickness: 1, color: Colors.grey),
                  const SizedBox(height: 16),

                  // TIPE ALOKASI ASET (SWITCHER)
                  const Text(
                    "Tipe Alokasi Aset",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        // Tab Aset Lokasi
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isLocationAsset = true),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isLocationAsset ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isLocationAsset
                                    ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                                    : [],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.business, // Icon gedung/kantor
                                    color: isLocationAsset ? Colors.blue : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Aset Lokasi",
                                    style: TextStyle(
                                      color: isLocationAsset ? Colors.blue : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Tab Aset Personal
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isLocationAsset = false),
                            child: Container(
                              decoration: BoxDecoration(
                                color: !isLocationAsset ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !isLocationAsset
                                    ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                                    : [],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    color: !isLocationAsset ? Colors.blue : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Aset Personal",
                                    style: TextStyle(
                                      color: !isLocationAsset ? Colors.blue : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // DYNAMIC FORM FIELD BERDASARKAN TIPE ALOKASI
                  if (isLocationAsset) ...[
                    _buildLabel("Lokasi Penempatan Baru"),
                    const TextField(
                      decoration: InputDecoration(
                        hintText: "Isi Lokasi",
                        prefixIcon: Icon(Icons.description_outlined, color: Colors.grey),
                      ),
                    ),
                  ] else ...[
                    _buildLabel("Nama Penerima Baru"),
                    const TextField(
                      decoration: InputDecoration(
                        hintText: "Isi Penerima",
                        prefixIcon: Icon(Icons.description_outlined, color: Colors.grey),
                      ),
                    ),
                  ],

                  const SizedBox(height: 100), // Space untuk bottom button
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12)),
        ),
        child: ElevatedButton.icon(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE0E0E0), // Warna tombol disable/grey
            foregroundColor: const Color(0xFF9E9E9E), // Warna text/icon grey
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.save),
          label: const Text(
            "Simpan & Cetak Label",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // Helper widget untuk label kecil di atas input field
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}