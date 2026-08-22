import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/report_service.dart';
import '../theme/app_theme.dart';
import '../widgets/campus_backdrop.dart';

/// Student form to report a campus event/safety concern to admins.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, this.studentEmail = 'student@campus.edu'});

  final String studentEmail;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  var _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty || _description.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a title and description'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _sending = true);
    await ReportService.instance.submitReport(
      title: _title.text,
      description: _description.text,
      reporterEmail: widget.studentEmail,
      locationLabel: _location.text.trim().isEmpty ? null : _location.text,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    _title.clear();
    _description.clear();
    _location.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report sent to admin inbox (demo — no backend yet)'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CampusBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Text(
                    'Report an event',
                    style: GoogleFonts.figtree(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tell campus admins about something that needs attention.',
                style: GoogleFonts.figtree(color: AppTheme.inkMuted),
              ),
              const SizedBox(height: 16),
              GlassPanel(
                borderRadius: 22,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _title,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g. Broken street light near Gate 2',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _location,
                      decoration: const InputDecoration(
                        labelText: 'Location (optional)',
                        hintText: 'Near library / Block B',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _description,
                      minLines: 4,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'What happened?',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _sending ? null : _submit,
                      child: _sending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4),
                            )
                          : const Text('Send to admin'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
