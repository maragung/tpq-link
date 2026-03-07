import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final value = barcode.rawValue!;
    if (!value.startsWith('tpqlink://login')) return;

    setState(() => _isProcessing = true);
    _handleQRLogin(value);
  }

  Future<void> _handleQRLogin(String deepLink) async {
    final uri = Uri.tryParse(deepLink);
    if (uri == null) {
      _showError('QR Code tidak valid');
      return;
    }

    final token = uri.queryParameters['token'];
    final serverUrl = uri.queryParameters['server'];

    if (token == null || token.isEmpty) {
      _showError('Token tidak ditemukan pada QR Code');
      return;
    }

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memproses login...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.loginWithToken(token, serverUrl ?? '');

    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      if (success) {
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false);
      } else {
        _showError(auth.error ?? 'Login gagal');
      }
    }
  }

  void _showError(String message) {
    setState(() => _isProcessing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                ),
                // Overlay
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code, size: 32, color: AppColors.primary),
                  const SizedBox(height: 8),
                  Text(
                    'Arahkan kamera ke QR Code\nyang ditampilkan di halaman admin',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
