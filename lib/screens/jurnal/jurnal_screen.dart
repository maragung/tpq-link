import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class JurnalScreen extends StatefulWidget {
  const JurnalScreen({super.key});

  @override
  State<JurnalScreen> createState() => _JurnalScreenState();
}

class _JurnalScreenState extends State<JurnalScreen> {
  List<dynamic> _jurnalList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final result = await ApiService.get(ApiConfig.jurnalUrl);
    if (result['success'] == true) {
      _jurnalList = result['data'] ?? [];
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetch,
            child: _jurnalList.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book_outlined, size: 64, color: AppColors.textSecondary),
                        SizedBox(height: 16),
                        Text('Belum ada data jurnal',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _jurnalList.length,
                    itemBuilder: (context, index) {
                      final j = _jurnalList[index];
                      final isMasuk = j['jenis'] == 'Masuk';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isMasuk
                                ? AppColors.success.withAlpha(51)
                                : AppColors.danger.withAlpha(51),
                            child: Icon(
                              isMasuk ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isMasuk ? AppColors.success : AppColors.danger,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            j['keterangan'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${j['referensi_kode'] ?? ''} • ${formatDate(j['tgl_transaksi'])}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              Text(
                                'Saldo: ${formatCurrency(j['saldo_berjalan'] ?? 0)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          trailing: Text(
                            '${isMasuk ? '+' : '-'} ${formatCurrency(j['nominal'] ?? 0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isMasuk ? AppColors.success : AppColors.danger,
                              fontSize: 13,
                            ),
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                  ),
    );
  }
}
