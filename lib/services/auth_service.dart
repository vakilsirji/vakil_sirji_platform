import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'supabase_service.dart';
import '../models/user_profile.dart';
import '../core/constants.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseService.client;
  User? _user;
  UserProfile? _userProfile;
  bool _isMockAuthenticated = false;

  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isAuthenticated => _user != null || _isMockAuthenticated;

  AuthService() {
    _supabase.auth.onAuthStateChange.listen((data) {
      if (_isMockAuthenticated) return;
      _user = data.session?.user;
      if (_user != null) {
        _fetchUserProfile(_user!.id);
      } else {
        _userProfile = null;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      _userProfile = UserProfile(
        id: response['id'] ?? userId,
        name: response['name'] ?? 'Unknown',
        email: response['email'] ?? '',
        mobile: response['mobile'] ?? '',
        role: UserRole.values.firstWhere(
          (e) =>
              e.toString().split('.').last.toLowerCase() ==
              (response['role']?.toString().toLowerCase() ?? 'owner'),
          orElse: () => UserRole.owner,
        ),
        joinedDate: response['joined_date'] ?? DateTime.now().toIso8601String(),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();

    await _supabase.auth.signInWithPassword(
      email: cleanEmail,
      password: password,
    );
  }

  Future<void> signUp(
    String email,
    String password,
    String name,
    String mobile,
    String role,
  ) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'mobile': mobile, 'role': role.toLowerCase()},
    );
  }

  // Uses a temporary client so the admin's session isn't overwritten
  Future<void> adminCreateStaff(
    String email,
    String password,
    String name,
    String mobile,
  ) async {
    final tempClient = SupabaseClient(
      AppConstants.supabaseUrl,
      AppConstants.supabaseAnonKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );

    try {
      await tempClient.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'mobile': mobile, 'role': 'staff'},
      );
    } finally {
      tempClient.dispose();
    }
  }

  Future<void> signOut() async {
    if (_isMockAuthenticated) {
      _isMockAuthenticated = false;
      _userProfile = null;
      notifyListeners();
      return;
    }
    await _supabase.auth.signOut();
  }
}
