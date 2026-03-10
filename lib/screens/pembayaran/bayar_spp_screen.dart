import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/santri_provider.dart';
import '../../providers/pembayaran_provider.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/pin_dialog.dart';

class BayarSPPScreen extends StatefulWidget {
  final bool embedded;
  const BayarSPPScreen({super.key, this.embedded = false});

  @override
  State<BayarSPPScreen> createState() => _BayarSPPScreenState();
}

class _BayarSPPScreenState extends State<BayarSPPScreen> {
  int? _selectedSantriId;
  String? _selectedSantriNama;
  int _tahun = DateTime.now().year;
  final Set<int> _selectedBulan = {};
  String _metodeBayar = 'Tunai';
  final _keteranganController = TextEditingController();
  bool _isLoading = false;
  /// Map bulan -> payment record {id, kode_invoice, nominal, tgl_bayar, metode_bayar}
  Map<int, Map<String, dynamic>> _paidPayments = {};
  bool _fetchingPayments = false;
  bool _didInitPayments = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final prevId = _selectedSantriId;
      _selectedSantriId ??= args['santri_id'];
      _selectedSantriNama ??= args['nama'];
      if (_selectedSantriId != null && !_didInitPayments && prevId != _selectedSantriId) {
        _didInitPayments = true;
        _fetchPaidPayments(_selectedSantriId!);
      }
    }
  }

  /// Fetch payment records (with IDs) for cancel support
  Future<void> _fetchPaidPayments(int santriId) async {
    setState(() => _fetchingPayments = true);
    final result = await ApiService.get(
      ApiConfig.pembayaranUrl,
      queryParams: {
        'santri_id': santriId.toString(),
        'tahun': _tahun.toString(),
        'limit': '12',
      },
    );
    if (!mounted) return;
    if (result['success'] == true) {
      final data = result['data'] as List? ?? [];
      final map = <int, Map<String, dynamic>>{};
      for (final p in data) {
        final bulan = p['bulan_spp'];
        if (bulan != null) {
          map[bulan is int ? bulan : int.tryParse('$bulan') ?? 0] =
              Map<String, dynamic>.from(p as Map);
        }
      }
      setState(() {
        _paidPayments = map;
        _fetchingPayments = false;
      });
    } else {
      setState(() => _fetchingPayments = false);
    }
  }

  Future<void> _showCancelPaymentDialog(int bulan) async {
    final payment = _paidPayments[bulan];
    if (payment == null) return;

    final id = payment['id'] as int?;
    if (id == null) return;

    final nominalP = payment['nominal'] ?? 0;
    final kode = payment['kode_invoice'] ?? '-';
    final tglBayar = payment['tgl_bayar'] != null
        ? _formatDate('${payment['tgl_bayar']}')
        : '-';
    final metode = payment['metode_bayar'] ?? 'Tunai';

    final action = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('💳 Pembayaran ${namaBulan(bulan)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _payDetailRow('Kode Invoice', kode),
            _payDetailRow('Tanggal Bayar', tglBayar),
            _payDetailRow('Nominal', formatCurrency(nominalP)),
            _payDetailRow('Metode', metode),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Batalkan Pembayaran'),
          ),
        ],
      ),
    );

    if (action != 'cancel' || !mounted) return;

    final pin = await showPinDialog(context);
    if (pin == null || !mounted) return;

    setState(() => _isLoading = true);
    final result = await context.read<PembayaranProvider>().deletePembayaran(id, pin);
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['pesan'] ?? 'Berhasil'),
        backgroundColor:
            result['success'] == true ? AppColors.success : AppColors.danger,
      ),
    );
    if (result['success'] == true) {
      context.read<SantriProvider>().fetchSantriStatus();
      if (_selectedSantriId != null) _fetchPaidPayments(_selectedSantriId!);
    }
  }

  Widget _payDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  /// Get the earliest unpaid required month for selected santri
  int? _getEarliestUnpaid(dynamic santri) {
    for (int bulan = 1; bulan <= 12; bulan++) {
      final status = santri.bulanStatus['$bulan'];
      final wajib = status?['wajib'] == true;
      final dibayar = status?['dibayar'] == true;
      if (wajib && !dibayar) return bulan;
    }
    return null;
  }

  bool _isBeforeRegistration(dynamic santri, int bulan) {
    final status = santri.bulanStatus['$bulan'];
    if (status == null) return false;
    final wajib = status['wajib'] == true;
    final alasan = status['alasan'] as String?;
    return !wajib && alasan == 'Belum Terdaftar';
  }

  Future<void> _bayar() async {
    if (_selectedSantriId == null || _selectedBulan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih santri dan minimal 1 bulan'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final pin = await showPinDialog(context);
    if (pin == null) return;

    setState(() => _isLoading = true);

    // ignore: use_build_context_synchronously
    final prov = context.read<PembayaranProvider>();
    final result = await prov.bayarSPP({
      'santri_id': _selectedSantriId,
      'bulan_list': _selectedBulan.toList()..sort(),
      'tahun_spp': _tahun,
      'metode_bayar': _metodeBayar,
      'keterangan': _keteranganController.text.trim(),
      'pin': pin,
    });

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['pesan'] ?? 'Berhasil'),
          backgroundColor: result['success'] == true ? AppColors.success : AppColors.danger,
        ),
      );
      if (result['success'] == true) {
        context.read<SantriProvider>().fetchSantriStatus();
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final santriProv = context.watch<SantriProvider>();
    final santriAktif = santriProv.santriList.where((s) => s.statusAktif).toList();
    final selectedSantri = _selectedSantriId != null
        ? santriAktif.where((s) => s.id == _selectedSantriId).firstOrNull
        : null;
    final totalNominal = selectedSantri != null
        ? _selectedBulan.length * selectedSantri.nominalSpp
        : 0;

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Santri selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih Santri',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedSantriId,
                    decoration: const InputDecoration(
                      hintText: 'Pilih santri...',
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: santriAktif
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text('${s.namaLengkap} (${s.jilid ?? "-"})'),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedSantriId = v;
                        _selectedBulan.clear();
                        _paidPayments.clear();
                      });
                      if (v != null) _fetchPaidPayments(v);
                    },
                    isExpanded: true,
                  ),
                  // Selected santri info
                  if (selectedSantri != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(13),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withAlpha(51)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedSantri.namaLengkap,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary),
                                    ),
                                    Text(
                                      '${selectedSantri.isSubsidi ? "Subsidi" : "Non Subsidi"} • ${selectedSantri.jilid ?? "-"}',
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
                                  color: AppColors.primary.withAlpha(26),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  formatCurrency(selectedSantri.nominalSpp),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (selectedSantri.tglMendaftar != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Terdaftar: ${_formatDate(selectedSantri.tglMendaftar!)}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Year & Method
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _tahun,
                      decoration: const InputDecoration(labelText: 'Tahun'),
                      items: List.generate(5, (i) {
                        final year = DateTime.now().year - i;
                        return DropdownMenuItem(value: year, child: Text('$year'));
                      }),
                      onChanged: (v) {
                        setState(() {
                          _tahun = v ?? _tahun;
                          _selectedBulan.clear();
                          _paidPayments.clear();
                        });
                        if (_selectedSantriId != null) {
                          _fetchPaidPayments(_selectedSantriId!);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _metodeBayar,
                      decoration: const InputDecoration(labelText: 'Metode'),
                      items: ['Tunai', 'Transfer']
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (v) => setState(() => _metodeBayar = v ?? 'Tunai'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Month Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih Bulan Pembayaran',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  // Info text
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
                          SizedBox(width: 4),
                          Expanded(child: Text(
                            'Pembayaran wajib berurutan dari bulan belum lunas pertama.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          )),
                        ]),
                        const SizedBox(height: 2),
                        const Row(children: [
                          SizedBox(width: 18),
                          Expanded(child: Text(
                            'Bulan ungu = sebelum tanggal daftar (tidak wajib dibayar).',
                            style: TextStyle(fontSize: 11, color: Colors.purple),
                          )),
                        ]),
                        if (selectedSantri != null) ...[
                          const SizedBox(height: 2),
                          const Row(children: [
                            SizedBox(width: 18),
                            Expanded(child: Text(
                              'Ketuk bulan hijau ✓ untuk melihat detail & batalkan.',
                              style: TextStyle(fontSize: 11, color: AppColors.success),
                            )),
                          ]),
                        ],
                      ],
                    ),
                  ),
                  _buildMonthGrid(selectedSantri),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Keterangan
          TextFormField(
            controller: _keteranganController,
            decoration: const InputDecoration(
              labelText: 'Keterangan (opsional)',
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 8),

          // Paid payments list (for cancel)
          if (_paidPayments.isNotEmpty) ...[  
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Riwayat Pembayaran',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const Spacer(),
                        if (_fetchingPayments)
                          const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ketuk bulan ✓ hijau pada grid di atas untuk melihat detail dan opsi batalkan.',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    ...(_paidPayments.entries.toList()
                          ..sort((a, b) => a.key.compareTo(b.key)))
                        .map((entry) {
                      final p = entry.value;
                      final bulan = entry.key;
                      return InkWell(
                        onTap: () => _showCancelPaymentDialog(bulan),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(13),
                            border: Border.all(
                                color: AppColors.success.withAlpha(77)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 16, color: AppColors.success),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      namaBulan(bulan),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                    Text(
                                      '${p['kode_invoice'] ?? '-'} • ${formatCurrency(p['nominal'] ?? 0)}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.cancel_outlined,
                                  size: 16, color: AppColors.danger),
                              const SizedBox(width: 4),
                              const Text('Batal',
                                  style: TextStyle(
                                      fontSize: 11, color: AppColors.danger)),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Summary
          if (_selectedBulan.isNotEmpty && selectedSantri != null) ...[
            Card(
              color: AppColors.primary.withAlpha(13),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Total: ${_selectedBulan.length} bulan',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _selectedBulan.map((b) => namaBulan(b)).join(', '),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(totalNominal),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          ElevatedButton.icon(
            onPressed: _isLoading ? null : _bayar,
            icon: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.payment),
            label: Text(_isLoading ? 'Memproses...' : 'Bayar SPP'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) return SafeArea(top: false, child: content);

    return Scaffold(
      appBar: AppBar(title: const Text('Bayar SPP')),
      body: SafeArea(top: false, child: content),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day} ${namaBulan(dt.month)} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  Widget _buildMonthGrid(dynamic selectedSantri) {
    // Determine the earliest unpaid required month
    final earliest = selectedSantri != null ? _getEarliestUnpaid(selectedSantri) : null;
    final selectedSorted = _selectedBulan.toList()..sort();
    final expectedNext = selectedSorted.isEmpty
        ? earliest
        : (selectedSorted.isNotEmpty ? selectedSorted.last + 1 : null);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(12, (i) {
        final bulan = i + 1;
        bool sudahBayar = false;
        bool wajib = true;
        bool beforeRegistration = false;

        if (selectedSantri != null) {
          beforeRegistration = _isBeforeRegistration(selectedSantri, bulan);
          final status = selectedSantri.bulanStatus['$bulan'];
          sudahBayar = status?['dibayar'] == true;
          wajib = status?['wajib'] == true;
        }

        final isSelected = _selectedBulan.contains(bulan);
        // Can select only if: wajib, not paid, and is the next in sequence
        final canSelect = wajib && !sudahBayar && bulan == expectedNext;

        return GestureDetector(
          onTap: sudahBayar
              ? () => _showCancelPaymentDialog(bulan)
              : (beforeRegistration || !wajib)
                  ? null
                  : () {
                      setState(() {
                        if (isSelected) {
                          // Allow removing only the last selected month
                          final last = selectedSorted.isNotEmpty ? selectedSorted.last : null;
                          if (bulan == last) _selectedBulan.remove(bulan);
                        } else if (canSelect) {
                          _selectedBulan.add(bulan);
                        }
                      });
                    },
          child: Container(
            width: (MediaQuery.of(context).size.width - 80) / 4,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: sudahBayar
                  ? AppColors.success.withAlpha(51)
                  : beforeRegistration
                      ? Colors.purple.withAlpha(26)
                      : isSelected
                          ? AppColors.primary
                          : !wajib
                              ? Colors.grey.withAlpha(26)
                              : canSelect
                                  ? Colors.grey.withAlpha(51)
                                  : Colors.grey.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
              border: isSelected && !sudahBayar
                  ? Border.all(color: AppColors.primary, width: 2)
                  : beforeRegistration
                      ? Border.all(color: Colors.purple.withAlpha(77), width: 1)
                      : canSelect
                          ? Border.all(color: AppColors.primary.withAlpha(102), width: 1)
                          : null,
            ),
            child: Column(
              children: [
                Text(
                  namaBulan(bulan).substring(0, 3),
                  style: TextStyle(
                    color: sudahBayar
                        ? AppColors.success
                        : beforeRegistration
                            ? Colors.purple
                            : isSelected
                                ? Colors.white
                                : !wajib
                                    ? Colors.grey
                                    : canSelect
                                        ? AppColors.textPrimary
                                        : Colors.grey,
                    fontWeight: isSelected || sudahBayar
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                if (sudahBayar)
                  const Icon(Icons.check_circle, size: 16, color: AppColors.success)
                else if (beforeRegistration)
                  const Icon(Icons.circle_outlined, size: 14, color: Colors.purple)
                else if (!wajib)
                  const Icon(Icons.remove, size: 16, color: Colors.grey)
                else if (isSelected)
                  const Icon(Icons.check, size: 16, color: Colors.white)
                else if (canSelect)
                  Icon(Icons.radio_button_unchecked,
                      size: 14, color: AppColors.primary.withAlpha(153))
                else
                  const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
              ],
            ),
          ),
        );
      }),
    );
  }
}
