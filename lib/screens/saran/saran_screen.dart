import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class SaranScreen extends StatefulWidget {
  const SaranScreen({super.key});

  @override
  State<SaranScreen> createState() => _SaranScreenState();
}

class _SaranScreenState extends State<SaranScreen> {
  List<dynamic> _saranList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final result = await ApiService.get(ApiConfig.saranUrl);
    if (result['success'] == true) {
      _saranList = result['data'] ?? [];
    }
    setState(() => _loading = false);
  }

  Future<void> _updateStatus(int id, String status) async {
    final result = await ApiService.put(
      ApiConfig.saranDetailUrl(id),
      body: {'status': status},
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

  Color _statusColor(String? status) {
    switch (status) {
      case 'Ditanggapi':
        return AppColors.success;
      case 'Dibaca':
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kotak Saran')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetch,
              child: _saranList.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mail_outline, size: 64,
                              color: AppColors.textSecondary),
                          SizedBox(height: 16),
                          Text('Belum ada saran masuk',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _saranList.length,
                      itemBuilder: (context, index) {
                        final s = _saranList[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s['nama_pengirim'] ?? 'Anonim',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            '${s['kategori'] ?? ''} • ${formatDate(s['created_at'])}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusColor(s['status'])
                                            .withAlpha(26),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        s['status'] ?? 'Belum Dibaca',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _statusColor(s['status']),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  s['isi_saran'] ?? '',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (s['status'] != 'Dibaca')
                                      TextButton.icon(
                                        onPressed: () =>
                                            _updateStatus(s['id'], 'Dibaca'),
                                        icon: const Icon(Icons.visibility,
                                            size: 16),
                                        label: const Text('Tandai Dibaca',
                                            style: TextStyle(fontSize: 12)),
                                      ),
                                    if (s['status'] != 'Ditanggapi')
                                      TextButton.icon(
                                        onPressed: () =>
                                            _updateStatus(s['id'], 'Ditanggapi'),
                                        icon: const Icon(Icons.check,
                                            size: 16),
                                        label: const Text('Ditanggapi',
                                            style: TextStyle(fontSize: 12)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
