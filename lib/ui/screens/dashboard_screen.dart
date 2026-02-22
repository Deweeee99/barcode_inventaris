import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/dashboard_model.dart'; 
import '../../models/tugas_model.dart'; 
import '../../services/api_services.dart'; 

import 'asset_list_screen.dart'; 
import 'bash_form_screen.dart'; 
import 'scan_screen.dart'; 
import 'form_add_asset_screen.dart';
import 'profile_screen.dart'; 
import 'task_list_screen.dart'; 
import 'task_detail_screen.dart'; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  late Future<DashboardModel> _futureDashboard;
  
  int _selectedIndex = 0; 
  
  // --- STATE BUAT NOTIFIKASI DINAMIS ---
  int _unreadNotifications = 0; 
  List<TugasModel> _unreadTasks = [];
  
  int _lastNotifiedTaskId = -1;

  @override
  void initState() {
    super.initState();
    _futureDashboard = fetchDashboard();
  }

  // --- JURUS BARU: POP UP DARI BAWAH (FLOATING SNACKBAR) ---
  void _showNewTaskSnackbar(TugasModel tugas) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0056D2),
        elevation: 10,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            const Icon(Icons.assignment_late_outlined, color: Colors.white, size: 28),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Tugas Baru: ${tugas.namaPemberiTugas}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                  Text(tugas.deskripsi, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'BUKA',
          textColor: Colors.orangeAccent,
          onPressed: () {
            // Langsung buka laci lonceng pas dipencet
            _showNotificationSheet();
          },
        ),
      ),
    );
  }

  Future<DashboardModel> fetchDashboard() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String namaUserAsli = prefs.getString('nama_user') ?? "Petugas TSI";

    // 1. Ambil Data Dashboard
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

    // 2. JURUS FIX PENUGASAN (Tarik Semua Dulu, Baru Filter Lokal)
    try {
      // Sekarang kita kaga nge-filter dari parameter API, tarik semua tugas dia!
      final resTugas = await _apiService.getTugas();
      var dataTugas = resTugas.data;
      if (dataTugas is String) dataTugas = jsonDecode(dataTugas);
      
      List<dynamic> listRawTugas = dataTugas['data']?['data'] ?? dataTugas['data'] ?? [];
      
      if (mounted) {
        List<TugasModel> allTasks = listRawTugas.map((e) => TugasModel.fromJson(e)).toList();
        
        // Filter mandiri di aplikasi (Tangkep "Pending" atau "Belum Dibaca")
        List<TugasModel> newTasks = allTasks.where((t) {
          String s = t.status.toLowerCase();
          return s == 'belum dibaca' || s == 'pending';
        }).toList();

        // Cek kalau ada tugas baru yang belum di-pop-up
        if (newTasks.isNotEmpty) {
          var latestTask = newTasks.first;
          if (_lastNotifiedTaskId != latestTask.idTugas) {
            _lastNotifiedTaskId = latestTask.idTugas;
            // Panggil snackbar setelah frame UI selesai di-build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showNewTaskSnackbar(latestTask);
            });
          }
        }

        setState(() {
          _unreadTasks = newTasks;
          _unreadNotifications = _unreadTasks.length; 
        });
      }
    } catch (e) {
      debugPrint("Gagal narik notif tugas: $e");
    }

    return DashboardModel(
      namaUser: namaUserAsli,
      totalAset: totalData,
      perluMaintenance: barangRusak,
      aktivitasTerbaru: aktivitasDinamis,
    );
  }

  // --- FITUR LACI NOTIFIKASI (BOTTOM SHEET) ---
  void _showNotificationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, 
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Notifikasi Penugasan", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey), 
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  
                  Expanded(
                    child: _unreadTasks.isEmpty 
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.done_all, size: 60, color: Colors.grey[300]),
                              const SizedBox(height: 10),
                              Text("Hore! Kaga ada tugas baru Tuan.", style: TextStyle(color: Colors.grey[500])),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _unreadTasks.length,
                          itemBuilder: (context, index) {
                            final tugas = _unreadTasks[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 15),
                              color: Colors.blue.withOpacity(0.05),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15), 
                                side: BorderSide(color: Colors.blue.withOpacity(0.2))
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                onTap: () async {
                                  Navigator.pop(context); 
                                  final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => TaskDetailScreen(tugas: tugas)));
                                  if (res == true) setState(() { _futureDashboard = fetchDashboard(); });
                                },
                                title: Text(tugas.deskripsi, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 5),
                                    Text("Aset: ${tugas.namaBarang}", style: const TextStyle(fontSize: 11)),
                                    Text("Tenggat: ${tugas.jadwalTenggat}", style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                                  tooltip: "Tandai Sudah Dibaca",
                                  onPressed: () async {
                                    try {
                                      await _apiService.updateStatusTugas(tugas.idTugas, 'Sudah Dibaca');
                                      setModalState(() { _unreadTasks.removeAt(index); }); 
                                      setState(() { _unreadNotifications = _unreadTasks.length; }); 
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sip! Tugas udah ditandain dibaca.'), backgroundColor: Colors.green));
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal ngupdate status!'), backgroundColor: Colors.red));
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                      ),
                  )
                ],
              ),
            );
          }
        );
      }
    ).then((_) {
      setState(() { _futureDashboard = fetchDashboard(); });
    });
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: return _buildHomeContent();
      case 3: return const ProfileScreen(); 
      default: return _buildHomeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(child: _buildBody()), 

      floatingActionButton: _selectedIndex != 3 ? SizedBox( 
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
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF0087FF)));
        if (snapshot.hasError) return const Center(child: Text("Error memuat dashboard"));
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
                  
                  GestureDetector(
                    onTap: _showNotificationSheet,
                    child: Container(
                      padding: const EdgeInsets.all(8), 
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(12), 
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
                      ), 
                      child: Stack(
                        children: [
                          const Icon(Icons.notifications_none_outlined, size: 28),
                          if (_unreadNotifications > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                                child: Text(
                                  _unreadNotifications.toString(), 
                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                        ],
                      ),
                    ),
                  ),
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
                  _buildMenu("Penugasan", Icons.assignment_turned_in_outlined, Colors.orange, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TaskListScreen()));
                  }),
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
        if (index == 1) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AssetListScreen()));
        } else if (index == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const BastFormScreen()));
        } else {
          setState(() => _selectedIndex = index);
        }
      },
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: isSelected ? const Color(0xFF0087FF) : Colors.grey, size: 26),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: isSelected ? const Color(0xFF0087FF) : Colors.grey, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      ]),
    );
  }
}