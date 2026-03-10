class Pembayaran {
  final int? id;
  final String? kodeInvoice;
  final int santriId;
  final int? adminId;
  final String? tglBayar;
  final int bulanSpp;
  final int tahunSpp;
  final num nominal;
  final String? metodeBayar;
  final String? keterangan;
  final String? santriNama;
  final String? adminNama;

  Pembayaran({
    this.id,
    this.kodeInvoice,
    required this.santriId,
    this.adminId,
    this.tglBayar,
    required this.bulanSpp,
    required this.tahunSpp,
    required this.nominal,
    this.metodeBayar,
    this.keterangan,
    this.santriNama,
    this.adminNama,
  });

  factory Pembayaran.fromJson(Map<String, dynamic> json) {
    return Pembayaran(
      id: json['id'],
      kodeInvoice: json['kode_invoice'],
      santriId: json['santri_id'] ?? 0,
      adminId: json['admin_id'],
      tglBayar: json['tgl_bayar'],
      bulanSpp: json['bulan_spp'] ?? 0,
      tahunSpp: json['tahun_spp'] ?? 0,
      nominal: json['nominal'] ?? 0,
      metodeBayar: json['metode_bayar'],
      keterangan: json['keterangan'],
      santriNama: json['santri']?['nama_lengkap'],
      adminNama: json['admin']?['nama_lengkap'],
    );
  }
}

class StatusPembayaran {
  final int id;
  final int? noAbsen;
  final String nik;
  final String namaLengkap;
  final String? jenisKelamin;
  final String? jilid;
  final bool statusAktif;
  final bool isSubsidi;
  final num nominalSpp;
  final int tahun;
  final Map<String, dynamic> bulanStatus;
  final num totalBayar;
  final int bulanDibayarTotal;
  final int bulanTerbayar;
  final int bulanWajib;
  final int bulanBelumBayar;
  final String? tglMendaftar;
  final String? tglNonaktif;
  final String? namaWali;
  final String? noTelpWali;

  StatusPembayaran({
    required this.id,
    this.noAbsen,
    required this.nik,
    required this.namaLengkap,
    this.jenisKelamin,
    this.jilid,
    required this.statusAktif,
    required this.isSubsidi,
    required this.nominalSpp,
    required this.tahun,
    required this.bulanStatus,
    required this.totalBayar,
    required this.bulanDibayarTotal,
    required this.bulanTerbayar,
    required this.bulanWajib,
    required this.bulanBelumBayar,
    this.tglMendaftar,
    this.tglNonaktif,
    this.namaWali,
    this.noTelpWali,
  });

  factory StatusPembayaran.fromJson(Map<String, dynamic> json) {
    return StatusPembayaran(
      id: json['id'] ?? 0,
      noAbsen: json['no_absen'],
      nik: json['nik'] ?? '',
      namaLengkap: json['nama_lengkap'] ?? '',
      jenisKelamin: json['jenis_kelamin'],
      jilid: json['jilid'],
      statusAktif: json['status_aktif'] ?? true,
      isSubsidi: json['is_subsidi'] ?? false,
      nominalSpp: json['nominal_spp'] ?? 0,
      tahun: json['tahun'] ?? DateTime.now().year,
      bulanStatus: Map<String, dynamic>.from(json['bulan_status'] ?? {}),
      totalBayar: json['total_bayar'] ?? 0,
      bulanDibayarTotal: json['bulan_dibayar_total'] ?? 0,
      bulanTerbayar: json['bulan_terbayar'] ?? 0,
      bulanWajib: json['bulan_wajib'] ?? 0,
      bulanBelumBayar: json['bulan_belum_bayar'] ?? 0,
      tglMendaftar: json['tgl_mendaftar'],
      tglNonaktif: json['tgl_nonaktif'],
      namaWali: json['nama_wali'],
      noTelpWali: json['no_telp_wali'],
    );
  }
}
