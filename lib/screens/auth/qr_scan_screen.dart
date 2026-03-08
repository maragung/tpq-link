import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
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

    // Support both QR schemes:
    //   tpqlink://qr-exchange  → one-time nonce (new, secure)
    //   tpqlink://login        → direct token   (legacy / app-login deep link)
    if (!value.startsWith('tpqlink://')) return;

    setState(() => _isProcessing = true);

    if (value.startsWith('tpqlink://qr-exchange')) {
      _handleNonceExchange(value);
    } else if (value.startsWith('tpqlink://login')) {
      _handleDirectTokenLogin(value);
    } else {
      _showError('QR code tidak dikenal');
    }
  }

  /// New secure flow: exchange a one-time nonce for a 30-day token.
  Future<void> _handleNonceExchange(String deepLink) async {
    final uri = Uri.tryParse(deepLink);
    if (uri == null) { _showError('QR code tidak valid'); return; }

    final nonce     = uri.queryParameters['nonce'];
    final serverUrl = uri.queryParameters['server'];

    if (nonce == null || nonce.isEmpty) {
      _showError('Nonce tidak ditemukan pada QR code');
      return;
    }
    if (serverUrl == null || serverUrl.isEmpty) {
      _showError('Alamat server tidak ditemukan pada QR code');
      return;
    }

    _showLoading();

    // Set server URL before calling exchange
    await ApiService.setServerUrl(serverUrl);
    ApiConfig.serverUrl = serverUrl;

    final result = await ApiService.post(
      ApiConfig.qrExchangeUrl,
      body: {'nonce': nonce},
    );

    if (!mounted) return;
    Navigator.pop(context); // close loading dialog

    if (result['success'] == true) {
      final data  = result['data'];
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        _showError('Token tidak ditemukan dalam respons server');
        return;
      }
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final ok   = await auth.loginWithToken(token, serverUrl);
      if (mounted) {
        if (ok) {
          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false);
        } else {
          _showError(auth.error ?? 'Login gagal');
        }
      }
    } else {
      _showError(result['pesan'] as String? ?? 'QR exchange gagal');
    }
  }

  /// Legacy direct-token flow (used by app-login deep links).
  Future<void> _handleDirectTokenLogin(String deepLink) async {
    final uri = Uri.tryParse(deepLink);
    if (uri == null) { _showError('QR code tidak valid'); return; }

    final token     = uri.queryParameters['token'];
    final serverUrl = uri.queryParameters['server'];

    if (token == null || token.isEmpty) {
      _showError('Token tidak ditemukan pada QR code');
      return;
    }

    _showLoading();
    final auth    = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.loginWithToken(token, serverUrl ?? '');

    if (mounted) {
      Navigator.pop(context);
      if (success) {
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false);
      } else {
        _showError(auth.error ?? 'Login gagal');
      }
    }
  }

  void _showLoading() {
    if (!mounted) return;
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
