import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_campus/app/firebase_bootstrap.dart';
import 'package:safe_campus/features/heatwave/data/crowd_zone.dart';
import 'package:safe_campus/shared/location/zone_service.dart';

/// Shared crowd zone sync.
/// Uses Firestore when Firebase is configured; otherwise an in-memory store
/// (same phone only — configure Firebase for multi-phone shared heatwave).
class CrowdSyncService {
  CrowdSyncService({ZoneService? zoneService})
      : _zoneService = zoneService ?? ZoneService();

  final ZoneService _zoneService;
  static const _staleAfter = Duration(minutes: 3);

  final _local = <String, CrowdZone>{};
  final _localController = StreamController<List<CrowdZone>>.broadcast();
  Timer? _staleTimer;

  bool get usingFirebase => FirebaseBootstrap.ready;

  Stream<List<CrowdZone>> watchZones() {
    _ensureSeeded();
    _staleTimer ??= Timer.periodic(const Duration(seconds: 30), (_) {
      _markStaleReporters();
    });

    if (usingFirebase) {
      return FirebaseFirestore.instance
          .collection('crowd_zones')
          .snapshots()
          .map((snap) {
        final byId = <String, CrowdZone>{
          for (final z in ZoneService.demoZones)
            z.id: CrowdZone.unknown(id: z.id, name: z.name),
        };
        for (final doc in snap.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          final def = _zoneService.byId(doc.id);
          byId[doc.id] = CrowdZone.fromMap(
            data,
            fallbackName: def?.name ?? doc.id,
          );
        }
        return byId.values.toList();
      });
    }

    return Stream.multi((controller) {
      controller.add(_snapshotLocal());
      final sub = _localController.stream.listen(controller.add);
      controller.onCancel = sub.cancel;
    });
  }

  Future<void> reportLive({
    required String zoneId,
    required String zoneName,
    required String reporterId,
    required int approxCount,
    required int btCount,
    required int wifiCount,
  }) async {
    final now = DateTime.now();
    if (usingFirebase) {
      final ref =
          FirebaseFirestore.instance.collection('crowd_zones').doc(zoneId);
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final reporters = <String>{};
        if (snap.exists) {
          final existing =
              (snap.data()?['activeReporters'] as List<dynamic>? ?? [])
                  .map((e) => e.toString());
          reporters.addAll(existing);
        }
        reporters.add(reporterId);
        tx.set(ref, {
          'id': zoneId,
          'name': zoneName,
          'status': CrowdStatus.live.name,
          'approxCount': approxCount,
          'btCount': btCount,
          'wifiCount': wifiCount,
          'updatedAt': now.toIso8601String(),
          'activeReporters': reporters.toList(),
          'lastHeartbeat': {
            reporterId: now.toIso8601String(),
          },
        }, SetOptions(merge: true));
      });
      return;
    }

    final current = _local[zoneId] ??
        CrowdZone.unknown(id: zoneId, name: zoneName);
    final reporters = {...current.activeReporters, reporterId};
    _local[zoneId] = current.copyWith(
      status: CrowdStatus.live,
      approxCount: approxCount,
      btCount: btCount,
      wifiCount: wifiCount,
      updatedAt: now,
      activeReporters: reporters,
    );
    _emitLocal();
  }

  Future<void> leaveZone({
    required String zoneId,
    required String reporterId,
  }) async {
    if (usingFirebase) {
      final ref =
          FirebaseFirestore.instance.collection('crowd_zones').doc(zoneId);
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return;
        final data = snap.data()!;
        final reporters = (data['activeReporters'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .where((id) => id != reporterId)
            .toSet();
        final status = reporters.isEmpty
            ? CrowdStatus.lastKnown.name
            : CrowdStatus.live.name;
        tx.update(ref, {
          'activeReporters': reporters.toList(),
          'status': status,
        });
      });
      return;
    }

    final current = _local[zoneId];
    if (current == null) return;
    final reporters = {...current.activeReporters}..remove(reporterId);
    _local[zoneId] = current.copyWith(
      activeReporters: reporters,
      status: reporters.isEmpty ? CrowdStatus.lastKnown : CrowdStatus.live,
    );
    _emitLocal();
  }

  void _ensureSeeded() {
    if (_local.isNotEmpty) return;
    for (final z in ZoneService.demoZones) {
      _local[z.id] = CrowdZone.unknown(id: z.id, name: z.name);
    }
  }

  List<CrowdZone> _snapshotLocal() {
    _ensureSeeded();
    return _local.values.toList();
  }

  void _emitLocal() {
    _localController.add(_snapshotLocal());
  }

  void _markStaleReporters() {
    if (usingFirebase) {
      // Client-side stale handling for Firebase is best done with Cloud Functions;
      // for the prototype we also demote local copies based on updatedAt in UI.
      return;
    }
    final now = DateTime.now();
    var changed = false;
    for (final entry in _local.entries) {
      final z = entry.value;
      if (z.status == CrowdStatus.live &&
          z.updatedAt != null &&
          now.difference(z.updatedAt!) > _staleAfter) {
        _local[entry.key] = z.copyWith(
          status: CrowdStatus.lastKnown,
          activeReporters: {},
        );
        changed = true;
      }
    }
    if (changed) _emitLocal();
  }

  void dispose() {
    _staleTimer?.cancel();
    _localController.close();
  }
}
