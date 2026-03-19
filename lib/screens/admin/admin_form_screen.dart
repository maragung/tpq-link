import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../widgets/pin_dialog.dart';

class AdminFormScreen extends StatefulWidget {
  const AdminFormScreen({super.key});

  @override
  State<AdminFormScreen> createState() => _AdminFormScreenState();
}

class _AdminFormScreenState extends State<AdminFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  String _jabatan = 'Pengajar';
  bool _loading = false;
  int? _id;

  final List<String> _jabatanOptions = [
    'Pimpinan TPQ',
    'Sekretaris',
    'Bendahara',
    'Pengajar',
    'Developer'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _id == null) {
      _id = args['id'];
      _namaController.text = args['nama_lengkap'] ?? '';
      _usernameController.text = args['username'] ?? '';
      _emailController.text = args['email'] ?? '';
      _jabatan = args['jabatan'] ?? 'Pengajar';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final pin = await showPinDialog(context);
    if (pin == null || !mounted) return;

    setState(() => _loading = true);
    
    final body = {
      'nama_lengkap': _namaController.text.trim(),
      'username': _usernameController.text.trim(),
      'email': _emailController.text.trim(),
      'jabatan': _jabatan,
      'pin': pin,
    };
    if (_passwordController.text.isNotEmpty) {
      body['password'] = _passwordController.text;
    }

    final result = _id == null
        ? await ApiService.post('${ApiConfig.baseUrl}/admin/kelola', body: body)
        : await ApiService.put('${ApiConfig.baseUrl}/admin/kelola/$_id', body: body);

    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['pesan'] ?? 'Berhasil simpan'),
          backgroundColor: result['success'] == true ? AppColors.success : AppColors.danger,
        ),
      );
      if (result['success'] == true) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_id == null ? 'Tambah Admin' : 'Edit Admin')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => v == null || v.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.badge_outlined)),
                validator: (v) => v == null || v.isEmpty ? 'Username wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email (Opsional)', prefixIcon: Icon(Icons.email_outlined)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: _id == null ? 'Password' : 'Password (Kosongkan jika tidak ubah)',
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (v) => _id == null && (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _jabatan,
                decoration: const InputDecoration(labelText: 'Jabatan', prefixIcon: Icon(Icons.work_outline)),
                items: _jabatanOptions.map((j) => DropdownMenuItem(value: j, child: Text(j))).toList(),
                onChanged: (v) => setState(() => _jabatan = v!),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Simpan Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
