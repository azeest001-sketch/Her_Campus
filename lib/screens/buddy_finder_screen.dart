import 'package:flutter/material.dart';

import '../services/buddy_service.dart';

/// Buddy Finder: same campus + within 300 m, notifies nearby students in-app.
class BuddyFinderScreen extends StatefulWidget {
  const BuddyFinderScreen({super.key});

  @override
  State<BuddyFinderScreen> createState() => _BuddyFinderScreenState();
}

class _BuddyFinderScreenState extends State<BuddyFinderScreen> {
  final _destination = TextEditingController();
  var _searching = false;
  List<NearbyBuddy> _nearby = [];
  List<BuddyNotificationItem> _notifications = [];
  String? _status;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _destination.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      final items = await BuddyService.instance.myNotifications();
      if (!mounted) return;
      setState(() => _notifications = items);
    } catch (_) {}
  }

  Future<void> _find() async {
    final dest = _destination.text.trim();
    if (dest.isEmpty) {
      setState(() => _status = 'Enter a destination first');
      return;
    }
    setState(() {
      _searching = true;
      _status = 'Scanning same campus within 300 m…';
      _nearby = [];
    });
    try {
      final result =
          await BuddyService.instance.findNearby(destination: dest);
      if (!mounted) return;
      setState(() {
        _nearby = result.nearby;
        _status = result.error ??
            (result.nearby.isEmpty
                ? 'No one nearby right now. Your request was saved — others within 300 m will get an in-app notice when online.'
                : 'Notified ${result.nearby.length} nearby student(s).');
      });
      await _loadNotifications();
    } catch (e) {
      if (mounted) setState(() => _status = '$e');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7C3AED);
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5FF),
      appBar: AppBar(
        title: const Text('Buddy Finder'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            tooltip: 'Refresh notices',
            onPressed: _loadNotifications,
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF6E7F8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Find students on your campus within ~300 m and notify them you want company to a destination.',
              style: TextStyle(height: 1.45),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'WHERE ARE YOU HEADING?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _destination,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_on_outlined),
                    hintText: 'e.g. Hostel B, Library',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _searching ? null : _find,
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  icon: _searching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search),
                  label: Text(_searching ? 'Searching…' : 'Find & notify'),
                ),
              ],
            ),
          ),
          if (_status != null) ...[
            const SizedBox(height: 14),
            Text(_status!, style: const TextStyle(color: Color(0xFF64748B))),
          ],
          if (_nearby.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              '${_nearby.length} NEARBY (NOTIFIED)',
              style: const TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ..._nearby.map(
              (b) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFFFE4EE),
                      child: Text(
                        b.displayName.isNotEmpty
                            ? b.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '~${b.distanceMeters.round()} m · ${b.email}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.notifications_active, color: accent),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
          const Text(
            'YOUR NOTICES',
            style: TextStyle(fontWeight: FontWeight.w800, color: accent),
          ),
          const SizedBox(height: 10),
          if (_notifications.isEmpty)
            const Text(
              'No buddy requests yet. When someone nearby asks, it shows here.',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          else
            ..._notifications.map(
              (n) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  n.read ? Icons.notifications_none : Icons.notifications_active,
                  color: accent,
                ),
                title: Text(n.message),
                subtitle: Text(
                  n.createdAt.toLocal().toString().split('.').first,
                  style: const TextStyle(fontSize: 11),
                ),
                onTap: () async {
                  await BuddyService.instance.markRead(n.id);
                  await _loadNotifications();
                },
              ),
            ),
        ],
      ),
    );
  }
}
