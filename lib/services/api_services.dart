import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  late Dio _dio;

  final String baseUrl = 'https://3d2c-101-255-138-6.ngrok-free.app/api';

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': '69420',
      },
    ));

   _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async { 
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('auth_token'); 
        
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options); 
      },
      onError: (DioException e, handler) {
        print("API Error: ${e.response?.statusCode} - ${e.response?.data}");
        String pesanError = e.message ?? "Error kaga jelas dari server";
        
        if (e.response?.statusCode == 403) {
          pesanError = "Akses Ditolak (403): Role lu kaga dapet izin masuk coy!";
        } else if (e.response?.statusCode == 401) {
          pesanError = "Sesi Habis (401): Token lu basi, coba login ulang!";
        } else if (e.response?.statusCode == 422) {
          var data = e.response?.data;
          if (data != null && data['errors'] != null) {
            List<String> errors = [];
            data['errors'].forEach((key, value) {
              errors.add("- $key: ${value.join(', ')}");
            });
            pesanError = "Validasi Gagal (422):\n${errors.join('\n')}";
          }
        }

        final customException = DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: e.type,
          error: pesanError,
        );

        return handler.next(customException);
      }
    ));
  }

  // ==========================================
  // 1. ENDPOINT AUTHENTICATION
  // ==========================================
  Future<Response> login(String username, String password) async {
    return await _dio.post('/login', data: {'username': username, 'password': password});
  }

  Future<Response> logout() async {
    return await _dio.post('/logout');
  }

  // --- TAMBAHAN BARU: Narik Profil User ---
  Future<Response> getUserProfile() async {
    return await _dio.get('/user');
  }

  // ==========================================
  // 2. ENDPOINT DASHBOARD & BARANG
  // ==========================================
  Future<Response> getDashboardSummary() async {
    return await _dio.get('/barang'); 
  }

  Future<Response> getBarang() async {
    return await _dio.get('/barang'); 
  }

  Future<Response> tambahBarang(Map<String, dynamic> dataKirim) async {
    return await _dio.post('/barang', data: dataKirim);
  }

  Future<Response> updateKondisiBarang(int idBarang, Map<String, dynamic> data) async {
    FormData formData = FormData.fromMap({
      "status_kondisi": data['status_kondisi'],
      "catatan": data['catatan'] ?? "",
      if (data.containsKey('foto_kondisi')) "foto_kondisi": data['foto_kondisi'], 
    });
    return await _dio.post('/barang/$idBarang/kondisi', data: formData);
  }

  Future<Response> getKontrak() async {
    return await _dio.get('/kontrak');
  }

  Future<Response> getDetailBarang(String barcode) async {
    return await _dio.get('/barang/$barcode');
  }

  Future<Response> submitMutasiBarang(Map<String, dynamic> data) async {
    FormData formData = FormData.fromMap(data);
    return await _dio.post('/mobilisasi', data: formData); 
  }
}