// lib/admin/pages/chatbot_management_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/chatbot_service.dart';
import '../../auths/api_service.dart';

class ChatbotManagementPage extends StatefulWidget {
  const ChatbotManagementPage({super.key});

  @override
  State<ChatbotManagementPage> createState() => _ChatbotManagementPageState();
}

class _ChatbotManagementPageState extends State<ChatbotManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ChatbotService? _chatbotService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatbotService ??= ChatbotService(context.read<ApiService>());
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
        title: const Text('Chatbot Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.chat), text: 'Sessions'),
            Tab(icon: Icon(Icons.help_outline), text: 'FAQ'),
            Tab(icon: Icon(Icons.library_books), text: 'Knowledge Base'),
          ],
        ),
      ),
      body: _chatbotService == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _SessionsTab(chatbotService: _chatbotService!),
                _FAQTab(chatbotService: _chatbotService!),
                _KnowledgeBaseTab(chatbotService: _chatbotService!),
              ],
            ),
    );
  }
}

// Sessions Tab
class _SessionsTab extends StatefulWidget {
  final ChatbotService chatbotService;

  const _SessionsTab({required this.chatbotService});

  @override
  State<_SessionsTab> createState() => _SessionsTabState();
}

class _SessionsTabState extends State<_SessionsTab> {
  List<Map<String, dynamic>> _sessions = [];
  Map<String, dynamic>? _selectedSession;
  List<Map<String, dynamic>> _history = [];
  bool _loading = false;
  bool _deleting = false;
  Map<String, dynamic> _analytics = {'totalSessions': 0, 'totalMessages': 0};

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _loadAnalytics();
  }

  Future<void> _loadSessions() async {
    setState(() => _loading = true);
    try {
      final sessions = await widget.chatbotService.getSessions();
      setState(() => _sessions = sessions);
    } catch (e) {
      _showError('Failed to load sessions: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      final analytics = await widget.chatbotService.getBasicAnalytics();
      setState(() => _analytics = analytics);
    } catch (e) {
      // Silent fail for analytics
    }
  }

  Future<void> _openSession(Map<String, dynamic> session) async {
    try {
      final details = await widget.chatbotService.getSessionDetails(
        session['sessionId'],
      );
      setState(() {
        _selectedSession = details['session'] ?? session;
        _history =
            (details['history'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      });
    } catch (e) {
      _showError('Failed to open session: $e');
    }
  }

  Future<void> _handoverSession(Map<String, dynamic> session) async {
    try {
      await widget.chatbotService.handoverSession(session['sessionId']);
      _loadSessions();
      if (_selectedSession != null &&
          _selectedSession!['sessionId'] == session['sessionId']) {
        _openSession(session);
      }
      _showSuccess('Session handed over successfully');
    } catch (e) {
      _showError('Failed to handover session: $e');
    }
  }

  Future<void> _deleteSession(Map<String, dynamic> session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text(
          'Are you sure you want to delete session ${session['sessionId']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await widget.chatbotService.deleteSession(session['sessionId']);
      if (_selectedSession != null &&
          _selectedSession!['sessionId'] == session['sessionId']) {
        setState(() {
          _selectedSession = null;
          _history = [];
        });
      }
      _loadSessions();
      _showSuccess('Session deleted successfully');
    } catch (e) {
      _showError('Failed to delete session: $e');
    } finally {
      setState(() => _deleting = false);
    }
  }

  Future<void> _clearAllSessions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Sessions'),
        content: const Text(
          'Are you sure you want to delete ALL sessions? This action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await widget.chatbotService.clearAllSessions();
      setState(() {
        _selectedSession = null;
        _history = [];
      });
      _loadSessions();
      _showSuccess('All sessions cleared successfully');
    } catch (e) {
      _showError('Failed to clear all sessions: $e');
    } finally {
      setState(() => _deleting = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ended':
        return Colors.red;
      case 'handed_over':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Analytics Card
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Sessions',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${_analytics['totalSessions']}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Messages',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${_analytics['totalMessages']}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _deleting || _sessions.isEmpty
                      ? null
                      : _clearAllSessions,
                  icon: const Icon(Icons.delete_sweep),
                  label: Text(_deleting ? 'Deleting...' : 'Clear All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Sessions List
        Expanded(
          child: Row(
            children: [
              // Sessions List
              Expanded(
                flex: 1,
                child: Card(
                  margin: const EdgeInsets.only(left: 16, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Sessions',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Expanded(
                        child: _loading
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                itemCount: _sessions.length,
                                itemBuilder: (context, index) {
                                  final session = _sessions[index];
                                  return ListTile(
                                    title: Text(
                                      session['sessionId'],
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                              session['status'],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            session['status'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(session['language'] ?? 'en'),
                                      ],
                                    ),
                                    trailing: PopupMenuButton(
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'open',
                                          child: Text('Open'),
                                        ),
                                        if (session['status'] !=
                                                'handed_over' &&
                                            session['status'] != 'ended')
                                          const PopupMenuItem(
                                            value: 'handover',
                                            child: Text('Handover'),
                                          ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete'),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'open':
                                            _openSession(session);
                                            break;
                                          case 'handover':
                                            _handoverSession(session);
                                            break;
                                          case 'delete':
                                            _deleteSession(session);
                                            break;
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              // Conversation View
              Expanded(
                flex: 1,
                child: Card(
                  margin: const EdgeInsets.only(right: 16, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Conversation',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Expanded(
                        child: _selectedSession == null
                            ? const Center(
                                child: Text(
                                  'Select a session to view conversation',
                                ),
                              )
                            : Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: _history.length,
                                  itemBuilder: (context, index) {
                                    final message = _history[index];
                                    final isBot = message['sender'] == 'bot';
                                    final isAgent =
                                        message['sender'] == 'agent';

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 10,
                                                backgroundColor: isBot
                                                    ? Colors.blue
                                                    : (isAgent
                                                          ? Colors.orange
                                                          : Colors.green),
                                                child: Text(
                                                  isBot
                                                      ? '🤖'
                                                      : (isAgent ? '👤' : '🧑'),
                                                  style: const TextStyle(
                                                    fontSize: 8,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                isBot
                                                    ? 'BOT'
                                                    : (isAgent
                                                          ? (message['senderName'] ??
                                                                'Agent')
                                                          : (message['senderName'] ??
                                                                'Customer')),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            margin: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              message['contentMasked'] ??
                                                  message['content'] ??
                                                  '',
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                      if (_selectedSession != null) ...[
                        if (_selectedSession!['rating'] != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Rating: ${_selectedSession!['rating']}★',
                            ),
                          ),
                        if (_selectedSession!['ratingNote'] != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Note: ${_selectedSession!['ratingNote']}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// FAQ Tab
class _FAQTab extends StatefulWidget {
  final ChatbotService chatbotService;

  const _FAQTab({required this.chatbotService});

  @override
  State<_FAQTab> createState() => _FAQTabState();
}

class _FAQTabState extends State<_FAQTab> {
  List<Map<String, dynamic>> _faqs = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadFAQs();
  }

  Future<void> _loadFAQs() async {
    setState(() => _loading = true);
    try {
      final faqs = await widget.chatbotService.getFAQs();
      setState(() => _faqs = faqs);
    } catch (e) {
      _showError('Failed to load FAQs: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteFAQ(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete FAQ'),
        content: const Text('Are you sure you want to delete this FAQ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.chatbotService.deleteFAQ(id);
      _loadFAQs();
      _showSuccess('FAQ deleted successfully');
    } catch (e) {
      _showError('Failed to delete FAQ: $e');
    }
  }

  void _showFAQDialog([Map<String, dynamic>? faq]) {
    final isEditing = faq != null;
    final questionController = TextEditingController(
      text: faq?['question'] ?? '',
    );
    final answerController = TextEditingController(text: faq?['answer'] ?? '');
    final tagsController = TextEditingController(text: faq?['tags'] ?? '');
    String selectedLanguage = faq?['language'] ?? 'en';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit FAQ' : 'Add FAQ'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(labelText: 'Question'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: answerController,
                  decoration: const InputDecoration(labelText: 'Answer'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedLanguage,
                  decoration: const InputDecoration(labelText: 'Language'),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'vi', child: Text('Vietnamese')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => selectedLanguage = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags (comma-separated)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'question': questionController.text,
                'answer': answerController.text,
                'language': selectedLanguage,
                'tags': tagsController.text,
              };

              try {
                if (isEditing) {
                  await widget.chatbotService.updateFAQ(
                    faq['id'].toString(),
                    data,
                  );
                } else {
                  await widget.chatbotService.createFAQ(data);
                }
                Navigator.pop(context);
                _loadFAQs();
                _showSuccess(
                  isEditing
                      ? 'FAQ updated successfully'
                      : 'FAQ created successfully',
                );
              } catch (e) {
                _showError('Failed to save FAQ: $e');
              }
            },
            child: Text(isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FAQ Management',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ElevatedButton.icon(
                onPressed: () => _showFAQDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add FAQ'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _faqs.length,
                  itemBuilder: (context, index) {
                    final faq = _faqs[index];
                    return Card(
                      child: ExpansionTile(
                        title: Text(
                          faq['question'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: faq['language'] == 'vi'
                                    ? Colors.red
                                    : Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                faq['language'].toString().toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            if (faq['tags'] != null &&
                                faq['tags'].toString().isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                faq['tags'],
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _showFAQDialog(faq);
                                break;
                              case 'delete':
                                _deleteFAQ(faq['id'].toString());
                                break;
                            }
                          },
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(faq['answer']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// Knowledge Base Tab
class _KnowledgeBaseTab extends StatefulWidget {
  final ChatbotService chatbotService;

  const _KnowledgeBaseTab({required this.chatbotService});

  @override
  State<_KnowledgeBaseTab> createState() => _KnowledgeBaseTabState();
}

class _KnowledgeBaseTabState extends State<_KnowledgeBaseTab> {
  List<Map<String, dynamic>> _articles = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadKnowledgeBase();
  }

  Future<void> _loadKnowledgeBase() async {
    setState(() => _loading = true);
    try {
      final articles = await widget.chatbotService.getKnowledgeBase();
      setState(() => _articles = articles);
    } catch (e) {
      _showError('Failed to load knowledge base: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteArticle(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Article'),
        content: const Text('Are you sure you want to delete this article?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.chatbotService.deleteKBArticle(id);
      _loadKnowledgeBase();
      _showSuccess('Article deleted successfully');
    } catch (e) {
      _showError('Failed to delete article: $e');
    }
  }

  void _showArticleDialog([Map<String, dynamic>? article]) {
    final isEditing = article != null;
    final titleController = TextEditingController(
      text: article?['title'] ?? '',
    );
    final contentController = TextEditingController(
      text: article?['content'] ?? '',
    );
    final tagsController = TextEditingController(text: article?['tags'] ?? '');
    String selectedLanguage = article?['language'] ?? 'en';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Article' : 'Add Article'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'Content'),
                  maxLines: 5,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedLanguage,
                  decoration: const InputDecoration(labelText: 'Language'),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'vi', child: Text('Vietnamese')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => selectedLanguage = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags (comma-separated)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'title': titleController.text,
                'content': contentController.text,
                'language': selectedLanguage,
                'tags': tagsController.text,
              };

              try {
                if (isEditing) {
                  await widget.chatbotService.updateKBArticle(
                    article['id'].toString(),
                    data,
                  );
                } else {
                  await widget.chatbotService.createKBArticle(data);
                }
                Navigator.pop(context);
                _loadKnowledgeBase();
                _showSuccess(
                  isEditing
                      ? 'Article updated successfully'
                      : 'Article created successfully',
                );
              } catch (e) {
                _showError('Failed to save article: $e');
              }
            },
            child: Text(isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Knowledge Base',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ElevatedButton.icon(
                onPressed: () => _showArticleDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Article'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _articles.length,
                  itemBuilder: (context, index) {
                    final article = _articles[index];
                    return Card(
                      child: ExpansionTile(
                        title: Text(
                          article['title'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: article['language'] == 'vi'
                                    ? Colors.red
                                    : Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                article['language'].toString().toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            if (article['tags'] != null &&
                                article['tags'].toString().isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                article['tags'],
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _showArticleDialog(article);
                                break;
                              case 'delete':
                                _deleteArticle(article['id'].toString());
                                break;
                            }
                          },
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(article['content']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
