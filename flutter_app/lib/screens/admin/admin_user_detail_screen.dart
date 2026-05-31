import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/api_constants.dart';
import '../../services/auth_service.dart';

// Disability types — mirrors the server-side DISABILITY_TYPES constant in User.js
const _kDisabilityTypes = [
  'Mobility Impairment',
  'Visual Impairment',
  'Hearing Impairment',
  'Other',
];

class AdminUserDetailScreen extends StatefulWidget {
  final String userId;
  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  static const _primary = Color(0xFF1E3A5F);

  Map<String, dynamic>? _user;
  List<dynamic> _bookings = [];
  List<dynamic> _transactions = [];
  int _openAppeals = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.get(ApiConstants.adminUserById(widget.userId));
      if (!mounted) return;
      setState(() {
        _user = data['user'] as Map<String, dynamic>?;
        _bookings = data['recentBookings'] as List? ?? [];
        _transactions = data['recentTransactions'] as List? ?? [];
        _openAppeals = data['openAppeals'] as int? ?? 0;
        _loading = false;
      });
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('401') || errStr.toLowerCase().contains('unauthorized')) {
        await AuthService.clearSession();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      if (!mounted) return;
      setState(() { _error = errStr.replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  // ── Permit actions ─────────────────────────────────────────────────────────

  Future<void> _showGrantPermitSheet() async {
    String? selectedType = _kDisabilityTypes.first;
    final noteCtrl = TextEditingController();
    bool granting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModal) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Grant Accessibility Permit',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1F36))),
                const SizedBox(height: 4),
                const Text('Select the user\'s disability type and optionally add a note.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                const SizedBox(height: 20),
                const Text('Disability Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1F36))),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: _kDisabilityTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setModal(() => selectedType = v),
                ),
                const SizedBox(height: 16),
                const Text('Admin Note (optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1F36))),
                const SizedBox(height: 8),
                TextFormField(
                  controller: noteCtrl,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'e.g. Medical documentation verified.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: granting
                        ? null
                        : () async {
                            setModal(() => granting = true);
                            try {
                              await ApiService.patch(
                                ApiConstants.adminUserAccessibility(widget.userId),
                                {
                                  'status': 'approved',
                                  'disabilityType': selectedType,
                                  'adminNote': noteCtrl.text.trim(),
                                },
                              );
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Permit granted successfully'), backgroundColor: Colors.green),
                              );
                              _loadDetail();
                            } catch (e) {
                              setModal(() => granting = false);
                              if (!ctx.mounted) return;
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                              );
                            }
                          },
                    child: granting
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Grant Permit', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
    noteCtrl.dispose();
  }

  Future<void> _showRevokeDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Permit'),
        content: const Text(
          'This will revoke the user\'s accessibility permit. Any active bookings on accessibility spots will be automatically cancelled and fully refunded. This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.patch(
        ApiConstants.adminUserAccessibility(widget.userId),
        {'status': 'none'},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permit revoked. Active bookings refunded.'), backgroundColor: Colors.orange),
      );
      _loadDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: _primary,
        title: const Text('User Detail', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadDetail),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A5F)))
          : _error != null
              ? _buildErrorState()
              : _user == null
                  ? const Center(child: Text('User not found'))
                  : RefreshIndicator(
                      onRefresh: _loadDetail,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildHeaderCard(),
                          const SizedBox(height: 14),
                          _buildStatsRow(),
                          const SizedBox(height: 14),
                          _buildAccessibilityCard(),
                          const SizedBox(height: 14),
                          _buildBookingsSection(),
                          const SizedBox(height: 14),
                          _buildTransactionsSection(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              onPressed: _loadDetail,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final user = _user!;
    final isAdmin = user['isAdmin'] == true;
    final name = user['name'] as String? ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(initial, style: const TextStyle(color: _primary, fontWeight: FontWeight.w800, fontSize: 24)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(name,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1F36)),
                        overflow: TextOverflow.ellipsis)),
                    if (isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(4)),
                        child: const Text('ADMIN', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(user['email'] as String? ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                Text('ID: ${user['idNumber'] ?? '—'}  ·  Plate: ${user['carPlate'] ?? '—'}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                const SizedBox(height: 4),
                Text('Wallet: ${((user['walletBalance'] ?? 0) as num).toStringAsFixed(2)} EGP',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final user = _user!;
    return Row(
      children: [
        _statTile('Bookings', '${user['totalBookings'] ?? 0}', Icons.book_online, Colors.blue),
        const SizedBox(width: 10),
        _statTile('Spent', '${((user['totalSpent'] ?? 0) as num).toStringAsFixed(0)} EGP', Icons.payments, Colors.green),
        const SizedBox(width: 10),
        _statTile('Penalties', '${((user['activePenalties'] ?? 0) as num).toStringAsFixed(0)} EGP', Icons.warning, Colors.orange),
        const SizedBox(width: 10),
        _statTile('Appeals', '$_openAppeals', Icons.gavel, Colors.purple),
      ],
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessibilityCard() {
    final user = _user!;
    final permit = user['accessibilityPermit'] as Map<String, dynamic>? ?? {};
    final status = permit['status'] as String? ?? 'none';
    final isApproved = status == 'approved';
    final disabilityType = permit['disabilityType'] as String? ?? '';
    final adminNote = permit['adminNote'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.accessible_forward, color: Color(0xFF1E3A5F), size: 20),
              SizedBox(width: 8),
              Text('Accessibility Permit', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1F36))),
            ],
          ),
          const SizedBox(height: 12),
          // Status chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isApproved
                  ? const Color(0xFF1D4ED8).withValues(alpha: 0.1)
                  : const Color(0xFF94A3B8).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isApproved
                  ? 'Approved${disabilityType.isNotEmpty ? " – $disabilityType" : ""}'
                  : 'None',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isApproved ? const Color(0xFF1D4ED8) : const Color(0xFF94A3B8),
              ),
            ),
          ),
          if (adminNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Note: $adminNote', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showGrantPermitSheet,
                  icon: const Icon(Icons.verified_user_outlined, size: 16),
                  label: const Text('Grant Permit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1D4ED8),
                    side: const BorderSide(color: Color(0xFF1D4ED8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isApproved ? _showRevokeDialog : null,
                  icon: const Icon(Icons.remove_circle_outline, size: 16),
                  label: const Text('Revoke Permit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: isApproved ? Colors.red : Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.book_online, color: Color(0xFF1E3A5F), size: 20),
              SizedBox(width: 8),
              Text('Recent Bookings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1F36))),
            ],
          ),
          const SizedBox(height: 12),
          if (_bookings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 36, color: Color(0xFF94A3B8)),
                    SizedBox(height: 8),
                    Text('No bookings yet', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            ...(_bookings.map((b) => _buildBookingTile(b as Map<String, dynamic>)).toList()),
        ],
      ),
    );
  }

  Widget _buildBookingTile(Map<String, dynamic> booking) {
    final status = booking['status'] as String? ?? '';
    Color statusColor;
    switch (status) {
      case 'active': statusColor = Colors.blue; break;
      case 'completed': statusColor = Colors.green; break;
      case 'cancelled': statusColor = Colors.red; break;
      default: statusColor = Colors.grey;
    }

    final start = booking['startTime'] != null
        ? DateTime.tryParse(booking['startTime'] as String)
        : null;
    final dateStr = start != null
        ? '${start.day}/${start.month}/${start.year}'
        : '—';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.local_parking, color: statusColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${booking['spotId'] ?? '—'} · Zone ${booking['zone'] ?? '—'}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1F36))),
                  Text('$dateStr · ${booking['duration'] ?? '?'}h · ${((booking['cost'] ?? 0) as num).toStringAsFixed(0)} EGP',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long, color: Color(0xFF1E3A5F), size: 20),
              SizedBox(width: 8),
              Text('Recent Transactions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1F36))),
            ],
          ),
          const SizedBox(height: 12),
          if (_transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 36, color: Color(0xFF94A3B8)),
                    SizedBox(height: 8),
                    Text('No transactions yet', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            ...(_transactions.map((t) => _buildTransactionTile(t as Map<String, dynamic>)).toList()),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    final type = tx['type'] as String? ?? '';
    // Badge color mapping (mirrors CS1-B3 Transaction enum):
    // recharge = green, payment = blue, penalty = red, refund = teal
    Color badgeColor;
    IconData icon;
    switch (type) {
      case 'recharge':
        badgeColor = Colors.green;
        icon = Icons.add_circle_outline;
        break;
      case 'payment':
        badgeColor = Colors.blue;
        icon = Icons.payments_outlined;
        break;
      case 'penalty':
        badgeColor = Colors.red;
        icon = Icons.warning_amber_outlined;
        break;
      case 'refund':
        badgeColor = Colors.teal;
        icon = Icons.undo_outlined;
        break;
      default:
        badgeColor = Colors.grey;
        icon = Icons.swap_horiz;
    }

    final amount = (tx['amount'] ?? 0) as num;
    final desc = tx['description'] as String? ?? '';
    final created = tx['createdAt'] != null
        ? DateTime.tryParse(tx['createdAt'] as String)
        : null;
    final dateStr = created != null
        ? '${created.day}/${created.month}/${created.year}'
        : '—';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: badgeColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(desc.isNotEmpty ? desc : type,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF1A1F36)),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text(dateStr, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${type == 'penalty' || type == 'payment' ? '-' : '+'}${amount.toStringAsFixed(0)} EGP',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: (type == 'penalty' || type == 'payment') ? Colors.red : badgeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
