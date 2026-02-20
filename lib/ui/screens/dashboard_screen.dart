import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/dashboard_model.dart'; 
import '../../services/api_services.dart'; 

import 'asset_list_screen.dart'; 
import 'bash_form_screen.dart'; 
import 'scan_screen.dart'; 
import 'form_add_asset_screen.dart';
import 'profile_screen.dart'; // <--- Import ini Tuan!

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  late Future<DashboardModel> _futureDashboard;
  
  int _selectedIndex = 0; 

  @override
  void initState() {
    super.initState();
    _futureDashboard = fetchDashboard();
  }

  Future<DashboardModel> fetchDashboard() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String namaUserAsli = prefs.getString('nama_user') ?? "Admin TSI";

    final response = await _apiService.getDashboardSummary(); 
    dynamic responseData;

    if (response.data is String) {
      String raw = response.data.toString().trim();
      int startIndex = raw.indexOf('{');
      int endIndex = raw.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1 && endIndex >= startIndex) {
        raw = raw.substring(startIndex, endIndex + 1);
      }
      responseData = jsonDecode(raw);
    } else {
      responseData = response.data;
    }

    int totalData = 0;
    int barangRusak = 0;
    List<dynamic> listBarang = [];

    if (responseData != null && responseData is Map) {
      if (responseData.containsKey('statistik')) {
        var stat = responseData['statistik'];
        totalData = int.tryParse(stat['total_aset']?.toString() ?? '0') ?? 0;
        barangRusak = int.tryParse(stat['total_rusak']?.toString() ?? '0') ?? 0;
      }
      if (responseData.containsKey('barang')) {
        var barangObj = responseData['barang'];
        if (barangObj is Map && barangObj.containsKey('data')) {
          listBarang = barangObj['data'] ?? [];
        } else if (barangObj is List) {
          listBarang = barangObj;
        }
      }
    }

    List<AktivitasModel> aktivitasDinamis = [];
    if (listBarang.isNotEmpty) {
      int ambilBerapa = listBarang.length > 3 ? 3 : listBarang.length;
      for (int i = 0; i < ambilBerapa; i++) {
        var item = listBarang[i]; 
        aktivitasDinamis.add(
          AktivitasModel(
            judul: "Aset: ${item['kode_barcode'] ?? '-'}", 
            deskripsi: item['nama_barang'] ?? 'Aset Baru', 
            waktu: item['created_at'] != null 
                ? item['created_at'].toString().split(' ').last.substring(0, 5) 
                : "Baru Saja"
          )
        );
      }
    } else {
       aktivitasDinamis.add(AktivitasModel(judul: "Belum Ada Aset", deskripsi: "Silakan tambah data aset", waktu: "-"));
    }

    return DashboardModel(
      namaUser: namaUserAsli,
      totalAset: totalData,
      perluMaintenance: barangRusak,
      aktivitasTerbaru: aktivitasDinamis,
    );
  }

  // --- JURUS SWITCHING HALAMAN ---
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: return _buildHomeContent();
      case 3: return const ProfileScreen(); // Langsung tampilin layar profil
      default: return _buildHomeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(child: _buildBody()), // Gunakan _buildBody()

      floatingActionButton: _selectedIndex != 3 ? SizedBox( // Hide button if in profile
        height: 70, width: 70,
        child: FloatingActionButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ScanScreen())),
          backgroundColor: const Color(0xFF0087FF),
          shape: const CircleBorder(),
          elevation: 4,
          child: const Icon(Icons.qr_code_scanner, size: 32, color: Colors.white),
        ),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

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
              Row(children: [
                _buildNavItem(icon: Icons.home_filled, label: "Beranda", index: 0),
                const SizedBox(width: 30),
                _buildNavItem(icon: Icons.inventory_2_outlined, label: "Aset", index: 1),
              ]),
              Row(children: [
                _buildNavItem(icon: Icons.swap_horiz, label: "Mutasi", index: 2),
                const SizedBox(width: 30),
                _buildNavItem(icon: Icons.person_outline, label: "Profil", index: 3),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return FutureBuilder<DashboardModel>(
      future: _futureDashboard,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return const Center(child: Text("Error"));
        final data = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async { setState(() { _futureDashboard = fetchDashboard(); }); },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Selamat pagi,", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                    Text(data.namaUser, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                  ]),
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: const Icon(Icons.notifications_none_outlined, size: 28)),
                ]),
                const SizedBox(height: 25),
                Row(children: [
                  _buildStatCard("Total Aset", data.totalAset.toString(), const Color(0xFF0087FF), Icons.inventory_2_outlined),
                  const SizedBox(width: 15),
                  _buildStatCard("Maintenance", data.perluMaintenance.toString(), Colors.redAccent, Icons.build_outlined),
                ]),
                const SizedBox(height: 35),
                Text("MENU CEPAT", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 15),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _buildMenu("Scan", Icons.qr_code_scanner, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ScanScreen()))),
                  _buildMenu("Tagging", Icons.add_circle_outline, Colors.green, () async {
                    final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AssetRegistrationPage()));
                    if (res == true) setState(() { _futureDashboard = fetchDashboard(); });
                  }),
                  _buildMenu("Mutasi", Icons.swap_horiz, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BastFormScreen()))),
                  _buildMenu("Laporan", Icons.insert_chart_outlined, Colors.orange, null),
                ]),
                const SizedBox(height: 35),
                Text("AKTIVITAS TERBARU", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
                  child: Column(children: data.aktivitasTerbaru.map((akt) => ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFFF0F7FF), child: Icon(Icons.history, color: Colors.blue, size: 20)),
                    title: Text(akt.judul, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text(akt.deskripsi, style: GoogleFonts.poppins(fontSize: 11)),
                    trailing: Text(akt.waktu, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                  )).toList()),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    bool isBlue = color == const Color(0xFF0087FF);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isBlue ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: !isBlue ? Border.all(color: Colors.grey[200]!) : null,
          boxShadow: [if(isBlue) BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: isBlue ? Colors.white : color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: isBlue ? Colors.white : Colors.black)),
          Text(title, style: GoogleFonts.poppins(fontSize: 11, color: isBlue ? Colors.white70 : Colors.grey)),
        ]),
      ),
    );
  }

  Widget _buildMenu(String label, IconData icon, Color color, VoidCallback? tap) {
    return GestureDetector(
      onTap: tap,
      child: Column(children: [
        Container(width: 60, height: 60, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: color, size: 26)),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (context) => const AssetListScreen()));
        else if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (context) => const BastFormScreen()));
        else setState(() => _selectedIndex = index);
      },
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: isSelected ? const Color(0xFF0087FF) : Colors.grey, size: 26),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: isSelected ? const Color(0xFF0087FF) : Colors.grey, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      ]),
    );
  }
}