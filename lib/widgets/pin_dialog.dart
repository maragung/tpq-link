import 'package:flutter/material.dart';
import '../../utils/constants.dart';

Future<String?> showPinDialog(BuildContext context, {String title = 'Verifikasi PIN'}) async {
  final pinController = TextEditingController();

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Masukkan PIN 6 digit untuk melanjutkan',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: pinController,
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
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            final pin = pinController.text.trim();
            if (pin.length == 6) {
              Navigator.pop(context, pin);
            }
          },
          child: const Text('Konfirmasi'),
        ),
      ],
    ),
  );
}
