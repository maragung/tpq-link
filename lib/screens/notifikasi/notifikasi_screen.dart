import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

const _tabelLabel = {
  'santri': 'Santri',
  'pembayaran_spp': 'Pembayaran SPP',
  'pengeluaran': 'Pengeluaran',
  'infak_sedekah': 'Infak/Sedekah',
  'jurnal_kas': 'Jurnal Kas',
  'admins': 'Admin',
  'pengaturan': 'Pengaturan',
};

const _aksiColor = {
  'tambah': Colors.green,
  'create': Colors.green,
  'insert': Colors.green,
  'ubah': Colors.blue,
  'update': Colors.blue,
  'edit': Colors.blue,
  'hapus': Colors.red,
  'delete': Colors.red,
  'batal': Colors.red,
  'batalkan': Colors.red,
};

const _aksiLabel = {
  'tambah': 'Tambah',
  'create': 'Tambah',
  'insert': 'Tambah',
  'ubah': 'Ubah',
  'update': 'Ubah',
  'edit': 'Ubah',
  'hapus': 'Hapus',
  'delete': 'Hapus',
  'batal': 'Batalkan',
  'batalkan': 'Batalkan',
};

Color _getAksiColor(String? aksi) {
  if (aksi == null) return Colors.grey;
  final key = aksi.toLowerCase().trim();
  for (final k in _aksiColor.keys) {
    if (key.contains(k)) return _aksiColor[k]!;
  }
  return Colors.grey;
}

String _getAksiLabel(String? aksi) {
  if (aksi == null) return '-';
  final key = aksi.toLowerCase().trim();
  for (final k in _aksiLabel.keys) {
    if (key.contains(k)) return _aksiLabel[k]!;
  }
  return aksi;
}

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  int _totalPages = 1;
  Map<String, dynamic>? _selected;

  @override
  void initState() {
    super.initState();
    _fetch(1);
  }

  Future<void> _fetch(int page, {bool append = false}) async {
    if (page == 1) setState(() => _loading = true);

    final result = await ApiService.get(
      ApiConfig.notifikasiUrl,
      queryParams: {'page': '$page', 'limit': '30'},
    );

    if (mounted) {
      if (result['success'] == true) {
        final data = result['data'] as List? ?? [];
        final pagination = result['pagination'] ?? {};
        setState(() {
          _items = append ? [..._items, ...data] : data;
          _page = pagination['page'] ?? page;
          _totalPages = pagination['totalPages'] ?? 1;
          _loading = false;
          _loadingMore = false;
        });
      } else {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _loadMore() {
    if (_page < _totalPages && !_loadingMore) {
      setState(() => _loadingMore = true);
      _fetch(_page + 1, append: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetch(1),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => _fetch(1),
                child: _items.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none,
                                size: 64, color: AppColors.textSecondary),
                            SizedBox(height: 16),
                            Text('Belum ada aktivitas',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length + (_page < _totalPages ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _items.length) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: _loadingMore
                                    ? const CircularProgressIndicator()
                                    : OutlinedButton(
                                        onPressed: _loadMore,
                                        child: const Text('Muat lebih banyak'),
                                      ),
                              ),
                            );
                          }

                          final n = _items[index];
                          final aksi = n['aksi'] as String?;
                          final tabel = n['tabel'] as String?;
                          final tabelLabel =
                              _tabelLabel[tabel] ?? tabel ?? '-';
                          final aksiLabel = _getAksiLabel(aksi);
                          final aksiColor = _getAksiColor(aksi);
                          final tgl = n['tgl_backup'] as String?;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () =>
                                  setState(() => _selected = Map<String, dynamic>.from(n)),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: aksiColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: aksiColor
                                                      .withAlpha(26),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  aksiLabel,
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: aksiColor),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                tabelLabel,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            tgl != null
                                                ? formatDateTime(tgl)
                                                : '-',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color:
                                                    AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right,
                                        color: AppColors.textSecondary,
                                        size: 20),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
      ),
      // Detail bottom sheet
      bottomSheet: _selected != null ? _buildDetail(_selected!) : null,
    );
  }

  Widget _buildDetail(Map<String, dynamic> item) {
    final aksi = item['aksi'] as String?;
    final tabel = item['tabel'] as String?;
    final tabelLabel = _tabelLabel[tabel] ?? tabel ?? '-';
    final aksiLabel = _getAksiLabel(aksi);
    final aksiColor = _getAksiColor(aksi);
    final tgl = item['tgl_backup'] as String?;
    final dataSesudah = item['data_sesudah'];
    final dataSebelum = item['data_sebelum'];

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [BoxShadow(blurRadius: 16, color: Colors.black26)],
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: aksiColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$aksiLabel — $tabelLabel',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        if (tgl != null)
                          Text(formatDateTime(tgl),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selected = null),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Body
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dataSesudah != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withAlpha(51)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Data Sesudah',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green)),
                            const SizedBox(height: 8),
                            _DataTable(data: dataSesudah),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (dataSebelum != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withAlpha(51)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Data Sebelum',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red)),
                            const SizedBox(height: 8),
                            _DataTable(data: dataSebelum),
                          ],
                        ),
                      ),
                    ],
                    if (dataSesudah == null && dataSebelum == null)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Tidak ada detail data tersimpan',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _hiddenKeys = ['password', 'pin', 'password_hash'];

class _DataTable extends StatelessWidget {
  final dynamic data;
  const _DataTable({required this.data});

  @override
  Widget build(BuildContext context) {
    dynamic parsed = data;
    if (data is String) {
      try {
        // Try to decode JSON string
        // ignore: avoid_catching_errors
        parsed = (data as String).contains('{') || (data as String).contains('[')
            ? data
            : data;
      } catch (_) {
        return Text(data.toString(),
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary));
      }
    }

    if (parsed == null) {
      return const Text('null',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary));
    }

    if (parsed is Map) {
      final entries = parsed.entries
          .where((e) => !_hiddenKeys.contains(e.key.toLowerCase()))
          .toList();
      return Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(3),
        },
        children: entries.map((e) {
          return TableRow(children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text('${e.key}',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text('${e.value ?? '-'}',
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
            ),
          ]);
        }).toList(),
      );
    }

    if (parsed is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: parsed.asMap().entries.map((e) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (parsed.length > 1)
                  Text('#${e.key + 1}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                _DataTable(data: e.value),
              ],
            ),
          );
        }).toList(),
      );
    }

    return Text('$parsed',
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary));
  }
}
