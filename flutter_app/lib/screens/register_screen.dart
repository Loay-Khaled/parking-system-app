import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _idNumberCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _plateCtrl.dispose();
    _idNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final result = await AuthService.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      carPlate: _plateCtrl.text.trim().toUpperCase(),
      idNumber: _idNumberCtrl.text.trim(),
    );
    if (!mounted) return;

    if (result['success']) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() { _error = result['message']; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 20)],
                  ),
                  child: const Icon(Icons.local_parking, size: 42, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                const Text('Create Account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                const SizedBox(height: 6),
                const Text('Join AAST Parking today', style: TextStyle(fontSize: 14, color: AppColors.muted)),
                const SizedBox(height: 32),
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                    ]),
                  ),
                CustomTextField(
                  label: 'Full Name', hint: 'Omar Ahmed',
                  prefixIcon: Icons.person_outline, controller: _nameCtrl,
                  validator: (v) => v!.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Email', hint: 'your.email@aast.edu',
                  prefixIcon: Icons.mail_outline, controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty ? 'Email is required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Password', hint: 'Create a strong password',
                  prefixIcon: Icons.lock_outline, controller: _passCtrl,
                  isPassword: true,
                  validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'ID Number', hint: 'Student or Staff ID',
                  prefixIcon: Icons.badge_outlined, controller: _idNumberCtrl,
                  validator: (v) => v!.isEmpty ? 'ID number is required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Car Plate Number', hint: 'ABC 1234',
                  prefixIcon: Icons.directions_car_outlined, controller: _plateCtrl,
                  validator: (v) => v!.isEmpty ? 'Car plate is required' : null,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Create Account'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Already have an account? Login',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
