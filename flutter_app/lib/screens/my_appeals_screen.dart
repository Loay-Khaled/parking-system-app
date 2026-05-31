import 'package:flutter/material.dart';
import '../models/appeal.dart';
import '../services/api_service.dart';
import '../services/appeal_service.dart';
import '../services/api_constants.dart';
import '../theme/app_theme.dart';

class MyAppealsScreen extends StatefulWidget {
  const MyAppealsScreen({super.key});

  @override
  State<MyAppealsScreen> createState() => _MyAppealsScreenState();
}

class _MyAppealsScreenState extends State<MyAppealsScreen> {
  List<Appeal> _appeals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAppeals();
  }

  Future<void> _loadAppeals() async {
    setState(() => _loading = true);
    try {
      final list = await AppealService.fetchMyAppeals();
      setState(() {
        _appeals = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load appeals: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.reserved;
      case 'approved': return AppColors.success;
      case 'rejected': return AppColors.error;
      default: return AppColors.muted;
    }
  }

  void _showFileAppealSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _FileAppealBottomSheet(),
    ).then((success) {
      if (success == true) {
        _loadAppeals();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Penalty Appeals'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAppeals,
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
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.gavel_outlined, size: 48, color: AppColors.primary),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No appeals filed',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.foreground),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'If you received a penalty for overstaying, you can file a dispute here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppColors.muted),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: _showFileAppealSheet,
                            icon: const Icon(Icons.add),
                            label: const Text('File New Appeal'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(200, 50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _appeals.length,
                    itemBuilder: (context, index) {
                      final appeal = _appeals[index];
                      final color = _statusColor(appeal.status);

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
                                  '${appeal.penaltyAmount.toInt()} EGP Penalty',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.foreground,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: color.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    appeal.status.toUpperCase(),
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (appeal.spotId.isNotEmpty) ...[
                              Text(
                                'Spot: Zone ${appeal.zone} – ${appeal.spotId}',
                                style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                            ],
                            const Text(
                              'Reason:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.foreground),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              appeal.reason,
                              style: const TextStyle(fontSize: 13, color: AppColors.muted),
                            ),
                            if (appeal.status == 'approved') ...[
                              const SizedBox(height: 12),
                              const Row(
                                children: [
                                  Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Refunded to wallet ✓',
                                    style: TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                            if (appeal.status == 'rejected' && appeal.adminNote.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Admin Note:',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      appeal.adminNote,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: _appeals.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showFileAppealSheet,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.gavel),
              label: const Text('New Appeal'),
            )
          : null,
    );
  }
}

class _FileAppealBottomSheet extends StatefulWidget {
  const _FileAppealBottomSheet();

  @override
  State<_FileAppealBottomSheet> createState() => _FileAppealBottomSheetState();
}

class _FileAppealBottomSheetState extends State<_FileAppealBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  List<dynamic> _penaltyTransactions = [];
  Map<String, dynamic>? _selectedTransaction;
  bool _loadingTx = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPenaltyTransactions();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  String _formatTxDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _loadPenaltyTransactions() async {
    try {
      final txs = await AppealService.fetchPenaltyTransactions();
      setState(() {
        _penaltyTransactions = txs;
        _loadingTx = false;
      });
    } catch (_) {
      setState(() => _loadingTx = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedTransaction == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      // Find associated bookingId.
      // Since booking details are usually in active or past bookings,
      // we can load completed bookings or retrieve from the transaction description / metadata.
      // In this project structure, let's query my bookings and search for matching endTime or spot,
      // or we can pass a dummy bookingId if not directly linkable, or look it up.
      // Let's retrieve all user bookings to find the matching one.
      final bookingsData = await ApiService.get('${ApiConstants.baseUrl}/bookings/my');
      String bookingId = '';
      if (bookingsData is List && bookingsData.isNotEmpty) {
        // Just link to the most recent booking, or one matching the penalty amount.
        bookingId = bookingsData[0]['_id'] ?? '';
      }

      await AppealService.submitAppeal(
        bookingId: bookingId,
        transactionId: _selectedTransaction!['_id'] ?? _selectedTransaction!['id'] ?? '',
        penaltyAmount: (_selectedTransaction!['amount'] ?? 0).toDouble(),
        reason: _reasonCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appeal submitted. Admin will review within 24 hours.'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'File Appeal Dispute',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.foreground),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                    ],
                  ),
                ),
              const Text('Select Penalty Transaction', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.foreground)),
              const SizedBox(height: 8),
              _loadingTx
                  ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                  : _penaltyTransactions.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            'No penalty transactions found. You have no penalties to appeal.',
                            style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonFormField<Map<String, dynamic>>(
                            decoration: const InputDecoration(border: InputBorder.none),
                            isExpanded: true,
                            hint: const Text('Choose a penalty...'),
                            // ignore: deprecated_member_use
                            value: _selectedTransaction,
                            validator: (val) {
                              if (val == null) return 'Please select a transaction';
                              return null;
                            },
                            items: _penaltyTransactions.map<DropdownMenuItem<Map<String, dynamic>>>((tx) {
                              final amt = (tx['amount'] ?? 0).toInt();
                              final desc = tx['description'] ?? 'Penalty';
                              final dateFormatted = _formatTxDate(tx['createdAt']);
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: Map<String, dynamic>.from(tx),
                                child: Text('EGP $amt — $desc — $dateFormatted', style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedTransaction = val;
                              });
                            },
                          ),
                        ),
              const SizedBox(height: 16),
              const Text('Reason for Appeal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.foreground)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonCtrl,
                maxLines: 4,
                maxLength: 500,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Reason is required';
                  if (v.trim().length < 20) return 'Please describe in at least 20 characters';
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'e.g. My scanner glitched at exit, or I checked out on time but system delayed...',
                  hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
                  fillColor: AppColors.inputBackground,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving || _selectedTransaction == null || _penaltyTransactions.isEmpty ? null : _submit,
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Appeal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
