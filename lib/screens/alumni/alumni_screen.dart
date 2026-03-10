import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/santri_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/pin_dialog.dart';

class AlumniScreen extends StatefulWidget {
  const AlumniScreen({super.key});

  @override
  State<AlumniScreen> createState() => _AlumniScreenState();
}

class _AlumniScreenState extends State<AlumniScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SantriProvider>().fetchAlumni();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> list) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((s) {
      final nama = (s['nama_lengkap'] ?? '').toString().toLowerCase();
      final nik = (s['nik'] ?? '').toString().toLowerCase();
      return nama.contains(q) || nik.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final santriProv = context.watch<SantriProvider>();
    final alumni = _filtered(santriProv.alumniList);
    final canManage =
        Provider.of<AuthProvider>(context, listen: false).user?.isFullAccess ??
            false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alumni / Lulus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<SantriProvider>().fetchAlumni(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
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
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            if (santriProv.alumniList.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${alumni.length} alumni',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: santriProv.alumniLoading
                  ? const Center(child: CircularProgressIndicator())
                  : alumni.isEmpty
                      ? RefreshIndicator(
                          onRefresh: () => santriProv.fetchAlumni(),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: 300,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.school_outlined,
                                        size: 64, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    const Text('Belum ada data alumni',
                                        style: TextStyle(
                                            color: AppColors.textSecondary)),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Santri yang ditandai lulus\nakan muncul di sini',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => santriProv.fetchAlumni(),
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: alumni.length,
                            itemBuilder: (context, index) {
                              final s = alumni[index];
                              final nama =
                                  s['nama_lengkap'] as String? ?? '-';
                              final nik = s['nik'] as String? ?? '-';
                              final jilid = s['jilid'] as String? ?? '-';
                              final tglLulus = s['tgl_lulus'] as String?;
                              final tglMendaftar =
                                  s['tgl_mendaftar'] as String?;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        Colors.deepPurple.withAlpha(51),
                                    child: Text(
                                      nama.isNotEmpty
                                          ? nama[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                  ),
                                  title: Text(nama,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'NIK: $nik • $jilid',
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12),
                                      ),
                                      if (tglLulus != null)
                                        Text(
                                          'Lulus: ${_formatDate(tglLulus)}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.deepPurple),
                                        )
                                      else if (tglMendaftar != null)
                                        Text(
                                          'Daftar: ${_formatDate(tglMendaftar)}',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500]),
                                        ),
                                    ],
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.withAlpha(26),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      '🎓 Alumni',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.deepPurple,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  onTap: canManage
                                      ? () => _showBatalLulus(context, s)
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const bulanList = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${dt.day} ${bulanList[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _showBatalLulus(
      BuildContext context, Map<String, dynamic> s) async {
    final nama = s['nama_lengkap'] as String? ?? '-';
    final id = s['id'];
    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan Status Lulus'),
        content: Text(
          'Batalkan status lulus santri $nama? Santri akan dikembalikan ke status Aktif.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Batalkan Lulus'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;
    final pin = await showPinDialog(context);
    if (pin == null || !context.mounted) return;

    final result =
        await context.read<SantriProvider>().batalLulusSantri(id, pin);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['pesan'] ?? 'Berhasil'),
        backgroundColor:
            result['success'] == true ? AppColors.success : AppColors.danger,
      ),
    );
  }
}
