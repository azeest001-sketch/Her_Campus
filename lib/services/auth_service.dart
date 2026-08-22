import '../models/user_model.dart';

/// Result of a mock / real sign-in attempt.
class AuthSignInResult {
  const AuthSignInResult.success(this.user) : errorMessage = null;
  const AuthSignInResult.failure(this.errorMessage) : user = null;

  final UserModel? user;
  final String? errorMessage;

  bool get ok => user != null;
}

/// Auth API surface for the backend teammate.
///
/// Frontend calls these methods. Replace the mock bodies with real
/// Supabase / API calls — keep the method signatures so UI stays stable.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// MOCK: replace with real sign-in (Supabase email/password, etc.).
  Future<AuthSignInResult> signIn({
    required UserRole role,
    required String email,
    required String password,
  }) async {
    // TODO(backend): authenticate against Supabase / your API.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final normalized = email.trim().toLowerCase();

    return AuthSignInResult.success(
      UserModel(
        id: 'mock-$normalized',
        email: normalized,
        displayName: normalized.split('@').first,
        role: role,
      ),
    );
  }

  /// MOCK: replace with real sign-up if needed.
  Future<UserModel?> signUp({
    required UserRole role,
    required String email,
    required String password,
    String? displayName,
    String? adminId,
  }) async {
    // TODO(backend): create account, verify adminId/invite code server-side,
    // then assign the role. Never trust the role sent by the frontend alone.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return null;
  }

  /// MOCK: send a verification code to the official college email.
  Future<void> sendOtp({required String email}) async {
    // TODO(backend): ask Supabase / your API to send the email OTP.
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  /// MOCK: verify the OTP entered by the user.
  Future<bool> verifyOtp({
    required String email,
    required String code,
  }) async {
    // TODO(backend): verify the code server-side. Do not verify it only in UI.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return false;
  }

  /// MOCK: replace with real sign-out.
  Future<void> signOut() async {
    // TODO(backend): await supabase.auth.signOut();
  }
}
