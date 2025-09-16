import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:fpt_final_project_mobile/auths/auth_provider.dart';
import 'package:fpt_final_project_mobile/auths/api_service.dart';
import 'package:fpt_final_project_mobile/styles/app_theme.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  // Dashboard data
  Map<String, dynamic> dashboardData = {
    'totalOrders': 0,
    'totalRevenue': 0.0,
    'totalCustomers': 0,
    'activeTables': '0/0',
    'recentActivities': <Map<String, dynamic>>[],
  };

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);
    try {
      final api = context.read<ApiService>();

      // Load dashboard statistics
      await Future.wait([
        _loadOrderStats(api),
        _loadCustomerStats(api),
        _loadTableStats(api),
        _loadRecentActivities(api),
      ]);
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadOrderStats(ApiService api) async {
    try {
      // Lấy analytics data từ API
      final analytics = await api.getDashboardAnalytics();
      final revenue = await api.getRevenueAnalytics(timeRange: 'month');

      setState(() {
        dashboardData['totalOrders'] = analytics['totalOrders'] ?? 0;
        dashboardData['totalRevenue'] = revenue['totalRevenue'] ?? 0.0;
      });
    } catch (e) {
      debugPrint('Error loading order stats: $e');
      // Fallback to sample data if API fails
      setState(() {
        dashboardData['totalOrders'] = 0;
        dashboardData['totalRevenue'] = 0.0;
      });
    }
  }

  Future<void> _loadCustomerStats(ApiService api) async {
    try {
      // Lấy customer statistics từ API
      final customerStats = await api.getCustomerStatistics();

      setState(() {
        dashboardData['totalCustomers'] = customerStats['totalCustomers'] ?? 0;
      });
    } catch (e) {
      debugPrint('Error loading customer stats: $e');
      // Fallback to 0 if API fails
      setState(() {
        dashboardData['totalCustomers'] = 0;
      });
    }
  }

  Future<void> _loadTableStats(ApiService api) async {
    try {
      // Lấy analytics data cho table stats
      final analytics = await api.getDashboardAnalytics();

      setState(() {
        // Sử dụng active tables từ analytics hoặc fallback
        final activeTables = analytics['activeTables'] ?? 0;
        final totalTables =
            analytics['totalTables'] ?? 15; // Default total tables
        dashboardData['activeTables'] = '$activeTables/$totalTables';
      });
    } catch (e) {
      debugPrint('Error loading table stats: $e');
      // Fallback if API fails
      setState(() {
        dashboardData['activeTables'] = '0/15';
      });
    }
  }

  Future<void> _loadRecentActivities(ApiService api) async {
    try {
      // Lấy VIP customers làm recent activities (hoặc có thể thêm endpoint riêng)
      final vipCustomers = await api.getVIPCustomers(limit: 5);

      List<Map<String, dynamic>> activities = [];

      // Convert VIP customers to activities format
      for (var customer in vipCustomers) {
        activities.add({
          'type': 'customer',
          'title': 'VIP Customer: ${customer['fullName'] ?? 'Unknown'}',
          'subtitle':
              'Points: ${customer['points'] ?? 0} - Orders: ${customer['totalOrders'] ?? 0}',
          'time': _formatDate(customer['lastOrderDate']),
        });
      }

      // Add some sample order activities if needed
      if (activities.length < 3) {
        activities.addAll([
          {
            'type': 'order',
            'title': 'Recent order activity',
            'subtitle': 'Check order management for details',
            'time': 'Recent',
          },
        ]);
      }

      setState(() {
        dashboardData['recentActivities'] = activities.take(5).toList();
      });
    } catch (e) {
      debugPrint('Error loading recent activities: $e');
      // Fallback to sample data if API fails
      setState(() {
        dashboardData['recentActivities'] = [
          {
            'type': 'order',
            'title': 'Dashboard loaded',
            'subtitle': 'Check API connection',
            'time': 'Now',
          },
        ];
      });
    }
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr.toString());
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateStr.toString();
    }
  }

  void _go(BuildContext context, String route, {Object? args}) {
    debugPrint('➡️ AdminHome._go: route=$route args=$args');
    try {
      final result = Navigator.pushNamed(context, route, arguments: args);
      result.then(
        (value) => debugPrint('✅ Navigation successful: $route'),
        onError: (error) => debugPrint('❌ Navigation failed: $error'),
      );
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Navigation error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final claims = _claimsFromJwt(auth.token);

    // Define these variables from claims
    final displayName = claims.name ?? claims.email ?? 'Unknown';
    final role = claims.role?.toUpperCase() ?? 'UNKNOWN';
    final avatarUrl = claims.avatarUrl;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.cardHeaderGradient,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Notification Icon
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    _go(context, '/admin/requests');
                  },
                ),
                // Badge for notification count
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppTheme.danger,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: const Text(
                      '3', // TODO: Replace with actual count
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Profile Avatar
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                _go(context, '/admin/profile');
              },
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null
                    ? Text(
                        _initials(displayName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),

      drawer: _AdminDrawer(
        onNavigate: (route, {args}) => _go(context, route, args: args),
        displayName: displayName,
        role: role,
        avatarUrl: avatarUrl,
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: AppTheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section với theme xanh
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppTheme.bgGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.mediumShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.dashboard_rounded,
                                color: Colors.white.withOpacity(0.9),
                                size: 24, // Giảm size
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome back!', // Rút ngắn text
                                      style: const TextStyle(
                                        fontSize: 20, // Giảm font size
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Restaurant overview',
                                      style: TextStyle(
                                        fontSize: 13, // Giảm font size
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick Stats Section
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          color: AppTheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Quick Overview',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12, // Giảm spacing
                      crossAxisSpacing: 12, // Giảm spacing
                      childAspectRatio: 1.4, // Tăng ratio để card thấp hơn
                      children: [
                        _DashboardStatCard(
                          title: 'Orders',
                          value: '${dashboardData['totalOrders']}',
                          icon: Icons.shopping_cart_outlined,
                          color: AppTheme.primary,
                          trend: '+12%',
                        ),
                        _DashboardStatCard(
                          title: 'Revenue',
                          value:
                              '\$${(dashboardData['totalRevenue'] as double).toStringAsFixed(0)}',
                          icon: Icons.attach_money_outlined,
                          color: AppTheme.success,
                          trend: '+8%',
                        ),
                        _DashboardStatCard(
                          title: 'Customers',
                          value: '${dashboardData['totalCustomers']}',
                          icon: Icons.people_outline,
                          color: AppTheme.info,
                          trend: '+15%',
                        ),
                        _DashboardStatCard(
                          title: 'Tables',
                          value: dashboardData['activeTables'],
                          icon: Icons.table_restaurant_outlined,
                          color: AppTheme.warning,
                          trend: '53%',
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Recent Activity Section
                    Row(
                      children: [
                        Icon(
                          Icons.timeline_outlined,
                          color: AppTheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Column(children: _buildActivityItems()),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildActivityItems() {
    final activities =
        dashboardData['recentActivities'] as List<Map<String, dynamic>>;

    if (activities.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: AppTheme.textLight),
              const SizedBox(height: 12),
              Text(
                'No recent activity',
                style: TextStyle(fontSize: 16, color: AppTheme.textLight),
              ),
            ],
          ),
        ),
      ];
    }

    List<Widget> items = [];
    for (int i = 0; i < activities.length; i++) {
      final activity = activities[i];
      items.add(
        _ActivityItem(
          icon: _getActivityIcon(activity['type']),
          title: activity['title'] ?? 'Unknown activity',
          subtitle: activity['subtitle'] ?? '',
          time: activity['time'] ?? '',
          color: _getActivityColor(activity['type']),
        ),
      );

      if (i < activities.length - 1) {
        items.add(Divider(height: 1, color: AppTheme.divider));
      }
    }

    return items;
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.receipt_long_outlined;
      case 'customer':
        return Icons.person_add_outlined;
      case 'table':
        return Icons.table_restaurant_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'order':
        return AppTheme.success;
      case 'customer':
        return AppTheme.primary;
      case 'table':
        return AppTheme.warning;
      default:
        return AppTheme.info;
    }
  }
}

class _AdminDrawer extends StatelessWidget {
  final void Function(String route, {Object? args}) onNavigate;
  final String displayName;
  final String role;
  final String? avatarUrl;

  const _AdminDrawer({
    required this.onNavigate,
    required this.displayName,
    required this.role,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primary, AppTheme.lightBlue],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Custom drawer header with blue theme
              Container(
                padding: const EdgeInsets.all(16), // Giảm padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30, // Giảm radius
                      backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl!)
                          : null,
                      child: avatarUrl == null
                          ? Text(
                              _initials(displayName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20, // Giảm font size
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12), // Giảm spacing
                    Text(
                      displayName.length > 20
                          ? '${displayName.substring(0, 20)}...'
                          : displayName, // Truncate long names
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16, // Giảm font size
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ), // Giảm padding
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // Giảm border radius
                      ),
                      child: Text(
                        role,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11, // Giảm font size
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  children: [
                    _DrawerItem(
                      icon: Icons.dashboard_outlined,
                      title: 'Dashboard',
                      onTap: () {
                        Navigator.pop(context);
                        onNavigate('/admin');
                      },
                    ),
                    _DrawerDivider(),
                    _DrawerItem(
                      icon: Icons.group_outlined,
                      title: 'Users',
                      subtitle: 'Manage users & roles',
                      onTap: () {
                        Navigator.pop(context);
                        onNavigate('/admin/users');
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.table_restaurant_outlined,
                      title: 'Tables',
                      subtitle: 'List, detail & QR',
                      onTap: () {
                        Navigator.pop(context);
                        onNavigate('/admin/tables');
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.fastfood_outlined,
                      title: 'Foods',
                      subtitle: 'Menu & status',
                      onTap: () {
                        Navigator.pop(context);
                        onNavigate('/admin/foods');
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.receipt_long_outlined,
                      title: 'Orders',
                      subtitle: 'View & manage',
                      onTap: () {
                        Navigator.pop(context);
                        onNavigate('/admin/orders');
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.people_outline,
                      title: 'Customers',
                      subtitle: 'Customer list',
                      onTap: () {
                        Navigator.pop(context);
                        onNavigate('/admin/customers');
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.card_giftcard_outlined,
                      title: 'Vouchers',
                      subtitle: 'Manage vouchers',
                      onTap: () {
                        Navigator.pop(context);
                        onNavigate('/admin/vouchers');
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.assignment_outlined,
                      title: 'Staff Requests',
                      subtitle: 'Staff requests',
                      onTap: () {
                        Navigator.pop(context);
                        onNavigate('/admin/requests');
                      },
                    ),
                    _DrawerDivider(),
                    _DrawerItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      isDestructive: true,
                      onTap: () => confirmAndLogout(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void confirmAndLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirm Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textMedium)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onNavigate('/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Custom Drawer Item Widget
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppTheme.danger : AppTheme.primary,
        size: 20, // Giảm icon size
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? AppTheme.danger : AppTheme.textDark,
          fontSize: 14, // Giảm font size
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(
                color: AppTheme.textMedium,
                fontSize: 11, // Giảm font size
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      dense: true, // Make items more compact
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ), // Giảm padding
    );
  }
}

// Custom Drawer Divider
class _DrawerDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppTheme.divider,
    );
  }
}

// Dashboard Stat Card Widget
class _DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;

  const _DashboardStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // Giảm border radius
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      padding: const EdgeInsets.all(16), // Giảm padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8), // Giảm padding
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8), // Giảm border radius
                ),
                child: Icon(icon, color: color, size: 20), // Giảm icon size
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ), // Giảm padding
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6), // Giảm border radius
                ),
                child: Text(
                  trend,
                  style: const TextStyle(
                    color: AppTheme.success,
                    fontSize: 10, // Giảm font size
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // Giảm spacing
          Flexible(
            // Sử dụng Flexible thay vì fix height
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18, // Giảm font size
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12, // Giảm font size
                    color: AppTheme.textMedium,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Activity Item Widget
class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12), // Giảm padding
      child: Row(
        children: [
          Container(
            width: 40, // Giảm size
            height: 40, // Giảm size
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10), // Giảm border radius
            ),
            child: Icon(icon, color: color, size: 20), // Giảm icon size
          ),
          const SizedBox(width: 12), // Giảm spacing
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14, // Giảm font size
                    color: AppTheme.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12, // Giảm font size
                    color: AppTheme.textMedium,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8), // Thêm spacing
          Text(
            time,
            style: const TextStyle(
              fontSize: 11, // Giảm font size
              color: AppTheme.textLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Helpers (JWT decode mini)
class _Claims {
  final String? userId; // Changed to String since sub is email
  final String? role;
  final String? name;
  final String? email;
  final String? avatarUrl;

  const _Claims({
    this.userId,
    this.role,
    this.name,
    this.email,
    this.avatarUrl,
  });
}

_Claims _claimsFromJwt(String? token) {
  if (token == null || token.isEmpty) return const _Claims();
  try {
    final parts = token.split('.');
    if (parts.length != 3) return const _Claims();

    final normalized = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final payload = json.decode(decoded);

    debugPrint('Raw JWT payload: $payload');

    // Extract email from sub claim
    final email = payload['sub']?.toString();

    // Extract role from authorities array
    String? role;
    if (payload['authorities'] is List) {
      role = (payload['authorities'] as List)
          .firstWhere(
            (auth) => auth.toString().startsWith('ROLE_'),
            orElse: () => '',
          )
          .toString()
          .replaceAll('ROLE_', '');
    }

    debugPrint('''
      Extracted claims:
      - userId: $email
      - email: $email
      - name: $email
      - role: $role
      - avatarUrl: null
    ''');

    return _Claims(
      userId: email, // Use email as userId
      role: role,
      name: email, // Use email as display name for now
      email: email,
      avatarUrl: null, // No avatar URL in this JWT
    );
  } catch (e, stack) {
    debugPrint('JWT parse error: $e');
    debugPrint('Stack trace: $stack');
    return const _Claims();
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    return parts.first.characters.take(2).toString().toUpperCase();
  }
  return (parts.first.characters.first + parts.last.characters.first)
      .toUpperCase();
}
