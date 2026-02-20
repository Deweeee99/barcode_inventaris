import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_services.dart';
import 'login_screens.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await _apiService.getUserProfile();
      if (mounted) {
        setState(() {
          _userData = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Gagal ambil profil: $e");
    }
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog first
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout?"),
        content: const Text("Yakin mau keluar dari akun Tuan?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Keluar", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await _apiService.logout();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context, 
            MaterialPageRoute(builder: (context) => const LoginScreen()), 
            (route) => false
          );
        }
      } catch (e) {
        print("Logout error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF0056D2))));
    }

    // Mapping Data dari Backend Laravel Tuan
    final karyawan = _userData?['karyawan'];
    final String nama = karyawan?['nama_karyawan'] ?? _userData?['username'] ?? "User TSI";
    final String nip = karyawan?['nip'] ?? "-";
    final String departemen = karyawan?['departemen'] ?? "Operasional Lapangan";
    final String jabatan = karyawan?['jabatan'] ?? "Petugas Lapangan";
    final String handle = "@${_userData?['username']?.toString().toLowerCase() ?? 'user'}";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. HEADER BIRU (Melengkung)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0056D2), Color(0xFF0087FF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          "Profil Saya",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 48), // Spacer biar title center
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Avatar with Badge
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: const NetworkImage("https://i.pravatar.cc/300"), // Dummy image
                        ),
                      ),
                      Positioned(
                        bottom: -5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0056D2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            "Petugas Lapangan",
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(nama, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                  Text(handle, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. CARD INFORMASI PEKERJAAN
                  Text("INFORMASI PEKERJAAN", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600], letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        _buildProfileInfoItem(Icons.badge_outlined, "Nomor Induk Pegawai (NIP)", "NIP. $nip"),
                        const Divider(height: 30),
                        _buildProfileInfoItem(Icons.shield_outlined, "Divisi / Departemen", departemen),
                        const Divider(height: 30),
                        _buildProfileInfoItem(Icons.work_outline, "Jabatan Saat Ini", jabatan),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 3. MENU LIST (Sinkronisasi, Notif, dll)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(Icons.sync, "Sinkronasi Data Offline", Colors.green[100]!, Colors.green),
                        _buildMenuItem(Icons.notifications_none, "Notifikasi", Colors.orange[100]!, Colors.orange),
                        _buildMenuItem(Icons.lock_outline, "Ubah Password", Colors.blue[100]!, Colors.blue),
                        _buildMenuItem(Icons.help_outline, "Bantuan & Panduan", Colors.grey[200]!, Colors.grey),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 4. LOGOUT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout),
                      label: const Text("Keluar dari Akun (Log Out)", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD1D1),
                        foregroundColor: const Color(0xFFFF4848),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFEBF5FF), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: const Color(0xFF0087FF), size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, Color bgIcon, Color iconColor) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: bgIcon, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.black54),
      onTap: () {},
    );
  }
}