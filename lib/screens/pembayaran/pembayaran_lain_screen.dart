import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/santri_provider.dart';
import '../../services/background_service.dart';
import '../../utils/constants.dart';
import '../../widgets/pin_dialog.dart';

class PembayaranLainScreen extends StatefulWidget {
  const PembayaranLainScreen({super.key});

  @override
  State<PembayaranLainScreen> createState() => _PembayaranLainScreenState();
}

class _PembayaranLainScreenState extends State<PembayaranLainScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedSantriId;
  final _nominalController = TextEditingController();
  final _keteranganController = TextEditingController();
  String _kategori = 'Pendaftaran';
  String _metodeBayar = 'Tunai';
  bool _isLoading = false;

  static const List<String> _kategoriList = [
    'Pendaftaran',
    'Buku/Jilid',
    'Seragam',
    'Kegiatan',
    'Wisuda',
    'Lainnya',
  ];

  @override
  void dispose() {
    _nominalController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSantriId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih santri terlebih dahulu'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final pin = await showPinDialog(context);
    if (pin == null) return;

    setState(() => _isLoading = true);

    final data = {
      'santri_id': _selectedSantriId,
      'nominal': int.tryParse(_nominalController.text.trim()) ?? 0,
      'keterangan': '[$_kategori] ${_keteranganController.text.trim()}',
      'metode_bayar': _metodeBayar,
      'pin': pin,
    };

    final result = await BackgroundService.enqueueOrExecute(
      'POST',
      ApiConfig.pengeluaranUrl,
      body: data,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['pesan'] ?? 'Berhasil'),
          backgroundColor:
              result['success'] == true ? AppColors.success : AppColors.danger,
        ),
      );
      if (result['success'] == true) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final santriProv = context.watch<SantriProvider>();
    final santriAktif =
        santriProv.santriList.where((s) => s.statusAktif).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran Lain')),
      body: SafeArea(top: false, child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              Card(
                color: AppColors.info.withAlpha(20),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.info, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Catat pembayaran selain SPP bulanan,\nseperti pendaftaran, buku, seragam, dll.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.info),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Santri selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pilih Santri',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
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
                                  child: Text(
                                      '${s.namaLengkap} (${s.jilid ?? "-"})'),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedSantriId = v),
                        isExpanded: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Kategori & Metode
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _kategori,
                        decoration:
                            const InputDecoration(labelText: 'Kategori'),
                        items: _kategoriList
                            .map((k) => DropdownMenuItem(
                                value: k, child: Text(k)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _kategori = v ?? _kategori),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _metodeBayar,
                        decoration: const InputDecoration(
                            labelText: 'Metode Bayar'),
                        items: ['Tunai', 'Transfer']
                            .map((m) => DropdownMenuItem(
                                value: m, child: Text(m)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _metodeBayar = v ?? 'Tunai'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Nominal
              TextFormField(
                controller: _nominalController,
                decoration: const InputDecoration(
                  labelText: 'Nominal',
                  prefixIcon: Icon(Icons.money),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Nominal wajib diisi';
                  }
                  if ((int.tryParse(v.trim()) ?? 0) <= 0) {
                    return 'Nominal harus lebih dari 0';
                  }
                  return null;
                },
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
              const SizedBox(height: 24),

              // Submit
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(
                    _isLoading ? 'Memproses...' : 'Simpan Pembayaran'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
