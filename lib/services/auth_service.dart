import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import 'profile_service.dart';
import 'supabase_service.dart';

/// Result of a sign-in / sign-up attempt.
class AuthSignInResult {
  const AuthSignInResult.success(this.user, {this.needsEmailConfirmation = false})
      : errorMessage = null;
  const AuthSignInResult.failure(this.errorMessage)
      : user = null,
        needsEmailConfirmation = false;

  final UserModel? user;
  final String? errorMessage;
  final bool needsEmailConfirmation;

  bool get ok => user != null && !needsEmailConfirmation;
}

/// Auth API used by login / signup screens — backed by Supabase Auth.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _timeout = Duration(seconds: 25);

  final _supabase = SupabaseService.instance;

  Future<AuthSignInResult> signIn({
    required UserRole role,
    required String email,
    required String password,
  }) async {
    if (!_supabase.isReady) {
      return const AuthSignInResult.failure(
        'Supabase is not connected. Check .env and rebuild the app.',
      );
    }

    final normalized = email.trim().toLowerCase();
    try {
      final response = await _supabase.auth
          .signInWithPassword(email: normalized, password: password)
          .timeout(_timeout);
      final user = response.user;
      if (user == null) {
        return const AuthSignInResult.failure('Sign-in failed. Try again.');
      }
      await ProfileService.instance.ensureProfile(role: role.name);
      return AuthSignInResult.success(_toUserModel(user, fallbackRole: role));
    } on TimeoutException {
      return const AuthSignInResult.failure(
        'Sign-in timed out. Check your internet connection.',
      );
    } on AuthException catch (e) {
      return AuthSignInResult.failure(_friendlyAuthError(e.message));
    } catch (e) {
      return AuthSignInResult.failure('Sign-in error: $e');
    }
  }

  /// Creates an email/password account in Supabase Auth.
  Future<AuthSignInResult> signUp({
    required UserRole role,
    required String email,
    required String password,
    String? displayName,
    String? adminId,
  }) async {
    if (!_supabase.isReady) {
      return const AuthSignInResult.failure(
        'Supabase is not connected. Check .env and rebuild the app.',
      );
    }

    final normalized = email.trim().toLowerCase();
    try {
      final response = await _supabase.auth
          .signUp(
            email: normalized,
            password: password,
            data: {
              'role': role.name,
              if (displayName != null && displayName.trim().isNotEmpty)
                'display_name': displayName.trim(),
              if (adminId != null && adminId.trim().isNotEmpty)
                'admin_id': adminId.trim(),
            },
          )
          .timeout(_timeout);

      final user = response.user;
      if (user == null) {
        return const AuthSignInResult.failure(
          'Could not create account. Try a different email.',
        );
      }

      // Email confirmation enabled in Supabase → no session until confirmed.
      if (response.session == null) {
        return AuthSignInResult.success(
          _toUserModel(user, fallbackRole: role),
          needsEmailConfirmation: true,
        );
      }

      await ProfileService.instance.ensureProfile(
        role: role.name,
        displayName: displayName,
      );
      return AuthSignInResult.success(_toUserModel(user, fallbackRole: role));
    } on TimeoutException {
      return const AuthSignInResult.failure(
        'Sign-up timed out. Check your internet connection.',
      );
    } on AuthException catch (e) {
      return AuthSignInResult.failure(_friendlyAuthError(e.message));
    } catch (e) {
      return AuthSignInResult.failure('Sign-up error: $e');
    }
  }

  /// Sends a Supabase email OTP (optional flow).
  Future<AuthSignInResult> sendOtp({required String email}) async {
    if (!_supabase.isReady) {
      return const AuthSignInResult.failure(
        'Supabase is not connected. Check .env and rebuild the app.',
      );
    }
    final normalized = email.trim().toLowerCase();
    try {
      await _supabase.auth
          .signInWithOtp(email: normalized)
          .timeout(_timeout);
      return AuthSignInResult.success(
        UserModel(email: normalized),
      );
    } on TimeoutException {
      return const AuthSignInResult.failure(
        'OTP request timed out. Check your internet connection.',
      );
    } on AuthException catch (e) {
      return AuthSignInResult.failure(_friendlyAuthError(e.message));
    } catch (e) {
      return AuthSignInResult.failure('OTP error: $e');
    }
  }

  Future<bool> verifyOtp({
    required String email,
    required String code,
  }) async {
    if (!_supabase.isReady) return false;
    final normalized = email.trim().toLowerCase();
    try {
      final response = await _supabase.auth
          .verifyOTP(
            email: normalized,
            token: code.trim(),
            type: OtpType.email,
          )
          .timeout(_timeout);
      return response.user != null || response.session != null;
    } on AuthException {
      return false;
    } on TimeoutException {
      return false;
    }
  }

  Future<void> signOut() async {
    if (!_supabase.isReady) return;
    await _supabase.auth.signOut();
  }

  String _friendlyAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('rate') &&
        (lower.contains('email') || lower.contains('limit'))) {
      return 'Email sending limit hit. In Supabase: Auth → Providers → Email → turn OFF “Confirm email”, wait a few minutes, then try again (or add the user in Authentication → Users).';
    }
    if (lower.contains('over_email_send_rate_limit') ||
        lower.contains('email rate limit exceeded')) {
      return 'Email sending limit hit. Turn OFF “Confirm email” in Supabase Auth, wait a few minutes, then try again.';
    }
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials')) {
      return 'Invalid email or password. Create an account first, or check spelling.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Confirm your email in the inbox, then try logging in.';
    }
    if (lower.contains('user already registered')) {
      return 'This email is already registered. Try logging in instead.';
    }
    return message;
  }

  UserModel _toUserModel(User user, {required UserRole fallbackRole}) {
    final meta = user.userMetadata ?? const <String, dynamic>{};
    final roleName = meta['role']?.toString();
    var role = fallbackRole;
    if (roleName != null) {
      for (final value in UserRole.values) {
        if (value.name == roleName) {
          role = value;
          break;
        }
      }
    }

    final display = meta['display_name']?.toString() ??
        meta['full_name']?.toString() ??
        user.email?.split('@').first;

    return UserModel(
      id: user.id,
      email: user.email,
      displayName: display,
      role: role,
    );
  }
}
