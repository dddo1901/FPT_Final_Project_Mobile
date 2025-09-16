import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../auths/api_service.dart';

class VoucherManagementPage extends StatefulWidget {
  const VoucherManagementPage({super.key});

  @override
  State<VoucherManagementPage> createState() => _VoucherManagementPageState();
}

class _VoucherManagementPageState extends State<VoucherManagementPage> {
  List<VoucherModel> _vouchers = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    setState(() => _loading = true);

    try {
      final api = context.read<ApiService>();
      final response = await api.client.get(
        Uri.parse('${api.baseUrl}/api/admin/vouchers'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final vouchers = data
            .map((json) => VoucherModel.fromJson(json))
            .toList();

        setState(() {
          _vouchers = vouchers;
          _loading = false;
        });
      } else {
        throw Exception('Failed to load vouchers: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[VOUCHER LIST ERROR] $e');
      setState(() => _loading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load vouchers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<VoucherModel> get _filteredVouchers {
    if (_searchQuery.isEmpty) return _vouchers;

    return _vouchers.where((voucher) {
      final name = voucher.name.toLowerCase();
      final code = voucher.code?.toLowerCase() ?? '';
      final description = voucher.description?.toLowerCase() ?? '';
      final searchLower = _searchQuery.toLowerCase();

      return name.contains(searchLower) ||
          code.contains(searchLower) ||
          description.contains(searchLower);
    }).toList();
  }

  String _getVoucherTypeLabel(String type) {
    switch (type.toUpperCase()) {
      case 'PERCENTAGE':
        return 'Percentage (%)';
      case 'FIXED_AMOUNT':
        return 'Fixed Amount (\$)';
      case 'FREE_ITEM':
        return 'Free Item';
      default:
        return type;
    }
  }

  String _getVoucherValue(VoucherModel voucher) {
    switch (voucher.type.toUpperCase()) {
      case 'PERCENTAGE':
        return '${voucher.value}%';
      case 'FIXED_AMOUNT':
        return '\$${voucher.value}';
      case 'FREE_ITEM':
        return 'Free Item';
      default:
        return voucher.value.toString();
    }
  }

  Color _getStatusColor(VoucherModel voucher) {
    if (voucher.expiresAt != null &&
        voucher.expiresAt!.isBefore(DateTime.now())) {
      return Colors.red; // Expired
    }
    if (voucher.usedQuantity >= voucher.totalQuantity) {
      return Colors.orange; // Used up
    }
    return Colors.green; // Active
  }

  String _getStatusText(VoucherModel voucher) {
    if (voucher.expiresAt != null &&
        voucher.expiresAt!.isBefore(DateTime.now())) {
      return 'Expired';
    }
    if (voucher.usedQuantity >= voucher.totalQuantity) {
      return 'Used Up';
    }
    return 'Active';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voucher Management'),
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
                    Expanded(
                      child: Row(
                        children: [
                          _buildStatCard(
                            'Total',
                            _vouchers.length.toString(),
                            Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          _buildStatCard(
                            'Active',
                            _vouchers
                                .where((v) => _getStatusText(v) == 'Active')
                                .length
                                .toString(),
                            Colors.green,
                          ),
                          const SizedBox(width: 8),
                          _buildStatCard(
                            'Expired',
                            _vouchers
                                .where((v) => _getStatusText(v) == 'Expired')
                                .length
                                .toString(),
                            Colors.red,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _loadVouchers,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText:
                        'Search vouchers by name, code, or description...',
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

          // Voucher list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVouchers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.card_giftcard_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No vouchers found'
                              : 'No vouchers match your search',
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
                    itemCount: _filteredVouchers.length,
                    itemBuilder: (context, index) {
                      final voucher = _filteredVouchers[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header row
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          voucher.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (voucher.code != null)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              voucher.code!,
                                              style: TextStyle(
                                                color: Colors.blue.shade700,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
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
                                      color: _getStatusColor(
                                        voucher,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      _getStatusText(voucher),
                                      style: TextStyle(
                                        color: _getStatusColor(voucher),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Description
                              if (voucher.description != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    voucher.description!,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),

                              // Details grid
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildVoucherDetail(
                                      '💰',
                                      'Value',
                                      _getVoucherValue(voucher),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildVoucherDetail(
                                      '📊',
                                      'Type',
                                      _getVoucherTypeLabel(voucher.type),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  Expanded(
                                    child: _buildVoucherDetail(
                                      '📦',
                                      'Usage',
                                      '${voucher.usedQuantity}/${voucher.totalQuantity}',
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildVoucherDetail(
                                      '💵',
                                      'Min Order',
                                      voucher.minOrderAmount != null
                                          ? '\$${voucher.minOrderAmount}'
                                          : 'No limit',
                                    ),
                                  ),
                                ],
                              ),

                              if (voucher.maxDiscountAmount != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: _buildVoucherDetail(
                                    '🎯',
                                    'Max Discount',
                                    '\$${voucher.maxDiscountAmount}',
                                  ),
                                ),

                              const SizedBox(height: 12),

                              // Dates
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '📅 Created',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          _formatDate(voucher.createdAt),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (voucher.expiresAt != null)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '⏰ Expires',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            _formatDate(voucher.expiresAt!),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                              color:
                                                  voucher.expiresAt!.isBefore(
                                                    DateTime.now(),
                                                  )
                                                  ? Colors.red
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),

                              // Public indicator
                              if (voucher.isPublic)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.public,
                                          size: 14,
                                          color: Colors.green.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Public Voucher',
                                          style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherDetail(String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(icon),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class VoucherModel {
  final String id;
  final String name;
  final String? description;
  final String type;
  final double value;
  final double? minOrderAmount;
  final double? maxDiscountAmount;
  final int totalQuantity;
  final int usedQuantity;
  final DateTime? expiresAt;
  final bool isPublic;
  final String? code;
  final DateTime createdAt;

  VoucherModel({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.value,
    this.minOrderAmount,
    this.maxDiscountAmount,
    required this.totalQuantity,
    required this.usedQuantity,
    this.expiresAt,
    required this.isPublic,
    this.code,
    required this.createdAt,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      description: json['description'],
      type: json['type'] ?? 'PERCENTAGE',
      value: (json['value'] ?? 0).toDouble(),
      minOrderAmount: json['minOrderAmount']?.toDouble(),
      maxDiscountAmount: json['maxDiscountAmount']?.toDouble(),
      totalQuantity: json['totalQuantity'] ?? 0,
      usedQuantity: json['usedQuantity'] ?? 0,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
      isPublic: json['isPublic'] ?? false,
      code: json['code'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
