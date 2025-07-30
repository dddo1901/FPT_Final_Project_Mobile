import 'package:flutter/material.dart';
import 'package:fpt_final_project_mobile/admin/pages/food_page.dart';
import 'package:fpt_final_project_mobile/admin/pages/order_page.dart';
import 'package:fpt_final_project_mobile/admin/pages/user_list_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  static final storage = FlutterSecureStorage();
  String? username;

  @override
  void initState() {
    super.initState();
    loadUsername();
  }

  Future<void> loadUsername() async {
    final user = await storage.read(key: 'username');
    setState(() {
      username = user ?? 'Admin';
    });
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _logout(BuildContext context) async {
    await storage.deleteAll();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $username'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (value) {
              switch (value) {
                case 'order':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OrderPage()),
                  );
                  break;
                case 'user':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UserListPage()),
                  );
                  break;
                case 'food':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FoodPage()),
                  );
                  break;
                case 'edit':
                  break;
                case 'logout':
                  _logout(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'order',
                child: Row(
                  children: const [
                    Icon(Icons.shopping_cart, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Order'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'user',
                child: Row(
                  children: const [
                    Icon(Icons.people, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('User'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'food',
                child: Row(
                  children: const [
                    Icon(Icons.fastfood, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Food'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: const [
                    Icon(Icons.edit, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Edit User'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: const [
                    Icon(Icons.logout, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 1,
          shrinkWrap: true,
          children: [
            _buildCircleButton(
              context,
              Icons.shopping_cart,
              'Orders',
              OrderPage(),
            ),
            _buildCircleButton(context, Icons.person, 'Users', UserListPage()),
            _buildCircleButton(context, Icons.fastfood, 'Foods', FoodPage()),
            _buildCircleButton(context, Icons.settings, 'Settings', null),
            _buildCircleButton(context, Icons.analytics, 'Reports', null),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton(
    BuildContext context,
    IconData icon,
    String label,
    Widget? page,
  ) {
    return InkWell(
      onTap: () {
        if (page != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40, // tăng kích thước icon
            backgroundColor: Colors.deepPurple,
            child: Icon(icon, color: Colors.white, size: 40),
          ),
          SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
