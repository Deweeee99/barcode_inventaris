class BarangModel {
  final String idBarang;
  final String namaBarang;
  final String kodeBarcode;
  final String spesifikasi;
  final int jumlahBarang;
  final String lokasiFisik;

  BarangModel({
    required this.idBarang,
    required this.namaBarang,
    required this.kodeBarcode,
    required this.spesifikasi,
    required this.jumlahBarang,
    required this.lokasiFisik,
  });

  // Untuk mengubah data dari JSON (Backend) ke Object Flutter
  factory BarangModel.fromJson(Map<String, dynamic> json) {
    return BarangModel(
      idBarang: json['id_barang'],
      namaBarang: json['nama_barang'],
      kodeBarcode: json['kode_barcode'],
      spesifikasi: json['spesifikasi'],
      jumlahBarang: json['jumlah_barang'],
      lokasiFisik: json['lokasi_fisik'],
    );
  }
}