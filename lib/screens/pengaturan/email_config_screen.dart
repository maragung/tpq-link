import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../widgets/pin_dialog.dart';

class EmailConfigScreen extends StatefulWidget {
  const EmailConfigScreen({super.key});

  @override
  State<EmailConfigScreen> createState() => _EmailConfigScreenState();
}

class _EmailConfigScreenState extends State<EmailConfigScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  Map<String, dynamic> _config = {};
  List<dynamic> _logs = [];

  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _fromController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final configRes = await ApiService.get(ApiConfig.emailServerUrl);
    final logsRes = await ApiService.get(ApiConfig.emailLogUrl);
    
    if (mounted) {
      setState(() {
        _loading = false;
        if (configRes['success'] == true) {
          _config = configRes['data'] ?? {};
          _hostController.text = _config['host'] ?? '';
          _portController.text = _config['port']?.toString() ?? '';
          _userController.text = _config['user'] ?? '';
          _fromController.text = _config['from_email'] ?? '';
        }
        if (logsRes['success'] == true) {
          _logs = logsRes['data'] ?? [];
        }
      });
    }
  }

  Future<void> _save() async {
    final pin = await showPinDialog(context);
    if (pin == null || !mounted) return;

    setState(() => _loading = true);
    final body = {
      'host': _hostController.text.trim(),
      'port': int.tryParse(_portController.text.trim()) ?? 587,
      'user': _userController.text.trim(),
      'from_email': _fromController.text.trim(),
      'pin': pin,
    };
    if (_passController.text.isNotEmpty) {
      body['pass'] = _passController.text;
    }

    final result = await ApiService.put(ApiConfig.emailServerUrl, body: body);
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['pesan'] ?? 'Berhasil update'),
          backgroundColor: result['success'] == true ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Server'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Konfigurasi', icon: Icon(Icons.settings)),
            Tab(text: 'Log Email', icon: Icon(Icons.history)),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildConfigTab(),
                _buildLogsTab(),
              ],
            ),
    );
  }

  Widget _buildConfigTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('SMTP Server Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _field(_hostController, 'SMTP Host', Icons.dns),
          const SizedBox(height: 12),
          _field(_portController, 'Port', Icons.numbers, type: TextInputType.number),
          const SizedBox(height: 12),
          _field(_userController, 'Username / Email', Icons.person),
          const SizedBox(height: 12),
          _field(_passController, 'Password', Icons.lock, obscure: true),
          const SizedBox(height: 12),
          _field(_fromController, 'From Email', Icons.alternate_email),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _save, child: const Text('Simpan Perubahan')),
          const SizedBox(height: 16),
          const Card(
            color: Color(0xFFEFF6FF),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Konfigurasi email digunakan untuk pengiriman notifikasi pembayaran dan laporan otomatis ke pimpinan.',
                style: TextStyle(fontSize: 12, color: Colors.blue),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsTab() {
    return RefreshIndicator(
      onRefresh: _fetch,
      child: _logs.isEmpty
          ? const Center(child: Text('Tidak ada riwayat email'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final l = _logs[index];
                final success = l['status'] == 'success' || l['status'] == 'sent';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(success ? Icons.check_circle : Icons.error, color: success ? Colors.green : Colors.red),
                    title: Text(l['to'] ?? '-'),
                    subtitle: Text('${l['subject']}\n${_formatDate(l['created_at'])}', style: const TextStyle(fontSize: 12)),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon, {bool obscure = false, TextInputType type = TextInputType.text}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      obscureText: obscure,
      keyboardType: type,
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '-';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute}';
    } catch (_) {
      return iso;
    }
  }
}
