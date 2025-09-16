import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../auths/api_service.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  List<CustomerModel> _customers = [];
  List<CustomerModel> _filteredCustomers = [];
  bool _loading = true;
  String _searchQuery = '';
  int _currentPage = 1;
  final int _customersPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _loading = true);

    try {
      final api = context.read<ApiService>();
      final response = await api.client.get(
        Uri.parse('${api.baseUrl}/api/admin/customers'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final customers = data
            .map((json) => CustomerModel.fromJson(json))
            .toList();

        setState(() {
          _customers = customers;
          _filteredCustomers = customers;
          _loading = false;
        });
      } else {
        throw Exception('Failed to load customers: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[CUSTOMER LIST ERROR] $e');
      setState(() => _loading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load customers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterCustomers(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;

      if (query.isEmpty) {
        _filteredCustomers = _customers;
      } else {
        _filteredCustomers = _customers.where((customer) {
          final fullName = customer.fullName?.toLowerCase() ?? '';
          final email = customer.email.toLowerCase();
          final phone = customer.phoneNumber?.toLowerCase() ?? '';
          final searchLower = query.toLowerCase();

          return fullName.contains(searchLower) ||
              email.contains(searchLower) ||
              phone.contains(searchLower);
        }).toList();
      }
    });
  }

  List<CustomerModel> get _paginatedCustomers {
    final startIndex = (_currentPage - 1) * _customersPerPage;
    final endIndex = startIndex + _customersPerPage;

    if (startIndex >= _filteredCustomers.length) return [];

    return _filteredCustomers.sublist(
      startIndex,
      endIndex > _filteredCustomers.length
          ? _filteredCustomers.length
          : endIndex,
    );
  }

  int get _totalPages {
    return (_filteredCustomers.length / _customersPerPage).ceil();
  }

  Future<void> _toggleCustomerStatus(CustomerModel customer) async {
    try {
      final api = context.read<ApiService>();
      final response = await api.client.put(
        Uri.parse(
          '${api.baseUrl}/api/admin/customers/${customer.id}/toggle-status',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Refresh the list
        await _loadCustomers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Customer ${customer.isActive ? "deactivated" : "activated"} successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to toggle status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[TOGGLE STATUS ERROR] $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update customer status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header with stats and search
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Customers: ${_customers.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: _loadCustomers,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: _filterCustomers,
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, or phone...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Customer list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No customers found'
                              : 'No customers match your search',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _paginatedCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = _paginatedCustomers[index];
                      final globalIndex =
                          (_currentPage - 1) * _customersPerPage + index + 1;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple.shade100,
                            child: Text(
                              globalIndex.toString(),
                              style: TextStyle(
                                color: Colors.purple.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  customer.fullName ?? 'N/A',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: customer.isActive
                                      ? Colors.green.shade100
                                      : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  customer.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: customer.isActive
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('📧 ${customer.email}'),
                              if (customer.phoneNumber != null)
                                Text('📱 ${customer.phoneNumber}'),
                              Text('🎁 ${customer.point ?? 0} points'),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'toggle') {
                                _showToggleDialog(customer);
                              } else if (value == 'details') {
                                _showCustomerDetails(customer);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'details',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility),
                                    SizedBox(width: 8),
                                    Text('View Details'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'toggle',
                                child: Row(
                                  children: [
                                    Icon(
                                      customer.isActive
                                          ? Icons.block
                                          : Icons.check_circle,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      customer.isActive
                                          ? 'Deactivate'
                                          : 'Activate',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Pagination
          if (_totalPages > 1)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Page $_currentPage of $_totalPages',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _currentPage > 1
                            ? () => setState(() => _currentPage--)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      IconButton(
                        onPressed: _currentPage < _totalPages
                            ? () => setState(() => _currentPage++)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showToggleDialog(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Action'),
        content: Text(
          'Are you sure you want to ${customer.isActive ? "deactivate" : "activate"} '
          '${customer.fullName ?? customer.email}?\n\n'
          '${customer.isActive ? "Deactivating will prevent this customer from logging in and placing orders." : "Activating will restore this customer\'s access to the system."}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleCustomerStatus(customer);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: customer.isActive ? Colors.red : Colors.green,
            ),
            child: Text(customer.isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
  }

  void _showCustomerDetails(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer.fullName ?? 'Customer Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Email', customer.email),
            _buildDetailRow('Phone', customer.phoneNumber ?? 'N/A'),
            _buildDetailRow('Points', '${customer.point ?? 0}'),
            _buildDetailRow(
              'Status',
              customer.isActive ? 'Active' : 'Inactive',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class CustomerModel {
  final String id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final int? point;
  final bool isActive;

  CustomerModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.point,
    required this.isActive,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      fullName: json['fullName'],
      phoneNumber: json['phoneNumber'],
      point: json['point'] is String
          ? int.tryParse(json['point'])
          : json['point'],
      isActive: json['isActive'] ?? true,
    );
  }
}
