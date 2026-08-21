import 'package:flutter/material.dart';

class TransitLogsScreen extends StatefulWidget {
  const TransitLogsScreen({Key? key}) : super(key: key);

  @override
  State<TransitLogsScreen> createState() => _TransitLogsScreenState();
}

class _TransitLogsScreenState extends State<TransitLogsScreen> {
  bool _isDark = false;
  bool _autoShare = true;
  String _parentNumber = '+91 98xxxxxx99';
  bool _isResident = false; // false -> Non-resident by default
  bool _isCampusBus = true; // true -> Campus Bus by default

  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  final List<Map<String, String>> _mockTrips = [
    {'title': 'Campus Gate → Home', 'time': 'Today, 08:12 AM', 'status': 'Live'},
    {'title': 'Hostel A → Library', 'time': 'Yesterday, 05:02 PM', 'status': 'Ended'},
    {'title': 'Library → Lab 2', 'time': 'Aug 9, 03:20 PM', 'status': 'Ended'},
  ];

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF06B6D4); // Cyber Cyan
    final cyberCircle = const Color(0xFF00F0FF);
    final bg = _isDark ? const Color(0xFF071021) : const Color(0xFFF7FAFC);
    final cardBg = _isDark ? const Color(0xFF0E1520) : Colors.white;
    final textColor = _isDark ? Colors.white : Colors.black87;

    return Theme(
      data: ThemeData(
        brightness: _isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: bg,
        primaryColor: accent,
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: textColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text('Transit Logs', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(_isDark ? Icons.wb_sunny : Icons.nights_stay, color: textColor),
                          onPressed: () => setState(() => _isDark = !_isDark),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {},
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: cyberCircle,
                            child: Text('AM', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Auto-share box
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text('Auto-share with parent after class', style: TextStyle(fontWeight: FontWeight.w700, color: textColor))),
                                Switch(
                                  value: _autoShare,
                                  activeColor: Colors.white,
                                  activeTrackColor: accent,
                                  onChanged: (v) => setState(() => _autoShare = v),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    readOnly: true,
                                    controller: TextEditingController(text: _parentNumber),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: _isDark ? const Color(0xFF081223) : const Color(0xFFF3F9FB),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    ),
                                    style: TextStyle(color: textColor),
                                  ),
                                ),
                                PopupMenuButton<int>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (v) {
                                    if (v == 1) {
                                      _showChangeNumberDialog();
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 1, child: Text('Change number')),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Streaming Info Bar
                            Container(
                              decoration: BoxDecoration(color: _isDark ? const Color(0xFF071A12) : const Color(0xFFF2FFF4), borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              child: Row(
                                children: [
                                  Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF10B981))),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Live location streaming to $_parentNumber', style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
                                        const SizedBox(height: 4),
                                        Text('Streaming currently active. Stop to end sharing.', style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {},
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(color: _isDark ? const Color(0xFF1F2937) : Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                                      child: Text('Stop', style: TextStyle(color: _isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Category toggle row
                      Row(
                        children: [
                          _buildPill('Non-resident student', !_isResident, () => setState(() => _isResident = false)),
                          const SizedBox(width: 10),
                          _buildPill('Resident student', _isResident, () => setState(() => _isResident = true)),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Transit mode row
                      Row(
                        children: [
                          _buildPill('Campus Bus', _isCampusBus, () => setState(() => _isCampusBus = true)),
                          const SizedBox(width: 10),
                          _buildPill('Public / Cab', !_isCampusBus, () => setState(() => _isCampusBus = false)),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Conditional fields
                      if (_isResident && !_isCampusBus) ...[
                        TextField(
                          controller: _startController,
                          decoration: InputDecoration(
                            labelText: 'Start Location',
                            filled: true,
                            fillColor: _isDark ? const Color(0xFF081224) : const Color(0xFFF3F7F8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _endController,
                          decoration: InputDecoration(
                            labelText: 'End Location',
                            filled: true,
                            fillColor: _isDark ? const Color(0xFF081224) : const Color(0xFFF3F7F8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ] else ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14)),
                          child: Text(
                            !_isResident
                                ? 'Campus -> Home'
                                : 'Typical route: Campus Gate → Academic Block → Hostels',
                            style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.85)),
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Action button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.play_arrow),
                          label: Text(_isCampusBus ? 'Start campus bus trip' : 'Start trip'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Recent trips header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent trips', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
                          Text('See all', style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Recent trips list
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _mockTrips.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final t = _mockTrips[i];
                          final isLive = t['status'] == 'Live';
                          return Container(
                            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: accent.withOpacity(0.12), shape: BoxShape.circle),
                                  child: Icon(Icons.directions_bus, color: accent),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(t['title']!, style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
                                      const SizedBox(height: 4),
                                      Text(t['time']!, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isLive ? const Color(0xFFE6FFFA) : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(isLive ? 'Live' : 'Ended', style: TextStyle(color: isLive ? const Color(0xFF065F46) : Colors.grey[700], fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 40),
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

  Widget _buildPill(String label, bool active, VoidCallback onTap) {
    final accent = const Color(0xFF06B6D4);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: active ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: active ? Colors.transparent : Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: active ? Colors.white : Colors.black87, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

  void _showChangeNumberDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final ctrl = TextEditingController(text: _parentNumber);
        return AlertDialog(
          title: const Text('Change parent number'),
          content: TextField(controller: ctrl, keyboardType: TextInputType.phone),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _parentNumber = ctrl.text;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
