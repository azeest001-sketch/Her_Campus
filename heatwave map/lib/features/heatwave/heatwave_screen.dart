import 'package:flutter/material.dart';
import 'package:safe_campus/features/heatwave/heatwave_controller.dart';

class HeatwaveScreen extends StatefulWidget {
  const HeatwaveScreen({super.key});

  @override
  State<HeatwaveScreen> createState() => _HeatwaveScreenState();
}

class _HeatwaveScreenState extends State<HeatwaveScreen> {
  late final HeatwaveController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HeatwaveController();
    _controller.addListener(_onUpdate);
    _controller.start();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estimate = _controller.lastEstimate;
    final projected = _controller.projectedHotspots();
    final me = _controller.projectedMe();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Heatwave'),
        actions: [
          IconButton(
            tooltip: 'Scan now',
            onPressed: _controller.scanning ? null : _controller.refreshNow,
            icon: _controller.scanning
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _controller.statusMessage ?? 'Starting…',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        label: 'Approx people',
                        value: estimate == null
                            ? '—'
                            : '~${estimate.approxPeople}',
                        emphasize: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatBox(
                        label: 'Bluetooth',
                        value: estimate == null ? '—' : '${estimate.btCount}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatBox(
                        label: 'WiFi / hotspot',
                        value: estimate == null
                            ? '—'
                            : (estimate.wifiAvailable
                                ? '${estimate.wifiCount}'
                                : 'N/A'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  projected.isEmpty
                      ? 'Blank area — hotspots appear only where crowd is detected.'
                      : '${projected.length} hotspot(s) where crowd was detected.',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  return Stack(
                    children: [
                      const Center(
                        child: Text(
                          'Detection area',
                          style: TextStyle(color: Colors.black26, fontSize: 16),
                        ),
                      ),
                      for (final p in projected)
                        Positioned(
                          left: p.x * w - _hotspotSize(p.hotspot.approxCount) / 2,
                          top: p.y * h - _hotspotSize(p.hotspot.approxCount) / 2,
                          child: GestureDetector(
                            onTap: () => _showHotspot(p.hotspot),
                            child: Container(
                              width: _hotspotSize(p.hotspot.approxCount),
                              height: _hotspotSize(p.hotspot.approxCount),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _hotColor(p.hotspot).withValues(alpha: 0.55),
                                border: Border.all(
                                  color: _hotColor(p.hotspot),
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '~${p.hotspot.approxCount}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (me != null)
                        Positioned(
                          left: me.dx * w - 10,
                          top: me.dy * h - 10,
                          child: const Icon(
                            Icons.person_pin_circle,
                            color: Colors.blue,
                            size: 28,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: FilledButton.icon(
              onPressed: _controller.scanning ? null : _controller.refreshNow,
              icon: const Icon(Icons.sensors),
              label: Text(
                _controller.scanning ? 'Scanning…' : 'Scan nearby devices',
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _hotspotSize(int count) {
    return (56 + count * 2).clamp(56, 120).toDouble();
  }

  Color _hotColor(CrowdHotspot hotspot) {
    final t = (hotspot.approxCount / 30).clamp(0.0, 1.0);
    return Color.lerp(Colors.orange, Colors.red, t)!;
  }

  void _showHotspot(CrowdHotspot hotspot) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hotspot.live ? 'Live hotspot' : 'Last known hotspot',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text('Approx people: ~${hotspot.approxCount}'),
              Text('Bluetooth signals: ${hotspot.btCount}'),
              Text('WiFi / hotspot signals: ${hotspot.wifiCount}'),
              Text('Updated: ${hotspot.updatedAt.toLocal()}'),
              const SizedBox(height: 8),
              const Text(
                'Anonymous radio estimate — identities are not stored.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: emphasize
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: emphasize ? 22 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
