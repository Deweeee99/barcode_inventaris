import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  late Dio _dio;

  // Pastiin baseUrl lu sesuai sama ngrok terbaru lu ya Tuan
  final String baseUrl = 'https://b541-2001-448a-2074-36ac-5826-4e31-be47-d48c.ngrok-free.app/api';

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
          } else if (data != null && data['message'] != null) {
             pesanError = "Gagal (422): ${data['message']}";
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

  Future<Response> getUserProfile() async {
    return await _dio.get('/user');
  }

  // ==========================================
  // 2. ENDPOINT BARANG (ASET)
  // ==========================================
  Future<Response> getDashboardSummary() async {
    return await _dio.get('/barang', queryParameters: {'per_page': 5}); 
  }

  Future<Response> getBarang({String? search, String? kategori, String? sort, int? page}) async {
    Map<String, dynamic> qParams = {};
    if (search != null && search.isNotEmpty) qParams['search'] = search;
    if (kategori != null && kategori.isNotEmpty) qParams['kategori'] = kategori;
    if (sort != null && sort.isNotEmpty) qParams['sort'] = sort;
    if (page != null) qParams['page'] = page;

    return await _dio.get('/barang', queryParameters: qParams); 
  }

  // --- JURUS FIX: KITA BALIKIN PAKE PATH URL ---
  // Rute di Laravel temen lu tetep /barang/{kodeBarcode} dan barcodenya udah aman kaga ada garis miring
  Future<Response> getDetailBarang(String barcode) async {
    // Kita panggil encodeComponent jaga-jaga kalau suatu saat ada spasi atau karakter aneh
    String safeBarcode = Uri.encodeComponent(barcode);
    return await _dio.get('/barang/$safeBarcode');
  }

  // Tambah Barang + Multi Foto (dokumentasi_barang[])
  Future<Response> tambahBarang(Map<String, dynamic> dataKirim, {List<XFile>? multiFoto}) async {
    FormData formData = FormData.fromMap(dataKirim);

    if (multiFoto != null && multiFoto.isNotEmpty) {
      for (var file in multiFoto) {
        formData.files.add(MapEntry(
          'dokumentasi_barang[]', 
          await MultipartFile.fromFile(file.path, filename: file.name),
        ));
      }
    }
    return await _dio.post('/barang', data: formData);
  }

  // Update Barang + Multi Foto
  Future<Response> updateBarangData(int id, Map<String, dynamic> dataKirim, {List<XFile>? multiFoto}) async {
    FormData formData = FormData.fromMap(dataKirim);

    if (multiFoto != null && multiFoto.isNotEmpty) {
      for (var file in multiFoto) {
        formData.files.add(MapEntry(
          'dokumentasi_barang[]',
          await MultipartFile.fromFile(file.path, filename: file.name),
        ));
      }
    }
    return await _dio.post('/barang/$id/update', data: formData);
  }

  Future<Response> hapusBarang(int id) async {
    return await _dio.delete('/barang/$id');
  }

  Future<Response> updateKondisiBarang(int idBarang, Map<String, dynamic> data) async {
    FormData formData = FormData.fromMap({
      "status_kondisi": data['status_kondisi'],
      "catatan": data['catatan'] ?? "",
      if (data.containsKey('foto_kondisi') && data['foto_kondisi'] != null) "foto_kondisi": data['foto_kondisi'], 
    });
    return await _dio.post('/barang/$idBarang/kondisi', data: formData);
  }

  Future<Response> getKontrak() async {
    return await _dio.get('/kontrak');
  }

  // ==========================================
  // 3. ENDPOINT MOBILISASI (BAST)
  // ==========================================
  
  Future<Response> getPendingMobilisasi() async {
    return await _dio.get('/mobilisasi/pending');
  }

  Future<Response> submitMutasiBarang(Map<String, dynamic> data) async {
    FormData formData = FormData();

    data.forEach((key, value) {
      if (key == 'id_barang' && value is List) {
        for (var id in value) {
          formData.fields.add(MapEntry('id_barang[]', id.toString()));
        }
      } else if (value is MultipartFile) {
        formData.files.add(MapEntry(key, value));
      } else {
        formData.fields.add(MapEntry(key, value.toString()));
      }
    });

    return await _dio.post('/mobilisasi', data: formData); 
  }

  // ==========================================
  // 4. ENDPOINT TUGAS (EVALUASI POIN 9)
  // ==========================================
  
  Future<Response> getTugas({String? status, String? tanggal}) async {
    Map<String, dynamic> qParams = {};
    if (status != null && status.isNotEmpty) qParams['status'] = status;
    if (tanggal != null && tanggal.isNotEmpty) qParams['tanggal'] = tanggal;
    
    return await _dio.get('/tugas', queryParameters: qParams);
  }

  Future<Response> getDetailTugas(int id) async {
    return await _dio.get('/tugas/$id');
  }

  Future<Response> updateStatusTugas(int id, String status) async {
    // Status isinya: 'Sudah Dibaca' atau 'Proses'
    return await _dio.put('/tugas/$id/status', data: {'status': status});
  }

  Future<Response> completeTugas(int id, String catatan, {List<XFile>? multiFoto}) async {
    FormData formData = FormData.fromMap({'catatan_petugas': catatan});

    // Kirim banyak foto bukti tugas
    if (multiFoto != null && multiFoto.isNotEmpty) {
      for (var file in multiFoto) {
        formData.files.add(MapEntry(
          'foto_bukti_tugas[]',
          await MultipartFile.fromFile(file.path, filename: file.name),
        ));
      }
    }
    return await _dio.post('/tugas/$id/complete', data: formData);
  }
}