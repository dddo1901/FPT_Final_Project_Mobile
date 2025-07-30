import 'package:flutter/material.dart';
import 'package:fpt_final_project_mobile/admin/models/user_model.dart';
import 'package:fpt_final_project_mobile/admin/pages/user_detail_page.dart';
import 'package:fpt_final_project_mobile/admin/pages/user_form_page.dart';
import 'package:fpt_final_project_mobile/admin/services/user_service.dart';
import '../widgets/user_card.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  late Future<List<UserModel>> _usersFuture;
  late UserService _userService;
  String _searchTerm = '';
  String _roleFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _userService = UserService(baseUrl: 'http://10.0.2.2:8080');
    _usersFuture = _fetchUsers();
    print(_usersFuture);
  }

  Future<List<UserModel>> _fetchUsers() async {
    return await _userService.getUsers();
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    return users.where((user) {
      final matchesSearch =
          _searchTerm.isEmpty ||
          user.username.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          (user.name ?? '').toLowerCase().contains(_searchTerm.toLowerCase());

      final matchesRole = _roleFilter == 'ALL' || user.role == _roleFilter;

      return matchesSearch && matchesRole;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User List'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _navigateToUserForm(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchTerm = value;
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                DropdownButton<String>(
                  value: _roleFilter,
                  items: [
                    DropdownMenuItem(value: 'ALL', child: Text('All')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                    DropdownMenuItem(value: 'STAFF', child: Text('Staff')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _roleFilter = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No users found'));
                }

                final filteredUsers = _filterUsers(snapshot.data!);

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return UserCard(
                      user: user,
                      onTap: () => _navigateToUserDetail(context, user.id),
                      onLongPress: () => _showUserActions(context, user),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToUserForm(BuildContext context, [UserModel? user]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            UserFormPage(userService: _userService, initialUser: user),
      ),
    );

    if (result == true) {
      setState(() {
        _usersFuture = _fetchUsers();
      });
    }
  }

  void _navigateToUserDetail(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            UserDetailPage(userId: userId, userService: _userService),
      ),
    );
  }

  void _showUserActions(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.info),
            title: Text('View Details'),
            onTap: () {
              Navigator.pop(context);
              _navigateToUserDetail(context, user.id);
            },
          ),
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit'),
            onTap: () {
              Navigator.pop(context);
              _navigateToUserForm(context, user);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context, user);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete ${user.name ?? user.username}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _userService.deleteUser(user.id);
                setState(() {
                  _usersFuture = _fetchUsers();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('User deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete user: $e')),
                );
              }
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}
