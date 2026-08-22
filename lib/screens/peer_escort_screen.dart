import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/escort_service.dart';
import '../services/profile_service.dart';
import '../models/escort_model.dart';

/// Student peer escort: request → matched → walking → safe (no QR).
class PeerEscortScreen extends StatefulWidget {
  const PeerEscortScreen({super.key});

  @override
  State<PeerEscortScreen> createState() => _PeerEscortScreenState();
}

class _PeerEscortScreenState extends State<PeerEscortScreen> {
  final _destination = TextEditingController();
  final _note = TextEditingController();
  final _steps = const ['Request', 'Matched', 'Walking', 'Safe'];

  var _step = 0;
  var _loading = false;
  EscortRequestModel? _request;
  EscortVolunteerModel? _volunteer;

  @override
  void dispose() {
    _destination.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final dest = _destination.text.trim();
    if (dest.isEmpty) {
      _toast('Enter where you need to go');
      return;
    }
    setState(() => _loading = true);
    try {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
        await ProfileService.instance
            .updateLocation(lat: pos.latitude, lng: pos.longitude);
      } catch (_) {}

      final request = await EscortService.instance.requestEscort(
        destination: dest,
        note: _note.text,
      );
      final volunteer =
          EscortService.instance.volunteerFor(request.assignedVolunteerEmail);
      if (!mounted) return;
      setState(() {
        _request = request;
        _volunteer = volunteer;
        _step = 1;
      });
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startWalk() async {
    final id = _request?.id;
    if (id == null) return;
    await EscortService.instance
        .setRequestStatus(id, EscortRequestStatus.accepted);
    setState(() => _step = 2);
  }

  Future<void> _markSafe() async {
    final id = _request?.id;
    if (id == null) return;
    await EscortService.instance
        .setRequestStatus(id, EscortRequestStatus.completed);
    setState(() => _step = 3);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7C3AED);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2FF),
      appBar: AppBar(
        title: const Text('Peer Escort'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF101828),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          _Stepper(steps: _steps, current: _step, accent: accent),
          const SizedBox(height: 20),
          if (_step == 0) _requestCard(accent),
          if (_step == 1) _matchedCard(accent),
          if (_step == 2) _walkingCard(accent),
          if (_step == 3) _safeCard(accent),
        ],
      ),
    );
  }

  Widget _requestCard(Color accent) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Request an escort',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your own destination. A registered volunteer will be assigned from the campus list.',
            style: TextStyle(color: Color(0xFF6B7280), height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _destination,
            decoration: const InputDecoration(
              labelText: 'Destination',
              hintText: 'e.g. Hostel B, Library, Main Gate',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'Meeting point, urgency, etc.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _loading ? null : _submitRequest,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : const Text('Send request'),
          ),
        ],
      ),
    );
  }

  Widget _matchedCard(Color accent) {
    final name = _volunteer?.displayName ?? 'Campus volunteer';
    final email = _volunteer?.email ?? _request?.assignedVolunteerEmail;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Escort matched',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: accent.withValues(alpha: 0.15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(color: accent, fontWeight: FontWeight.w800),
              ),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(email ?? 'Waiting for volunteer assignment'),
          ),
          Text('Going to: ${_request?.destination ?? '—'}'),
          if ((_request?.note ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Note: ${_request!.note}'),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: email == null ? null : _startWalk,
            style: FilledButton.styleFrom(backgroundColor: accent),
            child: const Text('Start walk together'),
          ),
          if (email == null)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'No volunteers yet — ask admin to add emails under Peer Escort Volunteers.',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _walkingCard(Color accent) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Walking',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'You are walking with ${_volunteer?.displayName ?? 'your escort'} toward ${_request?.destination ?? 'your destination'}.',
            style: const TextStyle(height: 1.45, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _markSafe,
            style: FilledButton.styleFrom(backgroundColor: accent),
            child: const Text('I arrived safely'),
          ),
        ],
      ),
    );
  }

  Widget _safeCard(Color accent) {
    return _Card(
      child: Column(
        children: [
          Icon(Icons.check_circle, color: accent, size: 56),
          const SizedBox(height: 12),
          const Text(
            'You are safe',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Escort marked complete. Stay aware on campus.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to dashboard'),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.steps,
    required this.current,
    required this.accent,
  });

  final List<String> steps;
  final int current;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                color: current >= i ? accent : const Color(0xFFD1D5DB),
              ),
            ),
          Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor:
                    current >= i ? accent : const Color(0xFFE5E7EB),
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    color: current >= i ? Colors.white : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(steps[i], style: const TextStyle(fontSize: 11)),
            ],
          ),
        ],
      ],
    );
  }
}
