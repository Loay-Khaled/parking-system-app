import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/api_constants.dart';
import 'admin_bottom_nav.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  static const _primary = Color(0xFF1E3A5F);

  List<dynamic> _users = [];
  bool _loadingUsers = true;
  bool _sending = false;

  String _selectedUserId = 'all';
  String _selectedType = 'info';
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _modalSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final data = await ApiService.get(ApiConstants.adminUsersListAll);
      setState(() {
        if (data is Map && data['users'] is List) {
          _users = List.from(data['users']);
        } else {
          _users = [];
        }
        _loadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _users = [];
        _selectedUserId = 'all';
        _loadingUsers = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load users. Tap refresh to try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _send() async {
    final title = _titleCtrl.text.trim();
    final message = _messageCtrl.text.trim();
    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title and message are required'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await ApiService.post(ApiConstants.adminSendNotification, {
        'userId': _selectedUserId,
        'title': title,
        'message': message,
        'type': _selectedType,
      });
      if (!mounted) return;

      String recipientName = 'All Users';
      if (_selectedUserId != 'all') {
        final targetUser = _users.firstWhere(
          (u) => (u['_id'] ?? u['id'] ?? '').toString() == _selectedUserId,
          orElse: () => null,
        );
        if (targetUser != null) {
          recipientName = targetUser['name'] ?? 'Selected User';
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notification sent to $recipientName.'),
          backgroundColor: Colors.green,
        ),
      );
      _titleCtrl.clear();
      _messageCtrl.clear();
      setState(() {
        _selectedUserId = 'all';
        _selectedType = 'info';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'success':
        return const Color(0xFF10B981);
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'error':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning_amber;
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  String _getSelectedUserLabel() {
    final user = _users.firstWhere(
      (u) => (u['_id'] ?? u['id'] ?? '').toString() == _selectedUserId,
      orElse: () => null,
    );
    if (user != null) {
      return '${user['name'] ?? ''} (${user['email'] ?? ''})';
    }
    return 'Select Recipient';
  }

  void _showRecipientPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = _modalSearchQuery.toLowerCase().trim();
            final filteredUsers = _users.where((u) {
              final name = (u['name'] ?? '').toString().toLowerCase();
              final email = (u['email'] ?? '').toString().toLowerCase();
              return name.contains(query) || email.contains(query);
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Recipient',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        _modalSearchQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.people, color: Color(0xFF1E3A5F)),
                          title: const Text('All Users', style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: _selectedUserId == 'all'
                              ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedUserId = 'all';
                            });
                            Navigator.pop(context);
                          },
                        ),
                        const Divider(height: 1),
                        ...filteredUsers.map((user) {
                          final id = (user['_id'] ?? user['id'] ?? '').toString();
                          final name = user['name'] ?? '';
                          final email = user['email'] ?? '';
                          final isSelected = _selectedUserId == id;
                          return ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A5F).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: Color(0xFF1E3A5F),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(email, style: const TextStyle(fontSize: 12)),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedUserId = id;
                              });
                              Navigator.pop(context);
                            },
                          );
                        }),
                        if (filteredUsers.isEmpty && query.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(
                              child: Text(
                                'No users match search query',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      _modalSearchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasSelectedUser = _selectedUserId == 'all' || _users.any((u) => (u['_id'] ?? u['id'] ?? '').toString() == _selectedUserId);
    final dropdownValue = hasSelectedUser ? _selectedUserId : 'all';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: _primary,
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send Notification',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            Text(
              'Broadcast or target a user',
              style: TextStyle(fontSize: 11, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadUsers,
            tooltip: 'Refresh user list',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _card(
              'Recipient',
              Icons.people_alt,
              GestureDetector(
                onTap: _loadingUsers ? null : _showRecipientPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _loadingUsers
                              ? 'Loading users...'
                              : dropdownValue == 'all'
                                  ? 'All Users'
                                  : _getSelectedUserLabel(),
                          style: TextStyle(
                            fontSize: 15,
                            color: _loadingUsers ? const Color(0xFF94A3B8) : const Color(0xFF1A1F36),
                          ),
                        ),
                      ),
                      if (_loadingUsers)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _card(
              'Message Details',
              Icons.message,
              Column(
                children: [
                  TextField(
                    controller: _titleCtrl,
                    decoration: _inputDecoration('Notification title'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _messageCtrl,
                    maxLines: 3,
                    decoration: _inputDecoration('Message body'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card(
              'Type',
              Icons.label_important,
              Row(
                children: ['success', 'info', 'warning', 'error'].map((t) {
                  final isSelected = _selectedType == t;
                  final color = _typeColor(t);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = t),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? color : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(_typeIcon(t), color: color, size: 18),
                            const SizedBox(height: 3),
                            Text(
                              t,
                              style: TextStyle(
                                fontSize: 9,
                                color: color,
                                fontWeight:
                                    isSelected ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _sending ? 'Sending…' : 'Send Notification',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 4),
    );
  }

  Widget _card(String title, IconData icon, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1A1F36),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1E3A5F), width: 2),
      ),
    );
  }
}
