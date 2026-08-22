import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_map/map_kit/map_kit.dart';

import '../models/campus_place_model.dart';
import '../services/campus_map_editor_service.dart';
import '../services/college_service.dart';
import '../theme/app_theme.dart';
import 'college_setup_screen.dart';
import 'student_dashboard.dart';

enum _MapEditMode { view, drawBorder, addPlace }

/// Admin tool: straight-line campus border, places, and GPS-precise pins.
///
/// When [confirmMode] is true (student onboarding), a Confirm map action
/// finishes setup and opens the student dashboard.
class CustomisableMapScreen extends StatefulWidget {
  const CustomisableMapScreen({super.key, this.confirmMode = false});

  final bool confirmMode;

  @override
  State<CustomisableMapScreen> createState() => _CustomisableMapScreenState();
}

class _CustomisableMapScreenState extends State<CustomisableMapScreen> {
  static const _placeCategories = [
    'Canteen',
    'Library',
    'Hostel',
    'Lab',
    'Gate',
    'Parking',
    'Other',
  ];

  final _editor = CampusMapEditorService.instance;
  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();

  TeamMapController? _map;
  _MapEditMode _mode = _MapEditMode.view;
  String _selectedCategory = _placeCategories.first;
  String? _namingPlaceId;
  var _painting = false;
  var _repaintQueued = false;
  var _dropping = false;

  bool get _isEditing =>
      _mode == _MapEditMode.drawBorder || _mode == _MapEditMode.addPlace;

  bool get _isNaming => _namingPlaceId != null;

