import 'package:flutter/material.dart';
import 'buddy_finder_screen.dart';
import 'peer_escort_screen.dart';
import 'student_report_screen.dart';
import 'trusted_circle_screen.dart';
import 'transit_logs_screen.dart';
import 'heat_map_screen.dart';
import 'floor_estimation_screen.dart';
import 'about_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({Key? key}) : super(key: key);

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  bool _isDark = false;
  bool _sosEnabled = false;

  final String _userName = 'Alex Morgan';
  final String _roll = 'Roll No. 20231234';

  final List<_Feature> _features = [
    _Feature('Heatwave Map', Icons.heat_pump),
    _Feature('Peer Escort', Icons.shield),
    _Feature('Trusted Circle', Icons.group),
    _Feature('Buddy Finder', Icons.search),
    _Feature('Transit Logs', Icons.directions_bus),
    _Feature('Automatic Floor Estimation', Icons.stairs),
    _Feature('Student Report', Icons.description),
  ];

  final List<Color> _lightFeatureColors = [
    const Color(0xFFFEF7ED),
    const Color(0xFFF3E8FF),
    const Color(0xFFF0FDF4),
    const Color(0xFFFFE4E8),
    const Color(0xFFE0FCFF),
    const Color(0xFFFEF3C7),
    const Color(0xFFFED7E2),
  ];

  final List<Color> _darkFeatureColors = [
    const Color(0xFF14141B),
    const Color(0xFF2B1F3D),
    const Color(0xFF11270F),
    const Color(0xFF3B131C),
    const Color(0xFF0A3942),
    const Color(0xFF4A3D12),
    const Color(0xFF4B1C2A),
  ];

  final List<Color> _featureAccentColors = [
    const Color(0xFFF97316),
    const Color(0xFF7C3AED),
    const Color(0xFF16A34A),
    const Color(0xFFF9737D),
    const Color(0xFF06B6D4),
    const Color(0xFFF59E0B),
    const Color(0xFFDC2626),
  ];

  @override
  Widget build(BuildContext context) {
    final bg = _isDark ? const Color(0xFF0F1720) : const Color(0xFFF6F7FB);
    final topGradientStart = _isDark ? const Color(0xFF4C1D95) : const Color(0xFF6A00F4);
    final topGradientEnd = _isDark ? const Color(0xFF7C3AED) : const Color(0xFF8E45FF);

    return Theme(
      data: ThemeData(
        brightness: _isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: bg,
        primaryColor: topGradientStart,
      ),
      child: Scaffold(
        drawer: _buildDrawer(context),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Builder(
                                builder: (context) => IconButton(
                                  icon: const Icon(Icons.menu, color: Colors.white),
                                  onPressed: () => Scaffold.of(context).openDrawer(),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => setState(() => _isDark = !_isDark),
                                    icon: Icon(
                                      _isDark ? Icons.wb_sunny : Icons.nights_stay,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: _showProfileDialog,
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.white24,
                                      child: const Text('AM', style: TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Hello, $_userName 👋',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text('Have a great day ahead!',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14)),
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
                            color: _isDark ? const Color(0xFF0B1220) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Search anything...',
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(color: Colors.grey[500]),
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
              SliverToBoxAdapter(
                child: const SizedBox(height: 48),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: _sosEnabled
                        ? (_isDark ? Colors.red.shade700 : Colors.red.shade100)
                        : (_isDark ? const Color(0xFF0B1220) : Colors.white),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Emergency SOS',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _isDark ? Colors.white : Colors.black)),
                                const SizedBox(height: 4),
                                Text(
                                  _sosEnabled ? 'SOS is active' : 'Tap to enable emergency help',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _sosEnabled,
                            activeColor: Colors.white,
                            activeTrackColor: Colors.red,
                            inactiveThumbColor: _isDark ? Colors.grey : Colors.grey.shade700,
                            onChanged: (v) => setState(() => _sosEnabled = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                sliver: SliverToBoxAdapter(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _features.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.05,
                    ),
                    itemBuilder: (context, index) {
                      final feature = _features[index];
                      final isPeerEscort = feature.title == 'Peer Escort';
                      final accentColor = _featureAccentColors[index];
                      final textColor = _isDark ? Colors.white : Colors.black87;

                      Color cardColor;
                      Color iconBackground;
                      Color iconColor;

                      if (feature.title == 'Heatwave Map') {
                        cardColor = _isDark ? const Color(0xFF1A1A1C) : const Color(0xFFF8F7F5);
                        iconBackground = const Color(0xFFFFF1E6);
                        iconColor = const Color(0xFFF97316);
                      } else if (feature.title == 'Automatic Floor Estimation') {
                        cardColor = _isDark ? const Color(0xFF2A2618) : const Color(0xFFFFFBEB);
                        iconBackground = const Color(0xFFFFF1C2);
                        iconColor = const Color(0xFFF59E0B);
                      } else {
                        cardColor = _isDark
                            ? _darkFeatureColors[index]
                            : isPeerEscort
                                ? const Color(0xFF7C3AED).withOpacity(0.08)
                                : _lightFeatureColors[index];
                        iconBackground = isPeerEscort
                            ? const Color(0xFFE9D5FF)
                            : feature.title == 'Buddy Finder'
                                ? const Color(0xFFFF7F50).withOpacity(0.18)
                                : feature.title == 'Transit Logs'
                                    ? const Color(0xFF00F0FF)
                                    : accentColor.withOpacity(0.18);
                        iconColor = isPeerEscort
                            ? const Color(0xFF7C3AED)
                            : feature.title == 'Buddy Finder'
                                ? const Color(0xFFFB923C)
                                : feature.title == 'Transit Logs'
                                    ? const Color(0xFF06B6D4)
                                    : accentColor;
                      }

                      return GestureDetector(
                        onTap: () {
                          if (feature.title == 'Peer Escort') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PeerEscortScreen()),
                            );
                          } else if (feature.title == 'Buddy Finder') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const BuddyFinderScreen()),
                            );
                          } else if (feature.title == 'Trusted Circle') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const TrustedCircleScreen()),
                            );
                          } else if (feature.title == 'Student Report') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const StudentReportScreen()),
                            );
                          } else if (feature.title == 'Transit Logs') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const TransitLogsScreen()),
                            );
                          } else if (feature.title == 'Heatwave Map') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => HeatMapScreen()),
                            );
                          } else if (feature.title == 'Automatic Floor Estimation') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => FloorEstimationScreen()),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: _isDark
                                ? [
                                    BoxShadow(
                                      color: accentColor.withOpacity(0.25),
                                      blurRadius: 20,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : [
                                    BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 4)),
                                  ],
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: iconBackground,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  feature.icon,
                                  color: iconColor,
                                  size: 26,
                                ),
                              ),
                              const Spacer(),
                              Text(feature.title,
                                  style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 15)),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Icon(Icons.chevron_right, color: textColor),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: const SizedBox(height: 12),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.deepOrange.shade400, Colors.red.shade700]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                          child: const Icon(Icons.battery_alert, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Low Battery SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              SizedBox(height: 4),
                              Text('Your device battery is low. Enable Low Battery SOS to auto-send location when critical.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.black26),
                          onPressed: () {},
                          child: const Text('Enable'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 36, child: const Text('AM')),
                const SizedBox(height: 12),
                Text(_userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(_roll, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                TextField(decoration: const InputDecoration(labelText: 'Change display name')),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
                    ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Save')),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    final items = [
      'Heatwave Map',
      'Peer Escort',
      'Trusted Circle',
      'Buddy Finder',
      'Transit Logs',
      'Automatic Floor Estimation',
      'Student Report',
      'About',
    ];

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.purple.shade700, Colors.purpleAccent.shade200]),
              ),
              currentAccountPicture: const CircleAvatar(child: Text('AM')),
              accountName: Text(_userName),
              accountEmail: Text(_roll),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final title = items[i];
                  return ListTile(
                    leading: const Icon(Icons.circle_outlined),
                    title: Text(title),
                    subtitle: null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      if (title == 'Heatwave Map') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HeatMapScreen()),
                        );
                      } else if (title == 'Peer Escort') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PeerEscortScreen()),
                        );
                      } else if (title == 'Trusted Circle') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TrustedCircleScreen()),
                        );
                      } else if (title == 'Buddy Finder') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BuddyFinderScreen()),
                        );
                      } else if (title == 'Transit Logs') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TransitLogsScreen()),
                        );
                      } else if (title == 'Automatic Floor Estimation') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const FloorEstimationScreen()),
                        );
                      } else if (title == 'Student Report') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const StudentReportScreen()),
                        );
                      } else if (title == 'About') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AboutScreen()),
                        );
                      }
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _Feature {
  final String title;
  final IconData icon;
  _Feature(this.title, this.icon);
}
