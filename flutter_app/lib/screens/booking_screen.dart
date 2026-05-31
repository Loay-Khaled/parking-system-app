import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/api_constants.dart';
import '../models/booking.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class BookingScreen extends StatefulWidget {
  final String spotId;
  const BookingScreen({super.key, required this.spotId});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _duration = 2;
  bool _loading = false;
  bool _isCustom = false;
  int _customHours = 6;
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    setState(() => _user = user);
    try {
      final freshUser = await AuthService.refreshUser();
      setState(() => _user = freshUser);
    } catch (_) {}
  }

  int _cost(int hours) => hours <= 1 ? 0 : (hours - 1) * 10;

  String _endTime(int hours) {
    final end = DateTime.now().add(Duration(hours: hours));
    final hour = end.hour > 12 ? end.hour - 12 : end.hour == 0 ? 12 : end.hour;
    final period = end.hour < 12 ? 'AM' : 'PM';
    return '$hour:${end.minute.toString().padLeft(2, '0')} $period';
  }

  Future<bool> _showPaymentConfirmationDialog(int cost) async {
    await _loadUser();
    if (!mounted) return false;
    final balance = _user?.walletBalance ?? 0.0;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount to pay: $cost EGP', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(
              'Your Wallet Balance: ${balance.toStringAsFixed(2)} EGP',
              style: TextStyle(
                color: balance >= cost ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (balance < cost) ...[
              const SizedBox(height: 16),
              const Text(
                'Insufficient funds in your virtual wallet.',
                style: TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          if (balance >= cost)
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.success),
              child: const Text('Pay from Wallet'),
            )
          else
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
                Navigator.pushNamed(context, '/wallet').then((_) => _loadUser());
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Text('Top Up'),
            ),
        ],
      ),
    );
    return confirm ?? false;
  }

  Future<void> _confirm() async {
    final cost = _cost(_duration);
    
    // If there is a cost, prompt for payment first
    if (cost > 0) {
      final confirmed = await _showPaymentConfirmationDialog(cost);
      if (!confirmed) return;
    }

    setState(() => _loading = true);
    try {
      // 1. If cost > 0, call the payment API first
      if (cost > 0) {
        await ApiService.processPayment(cost.toDouble());
      }

      // 2. Call the booking API to create the booking
      final data = await ApiService.post(ApiConstants.bookings, {
        'spotId': widget.spotId,
        'duration': _duration,
      });
      
      // Refresh user to get updated wallet balance and spending stats cached locally
      try {
        await AuthService.refreshUser();
      } catch (_) {}

      if (!mounted) return;
      final booking = Booking.fromJson(data);
      Navigator.pushReplacementNamed(context, '/confirmation', arguments: booking);
    } catch (e) {
      if (!mounted) return;
      
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      final isInsufficientFunds = errorMsg.toLowerCase().contains('insufficient funds');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isInsufficientFunds ? 'Insufficient funds. Please recharge your wallet.' : 'Error: $errorMsg'),
          backgroundColor: AppColors.error,
          action: isInsufficientFunds
              ? SnackBarAction(
                  label: 'Top Up',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.pushNamed(context, '/wallet').then((_) => _loadUser());
                  },
                )
              : null,
        ),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
            child: Row(
              children: [
                GestureDetector(onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 26)),
                const SizedBox(width: 16),
                Text('Book Spot ${widget.spotId}',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildDurationSelector(),
                  const SizedBox(height: 16),
                  _buildPriceBreakdown(),
                  const SizedBox(height: 16),
                  _buildTimeInfo(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _confirm,
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Confirm Booking'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.access_time, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Select Duration', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.foreground)),
          ]),
          const SizedBox(height: 16),
          ...List.generate(5, (i) {
            final hours = i + 1;
            final cost = _cost(hours);
            final selected = !_isCustom && _duration == hours;
            return GestureDetector(
              onTap: () => setState(() {
                _isCustom = false;
                _duration = hours;
              }),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 2)),
                      child: selected ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle))) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('$hours ${hours == 1 ? 'Hour' : 'Hours'}',
                          style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.foreground, fontSize: 15)),
                    ),
                    Text(cost == 0 ? 'FREE' : '$cost EGP',
                        style: TextStyle(fontWeight: FontWeight.w700,
                            color: cost == 0 ? AppColors.success : AppColors.foreground, fontSize: 15)),
                  ],
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: () => setState(() {
              _isCustom = true;
              _duration = _customHours;
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isCustom ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _isCustom ? AppColors.primary : AppColors.border, width: _isCustom ? 2 : 1),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                            border: Border.all(color: _isCustom ? AppColors.primary : AppColors.border, width: 2)),
                        child: _isCustom ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle))) : null,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Custom / Flexible Duration',
                            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.foreground, fontSize: 15)),
                      ),
                      if (!_isCustom)
                        const Icon(Icons.arrow_drop_down, color: AppColors.muted)
                      else
                        Text('${_cost(_customHours)} EGP',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 15)),
                    ],
                  ),
                  if (_isCustom) ...[
                    const Divider(height: 24, color: AppColors.border),
                    const Text('Adjust duration using the controls or slider below:',
                        style: TextStyle(color: AppColors.muted, fontSize: 12)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _customHours > 1
                              ? () => setState(() {
                                    _customHours--;
                                    _duration = _customHours;
                                  })
                              : null,
                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                          iconSize: 32,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text('$_customHours hr${_customHours > 1 ? 's' : ''}',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                        IconButton(
                          onPressed: _customHours < 48
                              ? () => setState(() {
                                    _customHours++;
                                    _duration = _customHours;
                                  })
                              : null,
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                          iconSize: 32,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: _customHours.toDouble(),
                      min: 1,
                      max: 24,
                      divisions: 23,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.border,
                      label: '$_customHours Hours',
                      onChanged: (val) {
                        setState(() {
                          _customHours = val.round();
                          _duration = _customHours;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    final cost = _cost(_duration);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.receipt_outlined, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Price Breakdown', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.foreground)),
          ]),
          const SizedBox(height: 16),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('First hour', style: TextStyle(fontSize: 13, color: AppColors.muted)),
            Text('FREE', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.success, fontSize: 13)),
          ]),
          if (_duration > 1) ...[
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${_duration - 1} additional hour${_duration - 1 > 1 ? 's' : ''} × 10 EGP',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted)),
              Text('${(_duration - 1) * 10} EGP', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.foreground, fontSize: 13)),
            ]),
          ],
          const Divider(height: 20, color: AppColors.border),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total Cost', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.foreground)),
            Text(cost == 0 ? 'FREE' : '$cost EGP',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22,
                    color: cost == 0 ? AppColors.success : AppColors.primary)),
          ]),
        ],
      ),
    );
  }

  Widget _buildTimeInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, color: AppColors.muted, size: 16),
          const SizedBox(width: 8),
          const Text('Start: ', style: TextStyle(color: AppColors.muted, fontSize: 13)),
          const Text('Now', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.foreground, fontSize: 13)),
          const Text('  •  ', style: TextStyle(color: AppColors.muted)),
          const Text('End: ', style: TextStyle(color: AppColors.muted, fontSize: 13)),
          Text(_endTime(_duration), style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.foreground, fontSize: 13)),
        ],
      ),
    );
  }
}
