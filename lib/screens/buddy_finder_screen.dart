import 'package:flutter/material.dart';

class BuddyFinderScreen extends StatefulWidget {
  const BuddyFinderScreen({Key? key}) : super(key: key);

  @override
  State<BuddyFinderScreen> createState() => _BuddyFinderScreenState();
}

class _BuddyFinderScreenState extends State<BuddyFinderScreen> {
  bool _isDark = false;
  bool _isSearching = false;
  bool _showResults = false;
  final TextEditingController _destinationController = TextEditingController();

  final List<Map<String, dynamic>> _students = [
    {
      'name': 'Priya N.',
      'initial': 'P',
      'department': 'B.Tech CSE - Yr 3',
      'location': 'Currently at Hostel B',
      'rating': '4.9',
      'requested': false,
    },
    {
      'name': 'Sana M.',
      'initial': 'S',
      'department': 'B.Des Media - Yr 2',
      'location': 'Currently at Library',
      'rating': '4.7',
      'requested': false,
    },
    {
      'name': 'Tanya R.',
      'initial': 'T',
      'department': 'B.Sc Bio - Yr 1',
      'location': 'Currently at Main Gate',
      'rating': '4.8',
      'requested': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bg = _isDark ? const Color(0xFF101828) : const Color(0xFFF9F5FF);
    final surface = _isDark ? const Color(0xFF131B2E) : Colors.white;
    final textColor = _isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedText = _isDark ? Colors.white70 : const Color(0xFF64748B);
    final accent = const Color(0xFF7C3AED);
    final actionGradient = const LinearGradient(
      colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Theme(
      data: ThemeData(
        brightness: _isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: bg,
        primaryColor: accent,
        textTheme: Theme.of(context).textTheme.apply(bodyColor: textColor, displayColor: textColor),
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: textColor),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => setState(() => _isDark = !_isDark),
                      icon: Icon(_isDark ? Icons.wb_sunny : Icons.nights_stay, color: textColor),
                      tooltip: 'Toggle theme',
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: accent.withOpacity(0.18),
                      child: Text('AM', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _isDark ? const Color(0xFF3F3A57) : const Color(0xFFF6E7F8),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('✨ Feeling alone or uncomfortable?',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                )),
                            const SizedBox(height: 12),
                            Text(
                              'Enter your campus destination to find and pair up with verified students who are currently there so you can walk or stay together.',
                              style: TextStyle(fontSize: 14, height: 1.5, color: mutedText),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(_isDark ? 0.18 : 0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('WHERE ARE YOU HEADING?',
                                style: TextStyle(
                                  fontSize: 13,
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                )),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _destinationController,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.location_on_outlined, color: accent),
                                hintText: 'e.g. Hostel B, Main Gate, Library',
                                filled: true,
                                fillColor: _isDark ? const Color(0xFF111827) : const Color(0xFFF7F0FF),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: _handleSearchPressed,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                  decoration: BoxDecoration(
                                    gradient: actionGradient,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.search, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isSearching ? 'Searching...' : 'Find',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      if (_isSearching) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                          decoration: BoxDecoration(
                            color: _isDark ? const Color(0xFF161E36) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _isDark ? Colors.white12 : const Color(0xFFE9E8F3)),
                          ),
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                color: accent,
                                strokeWidth: 4,
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Scanning nearby verified students... Within 100 m radius',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: mutedText, height: 1.5, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_showResults && !_isSearching) ...[
                        Text('3 STUDENTS CURRENTLY THERE',
                            style: TextStyle(fontSize: 14, color: accent, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 14),
                        ..._students.map((student) => _buildStudentCard(student, surface, textColor, mutedText, accent)).toList(),
                      ],
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

  Widget _buildStudentCard(Map<String, dynamic> student, Color surface, Color textColor, Color mutedText, Color accent) {
    final requested = student['requested'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.14 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFFFE4EE),
                child: Text(
                  student['initial'],
                  style: const TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w700, fontSize: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(student['name'], style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6FFFA),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text('🛡️ ID verified', style: TextStyle(color: Color(0xFF047857), fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(student['department'], style: TextStyle(color: mutedText, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('${student['location']} • ⭐ ${student['rating']}', style: TextStyle(color: mutedText, fontSize: 13, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: requested ? null : () => _requestPair(student),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: requested
                        ? null
                        : const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9333EA)]),
                    color: requested ? const Color(0xFFCBD5E1) : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    requested ? 'Requested' : '+ Pair up',
                    style: TextStyle(
                      color: requested ? const Color(0xFF475569) : Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (requested) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _isDark ? const Color(0xFF1F2937) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Text(
                "Waiting for ${student['name']} to accept. We'll share live location with both of you once paired.",
                style: TextStyle(color: mutedText, height: 1.5, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleSearchPressed() {
    if (_isSearching) return;
    setState(() {
      _isSearching = true;
      _showResults = false;
      for (var student in _students) {
        student['requested'] = false;
      }
    });

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _showResults = true;
      });
    });
  }

  void _requestPair(Map<String, dynamic> student) {
    setState(() {
      student['requested'] = true;
    });
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✔️ Request sent to ${student['name']}'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: Colors.black87,
      ),
    );
  }
}
