import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/request_service.dart';
import '../models/request_model.dart';
import '../../auths/api_service.dart';
import '../../common/extensions/notification_extension.dart';

class RequestCreatePage extends StatefulWidget {
  const RequestCreatePage({super.key});

  @override
  State<RequestCreatePage> createState() => _RequestCreatePageState();
}

class _RequestCreatePageState extends State<RequestCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _additionalInfoController = TextEditingController();

  RequestService? _requestService;
  RequestType _selectedType = RequestType.leave;
  DateTime? _selectedDate;
  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _requestService ??= RequestService(context.read<ApiService>());
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: tomorrow,
      firstDate: tomorrow,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Select target date',
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      context.showError('Please select a target date');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _requestService!.createRequest(
        type: _selectedType.value,
        reason: _reasonController.text.trim(),
        targetDate: _selectedDate!,
        additionalInfo: _additionalInfoController.text.trim().isNotEmpty
            ? _additionalInfoController.text.trim()
            : null,
      );

      if (mounted) {
        context.showSuccess('Request submitted successfully');
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        context.showError('Failed to submit request: $e');
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Request'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          if (_isSubmitting)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _requestService == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Request Type Selection
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Request Type',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            ...RequestType.values.map((type) {
                              return RadioListTile<RequestType>(
                                title: Text(type.label),
                                subtitle: Text(_getTypeDescription(type)),
                                value: type,
                                groupValue: _selectedType,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedType = value!;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Target Date Selection
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Target Date',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: _selectDate,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _selectedDate == null
                                          ? 'Select target date'
                                          : _formatDate(_selectedDate!),
                                      style: TextStyle(
                                        color: _selectedDate == null
                                            ? Colors.grey
                                            : Colors.black,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Reason Input
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reason',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _reasonController,
                              decoration: const InputDecoration(
                                hintText:
                                    'Please provide a reason for your request...',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please provide a reason';
                                }
                                if (value.trim().length < 10) {
                                  return 'Reason must be at least 10 characters';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Additional Information (Optional)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Additional Information (Optional)',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _additionalInfoController,
                              decoration: const InputDecoration(
                                hintText:
                                    'Any additional details you want to add...',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSubmitting
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Submitting...'),
                                ],
                              )
                            : const Text(
                                'Submit Request',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Guidelines
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                Text(
                                  'Guidelines',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '• Submit requests at least 24 hours in advance\n'
                              '• Provide clear and detailed reasons\n'
                              '• For urgent requests, contact your supervisor directly\n'
                              '• You will receive notification once your request is reviewed',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _getTypeDescription(RequestType type) {
    switch (type) {
      case RequestType.leave:
        return 'Request time off work';
      case RequestType.swap:
        return 'Request to swap shifts with another employee';
      case RequestType.overtime:
        return 'Request to work overtime hours';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
