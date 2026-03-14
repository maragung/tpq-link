import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_ui.dart';

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
                ? const AppEmptyState(
                    icon: Icons.book_outlined,
                    title: 'Belum ada data jurnal',
                    subtitle: 'Riwayat transaksi kas masuk dan kas keluar akan muncul di sini.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _jurnalList.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'Tanggal yang ditampilkan adalah tanggal aksi transaksi.',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        );
                      }

                      final j = _jurnalList[index - 1];
                      final isMasuk = j['jenis'] == 'Masuk';
                      final isKoreksiSpp = j['is_koreksi_spp'] == true;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isKoreksiSpp
                                ? Colors.amber.withAlpha(51)
                                : isMasuk
                                ? AppColors.success.withAlpha(51)
                                : AppColors.danger.withAlpha(51),
                            child: Icon(
                              isKoreksiSpp
                                  ? Icons.autorenew
                                  : (isMasuk
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward),
                              color: isKoreksiSpp
                                  ? Colors.amber.shade700
                                  : (isMasuk
                                      ? AppColors.success
                                      : AppColors.danger),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            isKoreksiSpp
                                ? '${j['keterangan'] ?? ''} (Koreksi SPP)'
                                : (j['keterangan'] ?? ''),
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${j['referensi_kode'] ?? ''} • ${formatDate(j['tanggal_aksi'] ?? j['tgl_transaksi'])}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              Text(
                                'Saldo: ${formatCurrency(j['saldo_berjalan'] ?? 0)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          trailing: Text(
                            '${isKoreksiSpp ? '±' : (isMasuk ? '+' : '-')} ${formatCurrency(j['nominal'] ?? 0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isKoreksiSpp
                                  ? Colors.amber.shade700
                                  : (isMasuk ? AppColors.success : AppColors.danger),
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
