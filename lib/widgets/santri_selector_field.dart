import 'package:flutter/material.dart';

import '../models/pembayaran.dart';
import '../models/santri.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class SantriSelectorField extends StatelessWidget {
  final List<StatusPembayaran> santriList;
  final int? value;
  final String labelText;
  final String hintText;
  final String? helperText;
  final String? fallbackName;
  final ValueChanged<StatusPembayaran> onSelected;
  final VoidCallback? onCleared;

  const SantriSelectorField({
    super.key,
    required this.santriList,
    required this.value,
    required this.onSelected,
    this.labelText = 'Pilih Santri',
    this.hintText = 'Cari no. absen atau nama santri',
    this.helperText,
    this.fallbackName,
    this.onCleared,
  });

  StatusPembayaran? get _selectedSantri {
    if (value == null) return null;
    for (final santri in santriList) {
      if (santri.id == value) return santri;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selectedSantri = _selectedSantri;
    final hasValue =
        selectedSantri != null || (fallbackName?.isNotEmpty ?? false);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final selected = await _showSelectorSheet(context);
        if (selected != null) onSelected(selected);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          helperText: helperText,
          prefixIcon: const Icon(Icons.person_search_outlined),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasValue && onCleared != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onCleared,
                  tooltip: 'Hapus pilihan',
                ),
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.expand_more),
              ),
            ],
          ),
        ),
        isEmpty: !hasValue,
        child: selectedSantri == null
            ? Text(
                fallbackName?.isNotEmpty == true ? fallbackName! : hintText,
                style: TextStyle(
                  color: hasValue
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 14,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedSantri.namaLengkap,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _buildSubtitle(selectedSantri),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<StatusPembayaran?> _showSelectorSheet(BuildContext context) async {
    final searchController = TextEditingController();
    String query = '';

    final selected = await showModalBottomSheet<StatusPembayaran>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool sortByAbsen = true;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = santriList.where((santri) {
              if (query.isEmpty) return true;
              final normalized = query.toLowerCase();
              final noAbsen = santri.noAbsen?.toString() ?? '';
              return santri.namaLengkap.toLowerCase().contains(normalized) ||
                  noAbsen.contains(normalized);
            }).toList()
              ..sort((a, b) {
                if (sortByAbsen) {
                  final aNo = a.noAbsen ?? 999999;
                  final bNo = b.noAbsen ?? 999999;
                  final noCompare = aNo.compareTo(bNo);
                  if (noCompare != 0) return noCompare;
                }
                return a.namaLengkap
                    .toLowerCase()
                    .compareTo(b.namaLengkap.toLowerCase());
              });

            return SafeArea(
              top: false,
              child: DraggableScrollableSheet(
                initialChildSize: 0.82,
                minChildSize: 0.52,
                maxChildSize: 0.95,
                expand: false,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pilih Santri',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${filtered.length} santri tersedia',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: searchController,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: hintText,
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: query.isEmpty
                                      ? null
                                      : IconButton(
                                          icon:
                                              const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            searchController.clear();
                                            setModalState(() => query = '');
                                          },
                                        ),
                                ),
                                onChanged: (value) {
                                  setModalState(() => query = value.trim());
                                },
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Text(
                                    'Urut:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _SortChip(
                                    label: 'No. Absen',
                                    selected: sortByAbsen,
                                    onTap: () => setModalState(() => sortByAbsen = true),
                                  ),
                                  const SizedBox(width: 6),
                                  _SortChip(
                                    label: 'Nama',
                                    selected: !sortByAbsen,
                                    onTap: () => setModalState(() => sortByAbsen = false),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: filtered.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                      'Santri tidak ditemukan.',
                                      style: TextStyle(
                                          color: AppColors.textSecondary),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  controller: scrollController,
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final santri = filtered[index];
                                    final isSelected = santri.id == value;

                                    return Material(
                                      color: isSelected
                                          ? AppColors.primary.withAlpha(18)
                                          : AppColors.background,
                                      borderRadius: BorderRadius.circular(18),
                                      child: ListTile(
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                            color: isSelected
                                                ? AppColors.primary
                                                    .withAlpha(90)
                                                : AppColors.border,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 6,
                                        ),
                                        leading: CircleAvatar(
                                          backgroundColor: isSelected
                                              ? AppColors.primary.withAlpha(32)
                                              : Colors.white,
                                          child: Text(
                                            santri.noAbsen?.toString() ?? '#',
                                            style: TextStyle(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.textSecondary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          santri.namaLengkap,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        subtitle: Text(
                                          _buildSubtitle(santri),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        trailing: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              formatCurrency(santri.nominalSpp),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Icon(
                                              isSelected
                                                  ? Icons.check_circle
                                                  : Icons.chevron_right,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.textSecondary,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                        onTap: () =>
                                            Navigator.pop(context, santri),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );

    searchController.dispose();
    return selected;
  }

  String _buildSubtitle(StatusPembayaran santri) {
    final parts = <String>[
      if (santri.noAbsen != null) 'No. ${santri.noAbsen}',
      santri.jilid ?? '-',
      santri.isSubsidi ? 'Subsidi' : 'Non Subsidi',
    ];
    return parts.join(' • ');
  }
}

class BasicSantriSelectorField extends StatelessWidget {
  final List<Santri> santriList;
  final int? value;
  final String labelText;
  final String hintText;
  final String? helperText;
  final ValueChanged<Santri> onSelected;
  final VoidCallback? onCleared;

  const BasicSantriSelectorField({
    super.key,
    required this.santriList,
    required this.value,
    required this.onSelected,
    this.labelText = 'Pilih Santri',
    this.hintText = 'Cari no. absen atau nama santri',
    this.helperText,
    this.onCleared,
  });

  Santri? get _selectedSantri {
    if (value == null) return null;
    for (final santri in santriList) {
      if (santri.id == value) return santri;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selectedSantri = _selectedSantri;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final selected = await _showSelectorSheet(context);
        if (selected != null) onSelected(selected);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          helperText: helperText,
          prefixIcon: const Icon(Icons.person_search_outlined),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedSantri != null && onCleared != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onCleared,
                  tooltip: 'Hapus pilihan',
                ),
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.expand_more),
              ),
            ],
          ),
        ),
        isEmpty: selectedSantri == null,
        child: selectedSantri == null
            ? const Text(
                'Cari no. absen atau nama santri',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedSantri.namaLengkap,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _buildSubtitle(selectedSantri),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<Santri?> _showSelectorSheet(BuildContext context) async {
    final searchController = TextEditingController();
    String query = '';

    final selected = await showModalBottomSheet<Santri>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool sortByAbsen = true;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = santriList.where((santri) {
              if (query.isEmpty) return true;
              final normalized = query.toLowerCase();
              final noAbsen = santri.noAbsen?.toString() ?? '';
              return santri.namaLengkap.toLowerCase().contains(normalized) ||
                  noAbsen.contains(normalized);
            }).toList()
              ..sort((a, b) {
                if (sortByAbsen) {
                  final aNo = a.noAbsen ?? 999999;
                  final bNo = b.noAbsen ?? 999999;
                  final noCompare = aNo.compareTo(bNo);
                  if (noCompare != 0) return noCompare;
                }
                return a.namaLengkap
                    .toLowerCase()
                    .compareTo(b.namaLengkap.toLowerCase());
              });

            return SafeArea(
              top: false,
              child: DraggableScrollableSheet(
                initialChildSize: 0.82,
                minChildSize: 0.52,
                maxChildSize: 0.95,
                expand: false,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pilih Santri',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${filtered.length} santri tersedia',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: searchController,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: hintText,
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: query.isEmpty
                                      ? null
                                      : IconButton(
                                          icon:
                                              const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            searchController.clear();
                                            setModalState(() => query = '');
                                          },
                                        ),
                                ),
                                onChanged: (value) {
                                  setModalState(() => query = value.trim());
                                },
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Text(
                                    'Urut:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _SortChip(
                                    label: 'No. Absen',
                                    selected: sortByAbsen,
                                    onTap: () => setModalState(() => sortByAbsen = true),
                                  ),
                                  const SizedBox(width: 6),
                                  _SortChip(
                                    label: 'Nama',
                                    selected: !sortByAbsen,
                                    onTap: () => setModalState(() => sortByAbsen = false),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: filtered.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                      'Santri tidak ditemukan.',
                                      style: TextStyle(
                                          color: AppColors.textSecondary),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  controller: scrollController,
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final santri = filtered[index];
                                    final isSelected = santri.id == value;

                                    return Material(
                                      color: isSelected
                                          ? AppColors.primary.withAlpha(18)
                                          : AppColors.background,
                                      borderRadius: BorderRadius.circular(18),
                                      child: ListTile(
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                            color: isSelected
                                                ? AppColors.primary
                                                    .withAlpha(90)
                                                : AppColors.border,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 6,
                                        ),
                                        leading: CircleAvatar(
                                          backgroundColor: isSelected
                                              ? AppColors.primary.withAlpha(32)
                                              : Colors.white,
                                          child: Text(
                                            santri.noAbsen?.toString() ?? '#',
                                            style: TextStyle(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.textSecondary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          santri.namaLengkap,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        subtitle: Text(
                                          _buildSubtitle(santri),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        trailing: Icon(
                                          isSelected
                                              ? Icons.check_circle
                                              : Icons.chevron_right,
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                          size: 18,
                                        ),
                                        onTap: () =>
                                            Navigator.pop(context, santri),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );

    searchController.dispose();
    return selected;
  }

  String _buildSubtitle(Santri santri) {
    final parts = <String>[
      if (santri.noAbsen != null) 'No. ${santri.noAbsen}',
      santri.jilid ?? '-',
      santri.isSubsidi ? 'Subsidi' : 'Non Subsidi',
    ];
    return parts.join(' • ');
  }
}

/// Tiny toggle chip used in the santri selector bottom sheet sort bar.
class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
