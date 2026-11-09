class CronStatusResponse {
  const CronStatusResponse({
    this.lastMinuteRun,
    this.lastMidnightRun,
    this.lastSundayRun,
    this.lastMinuteReportId,
    this.lastMidnightReportId,
    this.lastSundayReportId,
  });

  final DateTime? lastMinuteRun;
  final DateTime? lastMidnightRun;
  final DateTime? lastSundayRun;
  final String? lastMinuteReportId;
  final String? lastMidnightReportId;
  final String? lastSundayReportId;

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.parse(value) : null;

  factory CronStatusResponse.fromJson(Map<String, dynamic> json) =>
      CronStatusResponse(
        lastMinuteRun: _date(json['lastMinuteRun']),
        lastMidnightRun: _date(json['lastMidnightRun']),
        lastSundayRun: _date(json['lastSundayRun']),
        lastMinuteReportId: json['lastMinuteReportId'] as String?,
        lastMidnightReportId: json['lastMidnightReportId'] as String?,
        lastSundayReportId: json['lastSundayReportId'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'lastMinuteRun': lastMinuteRun?.toUtc().toIso8601String(),
    'lastMidnightRun': lastMidnightRun?.toUtc().toIso8601String(),
    'lastSundayRun': lastSundayRun?.toUtc().toIso8601String(),
    'lastMinuteReportId': lastMinuteReportId,
    'lastMidnightReportId': lastMidnightReportId,
    'lastSundayReportId': lastSundayReportId,
  };
}
