import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/santri_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/pin_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchDana();
      context.read<SantriProvider>().fetchSantriStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final santriProv = context.watch<SantriProvider>();

    return SafeArea(
      top: false,
      child: RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          dashboard.fetchDana(),
          santriProv.fetchSantriStatus(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(60),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assalamu\'alaikum,',
                            style: TextStyle(
                              color: Colors.white.withAlpha(204),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            auth.user?.namaLengkap ?? 'Admin',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(51),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              auth.user?.jabatan ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.mosque_rounded,
                      size: 48,
                      color: Colors.white24,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dana Summary
            if (dashboard.loading)
              const Center(child: CircularProgressIndicator())
            else if (dashboard.danaData != null) ...[
              const AppSectionHeader(
                title: 'Ringkasan Dana',
                subtitle: 'Pantau kondisi keuangan utama TPQ secara cepat.',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Saldo Kas',
                      value: formatCurrency(
                        dashboard.danaData!['saldo_kas'] ?? 0,
                      ),
                      icon: Icons.account_balance_wallet,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Pemasukan',
                      value: formatCurrency(
                        dashboard.danaData!['total_pemasukan'] ?? 0,
                      ),
                      icon: Icons.trending_up,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Pengeluaran',
                      value: formatCurrency(
                        dashboard.danaData!['total_pengeluaran'] ?? 0,
                      ),
                      icon: Icons.trending_down,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Total Infak',
                      value: formatCurrency(
                        dashboard.danaData!['total_infak'] ?? 0,
                      ),
                      icon: Icons.favorite,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const AppSectionHeader(
                title: 'Statistik Keuangan',
                subtitle: 'Perbandingan pemasukan dan pengeluaran tahun ini.',
              ),
              const SizedBox(height: 12),
              _DashboardChart(
                pemasukan: (dashboard.danaData!['total_pemasukan'] ?? 0).toDouble(),
                pengeluaran: (dashboard.danaData!['total_pengeluaran'] ?? 0).toDouble(),
              ),
            ],
            const SizedBox(height: 24),

            // Santri Summary
            const AppSectionHeader(
              title: 'Status Santri',
              subtitle: 'Lihat total santri, status aktif, dan progres pembayaran.',
            ),
            const SizedBox(height: 12),
            if (santriProv.loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Santri',
                      value: '${santriProv.santriList.length}',
                      icon: Icons.people,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Santri Aktif',
                      value:
                          '${santriProv.santriList.where((s) => s.statusAktif).length}',
                      icon: Icons.check_circle,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Lunas',
                      value:
                          '${santriProv.santriList.where((s) => s.statusAktif && s.bulanBelumBayar == 0).length}',
                      icon: Icons.verified,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Belum Lunas',
                      value:
                          '${santriProv.santriList.where((s) => s.statusAktif && s.bulanBelumBayar > 0).length}',
                      icon: Icons.warning_amber,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),

            // Quick Actions
            const AppSectionHeader(
              title: 'Aksi Cepat',
              subtitle: 'Akses menu penting hanya dengan satu ketukan.',
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
              children: [
                _QuickAction(
                  icon: Icons.payment,
                  label: 'Bayar\nSPP',
                  color: AppColors.secondary,
                  onTap: () => Navigator.pushNamed(context, '/bayar-spp'),
                ),
                _QuickAction(
                  icon: Icons.person_add,
                  label: 'Daftar\nSantri',
                  color: AppColors.primary,
                  onTap: () => Navigator.pushNamed(context, '/santri/tambah'),
                ),
                _QuickAction(
                  icon: Icons.people,
                  label: 'Data\nSantri',
                  color: AppColors.info,
                  onTap: () => Navigator.pushNamed(context, '/santri'),
                ),
                _QuickAction(
                  icon: Icons.edit_note,
                  label: 'Edit\nSantri',
                  color: const Color(0xFF0D9488),
                  onTap: () => Navigator.pushNamed(context, '/santri'),
                ),
                _QuickAction(
                  icon: Icons.person_off,
                  label: 'Non-\naktifkan',
                  color: AppColors.danger,
                  onTap: () => _showSantriActionDialog(context, 'nonaktifkan'),
                ),
                _QuickAction(
                  icon: Icons.school,
                  label: 'Luluskan\nSantri',
                  color: const Color(0xFF4F46E5),
                  onTap: () => _showSantriActionDialog(context, 'luluskan'),
                ),
                _QuickAction(
                  icon: Icons.history_edu,
                  label: 'Alumni/\nLulus',
                  color: const Color(0xFF7C3AED),
                  onTap: () => Navigator.pushNamed(context, '/alumni'),
                ),
                _QuickAction(
                  icon: Icons.favorite,
                  label: 'Infak/\nSedekah',
                  color: const Color(0xFFEC4899),
                  onTap: () => Navigator.pushNamed(context, '/infak'),
                ),
                _QuickAction(
                  icon: Icons.receipt_long,
                  label: 'Bayar\nLainnya',
                  color: const Color(0xFFD97706),
                  onTap: () => Navigator.pushNamed(context, '/pembayaran-lain'),
                ),
                _QuickAction(
                  icon: Icons.money_off,
                  label: 'Penge-\nluaran',
                  color: AppColors.warning,
                  onTap: () => Navigator.pushNamed(context, '/pengeluaran'),
                ),
                _QuickAction(
                  icon: Icons.book,
                  label: 'Jurnal\nKas',
                  color: AppColors.info,
                  onTap: () => Navigator.pushNamed(context, '/jurnal'),
                ),
                _QuickAction(
                  icon: Icons.account_balance,
                  label: 'Keuangan',
                  color: AppColors.success,
                  onTap: () => Navigator.pushNamed(context, '/keuangan'),
                ),
                _QuickAction(
                  icon: Icons.assessment,
                  label: 'Laporan/\nExport',
                  color: const Color(0xFF64748B),
                  onTap: () => Navigator.pushNamed(context, '/laporan'),
                ),
                _QuickAction(
                  icon: Icons.mail,
                  label: 'Kotak\nSaran',
                  color: Colors.purple,
                  onTap: () => Navigator.pushNamed(context, '/saran'),
                ),
                _QuickAction(
                  icon: Icons.notifications,
                  label: 'Noti-\nfikasi',
                  color: const Color(0xFFEA580C),
                  onTap: () => Navigator.pushNamed(context, '/notifikasi'),
                ),
                _QuickAction(
                  icon: Icons.settings,
                  label: 'Peng-\naturan',
                  color: const Color(0xFF6B7280),
                  onTap: () => Navigator.pushNamed(context, '/pengaturan'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }

  void _showSantriActionDialog(BuildContext context, String action) {
    final santriProv = context.read<SantriProvider>();
    final santriAktif =
        santriProv.santriList.where((s) => s.statusAktif).toList();

    final isLuluskan = action == 'luluskan';
    final title = isLuluskan ? 'Luluskan Santri' : 'Nonaktifkan Santri';
    final actionLabel = isLuluskan ? 'Luluskan' : 'Nonaktifkan';
    final actionColor = isLuluskan ? const Color(0xFF4F46E5) : AppColors.danger;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pilih santri yang akan di-${actionLabel.toLowerCase()}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: santriAktif.isEmpty
                  ? const Center(
                      child: Text('Tidak ada santri aktif',
                          style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: santriAktif.length,
                      itemBuilder: (context, index) {
                        final s = santriAktif[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: actionColor.withAlpha(51),
                            child: Text(
                              s.namaLengkap.isNotEmpty
                                  ? s.namaLengkap[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: actionColor,
                              ),
                            ),
                          ),
                          title: Text(s.namaLengkap),
                          subtitle: Text(
                            '${s.jilid ?? "-"} • NIK: ${s.nik}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Icon(
                            isLuluskan ? Icons.school : Icons.person_off,
                            color: actionColor,
                            size: 20,
                          ),
                          onTap: () => _confirmSantriAction(
                              context, s, action, actionLabel, actionColor),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSantriAction(BuildContext context, dynamic santri,
      String action, String actionLabel, Color actionColor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$actionLabel Santri'),
        content: Text(
          'Yakin ingin ${actionLabel.toLowerCase()} ${santri.namaLengkap}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: actionColor),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final pin = await showPinDialog(context);
    if (pin == null || !context.mounted) return;

    final santriProvider = Provider.of<SantriProvider>(
      context,
      listen: false,
    );
    final result = action == 'luluskan'
        ? await santriProvider.luluskanSantri(santri.id, pin)
        : await santriProvider.nonaktifkanSantri(santri.id, pin);

    if (!context.mounted) return;
    Navigator.pop(context); // Close bottom sheet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['pesan'] ?? 'Berhasil'),
        backgroundColor:
            result['success'] == true ? AppColors.success : AppColors.danger,
      ),
    );
  }
}

class _DashboardChart extends StatelessWidget {
  final double pemasukan;
  final double pengeluaran;

  const _DashboardChart({required this.pemasukan, required this.pengeluaran});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AspectRatio(
      aspectRatio: 1.7,
      child: Card(
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (pemasukan > pengeluaran ? pemasukan : pengeluaran) * 1.2,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const Text('Masuk', style: TextStyle(fontSize: 10));
                    if (value == 1) return const Text('Keluar', style: TextStyle(fontSize: 10));
                    return const SizedBox();
                  },
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: [
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(
                    toY: pemasukan,
                    color: AppColors.success,
                    width: 40,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 1,
                barRods: [
                  BarChartRodData(
                    toY: pengeluaran,
                    color: AppColors.danger,
                    width: 40,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(51)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
