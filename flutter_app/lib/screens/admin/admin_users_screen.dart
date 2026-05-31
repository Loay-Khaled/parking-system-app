import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/api_constants.dart';
import '../../services/auth_service.dart';
import 'admin_bottom_nav.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  static const _primary = Color(0xFF1E3A5F);

  List<dynamic> _users = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _totalPages = 1;
  int _total = 0;

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers(reset: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({bool reset = false}) async {
    if (reset) {
      setState(() { _loading = true; _error = null; _page = 1; _users = []; });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final search = _searchQuery.trim();
      final url = '${ApiConstants.adminUsers}?page=$_page&limit=20${search.isNotEmpty ? '&search=${Uri.encodeComponent(search)}' : ''}';
      final data = await ApiService.get(url);

      // Handle 401 → redirect to login
      if (!mounted) return;
      final users = data['users'] as List? ?? [];
      setState(() {
        if (reset) {
          _users = users;
        } else {
          _users.addAll(users);
        }
        _total = data['total'] ?? _users.length;
        _totalPages = data['pages'] ?? 1;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('401') || errStr.toLowerCase().contains('unauthorized')) {
        await AuthService.clearSession();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      setState(() {
        _error = errStr;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _totalPages) return;
    _page++;
    await _loadUsers(reset: false);
  }

  void _onSearch(String value) {
    _searchQuery = value;
    _loadUsers(reset: true);
  }

  Future<void> _deleteUser(String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete "$userName" and all their bookings? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.delete(ApiConstants.adminDeleteUser(userId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted'), backgroundColor: Colors.green),
      );
      _loadUsers(reset: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: _primary,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Users', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            Text('$_total registered', style: const TextStyle(fontSize: 11, color: Colors.white60)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadUsers(reset: true),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by ID or National ID…',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onSubmitted: _onSearch,
              onChanged: (v) => setState(() {}), // update clear button visibility
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A5F)))
          : _error != null
              ? _buildError()
              : _users.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: () => _loadUsers(reset: true),
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollEndNotification &&
                              notification.metrics.extentAfter < 200) {
                            _loadMore();
                          }
                          return false;
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _users.length + (_loadingMore ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            if (i == _users.length) {
                              return const Center(child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(color: Color(0xFF1E3A5F)),
                              ));
                            }
                            return _userCard(_users[i] as Map<String, dynamic>);
                          },
                        ),
                      ),
                    ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 1),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 56, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isEmpty ? 'No users found' : 'No users match "$_searchQuery"',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            Text(_error!.replaceAll('Exception: ', ''),
                textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              onPressed: () => _loadUsers(reset: true),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> user) {
    final isAdmin = user['isAdmin'] == true;
    final userId = user['_id'] ?? user['id'] ?? '';
    final permitStatus = (user['accessibilityPermit'] as Map<String, dynamic>?)?['status'] ?? 'none';
    final hasPermit = permitStatus == 'approved';

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/admin-user-detail', arguments: userId)
          .then((_) => _loadUsers(reset: true)),
      onLongPress: () => _deleteUser(userId, user['name'] as String? ?? 'user'),
      child: Container(
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
                // Avatar initials circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (user['name'] as String? ?? '?').isNotEmpty
                          ? (user['name'] as String).substring(0, 1).toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Color(0xFF1E3A5F), fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(user['name'] ?? '',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1F36)),
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(4)),
                              child: const Text('ADMIN', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                            ),
                          ],
                          if (hasPermit) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFF1D4ED8), borderRadius: BorderRadius.circular(4)),
                              child: const Text('PERMIT', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ],
                      ),
                      Text(user['email'] ?? '',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 12),
            Row(
              children: [
                _chip(Icons.credit_card, user['carPlate'] ?? '—'),
                const SizedBox(width: 16),
                _chip(Icons.book_online, '${user['totalBookings'] ?? 0} bookings'),
                const SizedBox(width: 16),
                _chip(Icons.payments, '${((user['totalSpent'] ?? 0) as num).toStringAsFixed(0)} EGP'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }
}
