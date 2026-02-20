import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import halaman Login yang sudah kita buat
// Pastikan folder kamu sesuai (lib/ui/screens/login_screen.dart)
import 'ui/screens/login_screens.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Menghilangkan pita "Debug" di pojok kanan atas
      title: 'TSI Asset Management',
      
      // Mengatur Tema Aplikasi secara Global
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0087FF)), // Warna Biru TSI
        useMaterial3: true,
        // Kita set font default aplikasi jadi Poppins biar konsisten
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),

      // INI BAGIAN PENTINGNYA!
      // Kita suruh aplikasi buka LoginScreen() pertama kali
      home: const LoginScreen(), 
    );
  }
}