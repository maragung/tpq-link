import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/santri_provider.dart';
import '../../providers/pembayaran_provider.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/pin_dialog.dart';
import '../../widgets/santri_selector_field.dart';

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
  final _nominalManualController = TextEditingController();
  bool _isLoading = false;
  bool _cancelSelectionMode = true;
  final Set<int> _selectedCancelPaymentIds = {};

  /// Map bulan -> payment record {id, kode_invoice, nominal, tgl_bayar, metode_bayar}
  Map<int, Map<String, dynamic>> _paidPayments = {};
  bool _fetchingPayments = false;
  bool _didInitPayments = false;

  /// Year-specific bulan status fetched locally (independent of global SantriProvider year)
  Map<String, dynamic> _localBulanStatus = {};
  bool _fetchingLocalStatus = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final prevId = _selectedSantriId;
      _selectedSantriId ??= args['santri_id'];
      _selectedSantriNama ??= args['nama'];
      if (_selectedSantriId != null &&
          !_didInitPayments &&
          prevId != _selectedSantriId) {
        _didInitPayments = true;
        _fetchPaidPayments(_selectedSantriId!);
        _fetchLocalBulanStatus(_selectedSantriId!, _tahun);
      }
    }
  }

  /// Fetch year-specific bulan status locally (does not change global SantriProvider year)
  Future<void> _fetchLocalBulanStatus(int santriId, int year) async {
    setState(() => _fetchingLocalStatus = true);
    final result = await ApiService.get(
      ApiConfig.pembayaranStatusUrl,
      queryParams: {
        'tahun': year.toString(),
        'santri_id': santriId.toString(),
        'include_nonaktif': 'true',
      },
    );
    if (!mounted) return;
    if (result['success'] == true) {
      final data = result['data'] as List? ?? [];
      for (final item in data) {
        if ((item['id'] as int?) == santriId) {
          final raw = (item['bulan_status'] as Map?) ?? {};
          setState(() {
            _localBulanStatus = {
              for (final k in raw.keys)
                k.toString(): Map<String, dynamic>.from(raw[k] as Map),
            };
            _fetchingLocalStatus = false;
          });
          return;
        }
      }
    }
    setState(() {
      _localBulanStatus = {};
      _fetchingLocalStatus = false;
    });
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
        final bulanInt = bulan is int ? bulan : int.tryParse('$bulan');
        if (bulanInt != null && bulanInt >= 1 && bulanInt <= 12) {
          map[bulanInt] = Map<String, dynamic>.from(p as Map);
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
    final result =
        await context.read<PembayaranProvider>().deletePembayaran(id, pin);
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
      if (_selectedSantriId != null) {
        _fetchPaidPayments(_selectedSantriId!);
        _fetchLocalBulanStatus(_selectedSantriId!, _tahun);
      }
    }
  }

  Future<void> _cancelSelectedPayments() async {
    if (_selectedCancelPaymentIds.isEmpty) return;

    final pin = await showPinDialog(context);
    if (pin == null || !mounted) return;

    setState(() => _isLoading = true);
    final prov = context.read<PembayaranProvider>();
    final ids = _selectedCancelPaymentIds.toList()..sort();
    final result = await prov.deletePembayaranBatch(ids, pin);

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
      setState(() {
        _cancelSelectionMode = false;
        _selectedCancelPaymentIds.clear();
      });
      context.read<SantriProvider>().fetchSantriStatus();
      if (_selectedSantriId != null) {
        _fetchPaidPayments(_selectedSantriId!);
        _fetchLocalBulanStatus(_selectedSantriId!, _tahun);
      }
    }
  }

  List<int> _sortedPaidMonthsDesc() {
    final months = _paidPayments.keys.where((m) => m >= 1 && m <= 12).toList();
    months.sort((a, b) => b.compareTo(a));
    return months;
  }

  bool _canSelectCancelMonth(int month, {required bool currentlySelected}) {
    if (currentlySelected) return true;
    final paidMonths = _sortedPaidMonthsDesc();
    if (paidMonths.isEmpty) return false;

    final selectedMonths = _paidPayments.entries
        .where((e) => _selectedCancelPaymentIds.contains(e.value['id']))
        .map((e) => e.key)
        .toList();
    selectedMonths.sort((a, b) => b.compareTo(a));

    final nextIndex = selectedMonths.length;
    return nextIndex < paidMonths.length && paidMonths[nextIndex] == month;
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
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withAlpha(77)),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, color: textColor, fontWeight: FontWeight.w600)),
    );
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    _nominalManualController.dispose();
    super.dispose();
  }

  int? _manualNominal() {
    final digits =
        _nominalManualController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    final parsed = int.tryParse(digits);
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }

  /// Get the earliest unpaid required month using local year-specific status
  int? _getEarliestUnpaid(dynamic _) {
    for (int bulan = 1; bulan <= 12; bulan++) {
      final status = _localBulanStatus['$bulan'];
      final wajib = status?['wajib'] == true;
      final dibayar = status?['dibayar'] == true;
      if (wajib && !dibayar) return bulan;
    }
    return null;
  }

  /// First month required to pay in the selected year using local status
  int? _getBulanMulai(dynamic _) {
    for (int bulan = 1; bulan <= 12; bulan++) {
      final status = _localBulanStatus['$bulan'];
      if (status?['wajib'] == true) return bulan;
    }
    return null;
  }

  bool _isBeforeRegistration(dynamic _, int bulan) {
    final status = _localBulanStatus['$bulan'];
    if (status == null) return false;
    final wajib = status['wajib'] == true;
    final alasan = status['alasan'] as String?;
    return !wajib && alasan == 'Belum Terdaftar';
  }

  bool _isNonaktif(dynamic _, int bulan) {
    final status = _localBulanStatus['$bulan'];
    if (status == null) return false;
    final wajib = status['wajib'] == true;
    final alasan = status['alasan'] as String?;
    return !wajib && alasan == 'Nonaktif';
  }

  bool _canSelectWithManualNominal(int bulan) {
    final status = _localBulanStatus['$bulan'];
    return status?['canSelectWithManualNominal'] == true;
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

    // Cek apakah ada bulan nonaktif yang dipilih
    bool hasNonaktifMonth = false;
    for (final bulan in _selectedBulan) {
      if (_canSelectWithManualNominal(bulan)) {
        hasNonaktifMonth = true;
        break;
      }
    }

    // Jika ada bulan nonaktif, wajib input nominal manual
    if (hasNonaktifMonth && _manualNominal() == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bulan nonaktif memerlukan input nominal manual'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final pin = await showPinDialog(context);
    if (!mounted || pin == null) return;

    setState(() => _isLoading = true);

    final prov = context.read<PembayaranProvider>();
    final santriList = context.read<SantriProvider>().santriList;
    final matching = santriList.where((s) => s.id == _selectedSantriId);
    final selectedSantri = matching.isEmpty ? null : matching.first;
    final nominalManual = _manualNominal();
    final nominalOtomatis = selectedSantri == null
        ? 0
        : _selectedBulan.length * selectedSantri.nominalSpp.toInt();
    final nominalFinal = nominalManual ?? nominalOtomatis;
    final result = await prov.bayarSPP({
      'santri_id': _selectedSantriId,
      'bulan_list': _selectedBulan.toList()..sort(),
      'tahun_spp': _tahun,
      'nominal': nominalFinal,
      if (nominalManual != null) 'nominal_per_bulan': nominalManual,
      if (nominalManual != null) 'abaikan_aturan_nominal': true,
      'metode_bayar': _metodeBayar,
      'keterangan': _keteranganController.text.trim(),
      'pin': pin,
    });

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
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final santriProv = context.watch<SantriProvider>();
    final santriAktif =
        santriProv.santriList.where((s) => s.statusAktif).toList();
    final selectedSantri = _selectedSantriId != null
        ? santriAktif.where((s) => s.id == _selectedSantriId).firstOrNull
        : null;
    final sortedSelectedMonths = _selectedBulan.toList()..sort();
    final nominalManual = _manualNominal();
    final nominalOtomatis = selectedSantri != null
        ? _selectedBulan.length * selectedSantri.nominalSpp
        : 0;
    final totalNominal = nominalManual ?? nominalOtomatis;

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
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  SantriSelectorField(
                    santriList: santriAktif,
                    value: _selectedSantriId,
                    fallbackName: _selectedSantriNama,
                    helperText: 'Cari berdasarkan no. absen atau nama santri.',
                    onSelected: (santri) {
                      setState(() {
                        _selectedSantriId = santri.id;
                        _selectedSantriNama = santri.namaLengkap;
                        _selectedBulan.clear();
                        _paidPayments.clear();
                        _cancelSelectionMode = false;
                        _selectedCancelPaymentIds.clear();
                        _nominalManualController.clear();
                        _localBulanStatus = {};
                      });
                      _fetchPaidPayments(santri.id);
                      _fetchLocalBulanStatus(santri.id, _tahun);
                    },
                    onCleared: _selectedSantriId == null
                        ? null
                        : () {
                            setState(() {
                              _selectedSantriId = null;
                              _selectedSantriNama = null;
                              _selectedBulan.clear();
                              _paidPayments.clear();
                              _nominalManualController.clear();
                              _localBulanStatus = {};
                            });
                          },
                  ),
                  // Selected santri info
                  if (selectedSantri != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(13),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: AppColors.primary.withAlpha(51)),
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
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  selectedSantri.noAbsen != null
                                      ? 'No. ${selectedSantri.noAbsen}'
                                      : 'Tanpa absen',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
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
                          const SizedBox(height: 8),
                          // Badges: wajib mulai & tunggakan
                          Builder(builder: (_) {
                            final bulanMulai = _getBulanMulai(selectedSantri);
                            final earliest = _getEarliestUnpaid(selectedSantri);
                            return Wrap(spacing: 6, runSpacing: 4, children: [
                              if (bulanMulai != null)
                                _infoBadge(
                                  'Wajib bayar mulai: ${namaBulan(bulanMulai)} $_tahun',
                                  Colors.amber.shade700,
                                  Colors.amber.shade50,
                                ),
                              if (earliest != null)
                                _infoBadge(
                                  'Tunggakan dari: ${namaBulan(earliest)} $_tahun',
                                  Colors.red.shade700,
                                  Colors.red.shade50,
                                )
                              else if (_localBulanStatus.values.any((s) => s['wajib'] == true))
                                _infoBadge(
                                  '✓ Lunas $_tahun',
                                  Colors.green.shade700,
                                  Colors.green.shade50,
                                ),
                            ]);
                          }),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pengaturan Pembayaran',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _tahun,
                    decoration: InputDecoration(
                      labelText: 'Tahun',
                      helperText: 'Pilihan tahun dipertahankan selama halaman ini aktif',
                    ),
                    items: List.generate(5, (i) {
                      final year = DateTime.now().year - i;
                      return DropdownMenuItem(
                          value: year, child: Text('$year'));
                    }),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _tahun = v;
                        _selectedBulan.clear();
                        _paidPayments.clear();
                        _cancelSelectionMode = false;
                        _selectedCancelPaymentIds.clear();
                        _nominalManualController.clear();
                        _localBulanStatus = {};
                      });
                      if (_selectedSantriId != null) {
                        _fetchPaidPayments(_selectedSantriId!);
                        _fetchLocalBulanStatus(_selectedSantriId!, v);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.payments_outlined,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Nominal per Bulan',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Dari pengaturan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          selectedSantri == null
                              ? '-'
                              : formatCurrency(selectedSantri.nominalSpp),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nominalManualController,
                    decoration: const InputDecoration(
                      labelText: 'Masukkan nominal manual',
                      hintText: 'Kosongkan untuk nominal otomatis',
                      prefixIcon: Icon(Icons.edit_note),
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _metodeBayar,
                    decoration: const InputDecoration(
                      labelText: 'Metode Pembayaran',
                    ),
                    items: ['Tunai', 'Transfer']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _metodeBayar = v ?? 'Tunai'),
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
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                          Icon(Icons.info_outline,
                              size: 14, color: AppColors.textSecondary),
                          SizedBox(width: 4),
                          Expanded(
                              child: Text(
                            'Pembayaran wajib berurutan dari bulan belum lunas pertama.',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textSecondary),
                          )),
                        ]),
                        if (selectedSantri != null) ...[
                          const SizedBox(height: 2),
                          const Row(children: [
                            SizedBox(width: 18),
                            Expanded(
                                child: Text(
                              'Ketuk bulan hijau ✓ untuk melihat detail & batalkan.',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.success),
                            )),
                          ]),
                          // Dynamic badges: wajib mulai + tunggakan
                          Builder(builder: (_) {
                            final bulanMulai = _getBulanMulai(selectedSantri);
                            final earliest = _getEarliestUnpaid(selectedSantri);
                            if (bulanMulai == null && earliest == null) {
                              return const SizedBox();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6, left: 18),
                              child: Wrap(spacing: 6, runSpacing: 4, children: [
                                if (bulanMulai != null)
                                  _infoBadge(
                                    '📅 Wajib mulai: ${namaBulan(bulanMulai)} $_tahun',
                                    Colors.amber.shade800,
                                    Colors.amber.shade50,
                                  ),
                                if (earliest != null)
                                  _infoBadge(
                                    '⚠ Tunggakan dari: ${namaBulan(earliest)} $_tahun',
                                    Colors.red.shade700,
                                    Colors.red.shade50,
                                  )
                                else if (_localBulanStatus.values.any((s) => s['wajib'] == true))
                                  _infoBadge(
                                    '✓ Lunas $_tahun',
                                    Colors.green.shade700,
                                    Colors.green.shade50,
                                  ),
                              ]),
                            );
                          }),
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
                    const Text(
                      'Centang dari bulan terakhir yang dibayar, satu per satu.',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    if (_cancelSelectionMode) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withAlpha(13),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: AppColors.danger.withAlpha(77)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_selectedCancelPaymentIds.length} pembayaran dipilih',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: (_selectedCancelPaymentIds.isEmpty ||
                                      _isLoading)
                                  ? null
                                  : _cancelSelectedPayments,
                              child: const Text('Batalkan Pembayaran'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    ...(_paidPayments.entries.toList()
                          ..sort((a, b) => b.key.compareTo(a.key)))
                        .map((entry) {
                      final p = entry.value;
                      final bulan = entry.key;
                      final id = p['id'] as int?;
                      final isSelected =
                          id != null && _selectedCancelPaymentIds.contains(id);
                      final isSelectable = _canSelectCancelMonth(
                        bulan,
                        currentlySelected: isSelected,
                      );
                      return InkWell(
                        onTap: () {
                          if (_cancelSelectionMode) {
                            if (id == null) return;
                            setState(() {
                              if (isSelected) {
                                final selectedMonths = _paidPayments.entries
                                    .where((e) => _selectedCancelPaymentIds
                                        .contains(e.value['id']))
                                    .map((e) => e.key)
                                    .toList()
                                  ..sort((a, b) => b.compareTo(a));
                                final canUncheck = selectedMonths.isNotEmpty &&
                                    selectedMonths.last == bulan;
                                if (canUncheck) {
                                  _selectedCancelPaymentIds.remove(id);
                                }
                              } else {
                                if (isSelectable) {
                                  _selectedCancelPaymentIds.add(id);
                                }
                              }
                            });
                            return;
                          }
                          _showCancelPaymentDialog(bulan);
                        },
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
                              if (_cancelSelectionMode)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    size: 18,
                                    color: isSelected
                                        ? AppColors.danger
                                        : isSelectable
                                            ? AppColors.textSecondary
                                            : AppColors.border,
                                  ),
                                ),
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
                                const SizedBox(width: 4),
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
                      sortedSelectedMonths.map((b) => namaBulan(b)).join(', '),
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
    // Determine the earliest unpaid required month from local year-specific status
    final earliest = _getEarliestUnpaid(null);
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
        bool wajib = false;
        bool beforeRegistration = false;
        bool isNonaktifSelectable = false;

        final status = _localBulanStatus['$bulan'];
        sudahBayar = status?['dibayar'] == true;
        wajib = status?['wajib'] == true;
        beforeRegistration = _isBeforeRegistration(null, bulan);
        isNonaktifSelectable = _canSelectWithManualNominal(bulan);

        final isSelected = _selectedBulan.contains(bulan);
        // Can select wajib only if: wajib, not paid, and is the next in sequence
        final canSelect = wajib && !sudahBayar && bulan == expectedNext;
        // Can select nonaktif if it has canSelectWithManualNominal and admin has nominal manual access
        final canSelectNonaktif = isNonaktifSelectable && !sudahBayar;

        return GestureDetector(
          onTap: sudahBayar
            ? null
            : (beforeRegistration || (!wajib && !isNonaktifSelectable))
                  ? null
                  : () {
                      setState(() {
                        if (isSelected) {
                          // Allow removing only the last selected month
                          final last = selectedSorted.isNotEmpty
                              ? selectedSorted.last
                              : null;
                          if (bulan == last) _selectedBulan.remove(bulan);
                        } else if (canSelect || canSelectNonaktif) {
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
                          : !wajib && !canSelectNonaktif
                              ? Colors.grey.withAlpha(26)
                              : isNonaktifSelectable && !canSelectNonaktif
                                  ? Colors.orange.withAlpha(26)
                                  : canSelect
                                      ? Colors.grey.withAlpha(51)
                                      : Colors.grey.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
              border: isSelected && !sudahBayar
                  ? Border.all(color: AppColors.primary, width: 2)
                  : beforeRegistration
                      ? Border.all(color: Colors.purple.withAlpha(77), width: 1)
                      : isNonaktifSelectable && canSelectNonaktif
                          ? Border.all(
                              color: Colors.orange.withAlpha(153), width: 1)
                          : canSelect
                              ? Border.all(
                                  color: AppColors.primary.withAlpha(102), width: 1)
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
                                : isNonaktifSelectable && !canSelectNonaktif
                                    ? Colors.orange
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
                  const Icon(Icons.check_circle,
                      size: 16, color: AppColors.success)
                else if (beforeRegistration)
                  const Icon(Icons.circle_outlined,
                      size: 14, color: Colors.purple)
                else if (!wajib && !isNonaktifSelectable)
                  const Icon(Icons.remove, size: 16, color: Colors.grey)
                else if (isNonaktifSelectable && !canSelectNonaktif)
                  const Icon(Icons.diamond_outlined, size: 16, color: Colors.orange)
                else if (isSelected)
                  const Icon(Icons.check, size: 16, color: Colors.white)
                else if (canSelect || canSelectNonaktif)
                  Icon(Icons.radio_button_unchecked,
                      size: 14, color: isNonaktifSelectable ? Colors.orange : AppColors.primary.withAlpha(153))
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
