import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  List<dynamic> _notifikasiList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final result = await ApiService.get(ApiConfig.notifikasiUrl);
    if (result['success'] == true) {
      _notifikasiList = result['data'] ?? [];
    }
    setState(() => _loading = false);
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'pembayaran':
        return Icons.payment;
      case 'santri':
        return Icons.person;
      case 'infak':
        return Icons.favorite;
      case 'pengeluaran':
        return Icons.money_off;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetch,
              child: _notifikasiList.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 64,
                              color: AppColors.textSecondary),
                          SizedBox(height: 16),
                          Text('Belum ada notifikasi',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifikasiList.length,
                      itemBuilder: (context, index) {
                        final n = _notifikasiList[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withAlpha(51),
                              child: Icon(
                                _iconForType(n['tipe']),
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              n['judul'] ?? n['pesan'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            subtitle: Text(
                              formatDateTime(n['created_at']),
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
