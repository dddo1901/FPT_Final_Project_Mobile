// lib/admin/pages/table_form_page.dart
import 'package:flutter/material.dart';
import 'package:fpt_final_project_mobile/admin/entities/table_entity.dart';
import 'package:fpt_final_project_mobile/admin/services/table_service.dart';

class TableFormPage extends StatefulWidget {
  final TableService service;
  final String? tableId; // null => create, else edit

  const TableFormPage({super.key, required this.service, this.tableId});

  @override
  State<TableFormPage> createState() => _TableFormPageState();
}

class _TableFormPageState extends State<TableFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _numberCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  TableStatus _status = TableStatus.available;

  bool _loading = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.tableId != null) _load();
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _capacityCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final t = await widget.service.getTable(widget.tableId!);
      _numberCtrl.text = t.number.toString();
      _capacityCtrl.text = t.capacity.toString();
      _locationCtrl.text = t.location ?? '';
      _status = t.status;
      setState(() {});
    } catch (e) {
      _snack('Failed to load: $e', isError: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final entity = TableEntity(
        id: widget.tableId ?? '', // backend sẽ gán khi tạo
        number: int.parse(_numberCtrl.text),
        capacity: int.parse(_capacityCtrl.text),
        location: _locationCtrl.text.trim().isEmpty
            ? null
            : _locationCtrl.text.trim(),
        status: _status,
      );

      if (widget.tableId == null) {
        await widget.service.createTable(entity);
        _snack('Table created successfully!');
      } else {
        await widget.service.updateTable(widget.tableId!, entity);
        _snack('Table updated successfully!');
      }

      if (!mounted) return;
      // Điều hướng về list
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/admin/tables',
        (r) => r.settings.name == '/admin' || r.isFirst,
      );
    } catch (e) {
      _snack('Save failed: $e', isError: true);
    } finally {
      setState(() => _submitting = false);
    }
  }

  String? _requiredPositive(String? v, String field) {
    final val = int.tryParse((v ?? '').trim());
    if (val == null || val <= 0) return '$field must be positive';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tableId == null ? 'Add Table' : 'Edit Table'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _numberCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Table Number',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => _requiredPositive(v, 'Table number'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _capacityCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Capacity',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => _requiredPositive(v, 'Capacity'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Location (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButton<TableStatus>(
                        isExpanded: true,
                        value: _status,
                        underline: const SizedBox.shrink(),
                        items: TableStatus.values
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.label),
                              ),
                            )
                            .toList(),
                        onChanged: (s) {
                          if (s != null) setState(() => _status = s);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: Text(
                        _submitting
                            ? 'Processing...'
                            : (widget.tableId == null
                                  ? 'Create Table'
                                  : 'Update Table'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
