import 'package:flutter/material.dart';
import '../services/biometric_service.dart';
import '../utils/constants.dart';

/// Shows a PIN entry dialog. If [allowBiometric] is true and the device has
/// biometric set up, a fingerprint button lets the user decrypt and submit
/// the stored PIN without typing.
///
/// Returns the PIN string on success, or null if cancelled.
Future<String?> showPinDialog(
  BuildContext context, {
  String title = 'Verifikasi PIN',
  bool allowBiometric = true,
}) async {
  // Check biometric availability before building the dialog
  final biometricAvailable =
      allowBiometric && await BiometricService.isEnabled();

  if (!context.mounted) return null;

  final pinController = TextEditingController();

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _PinDialog(
      title: title,
      pinController: pinController,
      biometricAvailable: biometricAvailable,
    ),
  );
}

class _PinDialog extends StatefulWidget {
  final String title;
  final TextEditingController pinController;
  final bool biometricAvailable;

  const _PinDialog({
    required this.title,
    required this.pinController,
    required this.biometricAvailable,
  });

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  bool _loadingBiometric = false;

  Future<void> _useBiometric() async {
    setState(() => _loadingBiometric = true);
    final pin = await BiometricService.authenticateAndGetPin(
      reason: 'Verifikasi untuk melanjutkan aksi',
    );
    if (!mounted) return;
    setState(() => _loadingBiometric = false);

    if (pin != null && pin.isNotEmpty) {
      Navigator.of(context).pop(pin);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Autentikasi biometrik gagal. Coba masukkan PIN manual.'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Masukkan PIN 6 digit untuk melanjutkan',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.pinController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            obscureText: true,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
            decoration: InputDecoration(
              hintText: '••••••',
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            autofocus: !widget.biometricAvailable,
          ),
          if (widget.biometricAvailable) ...[
            const SizedBox(height: 12),
            _loadingBiometric
                ? const SizedBox(
                    height: 32,
                    width: 32,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton.icon(
                    onPressed: _useBiometric,
                    icon: const Icon(Icons.fingerprint, size: 22),
                    label: const Text('Gunakan Sidik Jari'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                    ),
                  ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            final pin = widget.pinController.text.trim();
            if (pin.length == 6) {
              Navigator.pop(context, pin);
            }
          },
          child: const Text('Konfirmasi'),
        ),
      ],
    );
  }
}
