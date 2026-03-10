import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pembayaran_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/pin_dialog.dart';
import '../../widgets/skeleton_loader.dart';

class PembayaranScreen extends StatelessWidget {
  const PembayaranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PembayaranProvider>();
    final canManage =
        context.watch<AuthProvider>().user?.isFullAccess ?? false;

    return SafeArea(
      top: false,
      child: Column(
        children: [
        // Year selector
        Container(
          padding: const EdgeInsets.all(16),
          child: AppFilterCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
            children: [
              const Text('Tahun:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: prov.selectedYear,
                items: List.generate(5, (i) {
                  final year = DateTime.now().year - i;
                  return DropdownMenuItem(value: year, child: Text('$year'));
                }),
                onChanged: (v) {
                  if (v != null) prov.selectedYear = v;
                },
              ),
              const Spacer(),
              Text(
                '${prov.pembayaranList.length} transaksi',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
          ),
        ),
        ),

        // Payment list
        Expanded(
          child: prov.loading
              ? const SkeletonList(count: 6, showSubtitle2: true)
              : prov.pembayaranList.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.receipt_long,
                      title: 'Belum ada pembayaran',
                      subtitle: 'Semua transaksi pembayaran SPP yang tercatat akan tampil di halaman ini.',
                    )
                  : RefreshIndicator(
                      onRefresh: () => prov.fetchPembayaran(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: prov.pembayaranList.length,
                        itemBuilder: (context, index) {
                          final p = prov.pembayaranList[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.success.withAlpha(51),
                                child: const Icon(Icons.check, color: AppColors.success),
                              ),
                              title: Text(
                                p.santriNama ?? 'Santri #${p.santriId}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${namaBulan(p.bulanSpp)} ${p.tahunSpp}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Text(
                                    '${p.kodeInvoice ?? ''} • ${p.metodeBayar ?? 'Tunai'}',
                                    style: const TextStyle(
                                        fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatCurrency(p.nominal),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                  Text(
                                    formatDate(p.tglBayar),
                                    style: const TextStyle(
                                        fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                              onLongPress: canManage
                                  ? () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Hapus Pembayaran?'),
                                    content: Text(
                                        'Pembayaran ${p.kodeInvoice} akan dibatalkan.'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Batal')),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.danger),
                                        child: const Text('Hapus'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && context.mounted) {
                                  final pin = await showPinDialog(context);
                                  if (pin != null) {
                                    final result =
                                        await prov.deletePembayaran(p.id!, pin);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              result['pesan'] ?? 'Berhasil dihapus'),
                                          backgroundColor: result['success'] == true
                                              ? AppColors.success
                                              : AppColors.danger,
                                        ),
                                      );
                                    }
                                  }
                                }
                                  }
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    ),
    );
  }
}
