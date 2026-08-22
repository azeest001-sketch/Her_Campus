import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/floor_calibration_model.dart';
import '../services/floor_calibration_service.dart';
import '../theme/app_theme.dart';
import '../widgets/campus_backdrop.dart';

/// Admin mockup: define buildings/floors and capture pressure references.
class FloorCalibrationScreen extends StatefulWidget {
  const FloorCalibrationScreen({super.key});

  @override
  State<FloorCalibrationScreen> createState() => _FloorCalibrationScreenState();
}

class _FloorCalibrationScreenState extends State<FloorCalibrationScreen> {
  final _service = FloorCalibrationService.instance;
  final _buildingName = TextEditingController();
  var _floorCount = 3;
  String? _calibratingFloorId;

  @override
  void dispose() {
    _buildingName.dispose();
    super.dispose();
  }

  Future<void> _addBuilding() async {
    final name = _buildingName.text.trim();
    if (name.isEmpty) {
      _snack('Enter a building name');
      return;
    }
    _service.addBuilding(name, floorCount: _floorCount);
    _buildingName.clear();
    _snack('Building added — calibrate each floor next');
  }

  Future<void> _calibrate(BuildingCalibrationModel building, FloorLevelModel floor) async {
    setState(() => _calibratingFloorId = floor.id);
    try {
      await _service.calibrateFloor(building.id, floor.id);
      if (!mounted) return;
      _snack(
        '${floor.label} calibrated (mock barometer). Stand on that floor in the real app.',
      );
    } finally {
      if (mounted) setState(() => _calibratingFloorId = null);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CampusBackdrop(
        tone: CampusBackdropTone.admin,
        roleTint: AppTheme.blueSoft,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text(
                      'Floor Calibration',
                      style: GoogleFonts.figtree(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.adminInk,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'GPS can’t tell floors apart indoors. Capture a pressure reading on each floor so the app can estimate which level a student is on.',
                style: GoogleFonts.figtree(
                  fontSize: 13,
                  color: AppTheme.adminInkMuted,
                ),
              ),
              const SizedBox(height: 14),
              ListenableBuilder(
                listenable: _service,
                builder: (_, __) {
                  return Row(
                    children: [
                      _StatPill(
                        label: 'Buildings',
                        value: '${_service.buildings.length}',
                      ),
                      const SizedBox(width: 8),
                      _StatPill(
                        label: 'Ready',
                        value: '${_service.readyBuildingCount}',
                        accent: AppTheme.tealDeep,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              GlassPanel(
                borderRadius: 20,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add building',
                      style: GoogleFonts.figtree(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.adminInk,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _buildingName,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Science Block',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addBuilding(),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Floors to create: $_floorCount',
                      style: GoogleFonts.figtree(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.adminInkMuted,
                      ),
                    ),
                    Slider(
                      value: _floorCount.toDouble(),
                      min: 2,
                      max: 8,
                      divisions: 6,
                      label: '$_floorCount',
                      onChanged: (v) =>
                          setState(() => _floorCount = v.round()),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _addBuilding,
                        icon: const Icon(Icons.add_business_rounded, size: 18),
                        label: const Text('Add building'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Campus buildings',
                style: GoogleFonts.figtree(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.adminInk,
                ),
              ),
              const SizedBox(height: 8),
              ListenableBuilder(
                listenable: _service,
                builder: (context, _) {
                  final buildings = _service.buildings;
                  if (buildings.isEmpty) {
                    return GlassPanel(
                      borderRadius: 18,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No buildings yet. Add one above, then calibrate each floor.',
                        style: GoogleFonts.figtree(
                          color: AppTheme.adminInkMuted,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      for (final building in buildings)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _BuildingCard(
                            building: building,
                            calibratingFloorId: _calibratingFloorId,
                            onCalibrate: (floor) =>
                                _calibrate(building, floor),
                            onClear: (floor) => _service
                                .clearFloorCalibration(building.id, floor.id),
                            onAddFloor: () => _promptAddFloor(building),
                            onRemove: () =>
                                _service.removeBuilding(building.id),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Demo only — real barometer readings need device sensors + backend.',
                style: GoogleFonts.figtree(
                  fontSize: 11,
                  color: AppTheme.adminInkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _promptAddFloor(BuildingCalibrationModel building) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add floor',
          style: GoogleFonts.figtree(fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Floor label',
            hintText: 'e.g. Basement / Floor 3',
          ),
          onSubmitted: (_) => Navigator.pop(context, true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (ok == true) {
      _service.addFloor(building.id, controller.text);
    }
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    this.accent,
  });

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppTheme.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.figtree(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.figtree(
              fontSize: 12,
              color: AppTheme.adminInkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildingCard extends StatelessWidget {
  const _BuildingCard({
    required this.building,
    required this.calibratingFloorId,
    required this.onCalibrate,
    required this.onClear,
    required this.onAddFloor,
    required this.onRemove,
  });

  final BuildingCalibrationModel building;
  final String? calibratingFloorId;
  final void Function(FloorLevelModel floor) onCalibrate;
  final void Function(FloorLevelModel floor) onClear;
  final VoidCallback onAddFloor;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: 18,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.apartment_rounded,
                color: building.isReady ? AppTheme.tealDeep : AppTheme.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      building.name,
                      style: GoogleFonts.figtree(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.adminInk,
                      ),
                    ),
                    Text(
                      '${building.calibratedCount}/${building.floors.length} floors calibrated'
                      '${building.isReady ? ' · Ready' : ''}',
                      style: GoogleFonts.figtree(
                        fontSize: 12,
                        color: building.isReady
                            ? AppTheme.tealDeep
                            : AppTheme.adminInkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove building',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final floor in building.floors)
            _FloorRow(
              floor: floor,
              busy: calibratingFloorId == floor.id,
              onCalibrate: () => onCalibrate(floor),
              onClear: () => onClear(floor),
            ),
          TextButton.icon(
            onPressed: onAddFloor,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add floor'),
          ),
        ],
      ),
    );
  }
}

class _FloorRow extends StatelessWidget {
  const _FloorRow({
    required this.floor,
    required this.busy,
    required this.onCalibrate,
    required this.onClear,
  });

  final FloorLevelModel floor;
  final bool busy;
  final VoidCallback onCalibrate;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        ),
        child: Row(
          children: [
            Icon(
              floor.isCalibrated
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              size: 18,
              color: floor.isCalibrated ? AppTheme.tealDeep : AppTheme.adminInkMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    floor.label,
                    style: GoogleFonts.figtree(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    floor.isCalibrated
                        ? '${floor.pressureHpa!.toStringAsFixed(1)} hPa'
                        : 'Not calibrated',
                    style: GoogleFonts.figtree(
                      fontSize: 11,
                      color: AppTheme.adminInkMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (busy)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (floor.isCalibrated)
              TextButton(
                onPressed: onClear,
                child: const Text('Reset'),
              )
            else
              TextButton(
                onPressed: onCalibrate,
                child: const Text('Calibrate'),
              ),
          ],
        ),
      ),
    );
  }
}
