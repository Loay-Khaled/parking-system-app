import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../services/api_constants.dart';
import '../../theme/app_theme.dart';
import 'admin_bottom_nav.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _range = 'week'; // today | week | month
  bool _loading = true;
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.get('${ApiConstants.adminAnalytics}?range=$_range');
      setState(() {
        _data = response as Map<String, dynamic>;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Color _getOccupancyColor(double rate) {
    if (rate < 0.5) return AppColors.available;
    if (rate <= 0.8) return AppColors.reserved;
    return AppColors.occupied;
  }

  Color _getHeatmapColor(int count, int maxCount) {
    if (count == 0) return Colors.grey.shade100;
    if (maxCount == 0) return AppColors.primary.withValues(alpha: 0.1);
    final intensity = count / maxCount;
    if (intensity < 0.2) return AppColors.primary.withValues(alpha: 0.15);
    if (intensity < 0.5) return AppColors.primary.withValues(alpha: 0.4);
    if (intensity < 0.8) return AppColors.primary.withValues(alpha: 0.7);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Revenue Analytics'),
        backgroundColor: const Color(0xFF1E3A5F),
      ),
      body: Column(
        children: [
          _rangeSelector(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorView()
                    : RefreshIndicator(
                        onRefresh: _fetchData,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSummaryCards(),
                              const SizedBox(height: 24),
                              _sectionHeader('Daily Revenue & Bookings'),
                              const SizedBox(height: 12),
                              _buildRevenueChart(),
                              const SizedBox(height: 24),
                              _sectionHeader('Zone Performance'),
                              const SizedBox(height: 12),
                              _buildZonePerformanceGrid(),
                              const SizedBox(height: 24),
                              _sectionHeader('Peak Booking Hours'),
                              const SizedBox(height: 12),
                              _buildPeakHoursHeatmap(),
                              const SizedBox(height: 24),
                              _sectionHeader('Top Spenders'),
                              const SizedBox(height: 12),
                              _buildTopSpendersList(),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 0),
    );
  }

  Widget _rangeSelector() {
    return Container(
      color: const Color(0xFF1E3A5F),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'today', label: Text('Today')),
          ButtonSegment(value: 'week', label: Text('Week')),
          ButtonSegment(value: 'month', label: Text('Month')),
        ],
        selected: {_range},
        onSelectionChanged: (newSelection) {
          setState(() {
            _range = newSelection.first;
            _fetchData();
          });
        },
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: Colors.white,
          selectedForegroundColor: const Color(0xFF1E3A5F),
          foregroundColor: Colors.white70,
          side: const BorderSide(color: Colors.white24),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.foreground),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 52, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error!.replaceAll('Exception: ', ''), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _fetchData, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final summary = _data?['summary'] ?? {};
    final totalRevenue = (summary['totalRevenue'] ?? 0) as num;
    final totalBookings = (summary['totalBookings'] ?? 0) as num;
    final avgCost = (summary['averageBookingCost'] ?? 0) as num;
    final penalties = (summary['totalPenalties'] ?? 0) as num;
    final newUsers = (summary['newUsers'] ?? 0) as num;

    final cards = [
      _summaryCard('Total Revenue', '${totalRevenue.toInt()} EGP', Icons.payments, Colors.blue),
      _summaryCard('Total Bookings', '${totalBookings.toInt()}', Icons.receipt_long, Colors.purple),
      _summaryCard('Avg Booking', '${avgCost.toInt()} EGP', Icons.analytics, Colors.green),
      _summaryCard('Penalties', '${penalties.toInt()} EGP', Icons.gavel, Colors.orange),
      _summaryCard('New Users', '${newUsers.toInt()}', Icons.person_add, Colors.teal),
    ];

    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        itemBuilder: (_, index) => cards[index],
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w600)),
              Icon(icon, color: color, size: 16),
            ],
          ),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.foreground)),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            const Text('Failed to load data.'),
            TextButton(onPressed: _fetchData, child: const Text('Retry')),
          ],
        ),
      );
    }
    final daily = (_data?['dailyRevenue'] as List? ?? []);
    if (_data == null || _data!.isEmpty || daily.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: const Center(child: Text('No historical data in range.', style: TextStyle(color: AppColors.muted))),
      );
    }

    double maxRevenue = 100.0;
    List<FlSpot> revenueSpots = [];
    List<FlSpot> bookingSpots = [];

    for (int i = 0; i < daily.length; i++) {
      final item = daily[i];
      final rev = ((item['revenue'] ?? 0.0) as num).toDouble();
      final bk = ((item['bookings'] ?? 0) as num).toDouble();
      revenueSpots.add(FlSpot(i.toDouble(), rev));
      bookingSpots.add(FlSpot(i.toDouble(), bk * 10)); // Scale bookings * 10 for readability on same chart
      if (rev > maxRevenue) maxRevenue = rev;
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(10, 24, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: AppColors.foreground,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((s) {
                  final isRev = s.barIndex == 0;
                  final val = isRev ? s.y : s.y / 10;
                  return LineTooltipItem(
                    isRev ? 'Revenue: ${val.toInt()} EGP' : 'Bookings: ${val.toInt()}',
                    TextStyle(color: isRev ? Colors.blue : Colors.amber, fontWeight: FontWeight.bold, fontSize: 11),
                  );
                }).toList();
              },
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx >= 0 && idx < daily.length) {
                    final dateStr = daily[idx]['date'] as String;
                    final parts = dateStr.split('-');
                    if (parts.length == 3) {
                      return Text('${parts[2]}/${parts[1]}', style: const TextStyle(fontSize: 9, color: AppColors.muted));
                    }
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
          lineBarsData: [
            // Revenue Line
            LineChartBarData(
              spots: revenueSpots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
            // Bookings Line (Scaled)
            LineChartBarData(
              spots: bookingSpots,
              isCurved: true,
              color: Colors.amber,
              barWidth: 2,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZonePerformanceGrid() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            const Text('Failed to load data.'),
            TextButton(onPressed: _fetchData, child: const Text('Retry')),
          ],
        ),
      );
    }
    final breakdown = (_data?['zoneBreakdown'] as List? ?? []);
    if (_data == null || _data!.isEmpty || breakdown.isEmpty) {
      return const Center(child: Text('No data available.'));
    }
    return Row(
      children: breakdown.map<Widget>((z) {
        final zone = z['zone'] as String? ?? '';
        final rev = (z['revenue'] ?? 0) as num;
        final count = (z['bookings'] ?? 0) as num;
        final rate = ((z['occupancyRate'] ?? 0.0) as num).toDouble();

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Zone $zone', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.foreground)),
                const SizedBox(height: 10),
                Text('${rev.toInt()} EGP', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.blue)),
                Text('${count.toInt()} Bookings', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: rate,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(_getOccupancyColor(rate)),
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 4),
                Text('${(rate * 100).toInt()}% occupancy', style: const TextStyle(fontSize: 9, color: AppColors.muted)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPeakHoursHeatmap() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            const Text('Failed to load data.'),
            TextButton(onPressed: _fetchData, child: const Text('Retry')),
          ],
        ),
      );
    }
    final peak = (_data?['peakHours'] as List? ?? []);
    if (_data == null || _data!.isEmpty || peak.isEmpty) {
      return const Center(child: Text('No data available.'));
    }

    int maxCount = 0;
    for (final p in peak) {
      final count = (p['bookingCount'] ?? 0) as int;
      if (count > maxCount) maxCount = count;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 28,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 24,
              itemBuilder: (context, i) {
                final p = peak[i];
                final count = (p['bookingCount'] ?? 0) as int;
                final color = _getHeatmapColor(count, maxCount);
                return Tooltip(
                  message: '${i == 0 ? 12 : i > 12 ? i - 12 : i}${i < 12 ? 'am' : 'pm'}: $count bookings',
                  child: Container(
                    width: 12,
                    height: 24,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('12am', style: TextStyle(fontSize: 10, color: AppColors.muted)),
              Text('12pm', style: TextStyle(fontSize: 10, color: AppColors.muted)),
              Text('11pm', style: TextStyle(fontSize: 10, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopSpendersList() {
    final top = (_data?['topUsers'] as List? ?? []);
    if (top.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: const Center(child: Text('No users in range.', style: TextStyle(color: AppColors.muted))),
      );
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        children: List.generate(top.length, (index) {
          final user = top[index];
          final name = user['name'] as String? ?? 'User';
          final email = user['email'] as String? ?? '';
          final spent = (user['totalSpent'] ?? 0) as num;
          final count = (user['totalBookings'] ?? 0) as num;
          final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';

          return Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(initials, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.foreground)),
                subtitle: Text(email, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${spent.toInt()} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.foreground)),
                    Text('${count.toInt()} Bookings', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                  ],
                ),
              ),
              if (index < top.length - 1) const Divider(height: 1, color: AppColors.border),
            ],
          );
        }),
      ),
    );
  }
}
