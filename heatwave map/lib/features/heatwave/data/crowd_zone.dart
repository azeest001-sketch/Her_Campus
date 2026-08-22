enum CrowdStatus { unknown, live, lastKnown }

class CrowdZone {
  const CrowdZone({
    required this.id,
    required this.name,
    required this.status,
    required this.approxCount,
    required this.btCount,
    required this.wifiCount,
    required this.updatedAt,
    required this.activeReporters,
  });

  final String id;
  final String name;
  final CrowdStatus status;
  final int approxCount;
  final int btCount;
  final int wifiCount;
  final DateTime? updatedAt;
  final Set<String> activeReporters;

  bool get hasActiveReporter => activeReporters.isNotEmpty;

  String get statusLabel {
    switch (status) {
      case CrowdStatus.unknown:
        return 'Unknown crowd density';
      case CrowdStatus.live:
        return 'Live';
      case CrowdStatus.lastKnown:
        final ago = updatedAt == null
            ? ''
            : ' · ${_formatAgo(DateTime.now().difference(updatedAt!))}';
        return 'Last known$ago';
    }
  }

  CrowdZone copyWith({
    CrowdStatus? status,
    int? approxCount,
    int? btCount,
    int? wifiCount,
    DateTime? updatedAt,
    Set<String>? activeReporters,
  }) {
    return CrowdZone(
      id: id,
      name: name,
      status: status ?? this.status,
      approxCount: approxCount ?? this.approxCount,
      btCount: btCount ?? this.btCount,
      wifiCount: wifiCount ?? this.wifiCount,
      updatedAt: updatedAt ?? this.updatedAt,
      activeReporters: activeReporters ?? this.activeReporters,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'status': status.name,
        'approxCount': approxCount,
        'btCount': btCount,
        'wifiCount': wifiCount,
        'updatedAt': updatedAt?.toIso8601String(),
        'activeReporters': activeReporters.toList(),
      };

  factory CrowdZone.fromMap(Map<String, dynamic> map, {String? fallbackName}) {
    final statusName = map['status'] as String? ?? 'unknown';
    final status = CrowdStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => CrowdStatus.unknown,
    );
    final reporters = (map['activeReporters'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toSet();
    DateTime? updatedAt;
    final raw = map['updatedAt'];
    if (raw is String) {
      updatedAt = DateTime.tryParse(raw);
    }
    return CrowdZone(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? fallbackName ?? map['id'] as String? ?? '',
      status: status,
      approxCount: (map['approxCount'] as num?)?.toInt() ?? 0,
      btCount: (map['btCount'] as num?)?.toInt() ?? 0,
      wifiCount: (map['wifiCount'] as num?)?.toInt() ?? 0,
      updatedAt: updatedAt,
      activeReporters: reporters,
    );
  }

  factory CrowdZone.unknown({required String id, required String name}) {
    return CrowdZone(
      id: id,
      name: name,
      status: CrowdStatus.unknown,
      approxCount: 0,
      btCount: 0,
      wifiCount: 0,
      updatedAt: null,
      activeReporters: {},
    );
  }

  static String _formatAgo(Duration d) {
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

class CrowdEstimate {
  const CrowdEstimate({
    required this.btCount,
    required this.wifiCount,
    required this.approxPeople,
    required this.wifiAvailable,
    this.detail,
  });

  final int btCount;
  final int wifiCount;
  final int approxPeople;
  final bool wifiAvailable;
  final String? detail;
}
