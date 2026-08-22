import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/escort_service.dart';
import '../theme/app_theme.dart';
import '../widgets/campus_backdrop.dart';

/// Student: request a peer escort to a destination.
class EscortScreen extends StatefulWidget {
  const EscortScreen({super.key, this.studentEmail = 'student@campus.edu'});

  final String studentEmail;

  @override
  State<EscortScreen> createState() => _EscortScreenState();
}

class _EscortScreenState extends State<EscortScreen> {
  final _destination = TextEditingController();
  final _note = TextEditingController();
  var _sending = false;

  @override
  void dispose() {
    _destination.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    if (_destination.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Where do you want to go?'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _sending = true);
    final request = await EscortService.instance.requestEscort(
      studentEmail: widget.studentEmail,
      destination: _destination.text,
      note: _note.text,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    _destination.clear();
    _note.clear();

    final notify = request.assignedVolunteerEmail == null
        ? 'Request saved. Add volunteers in admin Peer Escort so someone is notified first.'
        : 'Request sent. First notified: ${request.assignedVolunteerEmail} (demo)';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(notify), behavior: SnackBarBehavior.floating),
    );
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
                    'Request peer escort',
                    style: GoogleFonts.figtree(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Text(
                'Ask a trained peer to walk with you somewhere you don’t feel comfortable going alone.',
                style: GoogleFonts.figtree(color: AppTheme.inkMuted),
              ),
              const SizedBox(height: 16),
              GlassPanel(
                borderRadius: 22,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _destination,
                      decoration: const InputDecoration(
                        labelText: 'Destination',
                        hintText: 'e.g. Hostel B / Parking lot',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _note,
                      minLines: 3,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        hintText: 'Meet at library entrance…',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _sending ? null : _request,
                      child: _sending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4),
                            )
                          : const Text('Request escort'),
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
