import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as import_auth;
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
                  FutureBuilder<String?>(
                    future: ApiService.getToken(),
                    builder: (context, snapshot) {
                      // We need user role, but PengaturanScreen doesn't watch AuthProvider.
                      // Let's use a dynamic approach or just check if the endpoint exists.
                      return Container(); // Placeholder or check via context
                    },
                  ),
                  // Using Provider directly is better
                  Builder(builder: (context) {
                    final isDev = Provider.of<import_auth.AuthProvider>(context, listen: false).user?.isDeveloper == true;
                    if (!isDev) return const SizedBox();
                    return _buildActionCard(
                      'Konfigurasi Email',
                      'Kelola server SMTP dan log pengiriman email',
                      Icons.email_outlined,
                      () => Navigator.pushNamed(context, '/email-config'),
                    );
                  }),
                  const SizedBox(height: 16),
                  Consumer<import_auth.ThemeProvider>(
                    builder: (context, theme, _) => Card(
                      child: SwitchListTile(
                        title: const Text('Mode Gelap', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Gunakan tema gelap untuk aplikasi'),
                        secondary: CircleAvatar(
                          backgroundColor: AppColors.primary.withAlpha(26),
                          child: Icon(theme.isDarkMode ? Icons.dark_mode : Icons.light_mode, color: AppColors.primary),
                        ),
                        value: theme.isDarkMode,
                        onChanged: (val) => theme.toggleTheme(),
                      ),
                    ),
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

  Widget _buildActionCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.secondary.withAlpha(26),
          child: Icon(icon, color: AppColors.secondary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
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
