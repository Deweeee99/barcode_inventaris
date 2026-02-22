import 'dart:convert';

class TugasModel {
  final int idTugas;
  final String status;
  final String jadwalMulai;
  final String jadwalTenggat;
  final String deskripsi;
  final String catatanPetugas;
  final List<String> fotoBuktiTugas;
  
  // Relasi Barang
  final int? idBarang;
  final String namaBarang;
  final String kodeBarcode;

  // Relasi Pemberi Tugas (Admin)
  final String namaPemberiTugas;

  TugasModel({
    required this.idTugas,
    required this.status,
    required this.jadwalMulai,
    required this.jadwalTenggat,
    required this.deskripsi,
    required this.catatanPetugas,
    required this.fotoBuktiTugas,
    this.idBarang,
    required this.namaBarang,
    required this.kodeBarcode,
    required this.namaPemberiTugas,
  });

  factory TugasModel.fromJson(Map<String, dynamic> json) {
    // Tangkep array foto bukti
    List<String> listFoto = [];
    if (json['foto_bukti_tugas'] != null) {
      if (json['foto_bukti_tugas'] is List) {
        listFoto = List<String>.from(json['foto_bukti_tugas'].map((x) => x.toString()));
      } else if (json['foto_bukti_tugas'] is String) {
        try {
          var parsed = jsonDecode(json['foto_bukti_tugas']);
          if (parsed is List) {
            listFoto = List<String>.from(parsed.map((x) => x.toString()));
          }
        } catch (e) {}
      }
    }

    // Tangkep relasi barang
    String nmBarang = '-';
    String brcBarang = '-';
    if (json['barang'] != null) {
      nmBarang = json['barang']['nama_barang'] ?? '-';
      brcBarang = json['barang']['kode_barcode'] ?? '-';
    }

    // Tangkep relasi admin/karyawan
    String nmAdmin = 'Sistem';
    if (json['admin'] != null && json['admin']['karyawan'] != null) {
      nmAdmin = json['admin']['karyawan']['nama_karyawan'] ?? 'Admin';
    }

    return TugasModel(
      idTugas: json['id_tugas'] ?? json['id'] ?? 0,
      status: json['status'] ?? 'Pending',
      jadwalMulai: json['jadwal_mulai']?.toString().substring(0, 10) ?? '-',
      jadwalTenggat: json['jadwal_tenggat']?.toString().substring(0, 10) ?? '-',
      deskripsi: json['deskripsi'] ?? 'Perawatan / Pengecekan Rutin',
      catatanPetugas: json['catatan_petugas'] ?? '',
      fotoBuktiTugas: listFoto,
      idBarang: json['id_barang'],
      namaBarang: nmBarang,
      kodeBarcode: brcBarang,
      namaPemberiTugas: nmAdmin,
    );
  }
}