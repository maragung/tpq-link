import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/background_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/pin_dialog.dart';
import '../../widgets/skeleton_loader.dart';

class InfakScreen extends StatefulWidget {
  const InfakScreen({super.key});

  @override
  State<InfakScreen> createState() => _InfakScreenState();
}

class _InfakScreenState extends State<InfakScreen> {
  List<dynamic> _infakList = [];
  num _totalInfak = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchInfak();
  }

  Future<void> _fetchInfak() async {
    setState(() => _loading = true);
    final result = await ApiService.get(ApiConfig.infakUrl);
    if (result['success'] == true) {
      _infakList = result['data'] ?? [];
      _totalInfak = result['total_infak'] ?? 0;
    }
    setState(() => _loading = false);
  }

  Future<void> _showAddDialog() async {
    final namaDonaturController = TextEditingController();
    final nominalController = TextEditingController();
    final catatanController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Infak/Sedekah'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaDonaturController,
                decoration: const InputDecoration(
                  labelText: 'Nama Donatur',
                  prefixIcon: Icon(Icons.person),
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
              TextField(
                controller: catatanController,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
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
              if (namaDonaturController.text.trim().isEmpty ||
                  nominalController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context, {
                'nama_donatur': namaDonaturController.text.trim(),
                'nominal': int.tryParse(nominalController.text.trim()) ?? 0,
                'catatan': catatanController.text.trim(),
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
        'POST', ApiConfig.infakUrl, body: result,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['pesan'] ?? 'Berhasil'),
            backgroundColor:
                response['success'] == true ? AppColors.success : AppColors.danger,
          ),
        );
        if (response['success'] == true) _fetchInfak();
      }
    }
  }

  Future<void> _deleteInfak(dynamic infak) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Infak'),
        content: Text(
          'Yakin ingin menghapus infak dari ${infak['nama_donatur']}?\n'
          'Nominal: ${formatCurrency(infak['nominal'] ?? 0)}',
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
      'DELETE', ApiConfig.infakDetailUrl(infak['id']),
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
      if (response['success'] == true) _fetchInfak();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage =
        Provider.of<AuthProvider>(context).user?.isFullAccess ?? false;
    return Scaffold(
      body: SafeArea(top: false, child: _loading
          ? const Column(
              children: [
                SkeletonSummaryCard(),
                Expanded(child: SkeletonList(count: 5)),
              ],
            )
          : RefreshIndicator(
              onRefresh: _fetchInfak,
              child: Column(
                children: [
                  // Total card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('Total Infak/Sedekah',
                            style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          formatCurrency(_totalInfak),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // List
                  Expanded(
                    child: _infakList.isEmpty
                        ? const Center(
                            child: Text('Belum ada data infak',
                                style: TextStyle(color: AppColors.textSecondary)))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                            itemCount: _infakList.length,
                            itemBuilder: (context, index) {
                              final infak = _infakList[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  onLongPress: canManage
                                      ? () => _deleteInfak(infak)
                                      : null,
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.pink.withAlpha(51),
                                    child: const Icon(Icons.favorite,
                                        color: Colors.pink, size: 20),
                                  ),
                                  title: Text(
                                    infak['nama_donatur'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    '${infak['kode_transaksi'] ?? ''} • ${formatDate(infak['tgl_terima'])}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: Text(
                                    formatCurrency(infak['nominal'] ?? 0),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.pink,
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
              backgroundColor: Colors.pink,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
