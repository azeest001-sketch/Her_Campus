import 'package:flutter/material.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool _isDark = false;

  final purpleStart = const Color(0xFF3B0764);
  final purpleEnd = const Color(0xFF7C3AED);

  final List<Map<String, dynamic>> _features = [
    {
      'title': 'Heatwave Map',
      'icon': Icons.map,
      'description': 'Monitor dynamic crowd density levels to plan safe transit paths.'
    },
    {
      'title': 'Peer Escort',
      'icon': Icons.shield,
      'description': 'Connect safely with verified seniors or approved student volunteers to walk with you anywhere on campus.'
    },
    {
      'title': 'Trusted Circle',
      'icon': Icons.group,
      'description': 'Securely store close contacts to share live location updates dynamically.'
    },
    {
      'title': 'Buddy Finder',
      'icon': Icons.search,
      'description': 'Match instantly with nearby students headed toward your same destination.'
    },
    {
      'title': 'Transit Logs',
      'icon': Icons.directions_bus,
      'description': 'Track your route options and auto-stream location metrics to parents until arrival.'
    },
    {
      'title': 'Automatic Floor Estimation',
      'icon': Icons.stairs,
      'description': 'Calculate high-precision barometric elevations to determine your exact multi-story building floor location.'
    },
    {
      'title': 'Student Report',
      'icon': Icons.description,
      'description': 'Submit urgent incident descriptions to campus administrative teams completely anonymously.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(scaffoldBackgroundColor: Colors.white),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [purpleStart, purpleEnd], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => setState(() => _isDark = !_isDark),
                              icon: Icon(_isDark ? Icons.wb_sunny : Icons.nights_stay, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {},
                              child: const CircleAvatar(radius: 18, backgroundColor: Colors.white24, child: Text('AM', style: TextStyle(color: Colors.white))),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 4),
                    const Text(
                      "Built for every girl who's ever walked home looking over her shoulder.",
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.15),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Her Campus brings together tools that help students feel safer while moving around campus — combining privacy-first design, on-device precision, and fast emergency response flows to reduce worry and improve outcomes.',
                      style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),

              // Body content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      const Text('Why we built Her Campus', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      // Pillars (no card)
                      _Pillar(title: 'Privacy', description: 'We minimize data retention and keep location sharing under your control.'),
                      const SizedBox(height: 12),
                      _Pillar(title: 'Precision', description: 'High-quality sensors and algorithms help provide accurate location and floor estimation.'),
                      const SizedBox(height: 12),
                      _Pillar(title: 'Speed of response', description: 'Quickly connect you with trusted helpers and campus safety when it matters most.'),

                      const SizedBox(height: 20),
                      const Text('How to use each feature', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),

                      // Grid of features 2-column
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.35,
                        children: _features.map((f) {
                          return _FeatureGridItem(
                            title: f['title'] as String,
                            icon: f['icon'] as IconData,
                            description: f['description'] as String,
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),
                      Center(child: Text('Thank you for trusting Her Campus', style: TextStyle(color: Colors.grey[700], fontSize: 13))),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pillar extends StatelessWidget {
  final String title;
  final String description;
  const _Pillar({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 6),
              Text(description, style: const TextStyle(color: Colors.black87, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureGridItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  const _FeatureGridItem({required this.title, required this.icon, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.purple, size: 22),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 6),
          Expanded(child: Text(description, style: const TextStyle(color: Colors.black87, fontSize: 12, height: 1.25))),
        ],
      ),
    );
  }
}
