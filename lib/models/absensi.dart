class Absensi {
  final int? id;
  final int santriId;
  final int? adminId;
  final String tanggal;
  final String status; // hadir, sakit, izin, alpha
  final String? catatan;
  final String? santriNama;
  final int? noAbsen;
  final String? adminNama;

  Absensi({
    this.id,
    required this.santriId,
    this.adminId,
    required this.tanggal,
    required this.status,
    this.catatan,
    this.santriNama,
    this.noAbsen,
    this.adminNama,
  });

  factory Absensi.fromJson(Map<String, dynamic> json) {
    final santri = json['santri'] as Map<String, dynamic>?;
    final admin = json['admin'] as Map<String, dynamic>?;
    return Absensi(
      id: json['id'],
      santriId: json['santri_id'] ?? 0,
      adminId: json['admin_id'],
      tanggal: json['tanggal'] ?? '',
      status: json['status'] ?? 'alpha',
      catatan: json['catatan'],
      santriNama: santri?['nama_lengkap'] ?? json['santri_nama'],
      noAbsen: santri?['no_absen'] ?? json['no_absen'],
      adminNama: admin?['nama_lengkap'] ?? json['admin_nama'],
    );
  }

  Map<String, dynamic> toJson() => {
    'santri_id': santriId,
    'status': status,
    if (catatan != null && catatan!.isNotEmpty) 'catatan': catatan,
  };

  Absensi copyWith({String? status, String? catatan}) {
    return Absensi(
      id: id,
      santriId: santriId,
      adminId: adminId,
      tanggal: tanggal,
      status: status ?? this.status,
      catatan: catatan ?? this.catatan,
      santriNama: santriNama,
      noAbsen: noAbsen,
      adminNama: adminNama,
    );
  }

  static const List<String> statusOptions = ['hadir', 'sakit', 'izin', 'alpha'];
}
