import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

class PengaturanScreen extends StatefulWidget {
  const PengaturanScreen({super.key});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  Map<String, dynamic> _pengaturan = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final result = await ApiService.get(ApiConfig.pengaturanUrl);
    if (result['success'] == true) {
      _pengaturan = {};
      final data = result['data'];
      if (data is List) {
        for (var item in data) {
          _pengaturan[item['key'] ?? item['kunci'] ?? ''] = item['value'] ?? item['nilai'] ?? '';
        }
      } else if (data is Map) {
        _pengaturan = Map<String, dynamic>.from(data);
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _updatePengaturan(String key, String value) async {
    final result = await ApiService.put(
      ApiConfig.pengaturanUrl,
      body: {'key': key, 'value': value},
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['pesan'] ?? 'Berhasil'),
          backgroundColor:
              result['success'] == true ? AppColors.success : AppColors.danger,
        ),
      );
      if (result['success'] == true) _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetch,
                child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSettingCard(
                    'SPP Non Subsidi',
                    _pengaturan['nominal_spp_non_subsidi']?.toString() ?? '40000',
                    Icons.money,
                    'nominal_spp_non_subsidi',
                  ),
                  _buildSettingCard(
                    'SPP Subsidi',
                    _pengaturan['nominal_spp_subsidi']?.toString() ?? '30000',
                    Icons.discount,
                    'nominal_spp_subsidi',
                  ),
                  const SizedBox(height: 16),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tentang Aplikasi',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Aplikasi Manajemen TPQ Futuhil Hidayah Wal Hikmah\n'
                            'Versi 1.0.0\n\n'
                            'Untuk pengelolaan data santri, pembayaran SPP, '
                            'infak/sedekah, dan laporan keuangan.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ),
    );
  }

  Widget _buildSettingCard(
      String title, String value, IconData icon, String key) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withAlpha(51),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('Rp $value'),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: AppColors.primary),
          onPressed: () => _showEditDialog(title, value, key),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(String title, String currentValue, String key) async {
    final controller = TextEditingController(text: currentValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Nominal',
            prefixText: 'Rp ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      _updatePengaturan(key, result);
    }
  }
}
