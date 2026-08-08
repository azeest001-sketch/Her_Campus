import '../models/user_model.dart';

/// Auth API surface for the backend teammate.
///
/// Frontend calls these methods. Replace the mock bodies with real
/// Supabase / API calls — keep the method signatures so UI stays stable.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// MOCK: replace with real sign-in (Supabase email/password, etc.).
  Future<UserModel?> signIn({
    required UserRole role,
    required String email,
    required String password,
  }) async {
    // TODO(backend): authenticate against Supabase / your API.
    // Example:
    // final res = await supabase.auth.signInWithPassword(...);
    // return UserModel.fromSupabase(res.user, role: role);

    await Future<void>.delayed(const Duration(milliseconds: 600));
    return null; // null = mock "not wired yet"
  }

  /// MOCK: replace with real sign-up if needed.
  Future<UserModel?> signUp({
    required UserRole role,
    required String email,
    required String password,
  }) async {
    // TODO(backend): create account + assign role claim/row.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return null;
  }

  /// MOCK: replace with real sign-out.
  Future<void> signOut() async {
    // TODO(backend): await supabase.auth.signOut();
  }
}
