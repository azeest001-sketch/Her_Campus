import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/report_model.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import '../widgets/campus_backdrop.dart';

/// Admin inbox for student-submitted campus reports (mockup).
class ReportInboxScreen extends StatelessWidget {
  const ReportInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ReportService.instance;

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
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        'Report Inbox',
                        style: GoogleFonts.figtree(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.adminInk,
                        ),
                      ),
                    ),
                    ListenableBuilder(
                      listenable: service,
                      builder: (_, __) => Text(
                        '${service.newCount} new',
                        style: GoogleFonts.figtree(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.blueSoft,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: service,
                  builder: (context, _) {
                    final reports = service.reports;
                    if (reports.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No reports yet. Students can send events from their home screen.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.figtree(
                              color: AppTheme.adminInkMuted,
                            ),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: reports.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final report = reports[index];
                        return _ReportCard(report: report);
                      },
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

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report.title,
                  style: GoogleFonts.figtree(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.adminInk,
                  ),
                ),
              ),
              PopupMenuButton<ReportStatus>(
                onSelected: (status) =>
                    ReportService.instance.setStatus(report.id, status),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: ReportStatus.newReport,
                    child: Text('Mark new'),
                  ),
                  PopupMenuItem(
                    value: ReportStatus.reviewing,
                    child: Text('Reviewing'),
                  ),
                  PopupMenuItem(
                    value: ReportStatus.resolved,
                    child: Text('Resolved'),
                  ),
                ],
                child: Chip(
                  label: Text(_statusLabel(report.status)),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            report.description,
            style: GoogleFonts.figtree(color: AppTheme.adminInkMuted),
          ),
          const SizedBox(height: 8),
          Text(
            [
              report.reporterEmail,
              if (report.locationLabel != null) report.locationLabel!,
              _timeLabel(report.createdAt),
            ].join(' · '),
            style: GoogleFonts.figtree(
              fontSize: 11,
              color: AppTheme.adminInkMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(ReportStatus status) {
    switch (status) {
      case ReportStatus.newReport:
        return 'New';
      case ReportStatus.reviewing:
        return 'Reviewing';
      case ReportStatus.resolved:
        return 'Resolved';
    }
  }

  String _timeLabel(DateTime time) {
    final local = time.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
