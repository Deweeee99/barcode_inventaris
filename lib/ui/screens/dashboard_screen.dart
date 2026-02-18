import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'asset_list_screen.dart'; // Pastikan file ini ada

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0; // State untuk menu bawah

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      
      // BODY HALAMAN
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER: Bagian Nama Petugas & Notifikasi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Selamat pagi,",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        "Petugas Lapangan",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  // Ikon Notifikasi
                  Stack(
                    children: [
                      const Icon(Icons.notifications_none_outlined, size: 32),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
              const SizedBox(height: 25),

              // RINGKASAN STATUS (Total Aset & Maintenance)
              Row(
                children: [
                  // --- KARTU BIRU (TOTAL ASET) ---
                  // Navigasi DIHAPUS dari sini, dikembalikan jadi Container biasa
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0087FF),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0087FF).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 24),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Total",
                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "159",
                            style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            "Aset dalam tanggung jawab",
                            style: GoogleFonts.poppins(fontSize: 10, color: Colors.white.withOpacity(0.9)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 15),
                  
                  // --- KARTU PUTIH (PERLU MAINTENANCE) ---
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 24),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Action",
                                  style: GoogleFonts.poppins(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "5",
                            style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          Text(
                            "Perlu Maintenance",
                            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 35),
              Text(
                "MENU CEPAT",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.0),
              ),
              const SizedBox(height: 15),

              // GRID MENU CEPAT
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickMenu(icon: Icons.qr_code_scanner, label: "Scan", color: const Color(0xFFE3F2FD), iconColor: Colors.blue),
                  _buildQuickMenu(icon: Icons.add_circle_outline, label: "Tagging", color: const Color(0xFFE8F5E9), iconColor: Colors.green),
                  _buildQuickMenu(icon: Icons.swap_horiz, label: "Mutasi", color: const Color(0xFFF3E5F5), iconColor: Colors.purple),
                  _buildQuickMenu(icon: Icons.insert_chart_outlined_outlined, label: "Laporan", color: const Color(0xFFFFF3E0), iconColor: Colors.orange),
                ],
              ),

              const SizedBox(height: 35),
              Text(
                "AKTIVITAS TERBARU",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.0),
              ),
              const SizedBox(height: 15),

              // DAFTAR AKTIVITAS TERBARU
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    _buildActivityItem("Update Kondisi Asset", "Laptop Asus - Gedung A", "2j lalu"),
                    const Divider(height: 1, indent: 70),
                    _buildActivityItem("Update Kondisi Asset", "Laptop Lenovo - Gedung A", "2j lalu"),
                    const Divider(height: 1, indent: 70),
                    _buildActivityItem("Update Kondisi Asset", "Laptop Acer - Gedung A", "2j lalu"),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),

      // TOMBOL SCAN (Tengah)
      floatingActionButton: SizedBox(
        height: 70,
        width: 70,
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: const Color(0xFF0087FF),
          shape: const CircleBorder(),
          elevation: 4,
          child: const Icon(Icons.qr_code_scanner, size: 32, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // MENU NAVIGASI BAWAH
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        color: Colors.white,
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // Kiri
              Row(
                children: [
                  _buildNavItem(icon: Icons.home_filled, label: "Beranda", index: 0),
                  const SizedBox(width: 30),
                  // INI TOMBOL ASET (Index 1)
                  _buildNavItem(icon: Icons.inventory_2_outlined, label: "Aset", index: 1),
                ],
              ),
              // Kanan
              Row(
                children: [
                  _buildNavItem(icon: Icons.add_circle_outline, label: "Tagging", index: 2),
                  const SizedBox(width: 30),
                  _buildNavItem(icon: Icons.person_outline, label: "Profil", index: 3),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET HELPER: Membuat Item Menu Cepat
  Widget _buildQuickMenu({required IconData icon, required String label, required Color color, required Color iconColor}) {
    return Column(
      children: [
        Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
      ],
    );
  }

  // WIDGET HELPER: Membuat Item Aktivitas
  Widget _buildActivityItem(String title, String subtitle, String time) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.history_rounded, color: Colors.blue, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Text(
        time,
        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400]),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    );
  }

  // WIDGET HELPER: Membuat Item Navigasi Bawah
  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          // KHUSUS TOMBOL "ASET" -> PINDAH HALAMAN
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AssetListScreen()),
          );
        } else {
          // YANG LAIN -> GANTI MENU BIASA
          setState(() {
            _selectedIndex = index;
          });
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF0087FF) : Colors.grey, size: 26),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: isSelected ? const Color(0xFF0087FF) : Colors.grey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}