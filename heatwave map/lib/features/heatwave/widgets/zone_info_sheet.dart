import 'package:flutter/material.dart';
import 'package:safe_campus/features/heatwave/data/crowd_zone.dart';

Future<void> showZoneInfoSheet(BuildContext context, CrowdZone zone) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              zone.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(zone.statusLabel),
            const SizedBox(height: 12),
            if (zone.status == CrowdStatus.unknown)
              const Text('Unknown crowd density')
            else ...[
              Text('Approximate crowd: ${zone.approxCount}'),
              Text('Bluetooth signals: ${zone.btCount}'),
              Text('WiFi / hotspot signals: ${zone.wifiCount}'),
            ],
            const SizedBox(height: 8),
            const Text(
              'Counts are anonymous radio estimates, not identities.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}
