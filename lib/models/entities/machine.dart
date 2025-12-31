/// Machine model for handling machine data from API
class Machine {
  final int id;
  final String machineId;
  final String machineType;
  final String status;
  final String? location;
  final bool isMasterMachine;
  final String? operatorName;
  final String? contactPhone;
  final String? installationDate;
  final String? notes;
  final int statusU; // User password status (0=disabled, 1=enabled)
  final int statusS; // Supervisor password status (0=disabled, 1=enabled)
  final String? createdAt;
  final String? updatedAt;

  // Society info
  final String? societyName;
  final String? societyId;
  final int? societyDbId;
  final String? presidentName;
  final String? societyLocation;

  // BMC info
  final String? bmcName;
  final String? bmcId;

  // Dairy info
  final String? dairyName;
  final String? dairyId;

  // 30-day statistics
  final int totalCollections30d;
  final double totalQuantity30d;
  final double avgFat30d;
  final double avgSnf30d;

  // Rate chart info
  final String? chartDetails;
  final int activeChartsCount;

  // Correction info
  final String? correctionDetails;
  final int activeCorrectionsCount;

  // Machine image
  final String? imageUrl;

  Machine({
    required this.id,
    required this.machineId,
    required this.machineType,
    required this.status,
    this.location,
    this.isMasterMachine = false,
    this.operatorName,
    this.contactPhone,
    this.installationDate,
    this.notes,
    this.statusU = 0,
    this.statusS = 0,
    this.createdAt,
    this.updatedAt,
    this.societyName,
    this.societyId,
    this.societyDbId,
    this.presidentName,
    this.societyLocation,
    this.bmcName,
    this.bmcId,
    this.dairyName,
    this.dairyId,
    this.totalCollections30d = 0,
    this.totalQuantity30d = 0.0,
    this.avgFat30d = 0.0,
    this.avgSnf30d = 0.0,
    this.chartDetails,
    this.activeChartsCount = 0,
    this.correctionDetails,
    this.activeCorrectionsCount = 0,
    this.imageUrl,
  });

  /// Create Machine from API JSON response
  factory Machine.fromJson(Map<String, dynamic> json) {
    return Machine(
      id: json['id'] ?? 0,
      machineId: json['machineId'] ?? json['machine_id'] ?? '',
      machineType: json['machineType'] ?? json['machine_type'] ?? '',
      status: json['status'] ?? 'inactive',
      location: json['location'],
      isMasterMachine:
          json['isMasterMachine'] == true || json['is_master_machine'] == 1,
      operatorName: json['operatorName'] ?? json['operator_name'],
      contactPhone: json['contactPhone'] ?? json['contact_phone'],
      installationDate: json['installationDate'] ?? json['installation_date'],
      notes: json['notes'],
      statusU: _parseIntSafe(json['statusU'] ?? json['statusu']),
      statusS: _parseIntSafe(json['statusS'] ?? json['statuss']),
      createdAt: json['createdAt'] ?? json['created_at'],
      updatedAt: json['updatedAt'] ?? json['updated_at'],
      societyName: json['societyName'] ?? json['society_name'],
      societyId: json['societyId'] ?? json['society_id']?.toString(),
      societyDbId: _parseIntSafe(json['societyDbId'] ?? json['society_db_id']),
      presidentName: json['presidentName'] ?? json['president_name'],
      societyLocation: json['societyLocation'] ?? json['society_location'],
      bmcName: json['bmcName'] ?? json['bmc_name'],
      bmcId: json['bmcId'] ?? json['bmc_id'],
      dairyName: json['dairyName'] ?? json['dairy_name'],
      dairyId: json['dairyId'] ?? json['dairy_id'],
      totalCollections30d: _parseIntSafe(
        json['totalCollections30d'] ?? json['total_collections_30d'],
      ),
      totalQuantity30d: _parseDoubleSafe(
        json['totalQuantity30d'] ?? json['total_quantity_30d'],
      ),
      avgFat30d: _parseDoubleSafe(json['avgFat30d'] ?? json['avg_fat_30d']),
      avgSnf30d: _parseDoubleSafe(json['avgSnf30d'] ?? json['avg_snf_30d']),
      chartDetails: json['chartDetails'] ?? json['chart_details'],
      activeChartsCount: _parseIntSafe(
        json['activeChartsCount'] ?? json['active_charts_count'],
      ),
      correctionDetails:
          json['correctionDetails'] ?? json['correction_details'],
      activeCorrectionsCount: _parseIntSafe(
        json['activeCorrectionsCount'] ?? json['active_corrections_count'],
      ),
      imageUrl: json['imageUrl'] ?? json['image_url'],
    );
  }

