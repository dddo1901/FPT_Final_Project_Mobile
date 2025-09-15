import 'package:flutter/material.dart';
import 'package:fpt_final_project_mobile/admin/models/user_model.dart';
import 'package:fpt_final_project_mobile/admin/services/user_service.dart';
import 'package:provider/provider.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  late Future<List<UserModel>> _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _future = context.read<UserService>().getUsers();
  }

  Future<void> _reload() async {
    setState(() {
      _future = context.read<UserService>().getUsers();
    });
  }

  void _goCreate() {
    Navigator.pushNamed(context, '/admin/users/create').then((_) => _reload());
  }

  void _goDetail(String id) {
    debugPrint('🔧 _goDetail called with id: $id');
    Navigator.pushNamed(
      context,
      '/admin/users/detail',
      arguments: id,
    ).then((_) => _reload());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          FilledButton.tonalIcon(
            onPressed: _goCreate,
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by username/email...',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _search = v.trim()),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final list = (snap.data ?? [])
                    .where(
                      (u) =>
                          _search.isEmpty ||
                          u.username.toLowerCase().contains(
                            _search.toLowerCase(),
                          ) ||
                          u.email.toLowerCase().contains(_search.toLowerCase()),
                    )
                    .toList();
                if (list.isEmpty) return const Center(child: Text('No users'));
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final u = list[i];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            u.username.isNotEmpty
                                ? u.username[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(u.name),
                        subtitle: Text('${u.email} • ${u.role}'),
                        onTap: () => _goDetail(u.id),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
