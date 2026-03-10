import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/santri_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/pin_dialog.dart';
import '../../widgets/skeleton_loader.dart';

enum _SantriSortBy { noAbsen, nama, tglMendaftar }

class SantriListScreen extends StatefulWidget {
  const SantriListScreen({super.key});

  @override
  State<SantriListScreen> createState() => _SantriListScreenState();
}

class _SantriListScreenState extends State<SantriListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _selectedKategori = <String>{};
  final Set<String> _selectedJilid = <String>{};
  _SantriSortBy _sortBy = _SantriSortBy.noAbsen;
  bool _sortAsc = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final santriProv = context.watch<SantriProvider>();
    final santriList = _filterSantri(santriProv.santriList);
    final jilidList = santriProv.santriList
        .map((s) => s.jilid)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort((a, b) => a.compareTo(b));

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: AppFilterCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
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
                    for (final kat in ['Subsidi', 'Non Subsidi', 'Lunas', 'Laki-laki', 'Perempuan'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(kat, style: const TextStyle(fontSize: 12)),
                          selected: _selectedKategori.contains(kat),
                          onSelected: (_) {
                            setState(() {
                              if (_selectedKategori.contains(kat)) {
                                _selectedKategori.remove(kat);
                              } else {
                                _selectedKategori.add(kat);
                              }
                            });
                          },
                          selectedColor: AppColors.primary.withAlpha(51),
                          labelStyle: TextStyle(
                            color: _selectedKategori.contains(kat)
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
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final jilid in jilidList)
                      FilterChip(
                        label: Text(jilid, style: const TextStyle(fontSize: 12)),
                        selected: _selectedJilid.contains(jilid),
                        onSelected: (_) {
                          setState(() {
                            if (_selectedJilid.contains(jilid)) {
                              _selectedJilid.remove(jilid);
                            } else {
                              _selectedJilid.add(jilid);
                            }
                          });
                        },
                        selectedColor: AppColors.secondary.withAlpha(40),
                        checkmarkColor: AppColors.secondary,
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.filter_alt_off, size: 16),
                      label: const Text('Reset', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        setState(() {
                          _selectedKategori.clear();
                          _selectedJilid.clear();
                          _sortBy = _SantriSortBy.noAbsen;
                          _sortAsc = true;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<_SantriSortBy>(
                      value: _sortBy,
                      decoration: InputDecoration(
                        labelText: 'Sortir',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: _SantriSortBy.noAbsen, child: Text('No. Absen')),
                        DropdownMenuItem(value: _SantriSortBy.nama, child: Text('Nama')),
                        DropdownMenuItem(value: _SantriSortBy.tglMendaftar, child: Text('Waktu Terdaftar')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _sortBy = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: DropdownButtonFormField<bool>(
                      value: _sortAsc,
                      decoration: InputDecoration(
                        labelText: 'Arah',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: true, child: Text('Naik')),
                        DropdownMenuItem(value: false, child: Text('Turun')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _sortAsc = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
          ),
        ),
        ),

        // Santri List
        Expanded(
          child: santriProv.loading
              ? const SkeletonList(count: 7, showSubtitle2: false)
              : santriList.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.people_outline,
                      title: 'Belum ada data santri',
                      subtitle: 'Data santri akan tampil di sini setelah berhasil ditambahkan atau dimuat dari server.',
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
                                'NIK: ${s.nik} • ${s.jilid ?? "-"}${s.jenisKelamin != null ? ' • ${s.jenisKelamin}' : ''}\nTerlunasi: ${s.bulanDibayarTotal}/${s.bulanSejakDaftarSampaiKini} • Tahun ini: ${s.bulanTerbayar}/${s.bulanWajib}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12),
                              ),
                              isThreeLine: true,
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
                                  const SizedBox(height: 4),
                                  Text(
                                    '${s.bulanDibayarTotal}/${s.bulanSejakDaftarSampaiKini}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _showSantriActions(context, s),
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

  List<dynamic> _filterSantri(List santriList) {
    var filtered = santriList.where((s) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!s.namaLengkap.toLowerCase().contains(q) &&
            !s.nik.toLowerCase().contains(q) &&
            !(s.jenisKelamin?.toLowerCase().contains(q) ?? false)) {
          return false;
        }
      }

      final subsidiFilter = _selectedKategori.where((e) => e == 'Subsidi' || e == 'Non Subsidi').toList();
      if (subsidiFilter.length == 1) {
        if (subsidiFilter.first == 'Subsidi' && !s.isSubsidi) return false;
        if (subsidiFilter.first == 'Non Subsidi' && s.isSubsidi) return false;
      }

      final genderFilter = _selectedKategori.where((e) => e == 'Laki-laki' || e == 'Perempuan').toList();
      if (genderFilter.length == 1) {
        if (genderFilter.first == 'Laki-laki' && s.jenisKelamin != 'Laki-laki') return false;
        if (genderFilter.first == 'Perempuan' && s.jenisKelamin != 'Perempuan') return false;
      }

      if (_selectedKategori.contains('Lunas') && !(s.statusAktif && s.bulanBelumBayar == 0)) {
        return false;
      }

      if (_selectedJilid.isNotEmpty && !_selectedJilid.contains(s.jilid)) {
        return false;
      }

      return true;
    }).toList();

    filtered.sort((a, b) {
      int result;
      switch (_sortBy) {
        case _SantriSortBy.noAbsen:
          result = (a.noAbsen ?? 999999).compareTo(b.noAbsen ?? 999999);
          break;
        case _SantriSortBy.tglMendaftar:
          final aDate = DateTime.tryParse(a.tglMendaftar ?? '') ?? DateTime(1970);
          final bDate = DateTime.tryParse(b.tglMendaftar ?? '') ?? DateTime(1970);
          result = aDate.compareTo(bDate);
          break;
        case _SantriSortBy.nama:
          result = a.namaLengkap.toLowerCase().compareTo(b.namaLengkap.toLowerCase());
          break;
      }
      return _sortAsc ? result : -result;
    });

    return filtered;
  }

  void _showSantriActions(BuildContext context, dynamic s) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final canManageStatus = user?.canManageSantriStatus ?? false;
    final canEditSantri = user?.canEditSantri ?? false;
    final canDeleteSantri = user?.canDeleteSantri ?? false;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: s.statusAktif
                          ? AppColors.primary.withAlpha(51)
                          : Colors.grey.withAlpha(51),
                      child: Text(
                        s.namaLengkap.isNotEmpty ? s.namaLengkap[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: s.statusAktif ? AppColors.primary : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.namaLengkap,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('${s.jilid ?? '-'} • ${s.isSubsidi ? 'Subsidi' : 'Non Subsidi'}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          if (s.jenisKelamin != null && s.jenisKelamin!.isNotEmpty)
                            Text(s.jenisKelamin!,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: s.statusAktif ? AppColors.success.withAlpha(26) : AppColors.danger.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s.statusAktif ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                          fontSize: 11,
                          color: s.statusAktif ? AppColors.success : AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Bayar SPP
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFD1FAE5),
                  child: Icon(Icons.payment, color: AppColors.primary),
                ),
                title: const Text('Bayar SPP',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Catat pembayaran SPP'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/bayar-spp',
                      arguments: {'santri_id': s.id, 'nama': s.namaLengkap});
                },
              ),
              if (canEditSantri) ...[
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFDBEAFE),
                    child: Icon(Icons.edit, color: Colors.blue),
                  ),
                  title: const Text('Edit Santri',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Ubah data santri'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/santri/tambah', arguments: s.id);
                  },
                ),
              ],
              if (canManageStatus) ...[
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: s.statusAktif
                        ? AppColors.danger.withAlpha(26)
                        : AppColors.success.withAlpha(26),
                    child: Icon(
                      s.statusAktif ? Icons.person_off : Icons.person_add,
                      color: s.statusAktif ? AppColors.danger : AppColors.success,
                    ),
                  ),
                  title: Text(
                    s.statusAktif ? 'Nonaktifkan' : 'Aktifkan Kembali',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: s.statusAktif ? AppColors.danger : AppColors.success,
                    ),
                  ),
                  subtitle: Text(s.statusAktif
                      ? 'Hentikan kewajiban SPP'
                      : 'Aktifkan kembali santri'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmStatusChange(context, s, s.statusAktif ? 'nonaktif' : 'aktifkan');
                  },
                ),
                if (s.statusAktif)
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFEF3C7),
                      child: Icon(Icons.school, color: Colors.amber),
                    ),
                    title: const Text('Luluskan',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.amber)),
                    subtitle: const Text('Tandai sebagai lulus/alumni'),
                    onTap: () {
                      Navigator.pop(context);
                      _confirmStatusChange(context, s, 'luluskan');
                    },
                  ),
              ],
              if (canDeleteSantri)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFEE2E2),
                    child: Icon(Icons.delete_outline, color: AppColors.danger),
                  ),
                  title: const Text('Hapus Santri',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: AppColors.danger)),
                  subtitle: const Text('Hapus permanen data santri'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmStatusChange(context, s, 'hapus');
                  },
                ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF3F4F6),
                  child: Icon(Icons.info_outline, color: AppColors.textSecondary),
                ),
                title: const Text('Lihat Detail',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Status pembayaran & info lengkap'),
                onTap: () {
                  Navigator.pop(context);
                  _showSantriDetail(context, s);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmStatusChange(
      BuildContext context, dynamic s, String action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(action == 'luluskan'
            ? 'Konfirmasi Kelulusan'
            : action == 'hapus'
                ? 'Hapus Santri'
            : action == 'aktifkan'
                ? 'Aktifkan Santri'
                : 'Nonaktifkan Santri'),
        content: Text(
          action == 'luluskan'
              ? 'Tandai ${s.namaLengkap} sebagai LULUS? Santri akan dipindahkan ke Alumni.'
              : action == 'hapus'
                  ? 'Hapus permanen ${s.namaLengkap}? Riwayat pembayaran, pembayaran lain, absensi, dan buku prestasi santri ini juga akan ikut terhapus.'
              : action == 'aktifkan'
                  ? 'Aktifkan kembali santri ${s.namaLengkap}?'
                  : 'Nonaktifkan santri ${s.namaLengkap}? SPP tidak lagi diwajibkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'nonaktif'
                  ? AppColors.danger
                  : action == 'luluskan'
                      ? Colors.amber
                      : AppColors.success,
            ),
            child: Text(action == 'luluskan'
                ? '🎓 Luluskan'
              : action == 'hapus'
                ? '🗑️ Hapus'
                : action == 'aktifkan'
                    ? 'Aktifkan'
                    : 'Nonaktifkan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final pin = await showPinDialog(context);
    if (pin == null || !context.mounted) return;

    final santriProv = Provider.of<SantriProvider>(context, listen: false);
    Map<String, dynamic> result;

    if (action == 'luluskan') {
      result = await santriProv.luluskanSantri(s.id, pin);
    } else if (action == 'aktifkan') {
      result = await santriProv.aktifkanSantri(s.id, pin);
    } else if (action == 'hapus') {
      result = await santriProv.deleteSantri(s.id, pin);
    } else {
      result = await santriProv.nonaktifkanSantri(s.id, pin);
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['pesan'] ?? 'Berhasil'),
        backgroundColor:
            result['success'] == true ? AppColors.success : AppColors.danger,
      ),
    );
  }

  void _showSantriDetail(BuildContext context, dynamic s) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final canManageStatus = user?.canManageSantriStatus ?? false;
    final canEditSantri = user?.canEditSantri ?? false;
    final canDeleteSantri = user?.canDeleteSantri ?? false;
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
              _DetailRow('Jenis Kelamin', s.jenisKelamin ?? '-'),
              _DetailRow('Jilid', s.jilid ?? '-'),
              if (s.noAbsen != null) _DetailRow('No. Absen', '${s.noAbsen}'),
              _DetailRow('Terlunasi', '${s.bulanDibayarTotal}/${s.bulanSejakDaftarSampaiKini} bulan'),
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

              // Action buttons
              if (canEditSantri || canManageStatus) ...[
                Row(
                  children: [
                    if (canEditSantri)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/santri/tambah',
                                arguments: s.id);
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: Text((user?.isPengajar ?? false) ? 'Ubah Jilid' : 'Edit'),
                        ),
                      ),
                    if (canEditSantri && canManageStatus) const SizedBox(width: 8),
                    if (canManageStatus)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            _confirmStatusChange(
                                context, s, s.statusAktif ? 'nonaktif' : 'aktifkan');
                          },
                          icon: Icon(
                            s.statusAktif ? Icons.person_off : Icons.person_add,
                            size: 18,
                            color: s.statusAktif ? AppColors.danger : AppColors.success,
                          ),
                          label: Text(
                            s.statusAktif ? 'Nonaktifkan' : 'Aktifkan',
                            style: TextStyle(
                                color: s.statusAktif
                                    ? AppColors.danger
                                    : AppColors.success),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: s.statusAktif
                                    ? AppColors.danger
                                    : AppColors.success),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (s.statusAktif) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmStatusChange(context, s, 'luluskan');
                          },
                          icon: const Icon(Icons.school, size: 18,
                              color: Colors.amber),
                          label: const Text('Luluskan',
                              style: TextStyle(color: Colors.amber)),
                          style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.amber)),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/bayar-spp',
                              arguments: {
                                'santri_id': s.id,
                                'nama': s.namaLengkap
                              });
                        },
                        icon: const Icon(Icons.payment, size: 18),
                        label: const Text('Bayar SPP'),
                      ),
                    ),
                  ],
                ),
                if (canDeleteSantri) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmStatusChange(context, s, 'hapus');
                      },
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: AppColors.danger),
                      label: const Text('Hapus Santri',
                          style: TextStyle(color: AppColors.danger)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                      ),
                    ),
                  ),
                ],
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/bayar-spp',
                        arguments: {'santri_id': s.id, 'nama': s.namaLengkap});
                  },
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text('Bayar SPP'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
              ],
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
