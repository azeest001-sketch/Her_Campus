import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_map/map_kit/map_kit.dart';

import '../models/college_model.dart';
import '../services/campus_map_editor_service.dart';
import '../services/college_service.dart';
import '../theme/app_theme.dart';
import '../widgets/campus_backdrop.dart';
import 'admin_dashboard.dart';
import 'customisable_map_screen.dart';

/// Admin mockup for choosing the college used by campus map features.
///
/// When [forStudent] is true, saving continues to student map confirmation
/// instead of the admin dashboard.
class CollegeSetupScreen extends StatefulWidget {
  const CollegeSetupScreen({super.key, this.forStudent = false});

  final bool forStudent;

  @override
  State<CollegeSetupScreen> createState() => _CollegeSetupScreenState();
}

class _CollegeSetupScreenState extends State<CollegeSetupScreen> {
  final _query = TextEditingController();
  final _placeSearch = PlaceSearch();
  Timer? _searchDebounce;
  Timer? _auto3dTimer;

  TeamMapController? _map;
  List<PlaceResult> _results = const [];
  CollegeModel? _selected;
  var _searching = false;
  var _saving = false;
  var _showMap = false;
  var _is3d = false;
  var _toggling3d = false;
  var _searchRequest = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = CollegeService.instance.selectedCollege;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _auto3dTimer?.cancel();
    _query.dispose();
    _placeSearch.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();

    if (query.length < 3) {
      setState(() {
        _results = const [];
        _error = null;
        _searching = false;
      });
      return;
    }

