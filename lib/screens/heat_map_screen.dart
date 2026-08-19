import 'package:flutter/material.dart';

class HeatMapScreen extends StatefulWidget {
  const HeatMapScreen({Key? key}) : super(key: key);

  @override
  State<HeatMapScreen> createState() => _HeatMapScreenState();
}

class _HeatMapScreenState extends State<HeatMapScreen> {
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
                  child: Text('Heatwave Map', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: headerColor)),
                ),
              ),
              const SizedBox(height: 18),
              // Map placeholder
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  height: 360,
                  decoration: BoxDecoration(
                    color: _isDark ? const Color(0xFF0B1220) : const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _isDark
                        ? [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 8))]
                        : [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 6))],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.map, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('Map overlay placeholder', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Legend pill
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isDark ? const Color(0xFF0B1220) : const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: _isDark
                        ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)]
                        : [BoxShadow(color: Colors.black12, blurRadius: 8)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LegendItem(color: Colors.red, label: 'Crowded'),
                      const SizedBox(width: 12),
                      _LegendItem(color: Colors.yellow.shade700, label: 'Moderate'),
                      const SizedBox(width: 12),
                      _LegendItem(color: Colors.green, label: 'Uncrowded'),
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

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
