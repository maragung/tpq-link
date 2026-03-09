import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/santri_provider.dart';
import '../../providers/pembayaran_provider.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _selectedSantriId ??= args['santri_id'];
      _selectedSantriNama ??= args['nama'];
    }
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
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
                    onChanged: (v) => setState(() {
                      _selectedSantriId = v;
                      _selectedBulan.clear();
                    }),
                    isExpanded: true,
                  ),
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
                      onChanged: (v) => setState(() {
                        _tahun = v ?? _tahun;
                        _selectedBulan.clear();
                      }),
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
                  const Text('Pilih Bulan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  _buildMonthGrid(),
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

          // Summary
          if (_selectedBulan.isNotEmpty && _selectedSantriId != null) ...[
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

  Widget _buildMonthGrid() {
    // Find the selected santri's payment status
    final santriProv = context.watch<SantriProvider>();
    final selectedSantri = _selectedSantriId != null
        ? santriProv.santriList
            .where((s) => s.id == _selectedSantriId)
            .firstOrNull
        : null;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(12, (i) {
        final bulan = i + 1;
        bool sudahBayar = false;
        bool wajib = true;

        if (selectedSantri != null) {
          final status = selectedSantri.bulanStatus['$bulan'];
          sudahBayar = status?['dibayar'] == true;
          wajib = status?['wajib'] == true;
        }

        final isSelected = _selectedBulan.contains(bulan);

        return GestureDetector(
          onTap: sudahBayar || !wajib
              ? null
              : () {
                  setState(() {
                    if (isSelected) {
                      _selectedBulan.remove(bulan);
                    } else {
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
                  : isSelected
                      ? AppColors.primary
                      : !wajib
                          ? Colors.grey.withAlpha(26)
                          : Colors.grey.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
              border: isSelected && !sudahBayar
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            child: Column(
              children: [
                Text(
                  namaBulan(bulan).substring(0, 3),
                  style: TextStyle(
                    color: sudahBayar
                        ? AppColors.success
                        : isSelected
                            ? Colors.white
                            : !wajib
                                ? Colors.grey
                                : AppColors.textPrimary,
                    fontWeight: isSelected || sudahBayar
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                if (sudahBayar)
                  const Icon(Icons.check_circle, size: 16, color: AppColors.success)
                else if (!wajib)
                  const Icon(Icons.remove, size: 16, color: Colors.grey),
              ],
            ),
          ),
        );
      }),
    );
  }
}
