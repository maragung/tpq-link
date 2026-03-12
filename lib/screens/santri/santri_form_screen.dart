import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/santri_provider.dart';
// api_service accessed via provider
import '../../utils/constants.dart';
import '../../widgets/pin_dialog.dart';

class SantriFormScreen extends StatefulWidget {
  const SantriFormScreen({super.key});

  @override
  State<SantriFormScreen> createState() => _SantriFormScreenState();
}

class _SantriFormScreenState extends State<SantriFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nikController = TextEditingController();
  final _namaController = TextEditingController();
  final _noAbsenController = TextEditingController();
  final _alamatController = TextEditingController();
  final _namaWaliController = TextEditingController();
  final _noTelpWaliController = TextEditingController();
  final _emailWaliController = TextEditingController();

  String _jenisKelamin = '';
  String _jilid = 'Jilid 1';
  bool _isSubsidi = false;
  DateTime _tglMendaftar = DateTime.now();
  bool _isEdit = false;
  int? _editId;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int && !_isEdit) {
      _editId = args;
      _isEdit = true;
      _loadSantriData(args);
    }
  }

  Future<void> _loadSantriData(int id) async {
    setState(() => _isLoading = true);
    final result = await context.read<SantriProvider>().getSantriDetail(id);
    if (result['success'] == true && mounted) {
      final data = result['data'];
      _nikController.text = data['nik'] ?? '';
      _namaController.text = data['nama_lengkap'] ?? '';
      _noAbsenController.text = '${data['no_absen'] ?? ''}';
      _alamatController.text = data['alamat'] ?? '';
      _namaWaliController.text = data['nama_wali'] ?? '';
      _noTelpWaliController.text = data['no_telp_wali'] ?? '';
      _emailWaliController.text = data['email_wali'] ?? '';
      _jenisKelamin = data['jenis_kelamin'] ?? '';
      _jilid = data['jilid'] ?? 'Jilid 1';
      _isSubsidi = data['is_subsidi'] ?? false;
      if (data['tgl_mendaftar'] != null) {
        _tglMendaftar = DateTime.tryParse(data['tgl_mendaftar']) ?? DateTime.now();
      }
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().user;
    final isPengajarEditOnly = (user?.isPengajar ?? false) && _isEdit;

    final pin = await showPinDialog(context);
    if (!mounted || pin == null) return;

    setState(() => _isLoading = true);

    final data = isPengajarEditOnly
        ? {
            'jilid': _jilid,
            'pin': pin,
          }
        : {
            'nik': _nikController.text.trim(),
            'nama_lengkap': _namaController.text.trim(),
            'jenis_kelamin': _jenisKelamin,
            'no_absen': _noAbsenController.text.trim().isNotEmpty
                ? int.tryParse(_noAbsenController.text.trim())
                : null,
            'jilid': _jilid,
            'alamat': _alamatController.text.trim(),
            'nama_wali': _namaWaliController.text.trim(),
            'no_telp_wali': _noTelpWaliController.text.trim(),
            'email_wali': _emailWaliController.text.trim(),
            'tgl_mendaftar': _tglMendaftar.toIso8601String().split('T')[0],
            'is_subsidi': _isSubsidi,
            'pin': pin,
          };

    final santriProv = context.read<SantriProvider>();
    final result = _isEdit
        ? await santriProv.updateSantri(_editId!, data)
        : await santriProv.addSantri(data);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['pesan'] ?? 'Berhasil'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['pesan'] ?? 'Gagal'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nikController.dispose();
    _namaController.dispose();
    _noAbsenController.dispose();
    _alamatController.dispose();
    _namaWaliController.dispose();
    _noTelpWaliController.dispose();
    _emailWaliController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isPengajar = user?.isPengajar ?? false;
    final isPengajarEditOnly = isPengajar && _isEdit;
    final isPengajarBlockedFromCreate = isPengajar && !_isEdit;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Santri' : 'Tambah Santri'),
      ),
      body: SafeArea(
        top: false,
        child: _isLoading && _isEdit
            ? const Center(child: CircularProgressIndicator())
            : isPengajarBlockedFromCreate
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock_outline,
                                size: 48,
                                color: AppColors.warning,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Mode Pengajar',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Pengajar hanya dapat mengubah Jilid santri yang sudah ada.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Kembali'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isPengajarEditOnly) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withAlpha(20),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.warning.withAlpha(60)),
                              ),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline, color: AppColors.warning),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Mode Pengajar: hanya field Jilid yang dapat diubah.',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          TextFormField(
                            controller: _noAbsenController,
                            decoration: const InputDecoration(
                              labelText: 'No. Absen',
                              prefixIcon: Icon(Icons.tag),
                            ),
                            keyboardType: TextInputType.number,
                            enabled: !isPengajarEditOnly,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nikController,
                            decoration: const InputDecoration(
                              labelText: 'NIK (16 digit)',
                              prefixIcon: Icon(Icons.credit_card),
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 16,
                            enabled: !_isEdit && !isPengajarEditOnly,
                            validator: (v) {
                              if (isPengajarEditOnly) return null;
                              if (v == null || v.trim().isEmpty) return 'NIK wajib diisi';
                              if (v.trim().length != 16) return 'NIK harus 16 digit';
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _namaController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Lengkap',
                              prefixIcon: Icon(Icons.person),
                            ),
                            enabled: !isPengajarEditOnly,
                            validator: (v) {
                              if (isPengajarEditOnly) return null;
                              return v == null || v.trim().isEmpty
                                  ? 'Nama wajib diisi'
                                  : null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _jenisKelamin.isEmpty ? null : _jenisKelamin,
                            decoration: const InputDecoration(
                              labelText: 'Jenis Kelamin',
                              prefixIcon: Icon(Icons.wc),
                            ),
                            items: jenisKelaminOptions
                                .map((j) => DropdownMenuItem(value: j, child: Text(j)))
                                .toList(),
                            onChanged: isPengajarEditOnly
                                ? null
                                : (v) => setState(() => _jenisKelamin = v ?? ''),
                            validator: (v) {
                              if (isPengajarEditOnly) return null;
                              return v == null || v.isEmpty
                                  ? 'Jenis kelamin wajib dipilih'
                                  : null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _jilid,
                            decoration: const InputDecoration(
                              labelText: 'Jilid/Kelas',
                              prefixIcon: Icon(Icons.book),
                            ),
                            items: jilidOptions
                                .map((j) => DropdownMenuItem(value: j, child: Text(j)))
                                .toList(),
                            onChanged: (v) => setState(() => _jilid = v ?? 'Jilid 1'),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.calendar_today),
                            title: const Text('Tanggal Mendaftar'),
                            subtitle: Text(
                              '${_tglMendaftar.day}/${_tglMendaftar.month}/${_tglMendaftar.year}',
                            ),
                            onTap: isPengajarEditOnly
                                ? null
                                : () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _tglMendaftar,
                                      firstDate: DateTime(2010),
                                      lastDate: DateTime.now(),
                                    );
                                    if (date != null) {
                                      setState(() => _tglMendaftar = date);
                                    }
                                  },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _alamatController,
                            decoration: const InputDecoration(
                              labelText: 'Alamat',
                              prefixIcon: Icon(Icons.home),
                            ),
                            maxLines: 2,
                            enabled: !isPengajarEditOnly,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _namaWaliController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Wali',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            enabled: !isPengajarEditOnly,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _noTelpWaliController,
                            decoration: const InputDecoration(
                              labelText: 'No. Telp Wali',
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                            enabled: !isPengajarEditOnly,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailWaliController,
                            decoration: const InputDecoration(
                              labelText: 'Email Wali',
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            enabled: !isPengajarEditOnly,
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Status Subsidi'),
                            subtitle: const Text('Aktifkan jika santri mendapat subsidi'),
                            value: _isSubsidi,
                            onChanged: isPengajarEditOnly
                                ? null
                                : (v) => setState(() => _isSubsidi = v),
                            activeThumbColor: AppColors.primary,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isPengajarEditOnly
                                        ? 'Simpan Jilid'
                                        : _isEdit
                                            ? 'Simpan Perubahan'
                                            : 'Daftarkan Santri',
                                    style: const TextStyle(fontSize: 16),
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
