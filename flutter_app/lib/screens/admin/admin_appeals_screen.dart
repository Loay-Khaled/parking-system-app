import 'package:flutter/material.dart';
import '../../models/appeal.dart';
import '../../services/appeal_service.dart';
import '../../theme/app_theme.dart';
import 'admin_bottom_nav.dart';

class AdminAppealsScreen extends StatefulWidget {
  const AdminAppealsScreen({super.key});

  @override
  State<AdminAppealsScreen> createState() => _AdminAppealsScreenState();
}

class _AdminAppealsScreenState extends State<AdminAppealsScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Appeal> _appeals = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _loadPendingAppeals();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_loading && !_loadingMore && _hasMore) {
        _loadMoreAppeals();
      }
    }
  }

  Future<void> _loadPendingAppeals() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _page = 1;
        _appeals = [];
      });
    }
    try {
      final response = await AppealService.fetchPendingAppeals(page: 1);
      final List<dynamic> list = response['appeals'] ?? [];
      final Map<String, dynamic> pagination = response['pagination'] ?? {};

      if (mounted) {
        setState(() {
          _appeals = list.map((a) => Appeal.fromJson(a)).toList();
          _hasMore = pagination['hasMore'] ?? false;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load appeals: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _loadMoreAppeals() async {
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final response = await AppealService.fetchPendingAppeals(page: nextPage);
      final List<dynamic> list = response['appeals'] ?? [];
      final Map<String, dynamic> pagination = response['pagination'] ?? {};

      if (mounted) {
        setState(() {
          _appeals.addAll(list.map((a) => Appeal.fromJson(a)).toList());
          _page = nextPage;
          _hasMore = pagination['hasMore'] ?? false;
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load more appeals: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _resolve(Appeal appeal, String decision) async {
    final noteCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(decision == 'approved' ? 'Approve Appeal' : 'Reject Appeal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to ${decision == 'approved' ? 'approve' : 'reject'} this appeal for ${appeal.penaltyAmount.toInt()} EGP?'),
            const SizedBox(height: 16),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Admin Note (Optional)',
                hintText: 'e.g. Approved due to exit gate scanner issues...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: decision == 'approved' ? AppColors.success : AppColors.error,
            ),
            child: Text(decision == 'approved' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await AppealService.resolveAppeal(
        appealId: appeal.id,
        decision: decision,
        adminNote: noteCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appeal resolved successfully as $decision'),
            backgroundColor: decision == 'approved' ? AppColors.success : AppColors.error,
          ),
        );
      }
      _loadPendingAppeals();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resolve appeal: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Manage Penalty Appeals'),
        backgroundColor: const Color(0xFF1E3A5F),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPendingAppeals,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _appeals.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No pending appeals 🎉',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.foreground),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'All penalty disputes have been resolved.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.muted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _appeals.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _appeals.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                          ),
                        );
                      }
                      final appeal = _appeals[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  appeal.userName.isNotEmpty ? appeal.userName : 'User Details',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.foreground,
                                  ),
                                ),
                                Text(
                                  '${appeal.penaltyAmount.toInt()} EGP',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              appeal.userEmail,
                              style: const TextStyle(fontSize: 12, color: AppColors.muted),
                            ),
                            const SizedBox(height: 12),
                            if (appeal.spotId.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Spot: Zone ${appeal.zone} – ${appeal.spotId}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            const Text(
                              'Dispute Reason:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.foreground),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              appeal.reason,
                              style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: AppColors.border),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _resolve(appeal, 'rejected'),
                                  icon: const Icon(Icons.close, size: 16),
                                  label: const Text('Reject'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    side: const BorderSide(color: AppColors.error),
                                    minimumSize: const Size(100, 40),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: () => _resolve(appeal, 'approved'),
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Approve'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(100, 40),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 0),
    );
  }
}
