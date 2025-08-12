import 'package:flutter/material.dart';
import 'package:fpt_final_project_mobile/admin/entities/table_entity.dart';
import 'package:fpt_final_project_mobile/admin/services/table_service.dart';

class TableListPage extends StatefulWidget {
  final TableService service;
  const TableListPage({super.key, required this.service});

  @override
  State<TableListPage> createState() => _TableListPageState();
}

class _TableListPageState extends State<TableListPage> {
  List<TableEntity> _all = [];
  bool _loading = true;
  String _search = '';
  TableStatus? _filterStatus;
  String? _sortKey;
  bool _ascending = true;

  // pagination đơn giản
  int _page = 1;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final items = await widget.service.getTables();
      setState(() {
        _all = items;
      });
    } catch (e) {
      _snack('Load failed: $e', isError: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  List<TableEntity> get _filteredSorted {
    var list = _all.where((t) {
      final okSearch = _search.isEmpty || t.number.toString().contains(_search);
      final okStatus = _filterStatus == null || t.status == _filterStatus;
      return okSearch && okStatus;
    }).toList();

    if (_sortKey != null) {
      list.sort((a, b) {
        int cmp;
        if (_sortKey == 'number') {
          cmp = a.number.compareTo(b.number);
        } else {
          cmp = a.capacity.compareTo(b.capacity);
        }
        return _ascending ? cmp : -cmp;
      });
    }
    return list;
  }

  Future<void> _confirmDelete(TableEntity t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Table'),
        content: Text('Delete table F${t.number}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.service.deleteTable(t.id);
      await _fetch();
      _snack('Deleted F${t.number}');
    } catch (e) {
      _snack('Delete failed: $e', isError: true);
    }
  }

  Future<void> _changeStatus(TableEntity t, TableStatus s) async {
    try {
      await widget.service.updateStatus(t.id, s);
      await _fetch();
    } catch (e) {
      _snack('Update status failed: $e', isError: true);
    }
  }

  Future<void> _showQr(TableEntity t) async {
    try {
      final url = await widget.service.fetchQrCodeUrl(t.id);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('QR for F${t.number}'),
          content: url.isEmpty
              ? const Text('No QR URL')
              : Image.network(url, height: 220, fit: BoxFit.contain),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      _snack('Load QR failed: $e', isError: true);
    }
  }

  void _goCreate() {
    Navigator.of(
      context,
    ).pushNamed('/admin/tables/create').then((_) => _fetch());
  }

  void _goEdit(TableEntity t) {
    Navigator.of(
      context,
    ).pushNamed('/admin/tables/edit', arguments: t.id).then((_) => _fetch());
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredSorted;
    final totalPages = (items.length / _pageSize).ceil().clamp(1, 1 << 31);
    final start = (_page - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, items.length);
    final pageItems = items.sublist(start < items.length ? start : 0, end);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Table List'),
        actions: [
          IconButton(onPressed: _fetch, icon: const Icon(Icons.refresh)),
          FilledButton(onPressed: _goCreate, child: const Text('+ Add')),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filters
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Search by table number...',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) {
                            setState(() {
                              _search = v.trim();
                              _page = 1;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<TableStatus?>(
                        value: _filterStatus,
                        hint: const Text('All status'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('ALL'),
                          ),
                          ...TableStatus.values.map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.label),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() {
                          _filterStatus = v;
                          _page = 1;
                        }),
                      ),
                      const SizedBox(width: 12),
                      // Sort controls
                      DropdownButton<String>(
                        value: _sortKey,
                        hint: const Text('Sort by'),
                        items: const [
                          DropdownMenuItem(
                            value: 'number',
                            child: Text('Number'),
                          ),
                          DropdownMenuItem(
                            value: 'capacity',
                            child: Text('Capacity'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _sortKey = v),
                      ),
                      IconButton(
                        onPressed: () =>
                            setState(() => _ascending = !_ascending),
                        icon: Icon(
                          _ascending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                        ),
                        tooltip: 'Toggle sort direction',
                      ),
                    ],
                  ),
                ),

                // Table
                Expanded(
                  child: pageItems.isEmpty
                      ? const Center(child: Text('No tables found'))
                      : ListView.separated(
                          itemCount: pageItems.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final t = pageItems[i];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text('F${t.number}'),
                              ),
                              title: Text('Capacity: ${t.capacity}'),
                              subtitle: Text(t.location ?? 'Not specified'),
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  // status dropdown
                                  DropdownButton<TableStatus>(
                                    value: t.status,
                                    items: TableStatus.values
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s.label),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (s) {
                                      if (s != null) _changeStatus(t, s);
                                    },
                                  ),
                                  IconButton(
                                    onPressed: () => _showQr(t),
                                    icon: const Icon(Icons.qr_code_2),
                                  ),
                                  IconButton(
                                    onPressed: () => _goEdit(t),
                                    icon: const Icon(Icons.edit),
                                  ),
                                  IconButton(
                                    onPressed: () => _confirmDelete(t),
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // Pagination
                if (totalPages > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _page > 1
                              ? () => setState(() => _page--)
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text('Page $_page / $totalPages'),
                        IconButton(
                          onPressed: _page < totalPages
                              ? () => setState(() => _page++)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