  CampusPlaceModel? get _namingPlace {
    final id = _namingPlaceId;
    if (id == null) return null;
    for (final place in _editor.places) {
      if (place.id == id) return place;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _editor.addListener(_onEditorChanged);
  }

  @override
  void dispose() {
    _editor.removeListener(_onEditorChanged);
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _onEditorChanged() {
    _paintMap();
    if (mounted) setState(() {});
  }

  void _setMode(_MapEditMode mode) {
    setState(() => _mode = mode);
    _paintMap();
  }

  // ── Map painting ───────────────────────────────────────────────────────

  /// Repaints the map, coalescing overlapping calls.
  ///
  /// A call arriving mid-paint queues a follow-up instead of being dropped, so
  /// the newest state always reaches the map.
  Future<void> _paintMap() async {
    if (_map == null) return;
    if (_painting) {
      _repaintQueued = true;
      return;
    }
    _painting = true;
    try {
      do {
        _repaintQueued = false;
        await _drawOnce();
      } while (_repaintQueued && mounted && _map != null);
    } finally {
      _painting = false;
    }
  }

  /// Runs one map operation, swallowing failures so a single bad call can't
  /// abort the rest of the redraw.
  Future<void> _guard(Future<void> Function() op) async {
    try {
      await op();
    } catch (error) {
      debugPrint('Customisable map draw step skipped: $error');
    }
  }

  Future<void> _drawOnce() async {
    final map = _map;
    if (map == null) return;

    await _guard(map.clearMarkers);
    await _guard(() => map.removePolyline('custom_border'));
    await _guard(() => map.removePolyline('custom_border_stroke'));
    await _guard(() => map.removePolygon('custom_border'));
    await _guard(() => map.removePolygon('campus_boundary'));
    await _guard(() => map.removePolyline('campus_boundary_stroke'));

    final college = CollegeService.instance.selectedCollege;
    final custom = _editor.borderPoints;

    // Places first so a later failure can never starve them.
    for (final place in _editor.places) {
      await _guard(
        () => map.addMarker(
          MapMarkerData(
            id: place.id,
            position: place.position,
            title: place.name,
            snippet: place.category,
            iconColor: '#7C3AED',
            iconSize: 1.6,
          ),
        ),
      );
    }

    // Keep the automatic OSM campus outline on screen even while the admin
    // is tracing a custom border over it.
    if (college != null &&
        college.hasBoundary &&
        college.boundary!.length >= 3) {
      await _guard(
        () => map.showCampusBoundary(
          outline: college.boundary!,
          fillOpacity: 0.08,
          strokeWidth: 2.4,
        ),
      );
    }

    if (custom.length >= 2) {
      final points = List<LatLng>.from(custom);
      final closed = _editor.borderClosed && points.length >= 3;
      if (closed) points.add(points.first);

      if (closed) {
        await _guard(
          () => map.showCampusBoundary(
            id: 'custom_border',
            outline: points,
            fillColor: '#2563EB',
            fillOpacity: 0.12,
            strokeColor: '#1D4ED8',
            strokeWidth: 3.2,
          ),
        );
      } else {
        await _guard(
          () => map.addPolyline(
            id: 'custom_border',
            points: points,
            color: '#1D4ED8',
            width: 3.2,
          ),
        );
      }
    }

    for (var i = 0; i < custom.length; i++) {
      await _guard(
        () => map.addMarker(
          MapMarkerData(
            id: 'border_v_$i',
            position: custom[i],
            iconColor: '#1D4ED8',
            iconSize: 0.55,
          ),
        ),
      );
    }
  }

  // ── Editing actions ────────────────────────────────────────────────────

  Future<void> _onMapTap(LatLng position) async {
    if (_isNaming) return;
    if (_mode == _MapEditMode.drawBorder) {
      _addBorderCorner(position);
    } else if (_mode == _MapEditMode.addPlace) {
      _savePlace(position, fromGps: false);
    }
  }

  void _addBorderCorner(LatLng position) {
    if (_editor.borderClosed) {
      _showSnack('Border closed. Tap Clear to redraw.');
      return;
    }
    _editor.addBorderVertex(position);
    _showSnack('Corner ${_editor.borderPoints.length} added', short: true);
  }

  /// Saves the pin first, then opens the inline label editor.
  ///
  /// Saving before any UI appears means the pin survives even if the map
  /// surface is rebuilt underneath us.
  void _savePlace(LatLng position, {required bool fromGps}) {
    final place = CampusPlaceModel(
      id: 'place-${DateTime.now().microsecondsSinceEpoch}',
      name: '',
      category: _selectedCategory,
      position: position,
      fromGps: fromGps,
    );
    _editor.addPlace(place);
    _beginNaming(place);
  }

  void _beginNaming(CampusPlaceModel place) {
    _nameController.clear();
    setState(() => _namingPlaceId = place.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nameFocus.requestFocus();
    });
  }

  void _commitName() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack('Type a name first');
      return;
    }
    final place = _namingPlace;
    if (place != null) {
      _editor.renamePlace(place.id, name);
    }
    _endNaming();
    _showSnack('$name saved', short: true);
  }

  void _endNaming() {
    _nameFocus.unfocus();
    setState(() => _namingPlaceId = null);
  }

  void _deleteNamingPlace() {
    final place = _namingPlace;
    _endNaming();
    if (place != null) {
      _editor.removePlace(place.id);
      _showSnack('Pin removed', short: true);
    }
  }

  Future<void> _dropAtCenter() async {
    final map = _map;
    if (map == null || _dropping) return;
    setState(() => _dropping = true);
    try {
      final position = map.cameraCenter;
      if (_mode == _MapEditMode.drawBorder) {
        _addBorderCorner(position);
      } else if (_mode == _MapEditMode.addPlace) {
        _savePlace(position, fromGps: false);
      }
    } finally {
      if (mounted) setState(() => _dropping = false);
    }
  }

  void _showSnack(String msg, {bool short = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: short ? 900 : 2200),
      ),
    );
  }

  Future<void> _openPlacesSheet() async {
    final toRename = await showModalBottomSheet<CampusPlaceModel>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return ListenableBuilder(
          listenable: _editor,
          builder: (context, _) {
            final places = _editor.places;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved places (${places.length})',
                      style: GoogleFonts.figtree(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.adminInk,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (places.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'No places yet. Pick a type, aim the crosshair, then Pin.',
                          style: GoogleFonts.figtree(
                            color: AppTheme.adminInkMuted,
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: places.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final place = places[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.place_outlined,
                                color: AppTheme.purple,
                              ),
                              title: Text(
                                place.name,
                                style: GoogleFonts.figtree(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '${place.category} · '
                                '${place.position.latitude.toStringAsFixed(4)}, '
                                '${place.position.longitude.toStringAsFixed(4)}',
                                style: GoogleFonts.figtree(fontSize: 11),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Rename',
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(sheetContext, place),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete',
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        _editor.removePlace(place.id),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                _map?.flyTo(place.position, zoom: 18.5);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (toRename != null && mounted) {
      _beginNaming(toRename);
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final college = CollegeService.instance.selectedCollege;

    if (college == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customisable Map')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Select a college first, then customize its map.',
              textAlign: TextAlign.center,
              style: GoogleFonts.figtree(color: AppTheme.adminInkMuted),
            ),
          ),
        ),
      );
    }

    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return PopScope(
      canPop: !widget.confirmMode,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !widget.confirmMode) return;
        _onStudentBack();
      },
      child: Scaffold(
      // Keep the map from being relaid out when the keyboard opens; the label
      // editor lifts itself above the keyboard instead.
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          TeamMap(
            config: MapConfig(
              initialCenter: college.position,
              initialZoom: 18,
              myLocationEnabled: true,
              enable3dOnStart: false,
            ),
            onReady: (controller) async {
              // Also fires after a style reload, so repaint from our state.
              _map = controller;
              controller.onMapTapped = _onMapTap;
              controller.onMapLongPressed = _onMapTap;
              await _guard(
                () => controller.flyTo(college.position, zoom: 18),
              );
              await _guard(controller.hideBasemapPlaceLabels);
              await _paintMap();
            },
          ),

          if (_isEditing && !_isNaming)
            const IgnorePointer(child: Center(child: _Crosshair())),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 8),
                    _buildModeRow(),
                    if (!_isNaming && _mode != _MapEditMode.view) ...[
                      const SizedBox(height: 8),
                      _buildToolPanel(),
                    ],
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: 14,
            right: 14,
            bottom: 16 + keyboardInset,
            child: SafeArea(
              top: false,
              child: _isNaming ? _buildNamingPanel() : _buildActionRow(),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildActionRow() {
    final dropFab = _isEditing
        ? FloatingActionButton.extended(
            heroTag: 'drop_fab',
            onPressed: _dropping ? null : _dropAtCenter,
            backgroundColor: _mode == _MapEditMode.drawBorder
                ? AppTheme.blue
                : AppTheme.teal,
            foregroundColor: Colors.white,
            icon: _dropping
                ? const _MiniSpinner()
                : Icon(
                    _mode == _MapEditMode.drawBorder
                        ? Icons.add_location_alt_outlined
                        : Icons.place_outlined,
                  ),
            label: Text(
              _mode == _MapEditMode.drawBorder
                  ? 'Drop corner here'
                  : 'Pin location here',
            ),
          )
        : null;

    if (!widget.confirmMode) {
      return dropFab ?? const SizedBox.shrink();
    }

    // Student onboarding: always show Finish so they never need the back arrow.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (dropFab != null) ...[
          Align(alignment: Alignment.centerRight, child: dropFab),
          const SizedBox(height: 10),
        ],
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: _confirmStudentMap,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.pinkSoft,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.check_circle_outline),
            label: Text(
              'Finish & go to dashboard',
              style: GoogleFonts.figtree(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  void _onStudentBack() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const CollegeSetupScreen(forStudent: true),
      ),
    );
  }

  void _confirmStudentMap() {
    // Auto-close a drawn border so Finish always completes setup.
    if (_editor.borderPoints.length >= 3) {
      _editor.confirmStudentMap();
    } else {
      _editor.finishStudentSetupWithoutBorder();
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const StudentDashboardScreen(),
      ),
      (_) => false,
    );
  }

  /// Inline label editor.
  ///
  /// Deliberately not a dialog — an overlay route over the map surface is what
  /// caused the black screen and lost input on Android.
  Widget _buildNamingPanel() {
    final place = _namingPlace;
    if (place == null) return const SizedBox.shrink();

    return _Panel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.place,
                size: 18,
                color: AppTheme.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Name this ${place.category}',
                  style: GoogleFonts.figtree(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.adminInk,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove this pin',
                onPressed: _deleteNamingPlace,
                icon: const Icon(Icons.delete_outline, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _nameController,
            focusNode: _nameFocus,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Location name',
              hintText: 'Type a name',
            ),
            onSubmitted: (_) => _commitName(),
          ),
          const SizedBox(height: 6),
          Text(
            'Saved at ${place.position.latitude.toStringAsFixed(5)}, '
            '${place.position.longitude.toStringAsFixed(5)}',
            style: GoogleFonts.figtree(
              fontSize: 11,
              color: AppTheme.adminInkMuted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (place.name.isEmpty) {
                      _deleteNamingPlace();
                    } else {
                      _endNaming();
                    }
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _commitName,
                  child: const Text('Save name'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return _Panel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.confirmMode
                ? _onStudentBack
                : () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            iconSize: 20,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.confirmMode
                      ? 'Confirm campus map'
                      : 'Customisable Map',
                  style: GoogleFonts.figtree(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.adminInk,
                  ),
                ),
                if (widget.confirmMode && !_isEditing && !_isNaming)
                  Text(
                    'Close the border, then tap Finish below',
                    style: GoogleFonts.figtree(
                      fontSize: 11,
                      color: AppTheme.adminInkMuted,
                    ),
                  )
                else if (_isEditing && !_isNaming)
                  Text(
                    _mode == _MapEditMode.drawBorder
                        ? 'Aim the + at a corner, then Drop'
                        : 'Aim the + at the place, then Pin',
                    style: GoogleFonts.figtree(
                      fontSize: 11,
                      color: AppTheme.adminInkMuted,
                    ),
                  ),
              ],
            ),
          ),
          ListenableBuilder(
            listenable: _editor,
            builder: (_, __) => IconButton(
              tooltip: 'Saved places',
              onPressed: _openPlacesSheet,
              iconSize: 20,
              icon: Badge.count(
                count: _editor.places.length,
                isLabelVisible: _editor.places.isNotEmpty,
                child: const Icon(Icons.list_alt_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ModeChip(
          label: 'View',
          selected: _mode == _MapEditMode.view,
          onTap: () => _setMode(_MapEditMode.view),
        ),
        _ModeChip(
          label: 'Draw border',
          selected: _mode == _MapEditMode.drawBorder,
          onTap: () => _setMode(_MapEditMode.drawBorder),
        ),
        _ModeChip(
          label: 'Add place',
          selected: _mode == _MapEditMode.addPlace,
          onTap: () => _setMode(_MapEditMode.addPlace),
        ),
      ],
    );
  }

  Widget _buildToolPanel() {
    return _Panel(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _modeHint,
            style: GoogleFonts.figtree(
              fontSize: 12,
              color: AppTheme.adminInkMuted,
            ),
          ),
          if (_mode == _MapEditMode.drawBorder) ...[
            const SizedBox(height: 8),
            Text(
              'Points: ${_editor.borderPoints.length}'
              '${_editor.borderClosed ? ' (closed)' : ''}',
              style: GoogleFonts.figtree(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.blue,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                _SmallButton(
                  label: 'Undo',
                  onPressed: _editor.borderPoints.isEmpty
                      ? null
                      : _editor.undoBorderVertex,
                ),
                _SmallButton(
                  label: 'Close shape',
                  onPressed: _editor.borderPoints.length < 3
                      ? null
                      : _editor.closeBorder,
                ),
                _SmallButton(
                  label: 'Clear',
                  onPressed: _editor.borderPoints.isEmpty
                      ? null
                      : _editor.clearBorder,
                ),
              ],
            ),
          ],
          if (_mode == _MapEditMode.addPlace) ...[
            const SizedBox(height: 8),
            Text(
              'Pick type, aim the +, then Pin',
              style: GoogleFonts.figtree(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.tealDeep,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _placeCategories.map((category) {
                final selected = category == _selectedCategory;
                return ChoiceChip(
                  label: Text(category),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _selectedCategory = category),
                  selectedColor: AppTheme.teal.withValues(alpha: 0.2),
                  visualDensity: VisualDensity.compact,
                  labelStyle: GoogleFonts.figtree(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppTheme.teal : AppTheme.adminInk,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String get _modeHint {
    switch (_mode) {
      case _MapEditMode.view:
        return 'Choose Draw border or Add place to edit the campus map.';
      case _MapEditMode.drawBorder:
        return 'Move the map so + sits on a corner, then Drop. Lines stay straight.';
      case _MapEditMode.addPlace:
        return 'Choose Canteen/Library/…, aim +, then Pin and type the label.';
    }
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

class _MiniSpinner extends StatelessWidget {
  const _MiniSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
  }
}

class _Crosshair extends StatelessWidget {
  const _Crosshair();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 44,
            height: 2,
            color: AppTheme.blue.withValues(alpha: 0.85),
          ),
          Container(
            width: 2,
            height: 44,
            color: AppTheme.blue.withValues(alpha: 0.85),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.blue, width: 2.5),
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.white,
      selectedColor: AppTheme.blue.withValues(alpha: 0.2),
      visualDensity: VisualDensity.compact,
      labelStyle: GoogleFonts.figtree(
        fontWeight: FontWeight.w700,
        color: selected ? AppTheme.blue : AppTheme.adminInk,
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: GoogleFonts.figtree(fontSize: 12),
        ),
        child: Text(label),
      ),
    );
  }
}
