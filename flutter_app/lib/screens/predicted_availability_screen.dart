import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../services/api_constants.dart';
import '../theme/app_theme.dart';

class PredictedAvailabilityScreen extends StatefulWidget {
  const PredictedAvailabilityScreen({super.key});

  @override
  State<PredictedAvailabilityScreen> createState() => _PredictedAvailabilityScreenState();
}

class _PredictedAvailabilityScreenState extends State<PredictedAvailabilityScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _loading = true;
  bool _insufficient = false;
  Map<String, dynamic>? _heatmapData;
  String? _error;
  int _currentHour = 9;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController!.addListener(() {
      setState(() {}); // Redraw chart for selected zone
    });
    _loadHeatmap();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadHeatmap() async {
    try {
      final response = await ApiService.get(ApiConstants.hourlyHeatmap);
      if (mounted) {
        if (response['insufficient'] == true) {
          setState(() {
            _insufficient = true;
            _loading = false;
          });
        } else {
          setState(() {
            _heatmapData = response;
            _currentHour = response['currentHour'] ?? DateTime.now().hour;
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _getZoneLetter() {
    switch (_tabController?.index) {
      case 0:
        return 'A';
      case 1:
        return 'B';
      case 2:
        return 'C';
      default:
        return 'A';
    }
  }

  Color _getBarColor(double val) {
    if (val < 1.0) return const Color(0xFF4CAF50); // Low
    if (val <= 2.5) return const Color(0xFFFFC107); // Moderate
    return const Color(0xFFF44336); // Busy
  }

  // Find 3 consecutive hours with the lowest average busyness
  String _getBestTimeWindow(Map<String, dynamic> hourlyData) {
    double minSum = double.infinity;
    int bestStart = 9;

    for (int i = 0; i < 22; i++) {
      double sum = 0;
      for (int offset = 0; offset < 3; offset++) {
        sum += (hourlyData[(i + offset).toString()] ?? 0.0) as double;
      }
      if (sum < minSum) {
        minSum = sum;
        bestStart = i;
      }
    }

    String formatHr(int hr) {
      if (hr == 0) return '12am';
      if (hr == 12) return '12pm';
      return hr < 12 ? '${hr}am' : '${hr - 12}pm';
    }

    return "${formatHr(bestStart)} – ${formatHr(bestStart + 3)}";
  }

  @override
  Widget build(BuildContext context) {
    final zone = _getZoneLetter();
    final Map<String, dynamic> hourlyData = _heatmapData != null
        ? Map<String, dynamic>.from(_heatmapData!['zones'][zone] ?? {})
        : {};
    final peakHour = _heatmapData != null
        ? (_heatmapData!['peakHour'][zone] as num?)?.toInt() ?? 10
        : 10;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Typical Parking Patterns'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _insufficient
                  ? _buildInsufficientDataView()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          color: AppColors.primary,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TabBar(
                            controller: _tabController,
                            indicatorColor: Colors.white,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white60,
                            tabs: const [
                              Tab(text: 'Zone A'),
                              Tab(text: 'Zone B'),
                              Tab(text: 'Zone C'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hourly Occupancy Heatmap',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.foreground),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Shows typical busy levels (average bookings per hour) based on historical records.',
                                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  height: 240,
                                  child: _buildBarChart(hourlyData),
                                ),
                                const SizedBox(height: 24),
                                _buildLegendAndPeakRow(peakHour),
                                const SizedBox(height: 24),
                                const Divider(color: AppColors.border),
                                const SizedBox(height: 16),
                                _buildRecommendationRow(hourlyData, zone),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
            Text('Failed to load patterns: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _loadHeatmap, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildInsufficientDataView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.analytics_outlined, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'Not enough data yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.foreground),
            ),
            const SizedBox(height: 8),
            const Text(
              'Typical parking heatmap patterns require at least 5 completed bookings in the database. Please check back later.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, dynamic> hourlyData) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            const Text('Failed to load data.'),
            TextButton(onPressed: _loadHeatmap, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_insufficient) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 48),
            SizedBox(height: 8),
            Text('Not enough data yet.\nCheck back after more bookings are made.', textAlign: TextAlign.center),
          ],
        ),
      );
    }
    if (hourlyData.isEmpty) {
      return const Center(child: Text('No data available.'));
    }

    double maxVal = 0.5;
    for (int hr = 0; hr < 24; hr++) {
      final val = (hourlyData[hr.toString()] ?? 0.0) as double;
      if (val > maxVal) maxVal = val;
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.25,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: AppColors.foreground,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final hr = group.x;
              final displayHr = hr == 0
                  ? '12am'
                  : hr == 12
                      ? '12pm'
                      : hr < 12
                          ? '${hr}am'
                          : '${hr - 12}pm';
              return BarTooltipItem(
                '$displayHr\n~${rod.toY.toStringAsFixed(1)} bookings',
                const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final hr = value.toInt();
                if (hr == 0) return const Text('12am', style: TextStyle(fontSize: 10, color: AppColors.muted));
                if (hr == 6) return const Text('6am', style: TextStyle(fontSize: 10, color: AppColors.muted));
                if (hr == 12) return const Text('12pm', style: TextStyle(fontSize: 10, color: AppColors.muted));
                if (hr == 18) return const Text('6pm', style: TextStyle(fontSize: 10, color: AppColors.muted));
                if (hr == 23) return const Text('12am', style: TextStyle(fontSize: 10, color: AppColors.muted));
                return const SizedBox();
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(24, (index) {
          final val = (hourlyData[index.toString()] ?? 0.0) as double;
          final isCurrent = index == _currentHour;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: val,
                color: _getBarColor(val),
                width: 7,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                borderSide: isCurrent
                    ? const BorderSide(color: AppColors.primary, width: 1.5)
                    : BorderSide.none,
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLegendAndPeakRow(int peakHour) {
    String formatPeak(int hr) {
      if (hr == 0) return '12:00 AM';
      if (hr == 12) return '12:00 PM';
      return hr < 12 ? '$hr:00 AM' : '${hr - 12}:00 PM';
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF44336).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '🔴 Peak: ${formatPeak(peakHour)}',
                style: const TextStyle(color: Color(0xFFF44336), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            Row(
              children: [
                _legendDot(const Color(0xFF4CAF50), 'Low'),
                const SizedBox(width: 12),
                _legendDot(const Color(0xFFFFC107), 'Mod'),
                const SizedBox(width: 12),
                _legendDot(const Color(0xFFF44336), 'Busy'),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
    );
  }

  Widget _buildRecommendationRow(Map<String, dynamic> hourlyData, String zone) {
    if (hourlyData.isEmpty) return const SizedBox.shrink();
    final bestWindow = _getBestTimeWindow(hourlyData);
    return Row(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.star, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Best time to book Zone $zone',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.foreground),
              ),
              const SizedBox(height: 4),
              Text(
                'Best window: $bestWindow (low demand)',
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
