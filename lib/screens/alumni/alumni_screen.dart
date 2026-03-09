import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/santri_provider.dart';
import '../../utils/constants.dart';

class AlumniScreen extends StatelessWidget {
  const AlumniScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final santriProv = context.watch<SantriProvider>();
    final alumni = santriProv.santriList.where((s) => !s.statusAktif).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Alumni / Lulus')),
      body: SafeArea(
        top: false,
        child: alumni.isEmpty
            ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('Belum ada data alumni',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text(
                    'Santri yang sudah lulus/nonaktif\nakan muncul di sini',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => santriProv.fetchSantriStatus(),
              child: Column(
                children: [
                  // Summary
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('Total Alumni / Lulus',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          '${alumni.length} santri',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: alumni.length,
                      itemBuilder: (context, index) {
                        final s = alumni[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  Colors.deepPurple.withAlpha(51),
                              child: Text(
                                s.namaLengkap.isNotEmpty
                                    ? s.namaLengkap[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                            title: Text(s.namaLengkap,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NIK: ${s.nik} • ${s.jilid ?? "-"}',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12),
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
                                'Alumni',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ),
    );
  }
}
