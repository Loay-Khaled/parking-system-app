import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/accessibility_service.dart';
import '../../services/api_service.dart';
import '../../services/api_constants.dart';
import '../../theme/app_theme.dart';
import 'admin_bottom_nav.dart';

class AdminAccessibilityScreen extends StatefulWidget {
  const AdminAccessibilityScreen({super.key});

  @override
  State<AdminAccessibilityScreen> createState() => _AdminAccessibilityScreenState();
}

class _AdminAccessibilityScreenState extends State<AdminAccessibilityScreen> with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFF1E3A5F);

  late TabController _tabController;
  
  // Tab 1 state
  List<User> _pendingApplications = [];
  bool _loadingApplications = true;
  String? _errorApplications;

  // Tab 2 state
  List<dynamic> _spots = [];
  bool _loadingSpots = true;
  String? _errorSpots;
  String _selectedZoneFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadApplications();
    _loadSpots();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _loadingApplications = true;
      _errorApplications = null;
    });
    try {
      final apps = await AccessibilityService.fetchPendingApplications();
      setState(() {
        _pendingApplications = apps;
        _loadingApplications = false;
      });
    } catch (e) {
      setState(() {
        _errorApplications = e.toString().replaceAll('Exception: ', '');
        _loadingApplications = false;
      });
    }
  }

  Future<void> _loadSpots() async {
    setState(() {
      _loadingSpots = true;
      _errorSpots = null;
    });
    try {
      final data = await ApiService.get(ApiConstants.adminSpots);
      setState(() {
        _spots = data is List ? data : [];
        _loadingSpots = false;
      });
    } catch (e) {
      setState(() {
        _errorSpots = e.toString().replaceAll('Exception: ', '');
        _loadingSpots = false;
      });
    }
  }

  Future<void> _resolveApplication(String userId, String decision, String adminNote) async {
    try {
      await AccessibilityService.resolveApplication(
        userId: userId,
        decision: decision,
        adminNote: adminNote,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Application has been $decision.'),
          backgroundColor: decision == 'approved' ? AppColors.success : AppColors.error,
        ),
      );
      _loadApplications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resolving application: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showResolveDialog(User user, String decision) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(decision == 'approved' ? 'Approve Application' : 'Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to $decision the accessibility permit application for ${user.name}?'),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Admin Note (Optional)',
                hintText: 'Enter internal reason or message to user',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: decision == 'approved' ? AppColors.success : AppColors.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _resolveApplication(user.id, decision, noteController.text.trim());
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSpotAccessibility(String spotId, bool isAccessibility, String label) async {
    try {
      await AccessibilityService.toggleSpotAccessibility(
        spotId: spotId,
        isAccessibility: isAccessibility,
        accessibilityLabel: label,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Spot $spotId accessibility updated successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadSpots();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating spot: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showSpotAccessibilityDialog(Map<String, dynamic> spot) {
    bool isAccessibility = spot['isAccessibility'] == true;
    final labelController = TextEditingController(
      text: spot['accessibilityLabel']?.toString().isNotEmpty == true
          ? spot['accessibilityLabel'].toString()
          : 'Wheelchair Access',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit Accessibility: ${spot['spotId'] ?? 'Spot'}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Accessibility Only'),
                subtitle: const Text('Restrict booking to users with approved permits'),
                value: isAccessibility,
                activeThumbColor: AppColors.primary,
                onChanged: (val) {
                  setDialogState(() {
                    isAccessibility = val;
                  });
                },
              ),
              const SizedBox(height: 12),
              if (isAccessibility)
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'Accessibility Label',
                    hintText: 'e.g. Wheelchair Access',
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _toggleSpotAccessibility(
                  spot['spotId']?.toString() ?? '',
                  isAccessibility,
                  isAccessibility ? labelController.text.trim() : '',
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: _primary,
        title: const Text('Accessibility Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, '/admin-home'),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Applications', icon: Icon(Icons.description_outlined)),
            Tab(text: 'Parking Spots', icon: Icon(Icons.local_parking)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildApplicationsTab(),
          _buildSpotsTab(),
        ],
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 0),
    );
  }

  Widget _buildApplicationsTab() {
    if (_loadingApplications) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }
    if (_errorApplications != null) {
      return _buildErrorState(_errorApplications!, _loadApplications);
    }
    if (_pendingApplications.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadApplications,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_turned_in_outlined, size: 64, color: AppColors.muted.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text(
                  'All Caught Up!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.foreground),
                ),
                const SizedBox(height: 8),
                const Text(
                  'There are no pending permit applications to review.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingApplications.length,
        itemBuilder: (ctx, i) {
          final user = _pendingApplications[i];
          final permit = user.accessibilityPermit;
          final dateStr = permit.submittedAt != null
              ? '${permit.submittedAt!.year}-${permit.submittedAt!.month.toString().padLeft(2, '0')}-${permit.submittedAt!.day.toString().padLeft(2, '0')}'
              : 'Unknown';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.foreground),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          'PENDING',
                          style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Email: ${user.email}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  Text('ID Number: ${user.idNumber}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.healing_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        permit.disabilityType,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      permit.conditionDescription,
                      style: const TextStyle(fontSize: 13, color: AppColors.foreground, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Submitted: $dateStr', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          minimumSize: const Size(100, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        onPressed: () => _showResolveDialog(user, 'rejected'),
                        child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          minimumSize: const Size(100, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        onPressed: () => _showResolveDialog(user, 'approved'),
                        child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpotsTab() {
    if (_loadingSpots) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }
    if (_errorSpots != null) {
      return _buildErrorState(_errorSpots!, _loadSpots);
    }

    // Filter spots based on choice
    final filteredSpots = _spots.where((s) {
      final mapSpot = s as Map<String, dynamic>;
      final zone = mapSpot['zone']?.toString() ?? '';
      if (_selectedZoneFilter == 'All') return true;
      return _selectedZoneFilter == 'Zone $zone';
    }).toList();

    // Group spots by zone
    final zones = <String, List<Map<String, dynamic>>>{};
    for (var s in filteredSpots) {
      final mapSpot = s as Map<String, dynamic>;
      final zone = mapSpot['zone']?.toString() ?? 'Other';
      zones.putIfAbsent(zone, () => []).add(mapSpot);
    }

    final sortedZones = zones.keys.toList()..sort();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['All', 'Zone A', 'Zone B', 'Zone C'].map((filter) {
              final isSelected = _selectedZoneFilter == filter;
              return ChoiceChip(
                label: Text(filter),
                selected: isSelected,
                selectedColor: _primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.foreground,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedZoneFilter = filter;
                    });
                  }
                },
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadSpots,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedZones.length,
              itemBuilder: (ctx, zi) {
          final zone = sortedZones[zi];
          final zoneSpots = zones[zone]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Zone $zone',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${zoneSpots.length} Spots',
                      style: const TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...zoneSpots.map((spot) {
                final isAcc = spot['isAccessibility'] == true;
                final label = spot['accessibilityLabel']?.toString() ?? '';
                final spotId = spot['spotId']?.toString() ?? '—';
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () => _showSpotAccessibilityDialog(spot),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isAcc ? AppColors.primary.withValues(alpha: 0.1) : AppColors.border.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isAcc ? AppColors.primary : AppColors.border,
                          width: isAcc ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        isAcc ? Icons.accessible : Icons.local_parking,
                        color: isAcc ? AppColors.primary : AppColors.muted,
                      ),
                    ),
                    title: Text(
                      'Spot $spotId',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.foreground),
                    ),
                    subtitle: Text(
                      isAcc
                          ? (label.isNotEmpty ? label : 'Wheelchair Access')
                          : 'Regular Parking Spot',
                      style: TextStyle(
                        fontSize: 12,
                        color: isAcc ? AppColors.primary : AppColors.muted,
                        fontWeight: isAcc ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: Switch(
                      value: isAcc,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        _toggleSpotAccessibility(
                          spotId,
                          val,
                          val ? 'Wheelchair Access' : '',
                        );
                      },
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    ),
  ),
],
);
}

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
