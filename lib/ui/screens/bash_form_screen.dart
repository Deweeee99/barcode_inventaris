import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:signature/signature.dart';

class BastFormScreen extends StatefulWidget {
  const BastFormScreen({super.key});

  @override
  State<BastFormScreen> createState() => _BastFormScreenState();
}

class _BastFormScreenState extends State<BastFormScreen> {
  bool _pindahTangan = true;

  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  @override
  void dispose() {
    // TODO: implement dispose
    _signatureController.dispose();
    super.dispose();
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
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
         ),
         actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "Step 1/1",
              style: GoogleFonts.poppins(
                color: const Color(0xFF0087FF),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          )
         ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFBBDEFB)),
              ),

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF0087FF)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Mobilisasi Aset",
                         style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0087FF),
                          ),
                      ),
                       const SizedBox(height: 4),
                        Text(
                          "Pastikan barang fisik telah diperiksa oleh penerima sebelum melakukan tanda tangan elektronik.",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF1565C0),
                          ),
                        ),
                    ],
                  ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            //Tombol tambah barang
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row( 
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Color(0xFF0087FF)),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    "Tambah Barang",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            //Toggle switch
            Text(
              "JENIS MUTASI ASET",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() =>_pindahTangan = true),
                      child: Container(
                        padding: const EdgeInsetsDirectional.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _pindahTangan ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _pindahTangan ? [BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_outline,
                            size: 18,
                            color: _pindahTangan ? const Color(0xFF0087FF) : Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              "Pindah Tangan",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color : _pindahTangan ? const Color(0xFF0087FF) : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() =>_pindahTangan = false),
                      child: Container(
                        padding: const EdgeInsetsDirectional.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_pindahTangan ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: !_pindahTangan ? [BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_outline,
                            size: 18,
                            color: !_pindahTangan ? const Color(0xFF0087FF) : Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              "Pindah Lokasi",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color : !_pindahTangan ? const Color(0xFF0087FF) : Colors.grey,
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

            const SizedBox(height: 12),

            //Form input
            if (_pindahTangan) ...[
              _buildInputLabel("Pihak pemberi", Icons.person_outline),
              const SizedBox(height: 8),
              _textField("Nama Lengkap / NIP Pemberi", enabled: false, initialValue: "Andiro Rizky (Saya)"),

              const SizedBox(height: 15),

             _buildInputLabel("Pihak Penerima", Icons.person_add_alt),
              const SizedBox(height: 8),
              _buildDropdownField("--- Pilih Nama Karyawan ---"),
            ] else ...[
              // FORM PINDAH LOKASI
              _buildInputLabel("Lokasi", Icons.location_on_outlined),
              const SizedBox(height: 8),
              _buildDropdownField("-- Pilih Ruangan / Gedung --"),
            ],

            const SizedBox(height: 25),

            // 5. AREA TANDA TANGAN
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Tanda Tangan Penerima",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                // Tombol Reset Tanda Tangan
                InkWell(
                  onTap: () => _signatureController.clear(),
                  child: Text("Hapus", style: GoogleFonts.poppins(color: Colors.red, fontSize: 12)),
                )
              ],
            ),

            const SizedBox(height: 10),

            // KOTAK TANDA TANGAN
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey, style: BorderStyle.none), // Bisa diganti DottedBorder kalo mau
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  children: [
                    // Canvas Tanda Tangan
                    Signature(
                      controller: _signatureController,
                      backgroundColor: const Color(0xFFEEEEEE), // Warna abu-abu muda
                      height: 180,
                      width: double.infinity,
                    ),
                    // Placeholder Text (Hilang kalau sudah tanda tangan - logika sederhana)
                    Center(
                      child: IgnorePointer( // Agar tap tembus ke canvas
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit, color: Colors.grey[400], size: 40),
                            const SizedBox(height: 10),
                            Text(
                              "Tap disini untuk tanda tangan",
                              style: GoogleFonts.poppins(
                                color: Colors.grey[500],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Saya menyatakan kondisi barang sesuai",
                              style: GoogleFonts.poppins(
                                color: Colors.grey[500],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),

            // FOOTER / TOMBOL CONFIRM
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total item", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                    Text("1 Unit Aset", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("Jenis Dokumen", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                    Text("BAST Elektronik", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0087FF))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Aksi Simpan BAST
                },
                icon: const Icon(Icons.description, size: 20),
                label: Text(
                  "Konfirmasi Serah Terima",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300], // Warna disable sesuai mockup (nanti ubah logicnya)
                  foregroundColor: Colors.grey[600],
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ],
    );
  }

   Widget _textField(String hint, {bool enabled = true, String? initialValue}) {
    return TextFormField(
      initialValue: initialValue,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200], // Background abu sesuai mockup
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14)),
          items: const [], // List kosong dulu
          onChanged: (val) {},
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        ),
      ),
    );
  }
}