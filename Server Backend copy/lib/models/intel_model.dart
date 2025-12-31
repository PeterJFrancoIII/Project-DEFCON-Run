class DataSource {
  final String title;
  final String source;
  final String url;
  final String timestamp;

  DataSource({
    required this.title,
    required this.source,
    required this.url,
    required this.timestamp,
  });

  factory DataSource.fromJson(Map<String, dynamic> json) {
    return DataSource(
      title: json['title'] ?? 'Unknown Report',
      source: json['source'] ?? 'Unknown Source',
      url: json['url'] ?? '#',
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class IntelReport {
  final int defconStatus;
  final String trend;
  final double threatDistanceKm;
  final String readinessCondition; // NEW FIELD
  final List<String> summary;
  final String lastUpdated;
  final String locationName;
  final List<DataSource> dataSources; // NEW FIELD

  IntelReport({
    required this.defconStatus,
    required this.trend,
    required this.threatDistanceKm,
    required this.readinessCondition,
    required this.summary,
    required this.lastUpdated,
    required this.locationName,
    required this.dataSources,
  });

  factory IntelReport.fromJson(Map<String, dynamic> json) {
    // Parse Sources List
    var sList = json['data_sources'] as List? ?? [];
    List<DataSource> sources = sList.map((i) => DataSource.fromJson(i)).toList();

    // Parse Summary Strings
    var sumList = json['summary'] as List? ?? [];
    List<String> summaryText = sumList.map((i) => i.toString()).toList();

    return IntelReport(
      defconStatus: json['defcon_status'] ?? 5,
      trend: json['trend'] ?? 'Stable',
      threatDistanceKm: (json['threat_distance_km'] ?? 999.0).toDouble(),
      // Default text if null to prevent UI crash
      readinessCondition: json['readiness_condition'] ?? "Maintain a Readiness Standard of : None",
      summary: summaryText,
      lastUpdated: json['last_updated'] ?? 'Unknown',
      locationName: json['location_name'] ?? 'Unknown Location',
      dataSources: sources,
    );
  }
}
