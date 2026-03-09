import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class KeuanganScreen extends StatefulWidget {
  const KeuanganScreen({super.key});

  @override
  State<KeuanganScreen> createState() => _KeuanganScreenState();
}

class _KeuanganScreenState extends State<KeuanganScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchDana();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Keuangan')),
      body: SafeArea(top: false, child: dashboard.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => dashboard.fetchDana(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Saldo Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text('Saldo Kas',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            formatCurrency(
                                dashboard.danaData?['saldo_kas'] ?? 0),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: _KeuanganCard(
                            title: 'Pemasukan',
                            value: formatCurrency(
                                dashboard.danaData?['total_pemasukan'] ?? 0),
                            icon: Icons.trending_up,
                            color: AppColors.success,
                            onTap: () =>
                                Navigator.pushNamed(context, '/pembayaran'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KeuanganCard(
                            title: 'Pengeluaran',
                            value: formatCurrency(
                                dashboard.danaData?['total_pengeluaran'] ?? 0),
                            icon: Icons.trending_down,
                            color: AppColors.danger,
                            onTap: () =>
                                Navigator.pushNamed(context, '/pengeluaran'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _KeuanganCard(
                            title: 'Total Infak',
                            value: formatCurrency(
                                dashboard.danaData?['total_infak'] ?? 0),
                            icon: Icons.favorite,
                            color: Colors.pink,
                            onTap: () =>
                                Navigator.pushNamed(context, '/infak'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KeuanganCard(
                            title: 'Jurnal Kas',
                            value: 'Lihat Detail',
                            icon: Icons.book,
                            color: AppColors.info,
                            onTap: () =>
                                Navigator.pushNamed(context, '/jurnal'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quick links
                    const Text(
                      'Aksi Keuangan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ActionTile(
                      icon: Icons.payment,
                      title: 'Bayar SPP',
                      subtitle: 'Catat pembayaran SPP santri',
                      color: AppColors.secondary,
                      onTap: () =>
                          Navigator.pushNamed(context, '/bayar-spp'),
                    ),
                    _ActionTile(
                      icon: Icons.favorite,
                      title: 'Catat Infak/Sedekah',
                      subtitle: 'Tambah catatan infak masuk',
                      color: Colors.pink,
                      onTap: () =>
                          Navigator.pushNamed(context, '/infak'),
                    ),
                    _ActionTile(
                      icon: Icons.money_off,
                      title: 'Catat Pengeluaran',
                      subtitle: 'Tambah catatan pengeluaran',
                      color: AppColors.warning,
                      onTap: () =>
                          Navigator.pushNamed(context, '/pengeluaran'),
                    ),
                    _ActionTile(
                      icon: Icons.receipt_long,
                      title: 'Pembayaran Lain',
                      subtitle: 'Catat pembayaran non-SPP',
                      color: Colors.amber.shade700,
                      onTap: () =>
                          Navigator.pushNamed(context, '/pembayaran-lain'),
                    ),
                    _ActionTile(
                      icon: Icons.assessment,
                      title: 'Laporan / Export',
                      subtitle: 'Buat & export laporan keuangan',
                      color: Colors.blueGrey,
                      onTap: () =>
                          Navigator.pushNamed(context, '/laporan'),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}

class _KeuanganCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _KeuanganCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
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
                  fontSize: 15,
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
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
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
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }
}
