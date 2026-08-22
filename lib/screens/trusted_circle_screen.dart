import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/profile_service.dart';
import '../services/trusted_circle_service.dart';

/// Trusted circle: name → signup email → live locations from Supabase.
class TrustedCircleScreen extends StatefulWidget {
  const TrustedCircleScreen({super.key});

  @override
  State<TrustedCircleScreen> createState() => _TrustedCircleScreenState();
}

class _TrustedCircleScreenState extends State<TrustedCircleScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();

  var _addStep = 0; // 0 = name, 1 = email
  var _loading = false;
  var _refreshing = true;
  List<TrustedMember> _members = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
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
    await _load();
  }

  Future<void> _load() async {
    setState(() => _refreshing = true);
    try {
      final list = await TrustedCircleService.instance.listMine();
      if (!mounted) return;
      setState(() => _members = list);
    } catch (e) {
      if (mounted) _toast('Could not load circle: $e');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _nextOrAdd() async {
    if (_addStep == 0) {
      if (_name.text.trim().isEmpty) {
        _toast('First enter their name');
        return;
      }
      setState(() => _addStep = 1);
      return;
    }

    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _toast('Enter the email they used to sign up');
      return;
    }

    setState(() => _loading = true);
    final err = await TrustedCircleService.instance.addByEmail(
      labelName: _name.text.trim(),
      email: email,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      _toast(err);
      return;
    }

    _name.clear();
    _email.clear();
    setState(() => _addStep = 0);
    _toast('Added to trusted circle');
    await _load();
  }

  Future<void> _remove(TrustedMember m) async {
    await TrustedCircleService.instance.remove(m.id);
    await _load();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF5B21B6);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
      appBar: AppBar(
        title: const Text('Trusted Circle'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _addStep == 0
                        ? 'Step 1 — Who is this person? (name)'
                        : 'Step 2 — Their signup email',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  if (_addStep == 0)
                    TextField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _nextOrAdd(),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Mira (roommate)',
                        border: OutlineInputBorder(),
                      ),
                    )
                  else
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _nextOrAdd(),
                      decoration: InputDecoration(
                        hintText: 'friend@college.edu',
                        border: const OutlineInputBorder(),
                        prefixText: '${_name.text.trim()} · ',
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (_addStep == 1)
                        TextButton(
                          onPressed: () => setState(() => _addStep = 0),
                          child: const Text('Back'),
                        ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _loading ? null : _nextOrAdd,
                        style:
                            FilledButton.styleFrom(backgroundColor: accent),
                        child: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(_addStep == 0 ? 'Next' : 'Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _refreshing
                ? const Center(child: CircularProgressIndicator())
                : _members.isEmpty
                    ? const Center(
                        child: Text(
                          'No trusted contacts yet.\nAdd someone by name, then their signup email.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                          itemCount: _members.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final m = _members[i];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        accent.withValues(alpha: 0.12),
                                    child: Text(
                                      m.labelName.isNotEmpty
                                          ? m.labelName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: accent,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m.labelName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          m.email,
                                          style: const TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              m.hasLiveLocation
                                                  ? Icons.my_location
                                                  : Icons.location_off,
                                              size: 14,
                                              color: m.hasLiveLocation
                                                  ? accent
                                                  : Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                m.locationLabel,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: m.hasLiveLocation
                                                      ? accent
                                                      : Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _remove(m),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
