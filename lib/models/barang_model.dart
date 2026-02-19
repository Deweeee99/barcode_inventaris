class BarangModel {
  final int idBarang;
  final String kodeBarcode;
  final String namaBarang;
  final String spesifikasi;
  final int jumlahBarang;
  final String lokasiFisik;
  final String tglLabeling;

  BarangModel({
    required this.idBarang,
    required this.kodeBarcode,
    required this.namaBarang,
    required this.spesifikasi,
    required this.jumlahBarang,
    required this.lokasiFisik,
    required this.tglLabeling,
  });

  // Untuk mengubah data dari JSON (Backend) ke Object Flutter
  factory BarangModel.fromJson(Map<String, dynamic> json) {
    return BarangModel(
      idBarang: json['id_barang'] ?? 0,
      kodeBarcode: json['kode_barcode'] ?? '',
      namaBarang: json['nama_barang'] ?? '',
      spesifikasi: json['spesifikasi'] ?? '',
      jumlahBarang: json['jumlah_barang'] ?? 0,
      lokasiFisik: json['lokasi_fisik'] ?? '',
      tglLabeling: json['tgl_labeling'] ?? '',
    );
  }
}