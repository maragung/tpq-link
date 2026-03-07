import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/pin_dialog.dart';

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
      final response = await ApiService.post(ApiConfig.pengeluaranUrl, body: result);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengeluaran')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetch,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('Total Pengeluaran',
                            style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          formatCurrency(_totalPengeluaran),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _pengeluaranList.isEmpty
                        ? const Center(
                            child: Text('Belum ada data pengeluaran',
                                style: TextStyle(color: AppColors.textSecondary)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _pengeluaranList.length,
                            itemBuilder: (context, index) {
                              final p = _pengeluaranList[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.danger,
        child: const Icon(Icons.add),
      ),
    );
  }
}
