import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/table_model.dart';
import '../services/table_service.dart';

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
      final qr = await svc.getTableQr(widget.tableId);
      final model = TableModel.fromEntity(entity, qrFromApi: qr);
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

  Future<void> _goEdit(String id) async {
    final ok = await Navigator.pushNamed(
      context,
      '/admin/tables/edit',
      arguments: id,
    );
    if (!mounted) return;
    if (ok == true) {
      await _refresh(); // ✅ sau edit xong, load lại detail ngay
      // Optionally: trả true lên List nếu user “back” khỏi Detail sau đó
      // (không bắt buộc, vì list đã tự reload khi quay lại trước đó)
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _model;

    return Scaffold(
      appBar: AppBar(title: const Text('Table Detail')),
      body: _loading && m == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (m?.title ?? 'Table #${widget.tableId}'),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      FilledButton.icon(
                        onPressed: () => _goEdit(m?.id ?? widget.tableId),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Info('Status', m?.status ?? '—'),
                  _Info('Capacity', m?.capacity?.toString() ?? '—'),
                  _Info('Location', m?.location ?? '—'),
                  _Info('Description', m?.description ?? '—'),
                  const SizedBox(height: 16),
                  Text(
                    'QR Code',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _QrViewer(qr: m?.qrUrl),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

class _QrViewer extends StatelessWidget {
  final String? qr; // http/https | data-url | base64 | null
  const _QrViewer({required this.qr});

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (qr == null || qr!.isEmpty) {
      child = _placeholder();
    } else if (qr!.startsWith('data:image')) {
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
      color: Colors.black12,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Text('No QR image'),
  );
}

class _Info extends StatelessWidget {
  final String label;
  final String value;
  const _Info(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(value),
    );
  }
}
