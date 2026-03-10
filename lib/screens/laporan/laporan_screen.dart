import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/santri_provider.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  int _selectedYear = DateTime.now().year;
  String? _generatedReport;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final isPengajar = context.watch<AuthProvider>().user?.isPengajar ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan / Export')),
      body: SafeArea(top: false, child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Year selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    const Text('Tahun Laporan:',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: _selectedYear,
                      items: List.generate(5, (i) {
                        final year = DateTime.now().year - i;
                        return DropdownMenuItem(
                            value: year, child: Text('$year'));
                      }),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedYear = v);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Pilih Jenis Laporan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            if (isPengajar)
              Card(
                color: AppColors.secondary.withAlpha(14),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Mode Pengajar: halaman ini hanya menampilkan data Buku Prestasi Santri.',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ),
            if (isPengajar) const SizedBox(height: 12),

            _ReportTile(
              icon: Icons.menu_book,
              title: 'Buku Prestasi Santri',
              subtitle: 'Rekap Surat Pendek, Doa Harian, dan Halaman Buku Prestasi Jilid',
              color: AppColors.success,
              onTap: _generatePrestasiReport,
            ),
            if (!isPengajar) ...[
              _ReportTile(
                icon: Icons.people,
                title: 'Laporan Data Santri',
                subtitle: 'Daftar lengkap santri aktif & nonaktif',
                color: AppColors.primary,
                onTap: _generateSantriReport,
              ),
              _ReportTile(
                icon: Icons.payment,
                title: 'Laporan Pembayaran SPP',
                subtitle: 'Rekap pembayaran SPP per tahun',
                color: AppColors.secondary,
                onTap: _generatePembayaranReport,
              ),
              _ReportTile(
                icon: Icons.favorite,
                title: 'Laporan Infak/Sedekah',
                subtitle: 'Rekap penerimaan infak',
                color: Colors.pink,
                onTap: _generateInfakReport,
              ),
              _ReportTile(
                icon: Icons.money_off,
                title: 'Laporan Pengeluaran',
                subtitle: 'Rekap pengeluaran TPQ',
                color: AppColors.warning,
                onTap: _generatePengeluaranReport,
              ),
              _ReportTile(
                icon: Icons.account_balance_wallet,
                title: 'Laporan Keuangan',
                subtitle: 'Ringkasan kas masuk & keluar',
                color: AppColors.success,
                onTap: _generateKeuanganReport,
              ),
            ],

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),

            if (_generatedReport != null) ...[
              const SizedBox(height: 20),
              Card(
                color: AppColors.primary.withAlpha(13),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.description,
                              color: AppColors.primary),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('Hasil Laporan',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: _copyReport,
                            tooltip: 'Salin',
                          ),
                        ],
                      ),
                      const Divider(),
                      SelectableText(
                        _generatedReport!,
                        style: const TextStyle(
                            fontSize: 12, fontFamily: 'monospace', height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _generatePrestasiReport() async {
    setState(() {
      _loading = true;
      _generatedReport = null;
    });

    final result = await ApiService.get(
      ApiConfig.exportUrl,
      queryParams: {
        'tipe': 'prestasi_santri',
        'tahun': _selectedYear.toString(),
      },
    );

    final list = (result['data'] ?? []) as List;
    if (result['success'] != true) {
      setState(() {
        _loading = false;
        _generatedReport = result['pesan'] ?? 'Gagal memuat Buku Prestasi Santri';
      });
      return;
    }

    final buf = StringBuffer();
    buf.writeln('BUKU PRESTASI SANTRI - TAHUN $_selectedYear');
    buf.writeln("TPQ Futuhil Hidayah wan Ni'mah");
    buf.writeln('=' * 50);
    buf.writeln('Jumlah Catatan : ${list.length}');
    buf.writeln('');

    for (var i = 0; i < list.length; i++) {
      final item = Map<String, dynamic>.from(list[i] as Map);
      buf.writeln('${i + 1}. ${item['nama_santri'] ?? '-'}');
      buf.writeln('   No. Absen : ${item['no_absen'] ?? '-'}');
      buf.writeln('   Tanggal   : ${formatDate(item['tanggal']?.toString())}');
      buf.writeln('   Jilid     : ${item['jilid'] ?? '-'}');
      buf.writeln('   Surat/Doa : ${item['surat_doa'] ?? '-'}');
      buf.writeln('   Halaman   : ${item['halaman'] ?? '-'}');
      buf.writeln('   Ust       : ${item['ust'] ?? '-'}');
      buf.writeln('   Paraf     : ${item['paraf'] ?? '-'}');
      buf.writeln('   Ket.      : ${item['keterangan'] ?? '-'}');
      buf.writeln('');
    }

    setState(() {
      _loading = false;
      _generatedReport = buf.toString();
    });
  }

  Future<void> _generateSantriReport() async {
    setState(() {
      _loading = true;
      _generatedReport = null;
    });

    final santriProv = context.read<SantriProvider>();
    await santriProv.fetchSantriStatus();

    final aktif =
        santriProv.santriList.where((s) => s.statusAktif).toList();
    final nonaktif =
        santriProv.santriList.where((s) => !s.statusAktif).toList();

    final buf = StringBuffer();
    buf.writeln('LAPORAN DATA SANTRI - TAHUN $_selectedYear');
    buf.writeln("TPQ Futuhil Hidayah wan Ni'mah");
    buf.writeln('=' * 40);
    buf.writeln('Total Santri : ${santriProv.santriList.length}');
    buf.writeln('Aktif        : ${aktif.length}');
    buf.writeln('Nonaktif     : ${nonaktif.length}');
    buf.writeln('');
    buf.writeln('--- SANTRI AKTIF ---');
    for (var i = 0; i < aktif.length; i++) {
      buf.writeln(
          '${i + 1}. ${aktif[i].namaLengkap} (${aktif[i].jilid ?? "-"})');
    }
    if (nonaktif.isNotEmpty) {
      buf.writeln('');
      buf.writeln('--- ALUMNI / NONAKTIF ---');
      for (var i = 0; i < nonaktif.length; i++) {
        buf.writeln(
            '${i + 1}. ${nonaktif[i].namaLengkap} (${nonaktif[i].jilid ?? "-"})');
      }
    }

    setState(() {
      _loading = false;
      _generatedReport = buf.toString();
    });
  }

  Future<void> _generatePembayaranReport() async {
    setState(() {
      _loading = true;
      _generatedReport = null;
    });

    final santriProv = context.read<SantriProvider>();
    if (santriProv.selectedYear != _selectedYear) {
      santriProv.selectedYear = _selectedYear;
    }
    await santriProv.fetchSantriStatus();

    final aktif =
        santriProv.santriList.where((s) => s.statusAktif).toList();
    final lunas =
        aktif.where((s) => s.bulanBelumBayar == 0).toList();
    final belum =
        aktif.where((s) => s.bulanBelumBayar > 0).toList();

    num totalTerbayar = 0;
    for (var s in aktif) {
      totalTerbayar += s.totalBayar;
    }

    final buf = StringBuffer();
    buf.writeln('LAPORAN PEMBAYARAN SPP - TAHUN $_selectedYear');
    buf.writeln("TPQ Futuhil Hidayah wan Ni'mah");
    buf.writeln('=' * 40);
    buf.writeln('Total Santri Aktif : ${aktif.length}');
    buf.writeln('Lunas              : ${lunas.length}');
    buf.writeln('Belum Lunas        : ${belum.length}');
    buf.writeln('Total Terbayar     : ${formatCurrency(totalTerbayar)}');
    buf.writeln('');
    if (belum.isNotEmpty) {
      buf.writeln('--- BELUM LUNAS ---');
      for (var i = 0; i < belum.length; i++) {
        buf.writeln(
            '${i + 1}. ${belum[i].namaLengkap} - sisa ${belum[i].bulanBelumBayar} bulan');
      }
    }
    if (lunas.isNotEmpty) {
      buf.writeln('');
      buf.writeln('--- LUNAS ---');
      for (var i = 0; i < lunas.length; i++) {
        buf.writeln('${i + 1}. ${lunas[i].namaLengkap}');
      }
    }

    setState(() {
      _loading = false;
      _generatedReport = buf.toString();
    });
  }

  Future<void> _generateInfakReport() async {
    setState(() {
      _loading = true;
      _generatedReport = null;
    });

    final result = await ApiService.get(ApiConfig.infakUrl);
    final infakList = (result['data'] ?? []) as List;
    num totalInfak = result['total_infak'] ?? 0;

    final buf = StringBuffer();
    buf.writeln('LAPORAN INFAK/SEDEKAH');
    buf.writeln("TPQ Futuhil Hidayah wan Ni'mah");
    buf.writeln('=' * 40);
    buf.writeln('Total Infak         : ${formatCurrency(totalInfak)}');
    buf.writeln('Jumlah Transaksi    : ${infakList.length}');
    buf.writeln('');
    for (var i = 0; i < infakList.length; i++) {
      final inf = infakList[i];
      buf.writeln(
          '${i + 1}. ${inf['nama_donatur']} - ${formatCurrency(inf['nominal'] ?? 0)} (${formatDate(inf['tgl_terima'])})');
    }

    setState(() {
      _loading = false;
      _generatedReport = buf.toString();
    });
  }

  Future<void> _generatePengeluaranReport() async {
    setState(() {
      _loading = true;
      _generatedReport = null;
    });

    final result = await ApiService.get(ApiConfig.pengeluaranUrl);
    final list = (result['data'] ?? []) as List;
    num total = 0;
    for (var item in list) {
      total += (item['nominal'] ?? 0) as num;
    }

    final buf = StringBuffer();
    buf.writeln('LAPORAN PENGELUARAN');
    buf.writeln("TPQ Futuhil Hidayah wan Ni'mah");
    buf.writeln('=' * 40);
    buf.writeln('Total Pengeluaran   : ${formatCurrency(total)}');
    buf.writeln('Jumlah Transaksi    : ${list.length}');
    buf.writeln('');
    for (var i = 0; i < list.length; i++) {
      final p = list[i];
      buf.writeln(
          '${i + 1}. ${p['keterangan'] ?? '-'} - ${formatCurrency(p['nominal'] ?? 0)} (${formatDate(p['tgl_pengeluaran'])})');
    }

    setState(() {
      _loading = false;
      _generatedReport = buf.toString();
    });
  }

  Future<void> _generateKeuanganReport() async {
    setState(() {
      _loading = true;
      _generatedReport = null;
    });

    final dashboard = context.read<DashboardProvider>();
    await dashboard.fetchDana();

    final buf = StringBuffer();
    buf.writeln('LAPORAN KEUANGAN');
    buf.writeln("TPQ Futuhil Hidayah wan Ni'mah");
    buf.writeln('=' * 40);
    buf.writeln(
        'Saldo Kas        : ${formatCurrency(dashboard.danaData?['saldo_kas'] ?? 0)}');
    buf.writeln(
        'Total Pemasukan  : ${formatCurrency(dashboard.danaData?['total_pemasukan'] ?? 0)}');
    buf.writeln(
        'Total Pengeluaran: ${formatCurrency(dashboard.danaData?['total_pengeluaran'] ?? 0)}');
    buf.writeln(
        'Total Infak      : ${formatCurrency(dashboard.danaData?['total_infak'] ?? 0)}');

    setState(() {
      _loading = false;
      _generatedReport = buf.toString();
    });
  }

  void _copyReport() {
    if (_generatedReport == null) return;
    Clipboard.setData(ClipboardData(text: _generatedReport!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan disalin ke clipboard'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

class _ReportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ReportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(26),
          child: Icon(icon, color: color, size: 22),
        ),
        title:
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.download, color: AppColors.textSecondary, size: 20),
        onTap: onTap,
      ),
    );
  }
}
