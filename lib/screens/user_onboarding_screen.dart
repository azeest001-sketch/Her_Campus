import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/student_invite_model.dart';
import '../services/student_onboarding_service.dart';
import '../theme/app_theme.dart';
import '../widgets/campus_backdrop.dart';

/// Invite-only student onboarding mockup for campus admins.
///
/// Organized as Year → Department → student emails.
class UserOnboardingScreen extends StatefulWidget {
  const UserOnboardingScreen({super.key});

  @override
  State<UserOnboardingScreen> createState() => _UserOnboardingScreenState();
}

class _UserOnboardingScreenState extends State<UserOnboardingScreen> {
  final _paste = TextEditingController();
  final _newDepartment = TextEditingController();
  final _service = StudentOnboardingService.instance;

  StudentYear _selectedYear = StudentYear.first;
  String? _selectedDepartment;
  List<String> _previewEmails = const [];
  var _sending = false;
  final Set<StudentYear> _expandedYears = {
    StudentYear.first,
    StudentYear.second,
    StudentYear.third,
  };
  final Set<String> _expandedDepartments = {};

  @override
  void dispose() {
    _paste.dispose();
    _newDepartment.dispose();
    super.dispose();
  }

  void _refreshPreview([String? value]) {
    setState(() {
      _previewEmails =
          StudentOnboardingService.parseEmails(value ?? _paste.text);
    });
  }

  String _deptKey(StudentYear year, String department) =>
      '${year.name}::$department';

