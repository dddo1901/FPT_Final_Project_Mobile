import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/request_service.dart';
import '../models/request_model.dart';
import '../../auths/api_service.dart';

class RequestManagementPage extends StatefulWidget {
  const RequestManagementPage({super.key});

  @override
  State<RequestManagementPage> createState() => _RequestManagementPageState();
}

class _RequestManagementPageState extends State<RequestManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  RequestService? _requestService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _requestService ??= RequestService(context.read<ApiService>());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Request Management'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions), text: 'Pending Requests'),
            Tab(icon: Icon(Icons.done_all), text: 'Confirmed Requests'),
          ],
        ),
      ),
      body: _requestService == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _PendingRequestsTab(requestService: _requestService!),
                _ConfirmedRequestsTab(requestService: _requestService!),
              ],
            ),
    );
  }
}

class _PendingRequestsTab extends StatefulWidget {
  final RequestService requestService;

  const _PendingRequestsTab({required this.requestService});

  @override
  State<_PendingRequestsTab> createState() => _PendingRequestsTabState();
}

class _PendingRequestsTabState extends State<_PendingRequestsTab> {
  List<StaffRequest> _requests = [];
  bool _isLoading = true;
  String? _error;
  final Map<String, bool> _processing = {};
  final Map<String, String> _adminNotes = {};

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final requestsData = await widget.requestService.getRequestsByStatus(
        'PENDING',
      );
      final requests = requestsData
          .map((data) => StaffRequest.fromJson(data))
          .toList();

      setState(() {
        _requests = requests;
        _isLoading = false;
        // Initialize admin notes
        for (final request in requests) {
          _adminNotes[request.id] = '';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load pending requests: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _approveRequest(StaffRequest request) async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Approve Request',
      'Are you sure you want to approve this ${request.type.label.toLowerCase()} request?',
      request,
    );

    if (confirmed == true) {
      await _processRequest(request.id, 'approve');
    }
  }

  Future<void> _denyRequest(StaffRequest request) async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Deny Request',
      'Are you sure you want to deny this ${request.type.label.toLowerCase()} request?',
      request,
    );

    if (confirmed == true) {
      await _processRequest(request.id, 'deny');
    }
  }

  Future<void> _processRequest(String requestId, String action) async {
    setState(() {
      _processing[requestId] = true;
    });

    try {
      final adminNote = _adminNotes[requestId];

      if (action == 'approve') {
        await widget.requestService.approveRequest(
          requestId,
          adminNote: adminNote,
        );
      } else {
        await widget.requestService.denyRequest(
          requestId,
          adminNote: adminNote,
        );
      }

      // Reload the list
      await _loadPendingRequests();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request ${action}d successfully'),
            backgroundColor: action == 'approve' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to $action request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _processing[requestId] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: _loadPendingRequests,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_requests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No pending requests',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final request = _requests[index];
          final isProcessing = _processing[request.id] ?? false;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.staffName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Code: ${request.staffCode}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeColor(request.type),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          request.type.label,
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

                  const SizedBox(height: 16),

                  // Admin note input
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Admin Note (Optional)',
                      border: OutlineInputBorder(),
                      hintText: 'Add a note for this request...',
                    ),
                    maxLines: 2,
                    onChanged: (value) {
                      _adminNotes[request.id] = value;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isProcessing
                              ? null
                              : () => _approveRequest(request),
                          icon: isProcessing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isProcessing
                              ? null
                              : () => _denyRequest(request),
                          icon: isProcessing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.close),
                          label: const Text('Deny'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
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

  Color _getTypeColor(RequestType type) {
    switch (type) {
      case RequestType.leave:
        return Colors.blue;
      case RequestType.swap:
        return Colors.orange;
      case RequestType.overtime:
        return Colors.purple;
    }
  }
}

class _ConfirmedRequestsTab extends StatefulWidget {
  final RequestService requestService;

  const _ConfirmedRequestsTab({required this.requestService});

  @override
  State<_ConfirmedRequestsTab> createState() => _ConfirmedRequestsTabState();
}

class _ConfirmedRequestsTabState extends State<_ConfirmedRequestsTab> {
  List<StaffRequest> _requests = [];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadConfirmedRequests();
  }

  Future<void> _loadConfirmedRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<Map<String, dynamic>> requestsData;

      if (_statusFilter == 'ALL') {
        requestsData = await widget.requestService.getAllConfirmedRequests();
      } else {
        requestsData = await widget.requestService.getRequestsByStatus(
          _statusFilter,
        );
      }

      final requests = requestsData
          .map((data) => StaffRequest.fromJson(data))
          .toList();

      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load confirmed requests: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter dropdown
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
                    _loadConfirmedRequests();
                  },
                  items: const [
                    DropdownMenuItem(
                      value: 'ALL',
                      child: Text('All Confirmed'),
                    ),
                    DropdownMenuItem(
                      value: 'APPROVED',
                      child: Text('Approved'),
                    ),
                    DropdownMenuItem(value: 'DENIED', child: Text('Denied')),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(child: _buildContent()),
      ],
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
              onPressed: _loadConfirmedRequests,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_requests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No confirmed requests',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConfirmedRequests,
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
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.staffName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Code: ${request.staffCode}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getTypeColor(request.type),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              request.type.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
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

  Color _getTypeColor(RequestType type) {
    switch (type) {
      case RequestType.leave:
        return Colors.blue;
      case RequestType.swap:
        return Colors.orange;
      case RequestType.overtime:
        return Colors.purple;
    }
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.approved:
        return Colors.green;
      case RequestStatus.denied:
        return Colors.red;
      case RequestStatus.pending:
        return Colors.orange;
    }
  }
}

Future<bool?> _showConfirmationDialog(
  BuildContext context,
  String title,
  String message,
  StaffRequest request,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Staff: ${request.staffName} (${request.staffCode})'),
                  Text('Type: ${request.type.label}'),
                  Text('Reason: ${request.reason}'),
                  Text('Target Date: ${request.formattedTargetDate}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: title.contains('Approve')
                  ? Colors.green
                  : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(title.contains('Approve') ? 'Approve' : 'Deny'),
          ),
        ],
      );
    },
  );
}
