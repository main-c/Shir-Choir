import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/user_model.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  
  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });
  
  bool get isAuthenticated => user != null;
  
  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _loadUser();
  }
  
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    
    if (userJson != null) {
      final user = User.fromJson(json.decode(userJson));
      state = state.copyWith(user: user);
    }
  }
  
  Future<void> login({
    required String name,
    required String role,
    String? voicePart,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        role: role,
        voicePart: voicePart,
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(user.toJson()));
      
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
  
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
