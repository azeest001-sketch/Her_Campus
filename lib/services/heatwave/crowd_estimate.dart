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

class CrowdHotspot {
  CrowdHotspot({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.approxCount,
    required this.btCount,
    required this.wifiCount,
    required this.updatedAt,
    required this.live,
  });

  final String id;
  final double latitude;
  final double longitude;
  int approxCount;
  int btCount;
  int wifiCount;
  DateTime updatedAt;
  bool live;
}
