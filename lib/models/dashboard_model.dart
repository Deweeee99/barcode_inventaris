// Bikin class kecil buat nampung satuan aktivitas
class AktivitasModel {
  final String judul;
  final String deskripsi;
  final String waktu;

  AktivitasModel({
    required this.judul,
    required this.deskripsi,
    required this.waktu,
  });

  factory AktivitasModel.fromJson(Map<String, dynamic> json) {
    return AktivitasModel(
      judul: json['judul'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      waktu: json['waktu'] ?? '',
    );
  }
}

// Class utama dashboard
class DashboardModel {
  final String namaUser;
  final int totalAset;
  final int perluMaintenance;
  final List<AktivitasModel> aktivitasTerbaru; // <--- Senjata baru lu

  DashboardModel({
    required this.namaUser,
    required this.totalAset,
    required this.perluMaintenance,
    required this.aktivitasTerbaru,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    // Tangkep array aktivitas dari JSON
    var listAktivitasRaw = json['aktivitas_terbaru'] as List? ?? [];
    List<AktivitasModel> listAktivitas = listAktivitasRaw.map((i) => AktivitasModel.fromJson(i)).toList();

    return DashboardModel(
      namaUser: json['nama_user'] ?? 'User',
      totalAset: json['total_aset'] ?? 0,
      perluMaintenance: json['perlu_maintenance'] ?? 0,
      aktivitasTerbaru: listAktivitas, // <--- Masukin sini
    );
  }
}