import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_services.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;
  
  // --- STATE BARU BUAT CHECKBOX PERSETUJUAN ---
  bool _isConsentGiven = false;

  final ApiService _apiService = ApiService();

  Future<void> _handleLogin() async {
    // Validasi form kosong
    if (_usernameCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username dan Password wajib diisi Tuan!'), backgroundColor: Colors.red),
      );
      return;
    }

    // Validasi checkbox wajib dicentang
    if (!_isConsentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap centang persetujuan data pribadi dulu Tuan!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.login(_usernameCtrl.text, _passwordCtrl.text);
      final responseData = response.data;

      var dataObj = responseData['data'];
      var userObj = dataObj['user'];
      var token = dataObj['token'];

      // Cek Role Admin
      String userRole = userObj['role']?.toString().toLowerCase() ?? '';
      
      if (userRole == 'admin') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akses Ditolak! Admin hanya boleh login via Website/Laptop.'), 
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 4),
          ),
        );
        return; 
      }

      // Simpan Token & Nama ke memori HP
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token); 
      
      String namaLengkap = userObj['karyawan']?['nama_karyawan'] ?? userObj['username'];
      await prefs.setString('nama_user', namaLengkap);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal login. Cek lagi username/password Tuan.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7), // Warna background abu-abu sangat muda sesuai mockup
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              // --- LOGO SECTION ---
              Center(
                child: Image.asset(
                  'assets/images/LOGO TSI.png', // Tuan tinggal masukin gambar logo ke folder assets dan daftarin di pubspec.yaml
                  height: 140,
                  // Kalau gambar belum ada di assets, ini fallbacknya biar kaga merah layarnya
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      children: [
                        const Icon(Icons.blur_circular, size: 80, color: Color(0xFF003B73)),
                        const SizedBox(height: 10),
                        Text(
                          "TEKNOLOGI SINERGI\nINFORMMITA\nT S I",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF003B73), fontSize: 16),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 60),
              
              // --- FORM USERNAME ---
              Text(
                "Username",
                style: GoogleFonts.poppins(fontSize: 20, color: Colors.black87, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _usernameCtrl,
                decoration: InputDecoration(
                  hintText: "Username",
                  hintStyle: const TextStyle(color: Colors.black38),
                  filled: true,
                  fillColor: const Color(0xFFE2E4E7), // Warna abu-abu field mockup
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none, // Hilangin garis
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
              ),
              
              const SizedBox(height: 25),
              
              // --- FORM PASSWORD ---
              Text(
                "Password",
                style: GoogleFonts.poppins(fontSize: 20, color: Colors.black87, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  hintText: "Password",
                  hintStyle: const TextStyle(color: Colors.black38),
                  filled: true,
                  fillColor: const Color(0xFFE2E4E7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.black87,
                    ),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),

              // --- CHECKBOX PERSETUJUAN ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _isConsentGiven,
                      onChanged: (value) => setState(() => _isConsentGiven = value ?? false),
                      activeColor: const Color(0xFF007BFF), // Warna biru pas dicentang
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
                        children: [
                          const TextSpan(text: "I give my consent to the processing of my\n"),
                          TextSpan(text: "Personal data", style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.w600)),
                          const TextSpan(text: " and the "),
                          TextSpan(text: "Privacy Policy", style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // --- TOMBOL LOGIN ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0087FF), // Warna biru cerah mockup
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text("Login", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}