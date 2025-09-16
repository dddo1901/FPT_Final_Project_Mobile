import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../entities/table_entity.dart';
import '../services/table_service.dart';

class TableFormPage extends StatefulWidget {
  final String? tableId; // null = create
  const TableFormPage({super.key, this.tableId});

  @override
  State<TableFormPage> createState() => _TableFormPageState();
}

class _TableFormPageState extends State<TableFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _numberC = TextEditingController();
  final _capacityC = TextEditingController();
  final _locationC = TextEditingController();
  final _descriptionC = TextEditingController();

  String _status = 'AVAILABLE';
  bool _loading = false;
  String? _qr;

  bool get _isEdit => widget.tableId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadForEdit();
  }

  @override
  void dispose() {
    _numberC.dispose();
    _capacityC.dispose();
    _locationC.dispose();
    _descriptionC.dispose();
    super.dispose();
  }

  Future<void> _loadForEdit() async {
    setState(() => _loading = true);
    try {
      final svc = context.read<TableService>();
      final e = await svc.getTableById(widget.tableId!);
      _numberC.text = (e.number ?? '').toString(); // ✅ dùng number
      _capacityC.text = (e.capacity ?? '').toString();
      _locationC.text = (e.location ?? '').toString();
      _descriptionC.text = (e.description ?? '').toString();
      _status = (e.status ?? 'AVAILABLE').toUpperCase();

      try {
        _qr = await svc.getTableQr(widget.tableId!);
      } catch (_) {}
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Load table failed: $e')));
      Navigator.pop(context, false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _posInt(String? v) {
    if (v == null || v.trim().isEmpty) return 'Cannot be empty';
    final x = int.tryParse(v);
    if (x == null || x <= 0) return 'Must be positive integer';
    return null;
  }

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final entity = TableEntity(
      id: _isEdit ? widget.tableId!.toString() : '0',
      number: int.parse(_numberC.text.trim()), // ✅ number
      capacity: int.parse(_capacityC.text.trim()),
      status: _status,
      location: _locationC.text.trim().isEmpty ? null : _locationC.text.trim(),
      description: _descriptionC.text.trim().isEmpty
          ? null
          : _descriptionC.text.trim(),
      qrCode: null,
    );

    setState(() => _loading = true);
    try {
      final svc = context.read<TableService>();
      if (_isEdit) {
        await svc.updateTable(entity.id, entity);
      } else {
        await svc.createTable(entity);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved!')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'Edit Table' : 'Create Table';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AbsorbPointer(
        absorbing: _loading,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_loading) const LinearProgressIndicator(minHeight: 2),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _numberC,
                          decoration: const InputDecoration(
                            labelText: 'Table Number',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: _posInt,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _capacityC,
                          decoration: const InputDecoration(
                            labelText: 'Capacity',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: _posInt,
                        ),
                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          value: _status,
                          items: const [
                            DropdownMenuItem(
                              value: 'AVAILABLE',
                              child: Text('AVAILABLE'),
                            ),
                            DropdownMenuItem(
                              value: 'OCCUPIED',
                              child: Text('OCCUPIED'),
                            ),
                            DropdownMenuItem(
                              value: 'RESERVED',
                              child: Text('RESERVED'),
                            ),
                            DropdownMenuItem(
                              value: 'CLEANING',
                              child: Text('CLEANING'),
                            ),
                            DropdownMenuItem(
                              value: 'INACTIVE',
                              child: Text('INACTIVE'),
                            ),
                          ],
                          onChanged: (v) => setState(
                            () => _status = (v ?? 'AVAILABLE').toUpperCase(),
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _locationC,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _descriptionC,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (_isEdit) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'QR Code',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _QrPreview(qr: _qr),
                          const SizedBox(height: 20),
                        ],

                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _onSubmit,
                                icon: const Icon(Icons.save),
                                label: const Text('Save'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.pop(context, false),
                                icon: const Icon(Icons.close),
                                label: const Text('Cancel'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrPreview extends StatelessWidget {
  final String? qr;
  const _QrPreview({required this.qr});

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (qr == null || qr!.isEmpty) {
      child = _placeholder();
    } else if (qr!.startsWith('data:image')) {
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
      child = Image.network(qr!, width: double.infinity, fit: BoxFit.contain);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: Colors.white,
        child: InteractiveViewer(minScale: 0.8, maxScale: 4, child: child),
      ),
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
