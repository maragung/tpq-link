import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/santri_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

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

    return RefreshIndicator(
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
            Card(
              color: AppColors.primary,
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
              const Text(
                'Ringkasan Dana',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
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
            ],
            const SizedBox(height: 24),

            // Santri Summary
            const Text(
              'Status Santri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
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
            const Text(
              'Aksi Cepat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _QuickAction(
                  icon: Icons.person_add,
                  label: 'Tambah\nSantri',
                  color: AppColors.primary,
                  onTap: () => Navigator.pushNamed(context, '/santri/tambah'),
                ),
                _QuickAction(
                  icon: Icons.payment,
                  label: 'Bayar\nSPP',
                  color: AppColors.secondary,
                  onTap: () => Navigator.pushNamed(context, '/bayar-spp'),
                ),
                _QuickAction(
                  icon: Icons.favorite,
                  label: 'Catat\nInfak',
                  color: AppColors.danger,
                  onTap: () => Navigator.pushNamed(context, '/infak'),
                ),
                _QuickAction(
                  icon: Icons.money_off,
                  label: 'Catat\nPengeluaran',
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
                  icon: Icons.mail,
                  label: 'Kotak\nSaran',
                  color: Colors.purple,
                  onTap: () => Navigator.pushNamed(context, '/saran'),
                ),
              ],
            ),
          ],
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(51)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
