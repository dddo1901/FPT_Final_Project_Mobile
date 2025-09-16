import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/table_model.dart';
import '../services/table_service.dart';
import '../../styles/app_theme.dart';

class TableDetailPage extends StatefulWidget {
  final String tableId;
  const TableDetailPage({super.key, required this.tableId});

  @override
  State<TableDetailPage> createState() => _TableDetailPageState();
}

class _TableDetailPageState extends State<TableDetailPage> {
  TableModel? _model; // dữ liệu hiện tại để render
  bool _loading = false; // trạng thái loading

  @override
  void initState() {
    super.initState();
    _refresh(); // load lần đầu
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final svc = context.read<TableService>();
      final entity = await svc.getTableById(widget.tableId);

      // Tạo QR URL theo format: http://localhost:3000/order?table=tableId
      final customQrUrl = 'http://localhost:3000/order?table=${widget.tableId}';

      final model = TableModel.fromEntity(entity, qrFromApi: customQrUrl);
      if (!mounted) return;
      setState(() {
        _model = model; // ✅ gán dữ liệu đã có, không để Future trong setState
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Load failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _model;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Table Detail',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.ultraLightBlue, AppTheme.surface],
            stops: [0.0, 0.3],
          ),
        ),
        child: _loading && m == null
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              )
            : RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m?.title ?? 'Table #${widget.tableId}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _InfoCard(
                            'Status',
                            m?.status ?? '—',
                            Icons.info_outline,
                            _getStatusColor(m?.status ?? ''),
                          ),
                          const SizedBox(height: 12),
                          _InfoCard(
                            'Capacity',
                            m?.capacity?.toString() ?? '—',
                            Icons.people,
                            AppTheme.info,
                          ),
                          const SizedBox(height: 12),
                          _InfoCard(
                            'Location',
                            m?.location ?? '—',
                            Icons.location_on,
                            AppTheme.warning,
                          ),
                          const SizedBox(height: 12),
                          _InfoCard(
                            'Description',
                            m?.description ?? '—',
                            Icons.description,
                            AppTheme.textMedium,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'QR Code',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _QrViewer(qr: m?.qrUrl),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'AVAILABLE':
        return AppTheme.success;
      case 'OCCUPIED':
        return AppTheme.warning;
      case 'RESERVED':
        return AppTheme.info;
      case 'MAINTENANCE':
        return AppTheme.danger;
      default:
        return AppTheme.textMedium;
    }
  }
}

class _QrViewer extends StatelessWidget {
  final String? qr; // QR URL text hoặc image
  const _QrViewer({required this.qr});

  @override
  Widget build(BuildContext context) {
    if (qr == null || qr!.isEmpty) {
      return _placeholder();
    }

    // Nếu là URL order link, tạo QR code image
    if (qr!.startsWith('http://localhost:3000/order?table=')) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          children: [
            // QR Code Image
            QrImageView(
              data: qr!,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primary,
            ),
            const SizedBox(height: 16),
            // URL Text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lightBlue,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.qr_code, color: AppTheme.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Table Order URL:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    qr!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMedium,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Xử lý QR code images như cũ
    Widget child;
    if (qr!.startsWith('data:image')) {
      // data-url → decode base64 phía sau dấu ','
      try {
        final base64Str = qr!.split(',').last;
        final bytes = base64Decode(base64Str);
        child = Image.memory(
          bytes,
          width: double.infinity,
          fit: BoxFit.contain,
        );
      } catch (_) {
        child = _placeholder();
      }
    } else if (!qr!.startsWith('http')) {
      // base64 "trần"
      try {
        final bytes = base64Decode(qr!);
        child = Image.memory(
          bytes,
          width: double.infinity,
          fit: BoxFit.contain,
        );
      } catch (_) {
        child = _placeholder();
      }
    } else {
      // http/https
      child = Image.network(qr!, width: double.infinity, fit: BoxFit.contain);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: InteractiveViewer(minScale: 0.8, maxScale: 4, child: child),
    );
  }

  Widget _placeholder() => Container(
    width: double.infinity,
    height: 200,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      gradient: AppTheme.cardHeaderGradient,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.qr_code_scanner, color: Colors.white, size: 48),
        SizedBox(height: 8),
        Text(
          'No QR image',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
