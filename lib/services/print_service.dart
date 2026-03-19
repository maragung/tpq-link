import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/helpers.dart';

class PrintService {
  static Future<void> printReceipt({
    required String namaSantri,
    required String nik,
    required String tanggal,
    required int nominal,
    required String bulan,
    required String admin,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Optimized for thermal printers but works for A4/A5
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('TPQ FUTUHIL HIDAYAH', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    pw.Text('WAL HIKMAH', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.Text('Kwitansi Pembayaran SPP', style: pw.TextStyle(fontSize: 10)),
                    pw.Divider(),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              _item('Tanggal', tanggal),
              _item('Nama', namaSantri),
              _item('NIK', nik),
              _item('Bulan', bulan),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(formatCurrency(nominal), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text('Status: LUNAS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Penerima,', style: pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 30),
                      pw.Text(admin, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: 'TPQ-LINK-RECEIPT-$nik-$tanggal',
                    width: 40,
                    height: 40,
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text('Terima kasih atas dukungannya.', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Kwitansi-$namaSantri-$bulan.pdf',
    );
  }

  static pw.Widget _item(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 60, child: pw.Text(label, style: const pw.TextStyle(fontSize: 10))),
          pw.Text(': ', style: const pw.TextStyle(fontSize: 10)),
          pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
        ],
      ),
    );
  }
}
