import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/college_service.dart';
import 'customisable_map_screen.dart';
import 'heatwave_map_screen.dart';
import 'peer_escort_volunteers_screen.dart';
import 'report_inbox_screen.dart';
import 'role_select_screen.dart';

/// Admin home — same visual language as the student dashboard.
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  var _isDark = false;

  final _adminName = 'Campus Admin';

    late final List<_AdminFeature> _features = [
    _AdminFeature(
      'Customisable Map',
      Icons.map_outlined,
      () => const CustomisableMapScreen(),
    ),
    _AdminFeature(
      'Peer Escort Volunteers',
      Icons.groups_outlined,
      () => const PeerEscortVolunteersScreen(),
    ),
    _AdminFeature(
      'Report Inbox',
      Icons.inbox_outlined,
      () => const ReportInboxScreen(),
    ),
    _AdminFeature(
      'Heatwave Map',
      Icons.whatshot_outlined,
      () => const HeatwaveMapScreen(),
    ),
  ];

  final _lightFeatureColors = const [
    Color(0xFFF3E8FF),
    Color(0xFFE0FCFF),
    Color(0xFFFEF7ED),
    Color(0xFFFFE4E8),
  ];

  final _darkFeatureColors = const [
    Color(0xFF2B1F3D),
    Color(0xFF0A3942),
    Color(0xFF14141B),
    Color(0xFF3B131C),
  ];

  final _featureAccentColors = const [
    Color(0xFF7C3AED),
    Color(0xFF06B6D4),
    Color(0xFFF97316),
    Color(0xFFDC2626),
  ];

  void _open(Widget Function() builder) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => builder()),
    );
  }

  Future<void> _logout() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const RoleSelectScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final college = CollegeService.instance.selectedCollege;
    final campusLabel =
        college?.name.split(',').first.trim() ?? 'Campus admin';

    final bg = _isDark ? const Color(0xFF0F1720) : const Color(0xFFF6F7FB);
    final topGradientStart =
        _isDark ? const Color(0xFF4C1D95) : const Color(0xFF6A00F4);
    final topGradientEnd =
        _isDark ? const Color(0xFF7C3AED) : const Color(0xFF8E45FF);

    return Theme(
      data: ThemeData(
        brightness: _isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: bg,
        primaryColor: topGradientStart,
      ),
      child: Scaffold(
        drawer: _buildDrawer(campusLabel),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [topGradientStart, topGradientEnd],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Builder(
                                builder: (context) => IconButton(
                                  icon: const Icon(Icons.menu,
                                      color: Colors.white),
                                  onPressed: () =>
                                      Scaffold.of(context).openDrawer(),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        setState(() => _isDark = !_isDark),
                                    icon: Icon(
                                      _isDark
                                          ? Icons.wb_sunny
                                          : Icons.nights_stay,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.white24,
                                    child: Text(
                                      'CA',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hello, $_adminName 👋',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            campusLabel,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: -28,
                      child: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: _isDark
                                ? const Color(0xFF0B1220)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Search campus tools...',
                                    border: InputBorder.none,
                                    hintStyle:
                                        TextStyle(color: Colors.grey[500]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Campus tools',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                sliver: SliverToBoxAdapter(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _features.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.05,
                    ),
                    itemBuilder: (context, index) {
                      final feature = _features[index];
                      final accent = _featureAccentColors[index];
                      final textColor =
                          _isDark ? Colors.white : Colors.black87;
                      final cardColor = _isDark
                          ? _darkFeatureColors[index]
                          : _lightFeatureColors[index];

                      return GestureDetector(
                        onTap: () => _open(feature.builder),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: _isDark
                                ? [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.25),
                                      blurRadius: 20,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : [
                                    const BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  feature.icon,
                                  color: accent,
                                  size: 26,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                feature.title,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Icon(
                                  Icons.chevron_right,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Drawer _buildDrawer(String campusLabel) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.shade700,
                    Colors.purpleAccent.shade200,
                  ],
                ),
              ),
              currentAccountPicture: const CircleAvatar(child: Text('CA')),
              accountName: Text(_adminName),
              accountEmail: Text(campusLabel),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: _features.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final feature = _features[i];
                  return ListTile(
                    leading: Icon(feature.icon),
                    title: Text(feature.title),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      _open(feature.builder);
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminFeature {
  const _AdminFeature(this.title, this.icon, this.builder);

  final String title;
  final IconData icon;
  final Widget Function() builder;
}
