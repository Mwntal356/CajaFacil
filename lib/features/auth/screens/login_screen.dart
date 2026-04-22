import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/dynamic_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String _pin = '';
  UserRole? _selectedRole;

  void _onKeyPress(String key) {
    if (_pin.length < 4) {
      setState(() => _pin += key);
    }
    if (_pin.length == 4) {
      _attemptLogin();
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  Future<void> _attemptLogin() async {
    final success = await ref.read(authProvider.notifier).loginWithPin(_pin);
    if (!success) {
      setState(() => _pin = '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN Incorrecto'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _selectedRole == null ? _buildRoleSelection() : _buildPinEntry(),
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Center(
      child: FadeInDown(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const DynamicLogo(size: 120),
            const SizedBox(height: 16),
            const Text(
              'CajaFácil',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1),
            ),
            const Text(
              'Gestión Inteligente de tu Tienda',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 60),
            _buildRoleCard(
              'PORTAL DEL DUEÑO',
              'Estadísticas, Inventario y Configuración',
              LucideIcons.shieldCheck,
              AppColors.blue,
              () => setState(() => _selectedRole = UserRole.dueno),
            ),
            const SizedBox(height: 20),
            _buildRoleCard(
              'CAJA Y VENTAS',
              'Vender, Turnos y Arqueos',
              LucideIcons.shoppingBag,
              AppColors.green,
              () => setState(() => _selectedRole = UserRole.cajero1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
            boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 20)],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinEntry() {
    return Center(
      child: FadeInUp(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(LucideIcons.arrowLeft),
              onPressed: () => setState(() { _selectedRole = null; _pin = ''; }),
            ),
            const SizedBox(height: 20),
            Text(
              _selectedRole == UserRole.dueno ? 'Acceso de Dueño' : 'Ingreso de Cajero',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < _pin.length ? AppColors.blue : AppColors.surface,
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
              )),
            ),
            const SizedBox(height: 60),
            Container(
              constraints: const BoxConstraints(maxWidth: 350),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.2,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  if (index == 9) return const SizedBox();
                  if (index == 10) return _buildPinKey('0');
                  if (index == 11) return IconButton(icon: const Icon(LucideIcons.delete), onPressed: _onBackspace);
                  return _buildPinKey('${index + 1}');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinKey(String key) {
    return InkWell(
      onTap: () => _onKeyPress(key),
      borderRadius: BorderRadius.circular(50),
      child: Center(
        child: Text(key, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
