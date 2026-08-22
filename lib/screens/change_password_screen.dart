import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/student_onboarding_service.dart';
import '../theme/app_theme.dart';
import '../widgets/campus_backdrop.dart';
import 'home_screen.dart';

/// Forced password change after a student signs in with a temporary password.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  var _obscure = true;
  var _loading = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    // TODO(backend): update password in auth provider, then clear temp-password flag.
    await StudentOnboardingService.instance.completePasswordChange(widget.email);

    if (!mounted) return;
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password updated in mockup — backend update pending'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => HomeScreen(studentEmail: widget.email),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CampusBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create a new password',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You signed in with a temporary password sent to ${widget.email}. Choose a new one to continue.',
                  style: GoogleFonts.figtree(
                    fontSize: 14,
                    height: 1.45,
                    color: AppTheme.inkMuted,
                  ),
                ),
                const SizedBox(height: 24),
                GlassPanel(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'New password',
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 8) {
                              return 'Use at least 8 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirm,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirm password',
                          ),
                          validator: (value) => value != _password.text
                              ? 'Passwords do not match'
                              : null,
                        ),
                        const SizedBox(height: 18),
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
                              : const Text('Save password'),
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
    );
  }
}
