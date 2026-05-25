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
      final data = await ApiService.get(ApiConstants.adminUsers);
      setState(() {
        _users = data is List
            ? data.where((u) => (u as Map<String, dynamic>)['isAdmin'] != true).toList()
            : [];
        _loadingUsers = false;
      });
    } catch (_) {
      setState(() => _loadingUsers = false);
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
      final result = await ApiService.post(ApiConstants.adminSendNotification, {
        'userId': _selectedUserId,
        'title': title,
        'message': message,
        'type': _selectedType,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((result as Map)['message']?.toString() ?? 'Notification sent!'),
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

  @override
  Widget build(BuildContext context) {
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _card(
              'Recipient',
              Icons.people_alt,
              _loadingUsers
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedUserId,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('All Users'),
                          ),
                          ..._users.map((u) {
                            final user = u as Map<String, dynamic>;
                            final id = (user['_id'] ?? user['id'] ?? '').toString();
                            return DropdownMenuItem(
                              value: id,
                              child: Text(
                                '${user['name'] ?? ''} (${user['email'] ?? ''})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (v) => setState(() => _selectedUserId = v ?? 'all'),
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