  /// Convert Machine to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'machineId': machineId,
      'machineType': machineType,
      'status': status,
      'location': location,
      'isMasterMachine': isMasterMachine,
      'operatorName': operatorName,
      'contactPhone': contactPhone,
      'installationDate': installationDate,
      'notes': notes,
      'statusU': statusU,
      'statusS': statusS,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'societyName': societyName,
      'societyId': societyId,
      'societyDbId': societyDbId,
      'presidentName': presidentName,
      'societyLocation': societyLocation,
      'bmcName': bmcName,
      'bmcId': bmcId,
      'dairyName': dairyName,
      'dairyId': dairyId,
      'totalCollections30d': totalCollections30d,
      'totalQuantity30d': totalQuantity30d,
      'avgFat30d': avgFat30d,
      'avgSnf30d': avgSnf30d,
      'chartDetails': chartDetails,
      'activeChartsCount': activeChartsCount,
      'correctionDetails': correctionDetails,
      'activeCorrectionsCount': activeCorrectionsCount,
      'imageUrl': imageUrl,
    };
  }

  /// Parse rate chart details into pending and downloaded lists
  RateChartInfo parseChartDetails() {
    final List<ChartItem> pending = [];
    final List<ChartItem> downloaded = [];

    if (chartDetails == null || chartDetails!.isEmpty) {
      return RateChartInfo(pending: pending, downloaded: downloaded);
    }

    final charts = chartDetails!.split('|||');
    for (final chart in charts) {
      final parts = chart.split(':');
      if (parts.length >= 3) {
        final channel = parts[0];
        final fileName = parts[1];
        final status = parts[2];

        final chartItem = ChartItem(channel: channel, fileName: fileName);

        if (status == 'pending') {
          pending.add(chartItem);
        } else {
          downloaded.add(chartItem);
        }
      }
    }

    return RateChartInfo(pending: pending, downloaded: downloaded);
  }

  /// Parse correction details to get count
  CorrectionInfo parseCorrectionDetails() {
    int pendingCount = 0;

    if (correctionDetails != null && correctionDetails!.isNotEmpty) {
      // Format: "pending:X corrections"
      final parts = correctionDetails!.split(':');
      if (parts.length >= 2) {
        final countPart = parts[1].trim().split(' ')[0];
        pendingCount = int.tryParse(countPart) ?? 0;
      }
    }

    return CorrectionInfo(pendingCount: pendingCount);
  }

  /// Get password status display info
  PasswordStatusInfo getPasswordStatusInfo() {
    bool hasUserPassword = statusU == 1;
    bool hasSupervisorPassword = statusS == 1;

    if (hasUserPassword && hasSupervisorPassword) {
      return PasswordStatusInfo(
        text: 'Both passwords enabled',
        statusType: PasswordStatusType.both,
      );
    } else if (hasUserPassword) {
      return PasswordStatusInfo(
        text: 'User password enabled',
        statusType: PasswordStatusType.userOnly,
      );
    } else if (hasSupervisorPassword) {
      return PasswordStatusInfo(
        text: 'Supervisor password enabled',
        statusType: PasswordStatusType.supervisorOnly,
      );
    } else {
      return PasswordStatusInfo(
        text: 'No passwords set',
        statusType: PasswordStatusType.none,
      );
    }
  }

  /// Safe int parser
  static int _parseIntSafe(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Safe double parser
  static double _parseDoubleSafe(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Get formatted installation date
  String? get formattedInstallationDate {
    if (installationDate == null || installationDate!.isEmpty) return null;
    try {
      final date = DateTime.parse(installationDate!);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return installationDate;
    }
  }
}

/// Rate chart info container
class RateChartInfo {
  final List<ChartItem> pending;
  final List<ChartItem> downloaded;

  RateChartInfo({required this.pending, required this.downloaded});
}

/// Single chart item
class ChartItem {
  final String channel;
  final String fileName;

  ChartItem({required this.channel, required this.fileName});
}

/// Password status types
enum PasswordStatusType { both, userOnly, supervisorOnly, none }

/// Password status info container
class PasswordStatusInfo {
  final String text;
  final PasswordStatusType statusType;

  PasswordStatusInfo({required this.text, required this.statusType});
}

/// Correction info container
class CorrectionInfo {
  final int pendingCount;

  CorrectionInfo({required this.pendingCount});
}
