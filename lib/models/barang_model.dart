class BarangModel {
  final int id;
  final String namaBarang;
  final String kodeBarcode;
  final String kondisi;
  final String statusPenguasaan;
  final String lokasiFisik;
  final String karyawanPemegang;
  final String tglLabeling;
  final String spesifikasi;
  
  // Field buat nyimpen data Kontrak
  final String noKontrak;
  final String tahunPengadaan;
  final String vendor;
  final String pihakPengada;

  BarangModel({
    required this.id,
    required this.namaBarang,
    required this.kodeBarcode,
    required this.kondisi,
    required this.statusPenguasaan,
    required this.lokasiFisik,
    required this.karyawanPemegang,
    required this.tglLabeling,
    required this.spesifikasi,
    required this.noKontrak,
    required this.tahunPengadaan,
    required this.vendor,
    required this.pihakPengada,
  });

  // FUNGSI SAKTI BUAT NGE-PARSE JSON DARI API
  factory BarangModel.fromJson(Map<String, dynamic> json) {
    
    // --- 1. JURUS NANGKEP PEMEGANG ASET ---
    String namaKaryawan = '-';
    if (json['karyawan'] != null && json['karyawan']['nama_karyawan'] != null) {
      namaKaryawan = json['karyawan']['nama_karyawan'];
    } else if (json['id_karyawan_pemegang'] != null) {
      namaKaryawan = 'ID Karyawan: ${json['id_karyawan_pemegang']}';
    }

    // --- 2. JURUS DETEKSI TIPE ASET ---
    String statusFinal = 'personal'; 
    if (json['lokasi_fisik'] != null && json['lokasi_fisik'].toString().trim() != '') {
      statusFinal = 'lokasi';
    } else if (json['id_karyawan_pemegang'] != null) {
      statusFinal = 'personal';
    } else if (json['status_penguasaan'] != null) {
      statusFinal = json['status_penguasaan'].toString().toLowerCase();
    }

    // --- 3. JURUS TANGKEP DATA KONTRAK (FULL SESUAI JSON LU) ---
    String noKontrakRaw = '-';
    String tahunRaw = '-';
    String vendorRaw = '-';
    String pengadaRaw = '-';

    if (json['kontrak'] != null) {
      noKontrakRaw = json['kontrak']['no_kontrak']?.toString() ?? '-';
      tahunRaw = json['kontrak']['tahun_kontrak']?.toString() ?? '-'; 
      vendorRaw = json['kontrak']['nama_vendor']?.toString() ?? '-'; 
      pengadaRaw = json['kontrak']['pihak_pengada']?.toString() ?? '-';
    }

    // --- 4. JURUS TANGKEP KONDISI (PRIORITAS LATEST_KONDISI) ---
    String kondisiAset = 'Belum Diatur';
    if (json['latest_kondisi'] != null && json['latest_kondisi']['status_kondisi'] != null) {
      kondisiAset = json['latest_kondisi']['status_kondisi'].toString();
    } else if (json['kondisi'] is List && (json['kondisi'] as List).isNotEmpty) {
      kondisiAset = (json['kondisi'] as List).last['status_kondisi']?.toString() ?? 'Belum Diatur';
    } else if (json['kondisi'] is String) {
      kondisiAset = json['kondisi'];
    }

    return BarangModel(
      // Sesuai JSON, id-nya ada di id_barang
      id: json['id_barang'] ?? json['id'] ?? 0,
      namaBarang: json['nama_barang'] ?? 'Aset Tanpa Nama',
      kodeBarcode: json['kode_barcode'] ?? '-',
      
      kondisi: kondisiAset, 
      statusPenguasaan: statusFinal,
      lokasiFisik: json['lokasi_fisik'] ?? '-',
      karyawanPemegang: namaKaryawan, 
      
      // Ambil tanggal dari created_at, potong 10 digit depan (YYYY-MM-DD)
      tglLabeling: json['created_at'] != null 
          ? json['created_at'].toString().substring(0, 10) 
          : '-',
          
      spesifikasi: json['spesifikasi'] ?? '-',
      
      // Masukin data kontrak ke dalam bungkusan model
      noKontrak: noKontrakRaw,
      tahunPengadaan: tahunRaw,
      vendor: vendorRaw,
      pihakPengada: pengadaRaw,
    );
  }
}