import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert'; // Wajib buat jinakin JSON

// Sesuaikan path import ini kalau merah ya Tuan!
import '../../models/dashboard_model.dart'; 
import '../../services/api_services.dart'; 

import 'asset_list_screen.dart'; 
import 'bash_form_screen.dart'; 
import 'scan_screen.dart'; 
import 'form_add_asset_screen.dart';

// Asumsi lu punya file main.dart atau ganti ke halaman yang bener buat Tagging
import '../../main.dart'; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0; 

  // 1. Panggil Senjata API lu
  final ApiService _apiService = ApiService();
  late Future<DashboardModel> _futureDashboard;

  @override
  void initState() {
    super.initState();
    // 2. Langsung sedot data pas halaman kebuka
    _futureDashboard = fetchDashboard();
  }

  // 3. Fungsi Nyedot Data Dashboard Anti Badai
  Future<DashboardModel> fetchDashboard() async {
    try {
      final response = await _apiService.getDashboardSummary();
      dynamic responseData = response.data;
      
      // Kalo Postman ngide ngirim String mentah
      if (responseData is String) {
        responseData = jsonDecode(responseData);
      }

      // Ambil bungkus "data" dari JSON lu
      final data = responseData['data'];
      return DashboardModel.fromJson(data);
    } catch (e) {
      throw Exception('Gagal nyedot data dashboard: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      
      // 4. BUNGKUS SELURUH BODY PAKE FUTURE BUILDER
      body: SafeArea(
        child: FutureBuilder<DashboardModel>(
          future: _futureDashboard,
          builder: (context, snapshot) {
            // Pas lagi nunggu server
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } 
            // Kalo server ngambek
            else if (snapshot.hasError) {
              return Center(child: Text('Error bos: ${snapshot.error}'));
            } 
            // Kalo data gaib
            else if (!snapshot.hasData) {
              return const Center(child: Text('Data dashboard kosong.'));
            }

                  
            final dashboardData = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Selamat pagi,", style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])),
                          // TAMPILIN NAMA USER DARI API
                          Text(dashboardData.namaUser, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                        ],
                      ),
                      Stack(
                        children: [
                          const Icon(Icons.notifications_none_outlined, size: 32),
                          Positioned(right: 4, top: 4, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle))),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 25),

                  // RINGKASAN STATUS
                  Row(
                    children: [
                      // Kartu Biru
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0087FF),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: const Color(0xFF0087FF).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
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
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                    child: Text("Total", style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
                                  )
                                ],
                              ),
                              const SizedBox(height: 12),
                              // TAMPILIN TOTAL ASET DARI API
                              Text(dashboardData.totalAset.toString(), style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text("Aset dalam tanggung jawab", style: GoogleFonts.poppins(fontSize: 10, color: Colors.white.withOpacity(0.9))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Kartu Putih
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
                                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                                    child: Text("Action", style: GoogleFonts.poppins(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                  )
                                ],
                              ),
                              const SizedBox(height: 12),
                              // TAMPILIN MAINTENANCE DARI API
                              Text(dashboardData.perluMaintenance.toString(), style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
                              Text("Perlu Maintenance", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),
                  Text("MENU CEPAT", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.0)),
                  const SizedBox(height: 15),

                  // GRID MENU CEPAT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickMenu(
                        icon: Icons.qr_code_scanner, 
                        label: "Scan", 
                        color: const Color(0xFFE3F2FD), 
                        iconColor: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => const ScanScreen())
                          );
                        }
                      ),
                      _buildQuickMenu(
                        icon: Icons.add_circle_outline, 
                        label: "Tagging", 
                        color: const Color(0xFFE8F5E9), 
                        iconColor: Colors.green,
                        onTap: () async {
                         final result = await Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const AssetRegistrationPage()));
                            if (result == true) {
                            // REFRESH DASHBOARDNYA!
                            setState(() {
                              _futureDashboard = fetchDashboard();
                            });
                          }
                        }
                      ),
                      _buildQuickMenu(
                        icon: Icons.swap_horiz, 
                        label: "Mutasi", 
                        color: const Color(0xFFF3E5F5), 
                        iconColor: Colors.purple,
                        onTap: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => const BastFormScreen())
                          );
                        }
                      ),
                      _buildQuickMenu(
                        icon: Icons.insert_chart_outlined_outlined, 
                        label: "Laporan", 
                        color: const Color(0xFFFFF3E0), 
                        iconColor: Colors.orange
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),
                  Text("AKTIVITAS TERBARU", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.0)),
                  const SizedBox(height: 15),

                  // LIST AKTIVITAS
                 // LIST AKTIVITAS (SEKARANG DINAMIS COY)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      // Kita Looping datanya pake map()
                      children: dashboardData.aktivitasTerbaru.map((aktivitas) {
                        return Column(
                          children: [
                            _buildActivityItem(aktivitas.judul, aktivitas.deskripsi, aktivitas.waktu),
                            // Biar garis bawahnya ilang di list paling terakhir
                            if (aktivitas != dashboardData.aktivitasTerbaru.last)
                              const Divider(height: 1, indent: 70),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),

      // TOMBOL TENGAH (SCAN)
      floatingActionButton: SizedBox(
        height: 70,
        width: 70,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ScanScreen()),
            );
          },
          backgroundColor: const Color(0xFF0087FF),
          shape: const CircleBorder(),
          elevation: 4,
          child: const Icon(Icons.qr_code_scanner, size: 32, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // BOTTOM NAVIGATION (FOOTER)
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
              Row(
                children: [
                  _buildNavItem(icon: Icons.home_filled, label: "Beranda", index: 0),
                  const SizedBox(width: 30),
                  _buildNavItem(icon: Icons.inventory_2_outlined, label: "Aset", index: 1),
                ],
              ),
              Row(
                children: [
                  _buildNavItem(icon: Icons.swap_horiz, label: "Mutasi", index: 2),
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

  // --- WIDGET HELPER ---
  Widget _buildQuickMenu({
    required IconData icon, 
    required String label, 
    required Color color, 
    required Color iconColor,
    VoidCallback? onTap, 
  }) {
    return GestureDetector( 
      onTap: onTap,
      child: Column(
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
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(color: Color(0xFFE3F2FD), shape: BoxShape.circle),
        child: const Icon(Icons.history_rounded, color: Colors.blue, size: 22),
      ),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
      trailing: Text(time, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400])),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AssetListScreen()));
        } else if (index == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const BastFormScreen()));
        } else {
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