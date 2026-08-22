import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/campus_backdrop.dart';
import '../widgets/her_campus_logo.dart';
import 'college_setup_screen.dart';

/// Admin registration mockup.
///
/// The backend must verify the college email OTP before creating the account.
class AdminSignUpScreen extends StatefulWidget {
  const AdminSignUpScreen({super.key});

  @override
  State<AdminSignUpScreen> createState() => _AdminSignUpScreenState();
}

class _AdminSignUpScreenState extends State<AdminSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  var _obscurePassword = true;
  var _obscureConfirmation = true;
  var _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final email = _email.text.trim();
    AuthSignInResult result;
    try {
      // Password signup against Supabase (avoids OTP hang / email provider setup).
      result = await AuthService.instance.signUp(
        role: UserRole.admin,
        email: email,
        password: _password.text,
        displayName: _name.text.trim(),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }

    if (!mounted) return;

    if (result.needsEmailConfirmation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created. Confirm the email Supabase sent, then log in.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Sign-up failed'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1A1230),
        ),
      );
      return;
    }

    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const CollegeSetupScreen(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CampusBackdrop(
        roleTint: AppTheme.pinkSoft,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppTheme.ink,
                    ),
                    const Spacer(),
                    GlassPanel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      borderRadius: 999,
                      blur: 16,
                      child: Text(
                        'ADMIN SIGN UP',
                        style: GoogleFonts.figtree(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppTheme.purpleDeep,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: HerCampusLogo(size: 72)),
                          const SizedBox(height: 18),
                          Text(
                            'Create admin account',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 34,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Create an admin account with your campus email.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.figtree(
                              fontSize: 14,
                              color: AppTheme.inkMuted,
                            ),
                          ),
                          const SizedBox(height: 24),
                          GlassPanel(
                            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextFormField(
                                    controller: _name,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'Full name',
                                      prefixIcon:
                                          Icon(Icons.person_outline_rounded),
                                    ),
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                            ? 'Enter your full name'
                                            : null,
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _email,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'Official campus email',
                                      prefixIcon:
                                          Icon(Icons.mail_outline_rounded),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Enter your email';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _password,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon:
                                          const Icon(Icons.lock_outline_rounded),
                                      suffixIcon: IconButton(
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter a password';
                                      }
                                      if (value.length < 8) {
                                        return 'Use at least 8 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _confirmPassword,
                                    obscureText: _obscureConfirmation,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _submit(),
                                    decoration: InputDecoration(
                                      labelText: 'Confirm password',
                                      prefixIcon:
                                          const Icon(Icons.lock_reset_rounded),
                                      suffixIcon: IconButton(
                                        onPressed: () => setState(
                                          () => _obscureConfirmation =
                                              !_obscureConfirmation,
                                        ),
                                        icon: Icon(
                                          _obscureConfirmation
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                    validator: (value) =>
                                        value != _password.text
                                            ? 'Passwords do not match'
                                            : null,
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: _loading ? null : _submit,
                                    child: _loading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                            ),
                                          )
                                        : const Text(
                                            'Create admin account',
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
