import 'dart:convert';

class BarangModel {
  final int id;
  final String namaBarang;
  final String kodeBarcode;
  final String kategori; 
  final String kondisi;
  final String statusPenguasaan;
  final String lokasiFisik;
  final String karyawanPemegang;
  final String nipPemegang; // --- BARU: Buat nyimpen NIP pemegang saat ini ---
  final String tglLabeling;
  final String spesifikasi;
  final List<String> dokumentasiBarang; 
  
  final String noKontrak;
  final String tahunPengadaan;
  final String vendor;
  final String pihakPengada;

  BarangModel({
    required this.id,
    required this.namaBarang,
    required this.kodeBarcode,
    required this.kategori,
    required this.kondisi,
    required this.statusPenguasaan,
    required this.lokasiFisik,
    required this.karyawanPemegang,
    required this.nipPemegang, // --- BARU ---
    required this.tglLabeling,
    required this.spesifikasi,
    required this.dokumentasiBarang,
    required this.noKontrak,
    required this.tahunPengadaan,
    required this.vendor,
    required this.pihakPengada,
  });

  factory BarangModel.fromJson(Map<String, dynamic> json) {
    
    // --- 1. JURUS NANGKEP PEMEGANG ASET & NIP-NYA ---
    String namaKaryawan = '-';
    String nipKaryawan = '-';

    if (json['karyawan'] != null) {
      namaKaryawan = json['karyawan']['nama_karyawan'] ?? '-';
      nipKaryawan = json['karyawan']['nip']?.toString() ?? '-';
    } else if (json['id_karyawan_pemegang'] != null) {
      namaKaryawan = 'ID Karyawan: ${json['id_karyawan_pemegang']}';
      nipKaryawan = json['id_karyawan_pemegang'].toString();
    } else if (json['nip'] != null) {
      nipKaryawan = json['nip'].toString();
    }

    // --- 2. JURUS DETEKSI TIPE ASET ---
    String statusFinal = 'pending'; 
    if (json['lokasi_fisik'] != null && json['lokasi_fisik'].toString().trim() != '') {
      statusFinal = 'lokasi';
    } else if (json['id_karyawan_pemegang'] != null || json['nip'] != null) {
      statusFinal = 'personal';
    } else if (json['status_penguasaan'] != null) {
      statusFinal = json['status_penguasaan'].toString().toLowerCase();
    }

    // --- 3. JURUS TANGKEP DATA KONTRAK ---
    String noKontrakRaw = '-';
    String tahunRaw = '-';
    String vendorRaw = '-';
    String pengadaRaw = '-';

    if (json['kontrak'] != null) {
      var k = json['kontrak'];
      noKontrakRaw = k['no_kontrak']?.toString() ?? '-';
      tahunRaw = k['tahun_kontrak']?.toString() ?? k['tahun_pengadaan']?.toString() ?? k['tahun']?.toString() ?? '-'; 
      vendorRaw = k['nama_vendor']?.toString() ?? k['vendor']?.toString() ?? '-'; 
      pengadaRaw = k['pihak_pengada']?.toString() ?? '-';
    }

    // --- 4. JURUS TANGKEP KONDISI ---
    String kondisiAset = 'Baik'; 
    if (json['latest_kondisi'] != null && json['latest_kondisi']['status_kondisi'] != null) {
      kondisiAset = json['latest_kondisi']['status_kondisi'].toString();
    } else if (json['kondisi'] is List && (json['kondisi'] as List).isNotEmpty) {
      kondisiAset = (json['kondisi'] as List).last['status_kondisi']?.toString() ?? 'Baik';
    } else if (json['kondisi'] is String) {
      kondisiAset = json['kondisi'];
    }

    // --- 5. JURUS NANGKEP BANYAK FOTO SEKALIGUS ---
    List<String> listFoto = [];
    if (json['dokumentasi_barang'] != null) {
      if (json['dokumentasi_barang'] is List) {
        listFoto = List<String>.from(json['dokumentasi_barang'].map((x) => x.toString()));
      } else if (json['dokumentasi_barang'] is String) {
        try {
          var parsed = jsonDecode(json['dokumentasi_barang']);
          if (parsed is List) {
            listFoto = List<String>.from(parsed.map((x) => x.toString()));
          }
        } catch(e) {}
      }
    }

    return BarangModel(
      id: json['id_barang'] ?? json['id'] ?? 0,
      namaBarang: json['nama_barang'] ?? 'Aset Tanpa Nama',
      kodeBarcode: json['kode_barcode'] ?? '-',
      kategori: json['kategori'] ?? '-', 
      
      kondisi: kondisiAset, 
      statusPenguasaan: statusFinal,
      lokasiFisik: json['lokasi_fisik'] ?? '-',
      karyawanPemegang: namaKaryawan, 
      nipPemegang: nipKaryawan, // --- BARU ---
      
      tglLabeling: json['created_at'] != null 
          ? json['created_at'].toString().substring(0, 10) 
          : '-',
          
      spesifikasi: json['spesifikasi'] ?? '-',
      dokumentasiBarang: listFoto, 
      
      noKontrak: noKontrakRaw,
      tahunPengadaan: tahunRaw,
      vendor: vendorRaw,
      pihakPengada: pengadaRaw,
    );
  }
}