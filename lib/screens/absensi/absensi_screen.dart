import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/absensi_provider.dart';
import '../../providers/santri_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/absensi.dart';
import '../../utils/constants.dart';
import '../../widgets/pin_dialog.dart';

class AbsensiScreen extends StatefulWidget {
  const AbsensiScreen({super.key});

  @override
  State<AbsensiScreen> createState() => _AbsensiScreenState();
}

class _AbsensiScreenState extends State<AbsensiScreen> {
  DateTime _selectedDate = DateTime.now();
  // Map santriId → status
  final Map<int, String> _absensiMap = {};
  final Map<int, String> _catatanMap = {};
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final tanggal = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final absensiProv = context.read<AbsensiProvider>();
    final santriProv = context.read<SantriProvider>();

    // Load santri list + current absensi
    final futures = <Future<void>>[
      absensiProv.fetchAbsensi(tanggal: tanggal),
      if (santriProv.santriList.isEmpty) santriProv.fetchSantriStatus(),
    ];
    await Future.wait(futures);

    // Populate map from fetched data
    setState(() {
      _absensiMap.clear();
      _catatanMap.clear();
      for (final a in absensiProv.absensiList) {
        _absensiMap[a.santriId] = a.status;
        if (a.catatan != null) _catatanMap[a.santriId] = a.catatan!;
      }
      _initialized = true;
    });
  }

  Future<void> _changeDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('id'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _initialized = false;
      });
      _loadData();
    }
  }

  void _toggleStatus(int santriId) {
    setState(() {
      final current = _absensiMap[santriId] ?? 'alpha';
      final idx = Absensi.statusOptions.indexOf(current);
      _absensiMap[santriId] = Absensi.statusOptions[(idx + 1) % Absensi.statusOptions.length];
    });
  }

  Future<void> _simpan() async {
    final pin = await showPinDialog(context, title: 'Verifikasi PIN');
    if (!mounted || pin == null || pin.isEmpty) return;

    final santriProv = context.read<SantriProvider>();
    final absensiProv = context.read<AbsensiProvider>();
    final tanggal = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // Build data from all santri
    final data = <Map<String, dynamic>>[];
    for (final s in santriProv.santriList.where((s) => s.statusAktif)) {
      data.add({
        'santri_id': s.id,
        'status': _absensiMap[s.id] ?? 'alpha',
        if (_catatanMap.containsKey(s.id)) 'catatan': _catatanMap[s.id],
      });
    }

    final ok = await absensiProv.simpanAbsensi(tanggal: tanggal, data: data, pin: pin);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Absensi berhasil disimpan'), backgroundColor: AppColors.success),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(absensiProv.error ?? 'Gagal menyimpan'), backgroundColor: AppColors.danger),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'hadir': return AppColors.success;
      case 'sakit': return AppColors.warning;
      case 'izin': return AppColors.info;
      case 'alpha': return AppColors.danger;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'hadir': return 'H';
      case 'sakit': return 'S';
      case 'izin': return 'I';
      case 'alpha': return 'A';
      default: return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final absensiProv = context.watch<AbsensiProvider>();
    final santriProv = context.watch<SantriProvider>();
    final user = context.read<AuthProvider>().user;
    final canManage = user != null && (user.isFullAccess || user.jabatan == 'Pengajar' || user.jabatan == 'Sekretaris');
    final aktivSantri = santriProv.santriList.where((s) => s.statusAktif).toList();
    aktivSantri.sort((a, b) => (a.noAbsen ?? 999).compareTo(b.noAbsen ?? 999));

    final tanggalStr = DateFormat('EEEE, d MMMM yyyy', 'id').format(_selectedDate);
    final ringkasan = absensiProv.ringkasan;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi'),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Simpan Absensi',
              onPressed: _simpan,
            ),
        ],
      ),
      body: SafeArea(top: false, child: Column(
        children: [
          // Date picker header
          InkWell(
            onTap: _changeDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.primary.withAlpha(26),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(tanggalStr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                  const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                ],
              ),
            ),
          ),

          // Ringkasan
          if (ringkasan != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _summaryChip('H', ringkasan['hadir'] ?? 0, AppColors.success),
                  const SizedBox(width: 8),
                  _summaryChip('S', ringkasan['sakit'] ?? 0, AppColors.warning),
                  const SizedBox(width: 8),
                  _summaryChip('I', ringkasan['izin'] ?? 0, AppColors.info),
                  const SizedBox(width: 8),
                  _summaryChip('A', ringkasan['alpha'] ?? 0, AppColors.danger),
                  const Spacer(),
                  Text('Total: ${ringkasan['total'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),

          const Divider(height: 1),

          // List santri with status toggle
          Expanded(
            child: absensiProv.loading && !_initialized
                ? const Center(child: CircularProgressIndicator())
                : aktivSantri.isEmpty
                    ? const Center(child: Text('Belum ada santri aktif'))
                    : ListView.separated(
                        itemCount: aktivSantri.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final santri = aktivSantri[index];
                          final status = _absensiMap[santri.id] ?? 'alpha';
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: _statusColor(status),
                              child: Text(
                                _statusLabel(status),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            title: Text(santri.namaLengkap, style: const TextStyle(fontSize: 14)),
                            subtitle: Text(
                              '${santri.noAbsen != null ? "No. ${santri.noAbsen} · " : ""}${santri.jilid}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            trailing: canManage
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: Absensi.statusOptions.map((s) {
                                      final isSelected = status == s;
                                      return Padding(
                                        padding: const EdgeInsets.only(left: 2),
                                        child: GestureDetector(
                                          onTap: () => setState(() => _absensiMap[santri.id] = s),
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: isSelected ? _statusColor(s) : Colors.transparent,
                                              border: Border.all(color: _statusColor(s), width: 1.5),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              _statusLabel(s),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected ? Colors.white : _statusColor(s),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusColor(status).withAlpha(38),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(status.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _statusColor(status))),
                                  ),
                            onTap: canManage ? () => _toggleStatus(santri.id) : null,
                          );
                        },
                      ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _summaryChip(String label, dynamic count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 4),
          Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
