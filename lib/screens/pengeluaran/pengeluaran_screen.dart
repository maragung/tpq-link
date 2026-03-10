import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/background_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/pin_dialog.dart';
import '../../widgets/skeleton_loader.dart';

class PengeluaranScreen extends StatefulWidget {
  const PengeluaranScreen({super.key});

  @override
  State<PengeluaranScreen> createState() => _PengeluaranScreenState();
}

class _PengeluaranScreenState extends State<PengeluaranScreen> {
  List<dynamic> _pengeluaranList = [];
  num _totalPengeluaran = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final result = await ApiService.get(ApiConfig.pengeluaranUrl);
    if (result['success'] == true) {
      _pengeluaranList = result['data'] ?? [];
      _totalPengeluaran = result['total_pengeluaran'] ?? 0;
    }
    setState(() => _loading = false);
  }

  Future<void> _showAddDialog() async {
    final keteranganController = TextEditingController();
    final nominalController = TextEditingController();
    final kategoriController = TextEditingController(text: 'Operasional');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Pengeluaran'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keteranganController,
                decoration: const InputDecoration(
                  labelText: 'Keterangan',
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nominalController,
                decoration: const InputDecoration(
                  labelText: 'Nominal',
                  prefixIcon: Icon(Icons.money),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: kategoriController.text,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category),
                ),
                items: ['Operasional', 'Gaji', 'Kegiatan', 'Infrastruktur', 'Lainnya']
                    .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                    .toList(),
                onChanged: (v) => kategoriController.text = v ?? 'Operasional',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (keteranganController.text.trim().isEmpty ||
                  nominalController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context, {
                'keterangan': keteranganController.text.trim(),
                'nominal': int.tryParse(nominalController.text.trim()) ?? 0,
                'kategori': kategoriController.text.trim(),
              });
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      final pin = await showPinDialog(context);
      if (pin == null) return;

      result['pin'] = pin;
      final response = await BackgroundService.enqueueOrExecute(
        'POST', ApiConfig.pengeluaranUrl, body: result,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['pesan'] ?? 'Berhasil'),
            backgroundColor:
                response['success'] == true ? AppColors.success : AppColors.danger,
          ),
        );
        if (response['success'] == true) _fetch();
      }
    }
  }

  Future<void> _deletePengeluaran(dynamic item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Pengeluaran'),
        content: Text(
          'Yakin ingin menghapus pengeluaran "${item['keterangan']}"?\n'
          'Nominal: ${formatCurrency(item['nominal'] ?? 0)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final pin = await showPinDialog(context);
    if (pin == null || !mounted) return;

    final response = await BackgroundService.enqueueOrExecute(
      'DELETE', ApiConfig.pengeluaranDetailUrl(item['id']),
      body: {'pin': pin},
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['pesan'] ?? 'Berhasil'),
          backgroundColor:
              response['success'] == true ? AppColors.success : AppColors.danger,
        ),
      );
      if (response['success'] == true) _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage =
        Provider.of<AuthProvider>(context).user?.isFullAccess ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Pengeluaran')),
      body: SafeArea(top: false, child: _loading
          ? const Column(
              children: [
                SkeletonSummaryCard(),
                Expanded(child: SkeletonList(count: 5)),
              ],
            )
          : RefreshIndicator(
              onRefresh: _fetch,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    child: AppSummaryBanner(
                      title: 'Total Pengeluaran',
                      value: formatCurrency(_totalPengeluaran),
                      colors: const [Color(0xFFEF4444), Color(0xFFB91C1C)],
                      icon: Icons.money_off,
                      footnote: '${_pengeluaranList.length} transaksi tercatat',
                    ),
                  ),
                  Expanded(
                    child: _pengeluaranList.isEmpty
                        ? const AppEmptyState(
                            icon: Icons.money_off_csred_outlined,
                            title: 'Belum ada data pengeluaran',
                            subtitle: 'Semua transaksi pengeluaran kas akan muncul di sini.',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                            itemCount: _pengeluaranList.length,
                            itemBuilder: (context, index) {
                              final p = _pengeluaranList[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  onLongPress: canManage
                                      ? () => _deletePengeluaran(p)
                                      : null,
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.danger.withAlpha(51),
                                    child: const Icon(Icons.money_off,
                                        color: AppColors.danger, size: 20),
                                  ),
                                  title: Text(
                                    p['keterangan'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    '${p['kategori'] ?? ''} • ${formatDate(p['tgl_pengeluaran'])}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: Text(
                                    formatCurrency(p['nominal'] ?? 0),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
        ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: _showAddDialog,
              backgroundColor: AppColors.danger,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
