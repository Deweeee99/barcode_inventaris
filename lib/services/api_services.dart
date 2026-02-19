import 'package:dio/dio.dart';

class ApiService {

  final Dio _dio = Dio();

  final String baseUrl = 'https://8d03373a-c9fa-43b8-b63c-8d3bb61d8fae.mock.pstmn.io';

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));
  }

    //ambil data barang dari server(GET)
    Future<Response> getBarang() async {
      try{
        final response = await _dio.get('/api/barang');
        return response;
      } on DioException catch (e) {
        throw Exception ('Gagal ambil data : ${e.message}');
      }
    }

    Future<Response> tambahBarang(Map<String, dynamic> dataBarang) async {
      try{
        final response = await _dio.post('api/barang', data: dataBarang);
        return response;
      }on DioException catch (e) {
        throw Exception('Gagal tambah barang : ${e.message}');
      }
    }
  }
