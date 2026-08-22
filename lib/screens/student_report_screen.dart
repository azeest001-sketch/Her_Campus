import 'package:flutter/material.dart';

class StudentReportScreen extends StatefulWidget {
  const StudentReportScreen({Key? key}) : super(key: key);

  @override
  State<StudentReportScreen> createState() => _StudentReportScreenState();
}

class _StudentReportScreenState extends State<StudentReportScreen> {
  bool _darkMode = false;
  bool _isVictim = true;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final background = _darkMode ? const Color(0xFF121316) : const Color(0xFFFFF8FB);
    final surface = _darkMode ? const Color(0xFF1C1C24) : Colors.white;
    final textPrimary = _darkMode ? Colors.white : const Color(0xFF111827);
    final textSecondary = _darkMode ? Colors.white70 : const Color(0xFF6B7280);
    final accent = const Color(0xFF9333EA);
    final accentGradientStart = const Color(0xFF8B5CF6);
    final accentGradientEnd = const Color(0xFFEC4899);
    final recordGradientStart = const Color(0xFF7C3AED);
    final recordGradientEnd = const Color(0xFFEC4899);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _darkMode ? const Color(0xFF2A2735) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: _darkMode
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                      ),
                      child: Icon(Icons.arrow_back, color: accent, size: 22),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _darkMode = !_darkMode),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _darkMode ? const Color(0xFF2A2735) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: _darkMode
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                      ),
                      child: Icon(
                        _darkMode ? Icons.wb_sunny : Icons.nights_stay,
                        color: accent,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(3),
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage('assets/avatar_placeholder.png'),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Student Report',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        )),
                    const SizedBox(height: 8),
                    Text('Share what happened anonymously with campus safety.',
                        style: TextStyle(color: textSecondary, height: 1.5)),
                    const SizedBox(height: 24),
                    Text('I AM REPORTING AS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                          letterSpacing: 1.2,
                        )),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isVictim = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _isVictim ? accent.withOpacity(0.12) : surface,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: _isVictim ? accent : const Color(0xFFE5E7EB),
                                  width: 1.2,
                                ),
                              ),
                              child: Center(
                                  child: Text('Victim',
                                      style: TextStyle(
                                        color: _isVictim ? accent : textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isVictim = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: !_isVictim ? accent.withOpacity(0.12) : surface,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: !_isVictim ? accent : const Color(0xFFE5E7EB),
                                  width: 1.2,
                                ),
                              ),
                              child: Center(
                                  child: Text('Witness',
                                      style: TextStyle(
                                        color: !_isVictim ? accent : textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ))),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('DESCRIBE WHAT HAPPENED',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                          letterSpacing: 1.2,
                        )),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: _darkMode ? const Color(0xFF23232D) : const Color(0xFFFDF4FB),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: _darkMode ? const Color(0xFF34343F) : const Color(0xFFEDE9FE),
                        ),
                      ),
                      child: TextField(
                        controller: _descriptionController,
                        maxLines: 8,
                        cursorColor: accent,
                        style: TextStyle(color: textPrimary, height: 1.5),
                        decoration: InputDecoration(
                          hintText: 'Where, when, what happened...',
                          hintStyle: TextStyle(color: textSecondary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [recordGradientStart, recordGradientEnd],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: recordGradientEnd.withOpacity(0.25),
                                  blurRadius: 30,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: const Icon(Icons.mic, size: 42, color: Color(0xFF7C3AED)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text('Tap to record audio (urgent)',
                              style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentGradientStart, accentGradientEnd],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: accentGradientEnd.withOpacity(0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {},
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.send, color: Colors.white),
                                SizedBox(width: 10),
                                Text('Send anonymously',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
