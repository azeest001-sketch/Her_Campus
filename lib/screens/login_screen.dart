import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/campus_backdrop.dart';
import '../widgets/her_campus_logo.dart';
import 'student_dashboard.dart';

/// Dark glass login — backend hooks stay in [AuthService].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.role});

  final UserRole role;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _obscure = true;
  var _loading = false;

  bool get _isAdmin => widget.role == UserRole.admin;

  Color get _accent =>
      _isAdmin ? AppTheme.blueSoft : AppTheme.pinkSoft;

  IconData get _roleIcon =>
      _isAdmin ? Icons.vpn_key_rounded : Icons.school_rounded;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final user = await AuthService.instance.signIn(
      role: widget.role,
      email: _email.text.trim(),
      password: _password.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isAdmin
                ? 'Admin login ready — waiting on backend auth'
                : 'Student login ready — waiting on backend auth',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1A1230),
        ),
      );
      return;
    }

    // TODO(frontend+backend): navigate after real auth succeeds.
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = _isAdmin ? 'Admin' : 'Student';

    return Scaffold(
      body: CampusBackdrop(
        roleTint: _accent,
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_roleIcon, size: 14, color: _accent),
                          const SizedBox(width: 6),
                          Text(
                            roleLabel.toUpperCase(),
                            style: GoogleFonts.figtree(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.3,
                              color: AppTheme.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: HerCampusLogo(size: 76)),
                        const SizedBox(height: 20),
                        Text(
                          'Welcome',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.figtree(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isAdmin
                              ? 'Sign in with your staff account'
                              : 'Sign in with your student email',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.figtree(
                            fontSize: 14,
                            color: AppTheme.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 28),
                        GlassPanel(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(color: AppTheme.ink),
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon:
                                        Icon(Icons.mail_outline_rounded),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Enter your email';
                                    }
                                    if (!v.contains('@')) {
                                      return 'Enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _password,
                                  obscureText: _obscure,
                                  textInputAction: TextInputAction.done,
                                  style: const TextStyle(color: AppTheme.ink),
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon:
                                        const Icon(Icons.lock_outline_rounded),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(
                                        () => _obscure = !_obscure,
                                      ),
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Enter your password';
                                    }
                                    if (v.length < 6) {
                                      return 'At least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      // TODO(backend): password reset
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Forgot password — backend pending',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Forgot password?',
                                      style: GoogleFonts.figtree(
                                        color: _accent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: _loading
                                        ? null
                                        : () async {
                                            await _submit();
                                            if (!mounted || _isAdmin) return;
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const StudentDashboardScreen(),
                                              ),
                                            );
                                          },
                                    child: _loading
                                        ? SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              color: _accent,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Login',
                                                style: GoogleFonts.figtree(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 18,
                                                color: _accent,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextButton(
                                  onPressed: () {
                                    // TODO(backend): sign-up
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Create account — backend pending',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  child: Text.rich(
                                    TextSpan(
                                      style: GoogleFonts.figtree(
                                        color: AppTheme.inkMuted,
                                        fontSize: 14,
                                      ),
                                      children: [
                                        const TextSpan(text: 'New here? '),
                                        TextSpan(
                                          text: 'Create account',
                                          style: TextStyle(
                                            color: _accent,
                                            fontWeight: FontWeight.w800,
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
                      ],
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
