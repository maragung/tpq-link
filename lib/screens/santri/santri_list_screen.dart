import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/santri_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/skeleton_loader.dart';

class SantriListScreen extends StatefulWidget {
  const SantriListScreen({super.key});

  @override
  State<SantriListScreen> createState() => _SantriListScreenState();
}

class _SantriListScreenState extends State<SantriListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterKategori = 'Semua';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final santriProv = context.watch<SantriProvider>();
    final santriList = _filterSantri(santriProv.santriList);

    return Column(
      children: [
        // Search & Filter Bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          color: Colors.white,
          child: Column(
            children: [
              // Year Selector
              Row(
                children: [
                  const Text('Tahun:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: santriProv.selectedYear,
                    items: List.generate(5, (i) {
                      final year = DateTime.now().year - i;
                      return DropdownMenuItem(value: year, child: Text('$year'));
                    }),
                    onChanged: (v) {
                      if (v != null) santriProv.selectedYear = v;
                    },
                  ),
                  const Spacer(),
                  Text(
                    '${santriList.length} santri',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              // Search
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari nama atau NIK...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 8),
              // Category filter chips
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final kat in ['Semua', 'Aktif', 'Nonaktif', 'Subsidi', 'Lunas', 'Belum Lunas'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(kat, style: const TextStyle(fontSize: 12)),
                          selected: _filterKategori == kat,
                          onSelected: (_) => setState(() => _filterKategori = kat),
                          selectedColor: AppColors.primary.withAlpha(51),
                          labelStyle: TextStyle(
                            color: _filterKategori == kat
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),

        // Santri List
        Expanded(
          child: santriProv.loading
              ? const SkeletonList(count: 7, showSubtitle2: false)
              : santriList.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary),
                          SizedBox(height: 16),
                          Text('Belum ada data santri', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => santriProv.fetchSantriStatus(),
                      child: ListView.builder(
                        itemCount: santriList.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final s = santriList[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: s.statusAktif
                                    ? AppColors.primary.withAlpha(51)
                                    : Colors.grey.withAlpha(51),
                                child: Text(
                                  s.namaLengkap.isNotEmpty
                                      ? s.namaLengkap[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: s.statusAktif
                                        ? AppColors.primary
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                              title: Text(s.namaLengkap,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                'NIK: ${s.nik} • ${s.jilid ?? "-"}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12),
                              ),
                              trailing: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: s.statusAktif
                                          ? AppColors.success.withAlpha(26)
                                          : AppColors.danger.withAlpha(26),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      s.statusAktif ? 'Aktif' : 'Nonaktif',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: s.statusAktif
                                            ? AppColors.success
                                            : AppColors.danger,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _showSantriDetail(context, s),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  List<dynamic> _filterSantri(List santriList) {
    var filtered = santriList.where((s) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!s.namaLengkap.toLowerCase().contains(q) &&
            !s.nik.toLowerCase().contains(q)) {
          return false;
        }
      }
      switch (_filterKategori) {
        case 'Aktif':
          return s.statusAktif;
        case 'Nonaktif':
          return !s.statusAktif;
        case 'Subsidi':
          return s.isSubsidi;
        case 'Lunas':
          return s.statusAktif && s.bulanBelumBayar == 0;
        case 'Belum Lunas':
          return s.statusAktif && s.bulanBelumBayar > 0;
        default:
          return true;
      }
    }).toList();
    return filtered;
  }

  void _showSantriDetail(BuildContext context, dynamic s) {
    final canManage =
        Provider.of<AuthProvider>(context, listen: false).user?.isFullAccess ??
            false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: s.statusAktif
                        ? AppColors.primary.withAlpha(51)
                        : Colors.grey.withAlpha(51),
                    child: Text(
                      s.namaLengkap.isNotEmpty ? s.namaLengkap[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: s.statusAktif ? AppColors.primary : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.namaLengkap,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text('NIK: ${s.nik}',
                            style: const TextStyle(color: AppColors.textSecondary)),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: s.statusAktif
                                    ? AppColors.success.withAlpha(26)
                                    : AppColors.danger.withAlpha(26),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                s.statusAktif ? 'Aktif' : 'Nonaktif',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: s.statusAktif
                                      ? AppColors.success
                                      : AppColors.danger,
                                ),
                              ),
                            ),
                            if (s.isSubsidi) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withAlpha(26),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Subsidi',
                                  style:
                                      TextStyle(fontSize: 11, color: AppColors.info),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Detail info
              _DetailRow('Jilid', s.jilid ?? '-'),
              if (s.noAbsen != null) _DetailRow('No. Absen', '${s.noAbsen}'),
              _DetailRow('Nominal SPP', formatCurrency(s.nominalSpp)),
              const Divider(height: 24),

              // Payment Status
              const Text('Status Pembayaran',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _buildPaymentGrid(s),
              const SizedBox(height: 16),

              // Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryChip('Terbayar', '${s.bulanTerbayar}', AppColors.success),
                  _SummaryChip('Belum', '${s.bulanBelumBayar}', AppColors.danger),
                  _SummaryChip('Total', formatCurrency(s.totalBayar), AppColors.primary),
                ],
              ),
              const SizedBox(height: 20),

              // Aif (canManage) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/santri/tambah',
                              arguments: s.id);
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ]it'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/bayar-spp',
                            arguments: {'santri_id': s.id, 'nama': s.namaLengkap});
                      },
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('Bayar SPP'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentGrid(dynamic s) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(12, (i) {
        final bulan = i + 1;
        final status = s.bulanStatus['$bulan'];
        final dibayar = status?['dibayar'] == true;
        final wajib = status?['wajib'] == true;

        Color bgColor;
        Color textColor;
        if (dibayar) {
          bgColor = AppColors.success.withAlpha(51);
          textColor = AppColors.success;
        } else if (!wajib) {
          bgColor = Colors.grey.withAlpha(26);
          textColor = Colors.grey;
        } else {
          bgColor = AppColors.danger.withAlpha(51);
          textColor = AppColors.danger;
        }

        return Container(
          width: (MediaQuery.of(context).size.width - 80) / 6,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                namaBulan(bulan).substring(0, 3),
                style: TextStyle(fontSize: 10, color: textColor),
              ),
              Icon(
                dibayar
                    ? Icons.check_circle
                    : wajib
                        ? Icons.cancel
                        : Icons.remove_circle_outline,
                size: 18,
                color: textColor,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
