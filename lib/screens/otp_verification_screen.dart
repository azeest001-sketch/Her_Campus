import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/campus_backdrop.dart';
import '../widgets/her_campus_logo.dart';
import 'college_setup_screen.dart';

/// Verifies the code sent to the administrator's college email.
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.name,
    required this.password,
  });

  final String email;
  final String name;
  final String password;

  @override
  State<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _code = TextEditingController();
  var _loading = false;
  var _resending = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the six-digit verification code'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    final verified = await AuthService.instance.verifyOtp(
      email: widget.email,
      code: _code.text,
    );

    if (!mounted) return;

    if (!verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP verification is waiting for backend setup'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // Mockup continues so frontend work can be tested. Backend must only create
    // the account after a real successful verification.
    await AuthService.instance.signUp(
      role: UserRole.admin,
      email: widget.email,
      password: widget.password,
      displayName: widget.name,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const CollegeSetupScreen(),
      ),
    );
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    await AuthService.instance.sendOtp(email: widget.email);
    if (!mounted) return;
    setState(() => _resending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A new code has been requested'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CampusBackdrop(
        roleTint: AppTheme.blue,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppTheme.ink,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: HerCampusLogo(size: 78)),
                          const SizedBox(height: 24),
                          Text(
                            'Check your email',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'We sent a six-digit code to\n${widget.email}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.figtree(
                              fontSize: 14,
                              height: 1.5,
                              color: AppTheme.inkMuted,
                            ),
                          ),
                          const SizedBox(height: 28),
                          GlassPanel(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: _code,
                                  autofocus: true,
                                  autofillHints: const [
                                    AutofillHints.oneTimeCode,
                                  ],
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.done,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(6),
                                  ],
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.figtree(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 10,
                                    color: AppTheme.ink,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: '000000',
                                    counterText: '',
                                  ),
                                  maxLength: 6,
                                  onSubmitted: (_) => _verify(),
                                ),
                                const SizedBox(height: 18),
                                ElevatedButton(
                                  onPressed: _loading ? null : _verify,
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                          ),
                                        )
                                      : const Text('Verify email'),
                                ),
                                const SizedBox(height: 10),
                                TextButton(
                                  onPressed: _resending ? null : _resend,
                                  child: Text(
                                    _resending
                                        ? 'Sending...'
                                        : 'Didn’t receive it? Resend code',
                                    style: GoogleFonts.figtree(
                                      color: AppTheme.purpleDeep,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
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
