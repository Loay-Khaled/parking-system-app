import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../models/user.dart';
import '../services/vehicle_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  List<Vehicle> _vehicles = [];
  bool _loading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadVehicles();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    setState(() => _currentUser = user);
  }

  Future<void> _loadVehicles() async {
    setState(() => _loading = true);
    try {
      final list = await VehicleService.getVehicles();
      setState(() {
        _vehicles = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load vehicles: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteVehicle(Vehicle vehicle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text('Are you sure you want to delete ${vehicle.brand} ${vehicle.model} (${vehicle.licensePlate})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await VehicleService.deleteVehicle(vehicle.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle deleted successfully'), backgroundColor: AppColors.success),
        );
      }
      _loadVehicles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete vehicle: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showAddVehicleSheet({String? prefilledPlate}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AddVehicleBottomSheet(prefilledPlate: prefilledPlate),
    ).then((success) {
      if (success == true) {
        _loadVehicles();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicles'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadVehicles,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _vehicles.isEmpty
                ? (_currentUser?.carPlate != null && _currentUser!.carPlate.isNotEmpty)
                    ? _buildFallbackVehicleTile()
                    : Center(
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
                                child: const Icon(Icons.directions_car_outlined, size: 48, color: AppColors.primary),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'No vehicles registered',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.foreground),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Add a vehicle to simplify your parking booking process.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: AppColors.muted),
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton.icon(
                                onPressed: _showAddVehicleSheet,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Your First Vehicle'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(220, 50),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = _vehicles[index];
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
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.directions_car, color: AppColors.primary, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${vehicle.brand} ${vehicle.model}',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.foreground,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: Text(
                                          vehicle.licensePlate,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.foreground,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: _parseColor(vehicle.color),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: AppColors.border),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            vehicle.color,
                                            style: const TextStyle(fontSize: 13, color: AppColors.muted),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.error),
                              onPressed: () => _deleteVehicle(vehicle),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: _vehicles.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showAddVehicleSheet,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Vehicle'),
            )
          : null,
    );
  }

  Widget _buildFallbackVehicleTile() {
    final plate = _currentUser?.carPlate ?? '';
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        GestureDetector(
          onTap: () => _showAddVehicleSheet(prefilledPlate: plate),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plate,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Your registered vehicle — tap to confirm details',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _parseColor(String colorName) {
    switch (colorName.toLowerCase().trim()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'grey':
      case 'gray':
        return Colors.grey;
      case 'brown':
        return Colors.brown;
      default:
        return AppColors.muted;
    }
  }
}

class _AddVehicleBottomSheet extends StatefulWidget {
  final String? prefilledPlate;
  const _AddVehicleBottomSheet({this.prefilledPlate});

  @override
  State<_AddVehicleBottomSheet> createState() => _AddVehicleBottomSheetState();
}

class _AddVehicleBottomSheetState extends State<_AddVehicleBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _plateCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledPlate != null) {
      _plateCtrl.text = widget.prefilledPlate!;
    }
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await VehicleService.addVehicle(
        licensePlate: _plateCtrl.text.trim().toUpperCase(),
        brand: _brandCtrl.text.trim(),
        model: _modelCtrl.text.trim(),
        color: _colorCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true);
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
                    'Add Vehicle Profile',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.foreground),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              CustomTextField(
                label: 'License Plate',
                hint: 'e.g. ABC 1234',
                prefixIcon: Icons.pin_outlined,
                controller: _plateCtrl,
                validator: (v) => v!.isEmpty ? 'License plate is required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Car Brand',
                hint: 'e.g. Toyota, BMW, Hyundai',
                prefixIcon: Icons.directions_car_outlined,
                controller: _brandCtrl,
                validator: (v) => v!.isEmpty ? 'Car brand is required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Car Model',
                hint: 'e.g. Corolla, Elantra',
                prefixIcon: Icons.layers_outlined,
                controller: _modelCtrl,
                validator: (v) => v!.isEmpty ? 'Car model is required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Color',
                hint: 'e.g. Red, Black, Blue, White',
                prefixIcon: Icons.palette_outlined,
                controller: _colorCtrl,
                validator: (v) => v!.isEmpty ? 'Color is required' : null,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save Vehicle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
