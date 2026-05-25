import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/api_constants.dart';
import '../theme/app_theme.dart';

class WaitingListScreen extends StatefulWidget {
  const WaitingListScreen({super.key});
  @override
  State<WaitingListScreen> createState() => _WaitingListScreenState();
}

class _WaitingListScreenState extends State<WaitingListScreen> {
  bool _inQueue = false;
  int _position = 0;
  int _totalWaiting = 0;
  bool _loading = true;

  @override
  void initState() { super.initState(); _checkStatus(); }

  Future<void> _checkStatus() async {
    try {
      final data = await ApiService.get(ApiConstants.myQueue);
      setState(() {
        _inQueue = data['inQueue'] ?? false;
        _position = data['position'] ?? 0;
        _totalWaiting = data['totalWaiting'] ?? 0;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _joinQueue() async {
    setState(() => _loading = true);
    try {
      await ApiService.post(ApiConstants.joinQueue, {});
      _checkStatus();
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _leaveQueue() async {
    setState(() => _loading = true);
    try {
      await ApiService.delete(ApiConstants.leaveQueue);
      setState(() { _inQueue = false; _position = 0; _loading = false; });
    } catch (e) {
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
            child: Row(children: [
              GestureDetector(onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 26)),
              const SizedBox(width: 16),
              const Text('Waiting List', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _inQueue ? _buildInQueue() : _buildNotInQueue(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotInQueue() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 96, height: 96,
          decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.people_outline, size: 52, color: AppColors.warning),
        ),
        const SizedBox(height: 20),
        const Text('Parking Full', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.foreground)),
        const SizedBox(height: 8),
        const Text('All parking spots are currently occupied.\nJoin the waiting list to be notified when a spot becomes available.',
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 14)),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('How It Works', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.foreground)),
              const SizedBox(height: 16),
              _step('1', 'Join the waiting list', 'Get in line for the next available spot'),
              const SizedBox(height: 12),
              _step('2', 'Receive notification', 'We\'ll alert you when a spot opens up'),
              const SizedBox(height: 12),
              _step('3', 'Confirm within time limit', 'You\'ll have 5 minutes to book the spot'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _joinQueue, child: const Text('Join Waiting List'))),
      ],
    );
  }

  Widget _buildInQueue() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.1), AppColors.secondary.withOpacity(0.1)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Container(
                width: 64, height: 64,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.people, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              const Text('You\'re in the Queue!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.foreground)),
              const SizedBox(height: 8),
              const Text('We\'ll notify you when a spot becomes available', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  const Text('Your position', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  const SizedBox(height: 4),
                  Text('$_position', style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  const Text('people ahead of you', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Row(children: [
            const Icon(Icons.access_time, color: AppColors.warning),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Estimated Wait Time', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.foreground)),
              Text('Approximately 15-20 minutes based on current queue', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ])),
          ]),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFDE68A))),
          child: const Text('You\'ll receive a notification when a spot becomes available. Make sure to confirm within 5 minutes or you\'ll lose your spot.',
              style: TextStyle(fontSize: 13, color: Color(0xFF92400E))),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _leaveQueue,
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
            child: const Text('Leave Queue'),
          ),
        ),
      ],
    );
  }

  Widget _step(String num, String title, String desc) {
    return Row(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
        child: Center(child: Text(num, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 12))),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.foreground)),
        Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ])),
    ]);
  }
}
