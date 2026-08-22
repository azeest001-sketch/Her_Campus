import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/escort_service.dart';
import '../services/student_onboarding_service.dart';
import '../theme/app_theme.dart';
import '../widgets/campus_backdrop.dart';

/// Admin: manage peer-escort volunteer emails (first notification receivers).
class PeerEscortVolunteersScreen extends StatefulWidget {
  const PeerEscortVolunteersScreen({super.key});

  @override
  State<PeerEscortVolunteersScreen> createState() =>
      _PeerEscortVolunteersScreenState();
}

class _PeerEscortVolunteersScreenState extends State<PeerEscortVolunteersScreen> {
  final _email = TextEditingController();
  final _service = EscortService.instance;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final value = _email.text.trim();
    if (value.isEmpty || !value.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid volunteer email'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await _service.addVolunteerEmail(value);
    _email.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${StudentOnboardingService.displayNameFromEmail(value)} as first receiver (demo)',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CampusBackdrop(
        tone: CampusBackdropTone.admin,
        roleTint: AppTheme.tealSoft,
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
                  Expanded(
                    child: Text(
                      'Peer Escort Volunteers',
                      style: GoogleFonts.figtree(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.adminInk,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'Add student emails who should get escort requests first and go assist.',
                style: GoogleFonts.figtree(color: AppTheme.adminInkMuted),
              ),
              const SizedBox(height: 16),
              GlassPanel(
                borderRadius: 22,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'volunteer@college.edu',
                          isDense: true,
                        ),
                        onSubmitted: (_) => _add(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _add,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Volunteer roster',
                style: GoogleFonts.figtree(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.adminInk,
                ),
              ),
              const SizedBox(height: 8),
              ListenableBuilder(
                listenable: _service,
                builder: (context, _) {
                  final volunteers = _service.volunteers;
                  final requests = _service.requests;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (volunteers.isEmpty)
                        GlassPanel(
                          borderRadius: 18,
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No volunteers yet. Paste emails of students who can escort others.',
                            style: GoogleFonts.figtree(
                              color: AppTheme.adminInkMuted,
                            ),
                          ),
                        )
                      else
                        ...volunteers.map(
                          (v) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GlassPanel(
                              borderRadius: 16,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  v.displayName,
                                  style: GoogleFonts.figtree(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(v.email),
                                trailing: IconButton(
                                  onPressed: () =>
                                      _service.removeVolunteer(v.email),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 18),
                      Text(
                        'Incoming requests (${_service.pendingCount} pending)',
                        style: GoogleFonts.figtree(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.adminInk,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (requests.isEmpty)
                        Text(
                          'Student escort requests will show here.',
                          style: GoogleFonts.figtree(
                            color: AppTheme.adminInkMuted,
                          ),
                        )
                      else
                        ...requests.map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GlassPanel(
                              borderRadius: 16,
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.destination,
                                    style: GoogleFonts.figtree(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'From ${r.studentEmail}',
                                    style: GoogleFonts.figtree(
                                      fontSize: 12,
                                      color: AppTheme.adminInkMuted,
                                    ),
                                  ),
                                  if (r.note.isNotEmpty) Text(r.note),
                                  if (r.assignedVolunteerEmail != null)
                                    Text(
                                      'First notified: ${r.assignedVolunteerEmail}',
                                      style: GoogleFonts.figtree(
                                        fontSize: 12,
                                        color: AppTheme.tealDeep,
                                      ),
                                    ),
                                  Text(
                                    r.status.name,
                                    style: GoogleFonts.figtree(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
