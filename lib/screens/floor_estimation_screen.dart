import 'package:flutter/material.dart';

class FloorEstimationScreen extends StatefulWidget {
  const FloorEstimationScreen({Key? key}) : super(key: key);

  @override
  State<FloorEstimationScreen> createState() => _FloorEstimationScreenState();
}

class _FloorEstimationScreenState extends State<FloorEstimationScreen> {
  bool _isDark = false;

  @override
  Widget build(BuildContext context) {
    final bg = _isDark ? const Color(0xFF0F1720) : const Color(0xFFF6F7FB);
    final headerColor = _isDark ? Colors.white : Colors.black87;

    return Theme(
      data: ThemeData(brightness: _isDark ? Brightness.dark : Brightness.light, scaffoldBackgroundColor: bg),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => setState(() => _isDark = !_isDark),
                          icon: Icon(_isDark ? Icons.wb_sunny : Icons.nights_stay, color: headerColor),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {},
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: _isDark ? Colors.white24 : Colors.grey[200],
                            child: const Text('AM'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Automatic Floor Estimation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: headerColor)),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: _isDark ? const Color(0xFF0B1220) : const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _isDark
                        ? [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 8))]
                        : [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 6))],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CURRENT LOCATION DETECTED', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 6),
                      Text('Block C • Floor 3rd', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      Row(
                        children: const [
                          Text('• High Precision Altimeter Active ·', style: TextStyle(fontSize: 13, color: Colors.black54)),
                        ],
                      ),
                      const Spacer(),
                      // Placeholder for telemetry visualization
                      Container(
                        height: 64,
                        decoration: BoxDecoration(
                          color: _isDark ? Colors.white10 : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text('Telemetry placeholder', style: TextStyle(color: Colors.grey))),
                      )
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
