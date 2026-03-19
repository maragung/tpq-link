import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class CekPembayaranScreen extends StatefulWidget {
  const CekPembayaranScreen({super.key});

  @override
  State<CekPembayaranScreen> createState() => _CekPembayaranScreenState();
}

class _CekPembayaranScreenState extends State<CekPembayaranScreen> {
  final _nikController = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _pembayaranData;
  String? _error;

  Future<void> _cek() async {
    final nik = _nikController.text.trim();
    if (nik.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _pembayaranData = null;
    });

    final result = await ApiService.get(
      '${ApiConfig.baseUrl}/publik/cek-pembayaran',
      queryParams: {'nik': nik},
    );

    if (mounted) {
      setState(() {
        _loading = false;
        if (result['success'] == true) {
          _pembayaranData = result['data'];
        } else {
          _error = result['pesan'] ?? 'Data tidak ditemukan';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cek Pembayaran')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Masukkan NIK Santri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gunakan NIK yang terdaftar untuk melihat status pembayaran SPP.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nikController,
              decoration: const InputDecoration(
                labelText: 'NIK Santri',
                prefixIcon: Icon(Icons.badge_outlined),
                hintText: '16 digit NIK',
              ),
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _cek(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _cek,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Cek Status'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 24),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              ),
            ],
            if (_pembayaranData != null) ...[
              const SizedBox(height: 24),
              _buildResultCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final santri = _pembayaranData!['santri'] ?? {};
    final riwayat = _pembayaranData!['riwayat'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Informasi Santri', style: TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                _infoRow('Nama', santri['nama_lengkap']),
                _infoRow('Jilid', santri['jilid']),
                _infoRow('Status', santri['status']),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Riwayat Pembayaran Terakhir', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...riwayat.take(5).map((p) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text('${p['bulan']} ${p['tahun']}'),
            subtitle: Text(formatCurrency(p['nominal'] ?? 0)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Lunas', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        )),
        if (riwayat.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('Belum ada riwayat pembayaran', style: TextStyle(color: AppColors.textSecondary))),
          ),
      ],
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          const Text(': '),
          Expanded(child: Text(value?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
