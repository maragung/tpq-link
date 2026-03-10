import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/prestasi_santri.dart';
import '../../models/santri.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_ui.dart';

class PrestasiSantriScreen extends StatefulWidget {
  final bool embedded;

  const PrestasiSantriScreen({super.key, this.embedded = false});

  @override
  State<PrestasiSantriScreen> createState() => _PrestasiSantriScreenState();
}

class _PrestasiSantriScreenState extends State<PrestasiSantriScreen> {
  final _searchController = TextEditingController();
  final _suratController = TextEditingController();
  final _halamanController = TextEditingController();
  final _parafController = TextEditingController();
  final _keteranganController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  int _tahun = DateTime.now().year;
  String _bulan = '';
  String _search = '';
  int? _editingId;
  int? _selectedSantriId;
  DateTime _tanggal = DateTime.now();
  String _jilid = '';
  List<Santri> _santriList = [];
  List<PrestasiSantri> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      _parafController.text = user?.namaLengkap ?? '';
      _fetch();
    });
    _searchController.addListener(() {
      setState(() => _search = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _suratController.dispose();
    _halamanController.dispose();
    _parafController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);

    final santriResult = await ApiService.get(
      ApiConfig.santriUrl,
      queryParams: {'status': 'aktif', 'limit': '500'},
    );
    final prestasiResult = await ApiService.get(
      ApiConfig.prestasiSantriUrl,
      queryParams: {
        'tahun': '$_tahun',
        if (_bulan.isNotEmpty) 'bulan': _bulan,
      },
    );

    if (!mounted) return;

    if (santriResult['success'] == true) {
      final data = santriResult['data'] as List? ?? [];
      _santriList = data.map((e) => Santri.fromJson(Map<String, dynamic>.from(e))).toList();
    }

    if (prestasiResult['success'] == true) {
      final data = prestasiResult['data'] as List? ?? [];
      _items = data.map((e) => PrestasiSantri.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      _showMessage(prestasiResult['pesan'] ?? 'Gagal memuat buku prestasi santri', false);
    }

    setState(() => _loading = false);
  }

  List<PrestasiSantri> get _filteredItems {
    if (_search.isEmpty) return _items;
    return _items.where((e) {
      final text = [
        e.santriNama,
        e.santriJilid,
        e.judulPrestasi,
        e.halaman,
        e.ustNama,
        e.paraf,
        e.keterangan,
      ].whereType<String>().join(' ').toLowerCase();
      return text.contains(_search);
    }).toList();
  }

  void _onSelectSantri(int? id) {
    final santri = _santriList.where((e) => e.id == id).cast<Santri?>().firstOrNull;
    setState(() {
      _selectedSantriId = id;
      _jilid = santri?.jilid ?? '';
    });
  }

  void _resetForm() {
    final user = context.read<AuthProvider>().user;
    setState(() {
      _editingId = null;
      _selectedSantriId = null;
      _tanggal = DateTime.now();
      _jilid = '';
      _suratController.clear();
      _halamanController.clear();
      _keteranganController.clear();
      _parafController.text = user?.namaLengkap ?? '';
    });
  }

  void _startEdit(PrestasiSantri item) {
    setState(() {
      _editingId = item.id;
      _selectedSantriId = item.santriId;
      _tanggal = DateTime.tryParse(item.tanggal) ?? DateTime.now();
      _jilid = item.jilid ?? item.santriJilid ?? '';
      _suratController.text = item.judulPrestasi ?? '';
      _halamanController.text = item.halaman ?? '';
      _parafController.text = item.paraf ?? item.ustNama;
      _keteranganController.text = item.keterangan ?? '';
    });
  }

  Future<void> _submit() async {
    if (_selectedSantriId == null) {
      _showMessage('Nama santri wajib dipilih', false);
      return;
    }
    if (_suratController.text.trim().isEmpty && _halamanController.text.trim().isEmpty) {
      _showMessage('Isi minimal Surat Pendek / Doa Harian atau Halaman Buku Prestasi Jilid', false);
      return;
    }

    setState(() => _saving = true);
    final payload = {
      'santri_id': _selectedSantriId,
      'tanggal': _tanggal.toIso8601String().split('T')[0],
      'jilid': _jilid,
      'judul_prestasi': _suratController.text.trim(),
      'halaman': _halamanController.text.trim(),
      'paraf': _parafController.text.trim(),
      'keterangan': _keteranganController.text.trim(),
    };

    final result = _editingId == null
        ? await ApiService.post(ApiConfig.prestasiSantriUrl, body: payload)
        : await ApiService.put(ApiConfig.prestasiSantriDetailUrl(_editingId), body: payload);

    if (!mounted) return;
    setState(() => _saving = false);

    _showMessage(result['pesan'] ?? (_editingId == null ? 'Berhasil menambah catatan' : 'Berhasil memperbarui catatan'), result['success'] == true);
    if (result['success'] == true) {
      _resetForm();
      await _fetch();
    }
  }

  Future<void> _delete(PrestasiSantri item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Catatan Prestasi'),
        content: Text('Hapus catatan ${item.santriNama}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ApiService.delete(ApiConfig.prestasiSantriDetailUrl(item.id));
    if (!mounted) return;
    _showMessage(result['pesan'] ?? 'Catatan dihapus', result['success'] == true);
    if (result['success'] == true) {
      if (_editingId == item.id) _resetForm();
      await _fetch();
    }
  }

  void _showMessage(String message, bool success) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.success : AppColors.danger,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final bulanOptions = List.generate(12, (i) => i + 1);

    return SafeArea(
      top: false,
      child: RefreshIndicator(
        onRefresh: _fetch,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppFilterCard(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSectionHeader(
                      title: 'Buku Prestasi Santri',
                      subtitle: 'Catat Surat Pendek & Doa Harian atau Halaman Buku Prestasi Jilid santri.',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _tahun,
                            decoration: const InputDecoration(labelText: 'Tahun'),
                            items: List.generate(6, (i) {
                              final year = DateTime.now().year - i;
                              return DropdownMenuItem(value: year, child: Text('$year'));
                            }),
                            onChanged: (v) async {
                              if (v != null) {
                                setState(() => _tahun = v);
                                await _fetch();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _bulan.isEmpty ? '' : _bulan,
                            decoration: const InputDecoration(labelText: 'Bulan'),
                            items: [
                              const DropdownMenuItem(value: '', child: Text('Semua')),
                              ...bulanOptions.map((b) => DropdownMenuItem(
                                    value: b.toString().padLeft(2, '0'),
                                child: Text(namaBulan(b)),
                                  )),
                            ],
                            onChanged: (v) async {
                              setState(() => _bulan = v ?? '');
                              await _fetch();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Cari catatan',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _editingId == null ? 'Tambah Catatan' : 'Edit Catatan',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ust otomatis: ${user?.namaLengkap ?? '-'}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedSantriId,
                      decoration: const InputDecoration(
                        labelText: 'Nama Santri',
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: _santriList
                          .map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text('${s.noAbsen != null ? '${s.noAbsen}. ' : ''}${s.namaLengkap} (${s.jilid ?? '-'})'),
                              ))
                          .toList(),
                      onChanged: _onSelectSantri,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.calendar_today),
                            title: const Text('Tanggal'),
                            subtitle: Text(formatDate(_tanggal.toIso8601String())),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _tanggal,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) setState(() => _tanggal = date);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: _jilid,
                            key: ValueKey('jilid_${_selectedSantriId ?? 0}_$_editingId'),
                            decoration: const InputDecoration(
                              labelText: 'Jilid',
                              prefixIcon: Icon(Icons.menu_book),
                            ),
                            onChanged: (v) => _jilid = v,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _suratController,
                      decoration: const InputDecoration(
                        labelText: 'Surat Pendek / Doa Harian',
                        prefixIcon: Icon(Icons.auto_stories),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _halamanController,
                      decoration: const InputDecoration(
                        labelText: 'Halaman Buku Prestasi Jilid',
                        prefixIcon: Icon(Icons.book),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _parafController,
                      decoration: const InputDecoration(
                        labelText: 'Paraf',
                        prefixIcon: Icon(Icons.draw),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _keteranganController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Keterangan',
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (_editingId != null)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _resetForm,
                              child: const Text('Batal'),
                            ),
                          ),
                        if (_editingId != null) const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving ? null : _submit,
                            child: Text(_saving ? 'Menyimpan...' : _editingId == null ? 'Tambah Catatan' : 'Simpan Perubahan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ))
            else if (_filteredItems.isEmpty)
              const AppEmptyState(
                icon: Icons.menu_book_outlined,
                title: 'Belum ada catatan prestasi',
                subtitle: 'Tambahkan catatan baru untuk mulai mengisi buku prestasi santri.',
              )
            else
              ..._filteredItems.map((item) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        item.santriNama,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Tanggal: ${formatDate(item.tanggal)}\nJilid: ${item.jilid ?? item.santriJilid ?? '-'}\nSurat/Doa: ${item.judulPrestasi ?? '-'}\nHalaman: ${item.halaman ?? '-'}\nUst: ${item.ustNama}\nParaf: ${item.paraf ?? '-'}\nKeterangan: ${item.keterangan ?? '-'}',
                        ),
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _startEdit(item);
                          } else if (value == 'hapus') {
                            _delete(item);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildContent(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buku Prestasi Santri'),
        actions: [
          IconButton(
            onPressed: _fetch,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildContent(context),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
