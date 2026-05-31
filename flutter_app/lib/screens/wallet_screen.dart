import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  User? _user;
  List<dynamic> _transactions = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      // Refresh user from API to get latest walletBalance
      final updatedUser = await AuthService.refreshUser();
      final txs = await ApiService.getTransactionHistory();
      setState(() {
        _user = updatedUser;
        _transactions = txs;
        _loading = false;
      });
    } catch (e) {
      // Fallback: try loading user from cache if offline
      final cachedUser = await AuthService.getUser();
      setState(() {
        _user = cachedUser;
        _errorMessage = 'Failed to load wallet data. Showing offline balance.';
        _loading = false;
      });
    }
  }

  void _showTopUpSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WalletTopUpBottomSheet(
        onSuccess: () {
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wallet topped up successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Custom Header
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                const Text(
                  'My Wallet',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          _buildBalanceCard(),
                          const SizedBox(height: 28),
                          
                          const Text(
                            'Recent Transactions',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.foreground),
                          ),
                          const SizedBox(height: 12),
                          _buildTransactionHistory(),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final balance = _user?.walletBalance ?? 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AAST PARKING CARD',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.2),
              ),
              Icon(Icons.contactless_outlined, color: Colors.white.withValues(alpha: 0.8), size: 28),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Available Balance',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '${balance.toStringAsFixed(2)} EGP',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _user?.name.toUpperCase() ?? '',
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              ElevatedButton.icon(
                onPressed: _showTopUpSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(120, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Top Up', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    if (_transactions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_outlined, size: 36, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Transactions Yet',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.foreground),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your payments and top-ups will show up here',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        final type = tx['type'] ?? 'recharge';
        final isRecharge = type == 'recharge';
        final amount = (tx['amount'] ?? 0.0).toDouble();
        final description = tx['description'] ?? '';
        final createdAtStr = tx['createdAt'];
        
        DateTime? dateTime;
        if (createdAtStr != null) {
          dateTime = DateTime.parse(createdAtStr).toLocal();
        }
        
        final formattedDate = dateTime != null
            ? DateFormat('dd MMM yyyy, hh:mm a').format(dateTime)
            : '-';

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isRecharge
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRecharge ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isRecharge ? AppColors.success : AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.foreground),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Text(
                '${isRecharge ? '+' : '-'}${amount.toStringAsFixed(2)} EGP',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isRecharge ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class WalletTopUpBottomSheet extends StatefulWidget {
  final VoidCallback onSuccess;
  const WalletTopUpBottomSheet({super.key, required this.onSuccess});

  @override
  State<WalletTopUpBottomSheet> createState() => _WalletTopUpBottomSheetState();
}

class _WalletTopUpBottomSheetState extends State<WalletTopUpBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardholderController = TextEditingController();
  
  bool _submitting = false;
  String? _errorMsg;

  @override
  void dispose() {
    _amountController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardholderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _submitting = true;
      _errorMsg = null;
    });

    try {
      final amount = double.parse(_amountController.text.trim());
      await ApiService.rechargeWallet(amount);
      if (!mounted) return;
      widget.onSuccess();
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMsg = e.toString().replaceAll('Exception: ', '');
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Top Up Wallet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.foreground),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 20, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              if (_errorMsg != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMsg!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Amount Input
              const Text('Recharge Amount (EGP)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: 'e.g. 100.00',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter an amount';
                  final numVal = double.tryParse(val.trim());
                  if (numVal == null || numVal <= 0) return 'Please enter a valid positive number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Mock Card Details Header
              const Row(
                children: [
                  Icon(Icons.credit_card_outlined, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Card Information (Mock)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 12),

              // Cardholder Name
              const Text('Cardholder Name', style: TextStyle(fontSize: 13, color: AppColors.muted)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _cardholderController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'John Doe'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Card Number
              const Text('Card Number', style: TextStyle(fontSize: 13, color: AppColors.muted)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'XXXX XXXX XXXX XXXX'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Expiry & CVV Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Expiry Date', style: TextStyle(fontSize: 13, color: AppColors.muted)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _expiryController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(hintText: 'MM/YY'),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CVV', style: TextStyle(fontSize: 13, color: AppColors.muted)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _cvvController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(hintText: 'XXX'),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Top Up Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