    // Nominatim asks clients not to send rapid requests. Waiting one second
    // gives useful predictions while respecting that limit.
    _searchDebounce = Timer(
      const Duration(milliseconds: 1000),
      () => _search(showEmptyError: false),
    );
  }

  Future<void> _search({bool showEmptyError = true}) async {
    final value = _query.text.trim();
    if (value.length < 3) return;
    final request = ++_searchRequest;

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final results = await _placeSearch.search(
        value,
        limit: 7,
      );
      if (!mounted || request != _searchRequest) return;
      setState(() {
        _results = results;
        _searching = false;
        if (results.isEmpty && showEmptyError) {
          _error = 'No match found. Try adding your city or state.';
        }
      });
    } catch (error) {
      if (!mounted || request != _searchRequest) return;
      setState(() {
        _searching = false;
        _error = error.toString().contains('Timeout')
            ? 'Search timed out. Try again in a moment.'
            : 'Search failed. Try again — if it keeps failing, check Wi‑Fi or mobile data.';
      });
    }
  }

  Future<void> _choose(PlaceResult place) async {
    _auto3dTimer?.cancel();
    setState(() {
      _searching = true;
      _error = null;
    });

    // Load the natural OSM campus polygon (not a square bounding box).
    final naturalBoundary = await _placeSearch.fetchNaturalBoundary(place);
    if (!mounted) return;

    final college = CollegeModel(
      name: place.displayName,
      position: place.position,
      boundary: naturalBoundary,
    );
    setState(() {
      _selected = college;
      _results = const [];
      _query.text = place.displayName.split(',').first;
      _showMap = true;
      _is3d = false;
      _map = null;
      _searching = false;
    });

    if (naturalBoundary == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No natural campus border in map data for this place — showing pin only',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggle3d() async {
    final map = _map;
    if (map == null || _toggling3d) return;

    _auto3dTimer?.cancel();
    setState(() => _toggling3d = true);
    await map.toggle3d();
    if (!mounted) return;
    setState(() {
      _is3d = map.is3dEnabled;
      _toggling3d = false;
    });
  }

  void _scheduleAutomatic3d(TeamMapController map) {
    _auto3dTimer?.cancel();
    _auto3dTimer = Timer(const Duration(milliseconds: 1000), () async {
      if (!mounted || _map != map || map.is3dEnabled) return;

      setState(() => _toggling3d = true);
      try {
        await map.enable3d(
          tilt: 58,
          bearing: -18,
          duration: const Duration(milliseconds: 2500),
        );
        if (!mounted || _map != map) return;
        setState(() => _is3d = true);
      } catch (_) {
        // The manual button remains available if automatic 3D is unsupported.
      } finally {
        if (mounted && _map == map) {
          setState(() => _toggling3d = false);
        }
      }
    });
  }

  Future<void> _save() async {
    final college = _selected;
    if (college == null) return;

    setState(() => _saving = true);
    await CollegeService.instance.saveCollege(college);
    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.forStudent
              ? 'College selected — next, confirm your campus map border'
              : 'College map saved for this mockup — backend persistence pending',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (widget.forStudent) {
      CampusMapEditorService.instance.clearStudentMapConfirmation();
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const CustomisableMapScreen(confirmMode: true),
        ),
      );
      return;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const AdminDashboard(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showMap && _selected != null) {
      return _buildMapPreview();
    }
    return _buildCollegeSearch();
  }

  Widget _buildCollegeSearch() {
    return Scaffold(
      body: CampusBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
                const Spacer(flex: 2),
                const Center(
                  child: GlassIconOrb(
                    icon: Icons.location_city_rounded,
                    color: AppTheme.purple,
                    size: 78,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Find your college',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Search for the campus you want to use.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.figtree(
                    fontSize: 14,
                    color: AppTheme.inkMuted,
                  ),
                ),
                const SizedBox(height: 28),
                GlassPanel(
                  borderRadius: 22,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _query,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onChanged: _onQueryChanged,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: 'Type college name and city',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              tooltip: 'Search',
                              onPressed: _search,
                              icon: const Icon(Icons.arrow_forward_rounded),
                            ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
                if (_results.isNotEmpty || _error != null) ...[
                  const SizedBox(height: 10),
                  GlassPanel(
                    borderRadius: 22,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _error != null
                        ? Padding(
                            padding: const EdgeInsets.all(14),
                            child: Text(_error!),
                          )
                        : ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 260),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: _results.length,
                              separatorBuilder: (_, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final place = _results[index];
                                return ListTile(
                                  leading: const Icon(Icons.school_outlined),
                                  title: Text(
                                    place.displayName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing:
                                      const Icon(Icons.chevron_right_rounded),
                                  onTap: () => _choose(place),
                                );
                              },
                            ),
                          ),
                  ),
                ],
                const Spacer(flex: 3),
                Text(
                  'The map appears only after you select a result.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.figtree(
                    fontSize: 12,
                    color: AppTheme.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapPreview() {
    final college = _selected!;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          TeamMap(
            config: MapConfig(
              initialCenter: college.position,
              initialZoom: 17.5,
              enable3dOnStart: false,
            ),
            onReady: (controller) async {
              _map = controller;
              await controller.addMarker(
                MapMarkerData(
                  id: 'selected_college',
                  position: college.position,
                  title: college.name.split(',').first,
                  iconColor: '#2563EB',
                ),
              );
              if (college.hasBoundary) {
                await controller.showCampusBoundary(
                  outline: college.boundary!,
                );
              }
              _scheduleAutomatic3d(controller);
            },
          ),
          Positioned(
            left: 16,
            top: MediaQuery.sizeOf(context).height * .44,
            child: GlassPanel(
              borderRadius: 22,
              padding: EdgeInsets.zero,
              blur: 24,
              child: SizedBox(
                width: 104,
                height: 68,
                child: TextButton(
                  onPressed: _toggling3d ? null : _toggle3d,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.purpleDeep,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: _toggling3d
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _is3d
                                  ? Icons.view_in_ar
                                  : Icons.view_in_ar_outlined,
                              size: 27,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _is3d ? '3D ON' : '3D MODE',
                              style: GoogleFonts.figtree(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .4,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                children: [
                  GlassPanel(
                    borderRadius: 22,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Choose another college',
                          onPressed: () {
                            setState(() {
                              _showMap = false;
                              _map = null;
                              _is3d = false;
                              _auto3dTimer?.cancel();
                            });
                          },
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Expanded(
                          child: Text(
                            college.name.split(',').first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.figtree(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GlassPanel(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Confirm this campus?',
                          style: GoogleFonts.figtree(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          college.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.figtree(
                            fontSize: 13,
                            color: AppTheme.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : const Text('Confirm campus'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
