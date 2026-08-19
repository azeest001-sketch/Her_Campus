import 'package:flutter/material.dart';

class PeerEscortScreen extends StatefulWidget {
  const PeerEscortScreen({Key? key}) : super(key: key);

  @override
  State<PeerEscortScreen> createState() => _PeerEscortScreenState();
}

class _PeerEscortScreenState extends State<PeerEscortScreen> {
  bool _isDark = false;
  int _currentStep = 1;

  final List<String> _stepTitles = [
    'Request',
    'Matched',
    'Verify',
    'Walking',
    'Safe',
  ];

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _isDark ? Colors.grey.shade900 : Colors.black87,
      ),
    );
  }

  void _advanceStep() {
    setState(() {
      if (_currentStep < 5) {
        _currentStep += 1;
      } else {
        _currentStep = 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final background = _isDark ? const Color(0xFF0F1720) : const Color(0xFFF4F2FF);
    final surface = _isDark ? const Color(0xFF111827) : Colors.white;
    final textPrimary = _isDark ? Colors.white : const Color(0xFF101828);
    final textSecondary = _isDark ? Colors.white70 : const Color(0xFF6B7280);
    final purpleSoft = const Color(0xFFE9D5FF);
    final purpleAccent = const Color(0xFF7C3AED);

    return Theme(
      data: ThemeData(
        brightness: _isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: background,
        primaryColor: purpleAccent,
        textTheme: Theme.of(context).textTheme.apply(bodyColor: textPrimary, displayColor: textPrimary),
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isDark ? const Color(0xFF1F2937) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(Icons.arrow_back, color: textPrimary),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _isDark = !_isDark),
                      child: Icon(
                        _isDark ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
                        color: textPrimary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: purpleAccent.withOpacity(0.16),
                      child: Text('AM', style: TextStyle(color: purpleAccent, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: Column(
                  children: [
                    _buildStepper(purpleAccent, textPrimary, textSecondary),
                    const SizedBox(height: 22),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  child: Column(
                    children: [
                      _buildCurrentStepCard(surface, purpleAccent, purpleSoft, textPrimary, textSecondary),
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

  Widget _buildStepper(Color activeColor, Color textPrimary, Color textSecondary) {
    return Column(
      children: [
        Row(
          children: List.generate(_stepTitles.length * 2 - 1, (index) {
            if (index.isEven) {
              final step = index ~/ 2 + 1;
              final isActive = _currentStep >= step;
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isActive ? activeColor : Colors.transparent,
                        border: Border.all(
                          color: isActive ? activeColor : const Color(0xFFCBD5E1),
                          width: 1.6,
                        ),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$step',
                        style: TextStyle(
                          color: isActive ? Colors.white : textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _stepTitles[step - 1],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive ? textPrimary : textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Expanded(
              child: Container(
                height: 2,
                color: _currentStep > (index ~/ 2 + 1) ? activeColor : const Color(0xFFD1D5DB),
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCurrentStepCard(Color surface, Color purpleAccent, Color purpleSoft, Color textPrimary, Color textSecondary) {
    switch (_currentStep) {
      case 2:
        return _buildMatchedStep(surface, purpleAccent, textPrimary, textSecondary);
      case 3:
        return _buildVerifyStep(surface, purpleAccent, textPrimary, textSecondary);
      case 4:
        return _buildWalkingStep(surface, textPrimary, textSecondary);
      case 5:
        return _buildSafeStep(surface, purpleAccent, textPrimary, textSecondary);
      default:
        return _buildRequestStep(surface, purpleAccent, purpleSoft, textPrimary, textSecondary);
    }
  }

  Widget _buildRequestStep(Color surface, Color purpleAccent, Color purpleSoft, Color textPrimary, Color textSecondary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Request an escort', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary)),
          const SizedBox(height: 12),
          Text(
            'Nearest verified seniors will be notified. Average match time: 2 min.',
            style: TextStyle(fontSize: 15, height: 1.6, color: textSecondary),
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: purpleSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: purpleAccent.withOpacity(0.16),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(Icons.shield, color: purpleAccent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Verified seniors are standing by to walk with you safely across campus.',
                    style: TextStyle(color: textSecondary, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () {
              setState(() => _currentStep = 2);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [purpleAccent, const Color(0xFF9333EA)]),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: const Text('Find a peer escort', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchedStep(Color surface, Color purpleAccent, Color textPrimary, Color textSecondary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: purpleAccent.withOpacity(0.18),
                child: Text('S', style: TextStyle(color: purpleAccent, fontWeight: FontWeight.w700, fontSize: 24)),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sneha Rao', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFFD05B), size: 18),
                      const SizedBox(width: 6),
                      Text('4.9', style: TextStyle(color: textSecondary, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F9F6),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Distance: 2 min away · 180 m', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(
                  'Sneha is a verified 3rd year peer escort. Please meet near the North Campus gate and present your verification QR code.',
                  style: TextStyle(color: textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () {
              _showMessage('✔️ Sneha (3rd yr) accepted your request');
              setState(() => _currentStep = 3);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: purpleAccent,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.qr_code, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('Open QR Scanner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyStep(Color surface, Color purpleAccent, Color textPrimary, Color textSecondary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Scan escort QR', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary)),
          const SizedBox(height: 14),
          Text(
            'Hold your phone steady and scan the QR code presented by your escort to begin the walk.',
            style: TextStyle(color: textSecondary, height: 1.5),
          ),
          const SizedBox(height: 26),
          Container(
            width: double.infinity,
            height: 280,
            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF111827) : const Color(0xFFF8F7FF),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF9CA3AF), width: 1.5, style: BorderStyle.solid),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner, size: 48, color: purpleAccent.withOpacity(0.9)),
                  const SizedBox(height: 14),
                  Text(
                    'Scanner view placeholder',
                    style: TextStyle(color: textSecondary, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () {
              setState(() => _currentStep = 4);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [purpleAccent, const Color(0xFF9333EA)]),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: const Text('Simulate scan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalkingStep(Color surface, Color textPrimary, Color textSecondary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F3EA),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, color: Color(0xFF16A34A), size: 14),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Walk in progress with Sneha · live tracked',
                    style: TextStyle(color: const Color(0xFF166534), fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Keep moving safely toward your destination. Your escort will stay beside you until you confirm arrival.',
              style: TextStyle(color: textSecondary, height: 1.6)),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildInfoChip(Icons.timer, 'Estimated 6 min'),
              const SizedBox(width: 12),
              _buildInfoChip(Icons.location_on, 'Live campus route'),
            ],
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () {
              _showMessage('✔️ Escort verified — walk started');
              setState(() => _currentStep = 5);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: const Text('Arrived Safely', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _isDark ? const Color(0xFF111827) : const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _isDark ? Colors.white70 : const Color(0xFF6D28D9)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: TextStyle(color: _isDark ? Colors.white70 : const Color(0xFF4B5563), fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafeStep(Color surface, Color purpleAccent, Color textPrimary, Color textSecondary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: purpleAccent.withOpacity(0.16),
            ),
            child: const Center(
              child: Icon(Icons.check, color: Color(0xFF7C3AED), size: 44),
            ),
          ),
          const SizedBox(height: 24),
          Text('You arrived safely', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textPrimary), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(
            'Your arrival has been confirmed with Sneha. A safety log has been added to your recent escort history.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textSecondary, height: 1.6),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () {
              _showMessage('✔️ Marked as arrived safely 🌸');
              setState(() => _currentStep = 1);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5E7FF),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Text('Request another escort', style: TextStyle(color: purpleAccent, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
