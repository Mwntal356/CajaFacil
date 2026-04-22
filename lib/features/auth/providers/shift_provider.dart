import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/models/shift.dart';
import 'auth_provider.dart';

class ShiftNotifier extends StateNotifier<Shift?> {
  final Box<Shift> _box;
  final AuthState _auth;

  ShiftNotifier(this._box, this._auth) : super(null) {
    _loadActiveShift();
  }

  void _loadActiveShift() {
    if (!_auth.isAuthenticated) {
      state = null;
      return;
    }
    
    try {
      // Buscar si este usuario tiene un turno abierto
      final active = _box.values.cast<Shift?>().firstWhere(
        (s) => s != null && s.userId == _auth.userName && s.isOpen,
        orElse: () => null,
      );
      state = active;
    } catch (_) {
      state = null;
    }
  }

  Future<void> openShift(double amount) async {
    if (!_auth.isAuthenticated) return;

    final newShift = Shift(
      userId: _auth.userName!,
      startTime: DateTime.now(),
      openingBalance: amount,
    );

    await _box.add(newShift);
    state = newShift;
  }

  Future<void> closeShift(double actualBalance) async {
    if (state == null) return;

    state!.endTime = DateTime.now();
    state!.closingBalance = actualBalance;
    state!.isOpen = false;
    await state!.save();
    
    state = null;
  }
}

final shiftBoxProvider = Provider<Box<Shift>>((ref) {
  return Hive.box<Shift>('shifts');
});

final shiftProvider = StateNotifierProvider<ShiftNotifier, Shift?>((ref) {
  final box = ref.watch(shiftBoxProvider);
  final auth = ref.watch(authProvider);
  return ShiftNotifier(box, auth);
});
