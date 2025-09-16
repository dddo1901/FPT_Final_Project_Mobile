import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TableQrWidget extends StatelessWidget {
  final String? tableId;
  final String? tableNumber;
  final double? size;
  final String baseUrl;

  const TableQrWidget({
    super.key,
    required this.tableId,
    this.tableNumber,
    this.size = 200,
    this.baseUrl = 'http://localhost:3000',
  });

  String get _qrData {
    final table = tableNumber ?? tableId ?? '';
    return '$baseUrl/order?table=$table';
  }

  @override
  Widget build(BuildContext context) {
    if (tableId == null || tableId!.isEmpty) {
      return _placeholder();
    }

    return Column(
      children: [
        // QR Code
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: QrImageView(
            data: _qrData,
            version: QrVersions.auto,
            size: size,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
            padding: const EdgeInsets.all(8),
          ),
        ),
        const SizedBox(height: 8),
        // URL text
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            _qrData,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
    width: size,
    height: size! + 50,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.black12,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.qr_code, size: 48, color: Colors.grey),
        SizedBox(height: 8),
        Text('No table ID'),
      ],
    ),
  );
}