  Future<void> _sendInvites() async {
    final department = _selectedDepartment?.trim();
    if (department == null || department.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Type and add a department first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final emails = StudentOnboardingService.parseEmails(_paste.text);
    if (emails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paste at least one valid college email'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _sending = true);
    await _service.inviteStudents(
      emails,
      year: _selectedYear,
      department: department,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      _paste.clear();
      _previewEmails = const [];
      _expandedYears.add(_selectedYear);
      _expandedDepartments.add(_deptKey(_selectedYear, department));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Queued ${emails.length} invite(s) under ${_selectedYear.label} · $department',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showCsvHint() async {
    // TODO(frontend): wire file_picker for real CSV uploads later.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'CSV upload coming later — for now paste emails or CSV text below',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addTypedDepartment() {
    final name = _newDepartment.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Type a department name first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _service.addDepartment(_selectedYear, name);
    setState(() {
      _selectedDepartment = name;
      _newDepartment.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CampusBackdrop(
        tone: CampusBackdropTone.admin,
        roleTint: AppTheme.blueSoft,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        'User Onboarding',
                        style: GoogleFonts.figtree(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.adminInk,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showCsvHint,
                      icon: const Icon(Icons.upload_file_outlined, size: 18),
                      label: const Text('CSV'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: _service,
                  builder: (context, _) {
                    final departments = _service.departmentsFor(_selectedYear);
                    if (_selectedDepartment != null &&
                        !departments.contains(_selectedDepartment)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        setState(() {
                          _selectedDepartment =
                              departments.isNotEmpty ? departments.first : null;
                        });
                      });
                    }

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      children: [
                        Text(
                          'Invite by year & department',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.adminInk,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Keep college invites organized: choose the year, pick a department, then paste that group’s emails.',
                          style: GoogleFonts.figtree(
                            fontSize: 13,
                            height: 1.45,
                            color: AppTheme.adminInkMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatusChip(
                                label: 'Invited',
                                count: _service.countBy(InviteStatus.invited),
                                color: AppTheme.adminInkMuted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatusChip(
                                label: 'Sent',
                                count: _service.countBy(InviteStatus.sent),
                                color: AppTheme.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatusChip(
                                label: 'Joined',
                                count: _service.countBy(InviteStatus.joined),
                                color: AppTheme.teal,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatusChip(
                                label: 'Failed',
                                count: _service.countBy(InviteStatus.failed),
                                color: AppTheme.accentDeep,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GlassPanel(
                          borderRadius: 24,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Year',
                                style: GoogleFonts.figtree(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.adminInkMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: StudentYear.values.map((year) {
                                  final selected = year == _selectedYear;
                                  return ChoiceChip(
                                    label: Text(year.label),
                                    selected: selected,
                                    onSelected: (_) {
                                      setState(() {
                                        _selectedYear = year;
                                        final deps =
                                            _service.departmentsFor(year);
                                        _selectedDepartment =
                                            deps.isNotEmpty ? deps.first : null;
                                      });
                                    },
                                    selectedColor:
                                        AppTheme.blue.withValues(alpha: 0.18),
                                    labelStyle: GoogleFonts.figtree(
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? AppTheme.blue
                                          : AppTheme.adminInk,
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Department',
                                style: GoogleFonts.figtree(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.adminInkMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _newDepartment,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _addTypedDepartment(),
                                      decoration: const InputDecoration(
                                        hintText: 'Type department name',
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _addTypedDepartment,
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(0, 48),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                    ),
                                    child: const Text('Add'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (departments.isEmpty)
                                Text(
                                  'No departments yet for ${_selectedYear.label}. Type one above and tap Add.',
                                  style: GoogleFonts.figtree(
                                    fontSize: 12,
                                    color: AppTheme.adminInkMuted,
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: departments.map((dept) {
                                    final selected =
                                        dept == _selectedDepartment;
                                    return ChoiceChip(
                                      label: Text(dept),
                                      selected: selected,
                                      onSelected: (_) => setState(
                                        () => _selectedDepartment = dept,
                                      ),
                                      selectedColor: AppTheme.teal
                                          .withValues(alpha: 0.18),
                                      labelStyle: GoogleFonts.figtree(
                                        fontWeight: FontWeight.w700,
                                        color: selected
                                            ? AppTheme.tealDeep
                                            : AppTheme.adminInk,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              const SizedBox(height: 14),
                              Text(
                                _selectedDepartment == null
                                    ? 'Emails'
                                    : 'Emails for ${_selectedYear.label} · $_selectedDepartment',
                                style: GoogleFonts.figtree(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.adminInk,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _paste,
                                minLines: 4,
                                maxLines: 7,
                                onChanged: _refreshPreview,
                                enabled: _selectedDepartment != null,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: _selectedDepartment == null
                                      ? 'Add a department first, then paste emails'
                                      : 'Paste emails for this department\njoy.smith@college.edu',
                                  alignLabelWithHint: true,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _previewEmails.isEmpty
                                    ? 'No valid emails detected yet'
                                    : '${_previewEmails.length} unique email(s) ready',
                                style: GoogleFonts.figtree(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.adminInkMuted,
                                ),
                              ),
                              if (_previewEmails.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                ..._previewEmails.take(6).map((email) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      '${StudentOnboardingService.displayNameFromEmail(email)}  ·  $email',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          GoogleFonts.figtree(fontSize: 12.5),
                                    ),
                                  );
                                }),
                                if (_previewEmails.length > 6)
                                  Text(
                                    '+${_previewEmails.length - 6} more…',
                                    style: GoogleFonts.figtree(
                                      fontSize: 12,
                                      color: AppTheme.adminInkMuted,
                                    ),
                                  ),
                              ],
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _sending || _selectedDepartment == null
                                    ? null
                                    : _sendInvites,
                                child: _sending
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                        ),
                                      )
                                    : Text(
                                        _selectedDepartment == null
                                            ? 'Add a department to continue'
                                            : 'Send invites to ${_selectedYear.label} · $_selectedDepartment',
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Organized invite list',
                          style: GoogleFonts.figtree(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.adminInk,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_service.invites.isEmpty)
                          GlassPanel(
                            borderRadius: 22,
                            padding: const EdgeInsets.all(18),
                            child: Text(
                              'No students invited yet. Pick a year and department above, then paste that group’s emails.',
                              style: GoogleFonts.figtree(
                                color: AppTheme.adminInkMuted,
                              ),
                            ),
                          )
                        else
                          ...StudentYear.values.map(
                            (year) => _YearSection(
                              year: year,
                              expanded: _expandedYears.contains(year),
                              onToggle: () {
                                setState(() {
                                  if (_expandedYears.contains(year)) {
                                    _expandedYears.remove(year);
                                  } else {
                                    _expandedYears.add(year);
                                  }
                                });
                              },
                              departments: _service.departmentsFor(year),
                              service: _service,
                              expandedDepartments: _expandedDepartments,
                              onToggleDepartment: (department) {
                                final key = _deptKey(year, department);
                                setState(() {
                                  if (_expandedDepartments.contains(key)) {
                                    _expandedDepartments.remove(key);
                                  } else {
                                    _expandedDepartments.add(key);
                                  }
                                });
                              },
                              deptKeyBuilder: _deptKey,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YearSection extends StatelessWidget {
  const _YearSection({
    required this.year,
    required this.expanded,
    required this.onToggle,
    required this.departments,
    required this.service,
    required this.expandedDepartments,
    required this.onToggleDepartment,
    required this.deptKeyBuilder,
  });

  final StudentYear year;
  final bool expanded;
  final VoidCallback onToggle;
  final List<String> departments;
  final StudentOnboardingService service;
  final Set<String> expandedDepartments;
  final ValueChanged<String> onToggleDepartment;
  final String Function(StudentYear year, String department) deptKeyBuilder;

  @override
  Widget build(BuildContext context) {
    final yearCount = service.countForYear(year);
    final activeDepartments = departments
        .where((dept) => service.countForDepartment(year, dept) > 0)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassPanel(
        borderRadius: 22,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              onTap: onToggle,
              title: Text(
                year.label,
                style: GoogleFonts.figtree(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.adminInk,
                ),
              ),
              subtitle: Text(
                yearCount == 0
                    ? 'No invites yet'
                    : '$yearCount student(s) · ${activeDepartments.length} department(s)',
                style: GoogleFonts.figtree(
                  fontSize: 12,
                  color: AppTheme.adminInkMuted,
                ),
              ),
              trailing: Icon(
                expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: AppTheme.blue,
              ),
            ),
            if (expanded) ...[
              if (activeDepartments.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Invite students into a department to see them here.',
                      style: GoogleFonts.figtree(
                        fontSize: 12,
                        color: AppTheme.adminInkMuted,
                      ),
                    ),
                  ),
                )
              else
                ...activeDepartments.map((department) {
                  final key = deptKeyBuilder(year, department);
                  final invites = service.invitesFor(
                    year: year,
                    department: department,
                  );
                  final open = expandedDepartments.contains(key);
                  return _DepartmentSection(
                    department: department,
                    invites: invites,
                    expanded: open,
                    onToggle: () => onToggleDepartment(department),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }
}

class _DepartmentSection extends StatelessWidget {
  const _DepartmentSection({
    required this.department,
    required this.invites,
    required this.expanded,
    required this.onToggle,
  });

  final String department;
  final List<StudentInviteModel> invites;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.blue.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            onTap: onToggle,
            title: Text(
              department,
              style: GoogleFonts.figtree(
                fontWeight: FontWeight.w800,
                color: AppTheme.adminInk,
              ),
            ),
            subtitle: Text(
              '${invites.length} student(s)',
              style: GoogleFonts.figtree(
                fontSize: 11,
                color: AppTheme.adminInkMuted,
              ),
            ),
            trailing: Icon(
              expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: AppTheme.tealDeep,
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                children: invites
                    .map(
                      (invite) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _InviteTile(invite: invite),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        children: [
          Text(
            '$count',
            style: GoogleFonts.figtree(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.figtree(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.adminInkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteTile extends StatelessWidget {
  const _InviteTile({required this.invite});

  final StudentInviteModel invite;

  Color get _statusColor {
    switch (invite.status) {
      case InviteStatus.invited:
        return AppTheme.adminInkMuted;
      case InviteStatus.sent:
        return AppTheme.blue;
      case InviteStatus.joined:
        return AppTheme.teal;
      case InviteStatus.failed:
        return AppTheme.accentDeep;
    }
  }

  String get _statusLabel {
    switch (invite.status) {
      case InviteStatus.invited:
        return 'Invited';
      case InviteStatus.sent:
        return 'Sent';
      case InviteStatus.joined:
        return 'Joined';
      case InviteStatus.failed:
        return 'Failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _statusColor.withValues(alpha: 0.15),
            child: Text(
              invite.displayName.isEmpty
                  ? '?'
                  : invite.displayName[0].toUpperCase(),
              style: GoogleFonts.figtree(
                fontWeight: FontWeight.w800,
                color: _statusColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.displayName,
                  style: GoogleFonts.figtree(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.adminInk,
                  ),
                ),
                Text(
                  invite.email,
                  style: GoogleFonts.figtree(
                    fontSize: 11.5,
                    color: AppTheme.adminInkMuted,
                  ),
                ),
                if (invite.errorMessage != null)
                  Text(
                    invite.errorMessage!,
                    style: GoogleFonts.figtree(
                      fontSize: 11,
                      color: AppTheme.accentDeep,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _statusLabel,
              style: GoogleFonts.figtree(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: _statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
