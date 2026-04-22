import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserRole { dueno, cajero1, cajero2, none }

class AuthState {
  final bool isAuthenticated;
  final UserRole role;
  final String? userName;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.role = UserRole.none,
    this.userName,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    UserRole? role,
    String? userName,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
      userName: userName ?? this.userName,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  Future<bool> loginWithPin(String pin) async {
    state = state.copyWith(error: null);
    
    if (pin == '0000') {
      state = state.copyWith(isAuthenticated: true, role: UserRole.dueno, userName: 'Dueño');
      return true;
    } else if (pin == '1111') {
      state = state.copyWith(isAuthenticated: true, role: UserRole.cajero1, userName: 'Juan');
      return true;
    } else if (pin == '2222') {
      state = state.copyWith(isAuthenticated: true, role: UserRole.cajero2, userName: 'Maritza');
      return true;
    } else {
      state = state.copyWith(error: 'PIN Incorrecto');
      return false;
    }
  }

  void logout() {
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
