import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/request_service.dart';
import '../models/request_model.dart';
import '../../auths/api_service.dart';
import '../../auths/auth_provider.dart';
import '../../common/extensions/notification_extension.dart';
import '../../common/widgets/notification_icon.dart';
import 'request_create_page.dart';

class StaffRequestListPage extends StatefulWidget {
  const StaffRequestListPage({super.key});

  @override
  State<StaffRequestListPage> createState() => _StaffRequestListPageState();
}

class _StaffRequestListPageState extends State<StaffRequestListPage> {
  RequestService? _requestService;
  List<StaffRequest> _requests = [];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'ALL';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _requestService ??= RequestService(context.read<ApiService>());

    // Debug user info
    final auth = context.read<AuthProvider>();
    print('Current user role: ${auth.role}');
    print('Is authenticated: ${auth.isAuthenticated}');
    print('Token: ${auth.token?.substring(0, 20)}...');

    _loadMyRequests();
  }

  Future<void> _loadMyRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final requestsData = await _requestService!.getMyRequests();
      List<StaffRequest> requests = requestsData
          .map((data) => StaffRequest.fromJson(data))
          .toList();

      // Filter by status if needed
      if (_statusFilter != 'ALL') {
        requests = requests
            .where((request) => request.status.value == _statusFilter)
            .toList();
      }

      // Sort by request date (newest first)
      requests.sort((a, b) => b.requestDate.compareTo(a.requestDate));

      setState(() {
        _requests = requests;
        _isLoading = false;
      });

      // Show success notification when loading completes
      if (mounted) {
        context.showSuccess('Requests loaded successfully');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load requests: $e';
        _isLoading = false;
      });

      // Show error notification
      if (mounted) {
        context.showError('Failed to load requests: $e');
      }
    }
  }

  Future<void> _cancelRequest(StaffRequest request) async {
    final confirmed = await context.showConfirm(
      title: 'Cancel Request',
      message: 'Are you sure you want to cancel this request?',
      confirmText: 'Yes, Cancel',
      cancelText: 'No',
      confirmColor: Colors.red,
    );

    if (confirmed) {
      try {
        await _requestService!.cancelRequest(request.id);

        if (mounted) {
          context.showSuccess('Request cancelled successfully');
          _loadMyRequests(); // Reload the list
        }
      } catch (e) {
        if (mounted) {
          context.showError('Failed to cancel request: $e');
        }
      }
    }
  }

  Future<void> _createNewRequest() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const RequestCreatePage()),
    );

    if (result == true) {
      context.showSuccess('Request created successfully');
      _loadMyRequests(); // Reload the list if a new request was created
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Requests'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          const NotificationIcon(),
          IconButton(
            onPressed: _loadMyRequests,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewRequest,
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: _requestService == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter Section
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'Status: ',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _statusFilter,
                          isExpanded: true,
                          onChanged: (value) {
                            setState(() {
                              _statusFilter = value!;
                            });
                            _loadMyRequests();
                          },
                          items: const [
                            DropdownMenuItem(
                              value: 'ALL',
                              child: Text('All Requests'),
                            ),
                            DropdownMenuItem(
                              value: 'PENDING',
                              child: Text('Pending'),
                            ),
                            DropdownMenuItem(
                              value: 'APPROVED',
                              child: Text('Approved'),
                            ),
                            DropdownMenuItem(
                              value: 'DENIED',
                              child: Text('Denied'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(child: _buildContent()),
              ],
            ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMyRequests,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _statusFilter == 'ALL'
                  ? 'No requests found'
                  : 'No $_statusFilter requests found',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _createNewRequest,
              icon: const Icon(Icons.add),
              label: const Text('Create Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyRequests,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final request = _requests[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with type and status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          request.type.label,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(request.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          request.status.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Request details
                  _buildDetailRow('Reason', request.reason),
                  _buildDetailRow('Request Date', request.formattedRequestDate),
                  _buildDetailRow('Target Date', request.formattedTargetDate),

                  if (request.additionalInfo != null &&
                      request.additionalInfo!.isNotEmpty)
                    _buildDetailRow('Additional Info', request.additionalInfo!),

                  if (request.adminNote != null &&
                      request.adminNote!.isNotEmpty)
                    _buildDetailRow('Admin Note', request.adminNote!),

                  // Action buttons for pending requests
                  if (request.isPending) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _cancelRequest(request),
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancel Request'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.approved:
        return Colors.green;
      case RequestStatus.denied:
        return Colors.red;
    }
  }
}
