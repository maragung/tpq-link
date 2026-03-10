class Santri {
  final int? id;
  final int? noAbsen;
  final String nik;
  final String namaLengkap;
  final String? jenisKelamin;
  final String? jilid;
  final String? alamat;
  final String? namaWali;
  final String? noTelpWali;
  final String? emailWali;
  final String? tglMendaftar;
  final bool statusAktif;
  final String? tglNonaktif;
  final bool isSubsidi;

  Santri({
    this.id,
    this.noAbsen,
    required this.nik,
    required this.namaLengkap,
    this.jenisKelamin,
    this.jilid,
    this.alamat,
    this.namaWali,
    this.noTelpWali,
    this.emailWali,
    this.tglMendaftar,
    this.statusAktif = true,
    this.tglNonaktif,
    this.isSubsidi = false,
  });

  factory Santri.fromJson(Map<String, dynamic> json) {
    return Santri(
      id: json['id'],
      noAbsen: json['no_absen'],
      nik: json['nik'] ?? '',
      namaLengkap: json['nama_lengkap'] ?? '',
      jenisKelamin: json['jenis_kelamin'],
      jilid: json['jilid'],
      alamat: json['alamat'],
      namaWali: json['nama_wali'],
      noTelpWali: json['no_telp_wali'],
      emailWali: json['email_wali'],
      tglMendaftar: json['tgl_mendaftar'],
      statusAktif: json['status_aktif'] ?? true,
      tglNonaktif: json['tgl_nonaktif'],
      isSubsidi: json['is_subsidi'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (noAbsen != null) 'no_absen': noAbsen,
        'nik': nik,
        'nama_lengkap': namaLengkap,
        'jenis_kelamin': jenisKelamin,
        'jilid': jilid,
        'alamat': alamat,
        'nama_wali': namaWali,
        'no_telp_wali': noTelpWali,
        'email_wali': emailWali,
        'tgl_mendaftar': tglMendaftar,
        'status_aktif': statusAktif,
        'is_subsidi': isSubsidi,
      };
}
