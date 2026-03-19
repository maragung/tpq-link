import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../widgets/pin_dialog.dart';

class AdminListScreen extends StatefulWidget {
  const AdminListScreen({super.key});

  @override
  State<AdminListScreen> createState() => _AdminListScreenState();
}

class _AdminListScreenState extends State<AdminListScreen> {
  List<dynamic> _admins = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final result = await ApiService.get('${ApiConfig.baseUrl}/admin/kelola');
    if (mounted) {
      setState(() {
        _loading = false;
        if (result['success'] == true) {
          _admins = result['data'] ?? [];
        }
      });
    }
  }

  Future<void> _delete(dynamic id, String nama) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Admin'),
        content: Text('Yakin ingin menghapus akun admin $nama?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
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

    setState(() => _loading = true);
    final result = await ApiService.delete(
      '${ApiConfig.baseUrl}/admin/kelola/$id',
      body: {'pin': pin},
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['pesan'] ?? 'Berhasil'),
          backgroundColor: result['success'] == true ? AppColors.success : AppColors.danger,
        ),
      );
      _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Admin'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetch,
              child: _admins.isEmpty
                  ? const Center(child: Text('Tidak ada data admin'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _admins.length,
                      itemBuilder: (context, index) {
                        final a = _admins[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withAlpha(50),
                              child: Text(a['nama_lengkap']?[0]?.toUpperCase() ?? 'A',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(a['nama_lengkap'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${a['username']} • ${a['jabatan']}'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'edit') {
                                  Navigator.pushNamed(context, '/admin-form', arguments: a).then((_) => _fetch());
                                } else if (val == 'delete') {
                                  _delete(a['id'], a['nama_lengkap'] ?? '');
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit')])),
                                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))])),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/admin-form').then((_) => _fetch()),
        child: const Icon(Icons.add),
      ),
    );
  }
}
