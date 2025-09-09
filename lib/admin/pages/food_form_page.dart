import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/food_service.dart';

class FoodFormPage extends StatefulWidget {
  final String? foodId; // null = create
  const FoodFormPage({super.key, this.foodId});

  @override
  State<FoodFormPage> createState() => _FoodFormPageState();
}

class _FoodFormPageState extends State<FoodFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _priceC = TextEditingController();
  final _descC = TextEditingController();

  String _status = 'AVAILABLE';
  String _type = 'OTHER';
  File? _imageFile;
  bool _loading = false;

  final _picker = ImagePicker();
  bool get _isEdit => widget.foodId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadForEdit();
  }

  @override
  void dispose() {
    _nameC.dispose();
    _priceC.dispose();
    _descC.dispose();
    super.dispose();
  }

  Future<void> _loadForEdit() async {
    setState(() => _loading = true);
    try {
      final svc = context.read<FoodService>();
      final m = await svc.getFoodById(widget.foodId!);
      if (!mounted) return;
      _nameC.text = m.name;
      _priceC.text = m.price.toStringAsFixed(2);
      _descC.text = m.description ?? '';
      _status = m.status;
      _type = m.type;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Load failed: $e')));
      Navigator.pop(context, false);
      return;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Không được để trống' : null;
  String? _price(String? v) {
    if (v == null || v.trim().isEmpty) return 'Không được để trống';
    final x = double.tryParse(v);
    if (x == null || x < 0) return 'Giá không hợp lệ';
    return null;
  }

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x != null) setState(() => _imageFile = File(x.path));
  }

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameC.text.trim();
    final price = double.parse(_priceC.text.trim());
    final desc = _descC.text.trim().isEmpty ? null : _descC.text.trim();

    setState(() => _loading = true);
    try {
      final svc = context.read<FoodService>();
      if (_isEdit) {
        await svc.updateFood(
          widget.foodId!,
          name: name,
          price: price,
          status: _status,
          type: _type,
          description: desc,
          imageFile: _imageFile,
        );
      } else {
        await svc.createFood(
          name: name,
          price: price,
          status: _status,
          type: _type,
          description: desc,
          imageFile: _imageFile,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved!')));
      Navigator.pop(context, true); // ✅ báo về list/detail để reload
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
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Food' : 'Create Food')),
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
                        // Name
                        TextFormField(
                          controller: _nameC,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: _req,
                        ),
                        const SizedBox(height: 12),

                        // Price
                        TextFormField(
                          controller: _priceC,
                          decoration: const InputDecoration(
                            labelText: 'Price',
                            hintText: 'e.g. 10.00',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: _price,
                        ),
                        const SizedBox(height: 12),

                        // Status
                        DropdownButtonFormField<String>(
                          value: _status,
                          items: const [
                            DropdownMenuItem(
                              value: 'AVAILABLE',
                              child: Text('AVAILABLE'),
                            ),
                            DropdownMenuItem(
                              value: 'UNAVAILABLE',
                              child: Text('UNAVAILABLE'),
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

                        // Type
                        DropdownButtonFormField<String>(
                          value: _type,
                          items: const [
                            DropdownMenuItem(
                              value: 'PIZZA',
                              child: Text('PIZZA'),
                            ),
                            DropdownMenuItem(
                              value: 'APPETIZER',
                              child: Text('APPETIZER'),
                            ),
                            DropdownMenuItem(
                              value: 'SALAD',
                              child: Text('SALAD'),
                            ),
                            DropdownMenuItem(
                              value: 'DRINK',
                              child: Text('DRINK'),
                            ),
                            DropdownMenuItem(
                              value: 'PASTA',
                              child: Text('PASTA'),
                            ),
                            DropdownMenuItem(
                              value: 'MAIN',
                              child: Text('MAIN'),
                            ),
                            DropdownMenuItem(
                              value: 'OTHER',
                              child: Text('OTHER'),
                            ),
                          ],
                          onChanged: (v) => setState(
                            () => _type = (v ?? 'OTHER').toUpperCase(),
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Description
                        TextFormField(
                          controller: _descC,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Image
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.image),
                              label: const Text('Pick Image'),
                            ),
                            const SizedBox(width: 12),
                            if (_imageFile != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _imageFile!,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),

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
