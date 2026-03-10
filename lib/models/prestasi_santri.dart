class PrestasiSantri {
  final int id;
  final int santriId;
  final int? adminId;
  final String tanggal;
  final String jenisPrestasi;
  final String? judulPrestasi;
  final String? jilid;
  final String? halaman;
  final String ustNama;
  final String? paraf;
  final String? keterangan;
  final int? santriNoAbsen;
  final String santriNama;
  final String? santriJilid;

  PrestasiSantri({
    required this.id,
    required this.santriId,
    this.adminId,
    required this.tanggal,
    required this.jenisPrestasi,
    this.judulPrestasi,
    this.jilid,
    this.halaman,
    required this.ustNama,
    this.paraf,
    this.keterangan,
    this.santriNoAbsen,
    required this.santriNama,
    this.santriJilid,
  });

  factory PrestasiSantri.fromJson(Map<String, dynamic> json) {
    return PrestasiSantri(
      id: json['id'] ?? 0,
      santriId: json['santri_id'] ?? json['santri']?['id'] ?? 0,
      adminId: json['admin_id'],
      tanggal: json['tanggal'] ?? '',
      jenisPrestasi: json['jenis_prestasi'] ?? '',
      judulPrestasi: json['judul_prestasi'],
      jilid: json['jilid'],
      halaman: json['halaman'],
      ustNama: json['ust_nama'] ?? json['admin']?['nama_lengkap'] ?? '-',
      paraf: json['paraf'],
      keterangan: json['keterangan'],
      santriNoAbsen: json['santri']?['no_absen'],
      santriNama: json['santri']?['nama_lengkap'] ?? '-',
      santriJilid: json['santri']?['jilid'],
    );
  }
}
