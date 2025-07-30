import 'package:flutter/material.dart';
import 'package:fpt_final_project_mobile/admin/models/user_model.dart';
import 'package:fpt_final_project_mobile/admin/pages/user_form_page.dart';
import 'package:fpt_final_project_mobile/admin/services/user_service.dart';
import 'package:provider/provider.dart';

class UserDetailPage extends StatefulWidget {
  final String userId;
  final UserService userService;

  const UserDetailPage({
    super.key,
    required this.userId,
    required this.userService,
  });

  @override
  _UserDetailPageState createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  late Future<UserModel> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchUserDetails();
  }

  Future<UserModel> _fetchUserDetails() async {
    final userService = Provider.of<UserService>(context, listen: false);
    return await userService.getUserById(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _navigateToUserForm(context),
          ),
        ],
      ),
      body: FutureBuilder<UserModel>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('User not found'));
          }

          final user = snapshot.data!;
          return _buildUserDetails(user);
        },
      ),
    );
  }

  Widget _buildUserDetails(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add your user detail widgets here
          // Similar to the previous implementation
          // with sections for account, personal, and work info
        ],
      ),
    );
  }

  void _navigateToUserForm(BuildContext context) async {
    final user = await _userFuture;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserFormPage(
          userService: widget.userService, // Thêm dòng này
          initialUser: user,
        ),
      ),
    );

    if (result == true) {
      setState(() {
        _userFuture = _fetchUserDetails();
      });
    }
  }
}
