import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- Buat nyimpen token

import '../../services/api_services.dart'; // <-- Mesin API kita
import 'dashboard_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiService _apiService = ApiService(); // Panggil mesin API

  bool _obscureText = true;
  bool _isConsentChecked = false;
  bool _isLoading = false; // State buat nahan loading

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // FUNGSI INTI BUAT LOGIN KE SERVER
  Future<void> _handleLogin() async {
    // 1. Validasi kosong
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username sama Password jangan dikosongin bos!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Nyalain muter-muter
    });

    try {
      // 2. Tembak API Login pake data ketikan
      final response = await _apiService.login(
        _usernameController.text, 
        _passwordController.text
      );

      // 3. Ekstrak Token dari balikan Server
      String? token;
      if (response.data['token'] != null) {
        token = response.data['token'];
      } else if (response.data['data'] != null && response.data['data']['token'] != null) {
        token = response.data['data']['token'];
      }

      if (token != null) {
        // 4. Buka Brankas HP dan Simpen Tokennya!
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        if (response.data['user'] != null && response.data['user']['name'] != null) {
          await prefs.setString('nama_user', response.data['user']['name']);
        } else {
          // Kalo API lu belom ngasih nama di balikan login, sementara pake username ketikan lu aja
          await prefs.setString('nama_user', _usernameController.text); 
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login Sukses! Selamat datang Tuan.'), backgroundColor: Colors.green),
          );

          // 5. Pindah ke Dashboard pake pushReplacement (biar kaga bisa di-back ke login)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } else {
        throw Exception("Waduh, server kaga ngasih token nih!");
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal Login: Cek lagi username/password lu!'), backgroundColor: Colors.red),
        );
        print("Error Login: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Matiin muter-muter
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Center(
                child: Image.asset(
                  'assets/images/LOGO TSI.png', 
                  height: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.business, size: 100, color: Colors.blue);
                  },
                ),
              ),
              const SizedBox(height: 40),
              Text(
                "Username",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: "Username",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFE0E0E0),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Text(
                "Password",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  hintText: "Password",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFE0E0E0),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _isConsentChecked,
                      activeColor: const Color(0xFF0087FF),
                      onChanged: (bool? value) {
                        setState(() {
                          _isConsentChecked = value ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.black),
                        children: [
                          const TextSpan(text: "I give my consent to the processing of my "),
                          TextSpan(
                            text: "Personal data",
                            style: GoogleFonts.poppins(color: const Color(0xFF0D47A1), fontWeight: FontWeight.w600),
                          ),
                          const TextSpan(text: " and the "),
                          TextSpan(
                            text: "Privacy Policy",
                            style: GoogleFonts.poppins(color: const Color(0xFF0D47A1), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // TOMBOL LOGIN DENGAN NAVIGASI & LOADING API
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  // Logikanya: Kalo belom dicentang ATAU lagi loading muter, tombol kaga bisa dipencet (null)
                  onPressed: (!_isConsentChecked || _isLoading) 
                    ? null 
                    : _handleLogin, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0087FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        height: 24, 
                        width: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : Text(
                        "Login",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}