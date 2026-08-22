import 'package:flutter/material.dart';
import 'package:safe_campus/app/routes.dart';

class StudentHomePage extends StatelessWidget {
  const StudentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student home'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.modeSelect,
                (_) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Features',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap Heatwave for crowd density. Other icons are placeholders for teammates.',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _FeatureTile(
                    icon: Icons.local_fire_department,
                    label: 'Heatwave',
                    enabled: true,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.heatwave);
                    },
                  ),
                  const _FeatureTile(
                    icon: Icons.map_outlined,
                    label: 'Campus map',
                    enabled: false,
                  ),
                  const _FeatureTile(
                    icon: Icons.sos_outlined,
                    label: 'SOS',
                    enabled: false,
                  ),
                  const _FeatureTile(
                    icon: Icons.more_horiz,
                    label: 'Coming soon',
                    enabled: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.enabled,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? Theme.of(context).colorScheme.secondaryContainer
          : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: enabled
                  ? Theme.of(context).colorScheme.onSecondaryContainer
                  : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: enabled ? null : Colors.grey,
              ),
            ),
            if (!enabled)
              const Text(
                'Coming soon',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
